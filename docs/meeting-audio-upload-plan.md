# Plan: Large Audio / Video File Transcription into Meeting Transcript

> **Status:** PROPOSAL — READ-ONLY survey. No source edits performed. Awaiting Manager/Owner approval (Sovereign Approval Gate).
> **Design priority (OWNER MANDATE): LARGE-FILE-FIRST.** Big audio **and** video files MUST be supported. The primary path therefore **bypasses the Cloudflare Worker ~100 MB request-body limit** by uploading the media to **R2 first** and handing Deepgram a **public R2 URL** — Deepgram fetches the file itself, so large media never streams through the worker.
> **Secondary path:** a `bytes` mode on the *same* route for **small files / local dev**, where the miniflare R2 URL is not internet-reachable by Deepgram.
> **Goal:** Let the Meeting Summary system accept an uploaded **audio** (mp3/wav/m4a/…) or **video** (mp4/mov/webm/…) file, transcribe it via Deepgram **pre-recorded** REST API, and merge the result into the existing meeting transcript — alongside the existing real-time microphone/system STT (Phase 178/179).
> **GitNexus note:** The knowledge graph index is **stale** for this slice (`context`/`impact` on `SttStreamService`, `uploadImage`, `MeetingsBoardSheet` return *not found*; index = 634 symbols, predates Phase 178/179). All findings below come from direct file reads with `file:line` evidence. Run `npx gitnexus analyze` before/after implementation so impact analysis covers the new symbols.

---

## (A) Current Architecture — Findings & Evidence

### A.1 Live STT WebSocket Proxy (Deepgram, Phase 179) — KEY PATTERN TO MIRROR
`cloudflare_backend/cloudflare_worker.js`
- Route: `if (url.pathname === "/api/meetings/stream-stt")` — **line 137**. Requires `Upgrade: websocket`.
- API key: `env.DEEPGRAM_API_KEY` (logged present at **line 143**, used at **line 152** as `Authorization: Token ${env.DEEPGRAM_API_KEY}`). **The key never leaves the worker** — clients only ever see the worker.
- Deepgram live target (**line 146**): `https://api.deepgram.com/v1/listen?model=nova-3&diarize=true&language=th&interim_results=true&endpointing=300`
- Mechanism: worker `fetch(deepgramUrl,{headers:{Upgrade,Authorization}})` → 101 → pipes `WebSocketPair` ↔ Deepgram socket with safe-close helpers (lines ~165–215+).
- **Reuse:** the **auth header + Thai params** carry over verbatim to the pre-recorded REST call.

### A.2 R2 Upload Pipeline — THE LARGE-FILE BYPASS (reusable as-is)
`cloudflare_backend/cloudflare_worker.js`
- `POST /api/upload` — **line 763**: `multipart/form-data`, fields `file` / `uid` / `folder` (default `"uploads"`); stores via `env.ASSETS.put(key, buffer, {httpMetadata:{contentType: file.type}})`; key = `${folder}/${uid}/${crypto.randomUUID()}.${ext}`; returns `{ success, key, url }` where `url = ${protocol}//${host}/api/images/${key}` (**line 786**). **`folder` is parameterized → pass `meetings`.** Content-Type is echoed from `file.type` → audio/video flow through unchanged (only the *fallback defaults* are image-centric).
- `GET /api/images/{key}` — **line 747**: serves the R2 object **publicly** with `Access-Control-Allow-Origin: *`. **This is the Deepgram-reachable public URL** (once deployed on a real host).

`my_ai_assistant/lib/databases/api_cloudflare.dart`
- `static Future<Map<String,dynamic>> uploadImage(List<int> bytes, String filename, {String path = 'uploads'})` — **line 368**: `http.MultipartRequest` → `/api/upload`, 30 s timeout, returns parsed `{url,...}`. **Directly reusable** with `path:'meetings'`; we add a thin generic alias for clarity (see Task L3.1).

### A.3 STT Client Service — the canonical transcript model to reuse
`my_ai_assistant/lib/services/stt_stream_service.dart`
- `class SpeakerUtterance { final int speaker; String text; final DateTime timestamp; }` (JSON `{speaker,text,timestamp}`). **⚠ No `start`/`end`/`words` fields** — Deepgram timing must be folded into `timestamp` (no model change; see §B mapping).
- State: `final List<SpeakerUtterance> _utterances`, `SpeakerUtterance? _interimUtterance`.
- `getJsonTranscript()` → serializes `_utterances` (this is what is persisted to `meeting.transcript`).
- `loadExistingTranscript(raw)` → parses stored JSON list or `Speaker N:` text.
- `_handleTranscriptJson(jsonString)` → **live** frame parser: groups consecutive `alt.words[]` by `w['speaker']`, merges into `_utterances` on `is_final`. **This exact grouping algorithm is the fallback for pre-recorded results when `utterances[]` is absent.**

### A.4 Web Audio Capture (live-only — NOT touched by file upload)
`web/audio_recorder.js` + `lib/services/web_audio_service.dart`: `getUserMedia`/`getDisplayMedia` → `AudioContext` mix → `MediaRecorder` → 250 ms chunks over the worker WS. **The file-upload path needs none of this** (no in-browser MediaRecorder/ffmpeg).

### A.5 Meeting Model — no schema change
`my_ai_assistant/lib/models/meeting_model.dart`: `transcript` (String), `notes`, `summary`, `attachments: List<Map<String,String>>`, `copyWith(...)`. Transcript already holds the JSON utterance list. The uploaded media's R2 URL can also be recorded in `attachments` for traceability (optional, free win from the URL-first path).

### A.6 Meetings Editor UI + Autosave
`my_ai_assistant/lib/ui/meetings/meetings_board_sheet.dart`
- `late final SttStreamService _sttService` — **line 96**; `_includeMic`/`_includeSystem` — **97–98**.
- `_onSttServiceChanged()` — **~line 124**: **only while `_sttService.isRecording`** does it push `getJsonTranscript()` into `_selectedMeeting.copyWith(transcript:…)` + `_scheduleAutoSave()`. **⇒ File ingestion (isRecording == false) MUST call `copyWith` + `_scheduleAutoSave()` explicitly.**
- Debounced autosave `_scheduleAutoSave()` → `Timer(1500ms)` → `_performAutoSave()` with `_isSuppressingAutoSave` guard.
- `_buildSttControls()` — **line 1715**: source toggles + **Start Live Transcription** (`_sttService.startSession(backendBaseUrl: EnvConfig.backendUrl, …)` at **~line 1773**).
- **File-pick precedent:** `_uploadAttachment` + `_isUploading` spinner — **~line 1392** (FilePicker → upload → `_attachments`). Mirror this UX.

**→ The "Upload audio/video" entry point belongs inside `_buildSttControls()`, a sibling to "Start Live Transcription".**

---

## (B) Refined Design — LARGE-FILE-FIRST (R2-URL primary, bytes secondary)

Two reuse-first principles hold: (1) **never expose `DEEPGRAM_API_KEY`** — always proxy through the worker; (2) **reuse the utterance model + debounced autosave** so uploaded transcripts behave identically to live ones.

### B.1 Dual-Mode Decision Matrix (same route, content-type switched)
| Mode | When | Transport | Worker → Deepgram | Body limit | Local dev? |
|---|---|---|---|---|---|
| **URL (PRIMARY — large files, production)** | Default for any file once on a **deployed/public host**; the only viable path for files near/over the worker body limit. | `POST /api/upload` (folder `meetings`) → get public R2 URL → `POST /api/meetings/transcribe-file` with **JSON `{url,language,meetingId}`**. | `Content-Type: application/json`, body `{"url": r2PublicUrl}` — **Deepgram fetches R2 itself; bytes never touch the worker; video audio de-muxed server-side**. | **None** (worker forwards a tiny JSON, not the media). | **No** — Deepgram cannot reach miniflare `localhost` (see §E local caveat). |
| **bytes (SECONDARY — small files / local dev)** | Small clips, or local testing where R2 URL is not internet-reachable. | `POST /api/meetings/transcribe-file` with **raw binary body**. | `Content-Type: <audio/video mime>` echoed, body = raw bytes; worker reads `request.arrayBuffer()` and forwards. | **~100 MB** worker body cap → enforce a client/worker size guard (413). | **Yes** — fully self-contained. |

**Selection rule (client `MeetingTranscriptionService`):**
1. If `EnvConfig.backendUrl` host is `localhost`/`127.0.0.1`/`10.0.2.2` → **bytes mode** (URL mode impossible locally). Warn if file is large.
2. Else (deployed) → **URL mode** (upload→transcribe-by-url) for **all** files — large-file-first.
3. Optional override: tiny files on deployed env may still use bytes mode, but URL mode is the default everywhere in production.

### B.2 Worker Route Contract — `POST /api/meetings/transcribe-file`
Single route, mode auto-detected by request `Content-Type`.

**URL mode (primary) — request:**
```http
POST /api/meetings/transcribe-file
Content-Type: application/json

{ "url": "https://<worker-host>/api/images/meetings/<uid>/<uuid>.mp4",
  "language": "th",
  "meetingId": "<meeting id>" }
```
Worker action: `POST https://api.deepgram.com/v1/listen?model=nova-3&language=th&diarize=true&utterances=true&punctuate=true&smart_format=true`
with headers `Authorization: Token ${env.DEEPGRAM_API_KEY}`, `Content-Type: application/json`, body `{"url": <url>}`.

**bytes mode (secondary) — request:**
```http
POST /api/meetings/transcribe-file?language=th&meetingId=<id>
Content-Type: audio/mpeg            # or video/mp4, audio/wav, video/quicktime, …

<raw binary body>
```
Worker action: same Deepgram URL/params, headers `Authorization: Token …`, `Content-Type: <echoed mime>`, body = `await request.arrayBuffer()`. Enforce a max-size guard (e.g. 90 MB) → **413** with a "use URL mode" message.

**Response (both modes) — `200`:**
```json
{ "success": true,
  "mode": "url",                       // or "bytes"
  "result": { /* full Deepgram pre-recorded JSON: results.channels[] + results.utterances[] */ } }
```
**Errors:** `400 {success:false,error:"Missing url or body"}` · `413 {success:false,error:"File exceeds bytes-mode limit; use URL mode"}` · `502 {success:false,error:"Deepgram failed: <status> <body>"}`. High-verbosity `[Network]`/`[Error]` logs (mirror stream-stt logging): log mode, url/size, Deepgram status, and error body verbatim.

> Deepgram returns the **same params** as live for Thai (`model=nova-3`, `language=th`, `diarize=true`) plus pre-recorded extras `utterances=true&punctuate=true&smart_format=true`. Deepgram ingests common A/V containers (`video/mp4`, `video/quicktime`, `video/webm`, …) and de-muxes audio **server-side** — eliminating in-browser ffmpeg. Exact accepted MIME list is Deepgram-governed; pass the file's `Content-Type` through (bytes mode) / let Deepgram detect from the URL (URL mode) and surface Deepgram's error verbatim. **Verify common formats by curl in Task L1.2.**

### B.3 Deepgram pre-recorded → `SpeakerUtterance` mapping (`ingestPrerecordedResult`)
Pre-recorded JSON differs from streaming. Primary source = top-level **`results.utterances[]`** (present because `utterances=true`); each item: `{ speaker:int, transcript:string, start:double(sec), end:double(sec), … }`.

| Deepgram `utterances[]` field | → `SpeakerUtterance` | Transform |
|---|---|---|
| `speaker` | `speaker` | `(u['speaker'] ?? 0) as int` |
| `transcript` | `text` | direct string |
| `start` (seconds, double) | `timestamp` | `_baseTime.add(Duration(milliseconds: (start*1000).round()))` — preserves chronological order **without any model change** |
| `end` | *(not stored)* | model has no `end`; ignore for v1 (ordering comes from `start`) |

- **Fallback** (no `utterances[]`): read `results.channels[0].alternatives[0].words[]` and run the **exact word-grouping algorithm already in `_handleTranscriptJson`** (group consecutive words by `w['speaker']`), timestamp from each group's first word `start`.
- New API: `void ingestPrerecordedResult(Map<String,dynamic> deepgramJson, {bool replace = false})` → builds `SpeakerUtterance`s via a **pure, unit-testable** helper `List<SpeakerUtterance> _utterancesFromPrerecorded(Map json, {DateTime? base})`, appends (or replaces) into `_utterances`, clears `_interimUtterance`, `notifyListeners()`. The sheet's existing `getJsonTranscript()` → autosave path is unchanged → uploaded transcripts render/persist identically to live STT.
- **Speaker-numbering note:** an uploaded file's diarization speaker indices are **per-source** and may not align with prior live utterances. v1 default = **append**; expose an optional "Replace vs Append" choice (`replace` flag) in the UI.

---

## (C) ASCII Data-Flow Diagrams

### C.1 PRIMARY — Large-file URL path (audio OR video, any size)
```
[Meetings Sheet] pick audio/video file  (FileType.custom: mp3/wav/m4a/mp4/mov/webm/mkv…)
   │ bytes
   ▼
[ApiCloudflare.uploadMeetingMedia(bytes, name, mime)]  ── multipart ──▶ [Worker  POST /api/upload]
   │   (reuses /api/upload, folder='meetings')                              │ env.ASSETS.put(meetings/<uid>/<uuid>.ext,
   │                                                                         │                 {contentType: mime})
   │   ◀────── { url:"https://HOST/api/images/meetings/…" } ◀───────────────┘
   ▼
[ApiCloudflare.transcribeMeetingFile(url:…, language:'th', meetingId)]
   │   POST application/json {url}
   ▼
[Worker  POST /api/meetings/transcribe-file]
   │   POST {"url":…}  + Authorization: Token DEEPGRAM_API_KEY
   ▼
[Deepgram  /v1/listen?model=nova-3&language=th&diarize&utterances&punctuate&smart_format]
   │   ┌──────────────────────────────────────────────────────────────────┐
   │   │ Deepgram FETCHES the R2 URL itself → large file + video NEVER pass │
   │   │ through the worker; audio de-muxed from video server-side.        │
   │   └──────────────────────────────────────────────────────────────────┘
   ▼
 transcript JSON  ── { success:true, mode:"url", result:<deepgram json> } ──▶ back to client
   ▼
[SttStreamService.ingestPrerecordedResult(result)]  → _utterances (from results.utterances[])
   ▼
_selectedMeeting.copyWith(transcript: getJsonTranscript())
   ▼
_scheduleAutoSave() → _performAutoSave() → persist (D1 / SQLite)
   ▼
Transcript tab re-renders — identical to live STT output   (optional: media URL saved to attachments)
```

### C.2 SECONDARY — Small-file / local-dev bytes path
```
[Meetings Sheet] pick small clip
   │ bytes (≤ ~90 MB)
   ▼
[ApiCloudflare.transcribeMeetingFile(bytes:…, mimeType:'audio/mpeg', language:'th')]
   │   POST raw body, Content-Type: audio/mpeg
   ▼
[Worker /api/meetings/transcribe-file]  request.arrayBuffer() → size guard (413 if too big)
   │   forward bytes, Content-Type echoed, Authorization: Token …
   ▼
[Deepgram /v1/listen?…]  (bytes pass THROUGH the worker — only OK for small files)
   ▼
 { success:true, mode:"bytes", result:<deepgram json> } → ingestPrerecordedResult → autosave
```

---

## (D) Recommended Approach
1. **URL mode is the default everywhere in production** (large-file-first); bytes mode is the local-dev / small-file fallback on the same route. No separate endpoints.
2. **Reuse the R2 pipeline** (`/api/upload`, folder `meetings`) for the bypass; reuse the **same Thai Deepgram params** as live plus pre-recorded extras.
3. **Reuse the utterance model + debounced autosave** — uploaded transcript flows through the exact `getJsonTranscript()` → `_scheduleAutoSave()` pipeline.
4. **Keep the sheet thin (anti-bloat):** orchestration (pick → upload → transcribe → ingest, mode selection) lives in a new `meeting_transcription_service.dart`, not inside the already-large `meetings_board_sheet.dart`.
5. **Record the uploaded media URL in `attachments`** (free traceability from the URL-first path).
6. **Worker wall-clock for very long media:** sync REST with `{url}` returns when Deepgram finishes; for extreme durations add the optional async-callback path (Phase L6) to avoid a long-held worker request.

---

## (E) Local-Test Caveat (CRITICAL)
**Deepgram cannot fetch a miniflare/`localhost` R2 URL.** Therefore URL mode is **not** testable purely on local `wrangler dev`. Three sanctioned test strategies:

1. **bytes mode locally (small file):** fully self-contained — Deepgram receives the bytes via the worker.
   ```bash
   curl -X POST "http://localhost:8787/api/meetings/transcribe-file?language=th&meetingId=test" \
        -H "Content-Type: audio/mpeg" --data-binary @small_th.mp3
   # expect: {"success":true,"mode":"bytes","result":{...}}
   ```
   Repeat with `-H "Content-Type: video/mp4" --data-binary @small.mp4` to confirm server-side audio extraction.
2. **URL mode locally against a PUBLIC sample URL** (Deepgram fetches the public sample, not miniflare):
   ```bash
   curl -X POST "http://localhost:8787/api/meetings/transcribe-file" \
        -H "Content-Type: application/json" \
        -d '{"url":"https://dpgr.am/spacewalk.wav","language":"th","meetingId":"test"}'
   # expect: {"success":true,"mode":"url","result":{...}}
   ```
3. **URL mode end-to-end** must be verified **against the DEPLOYED worker** (real public `…/api/images/meetings/…` URL that Deepgram can reach).

> Also note `EnvConfig.sanitizeUrl` rewrites `https://localhost→http://localhost` for *image display*; for Deepgram URL mode the upload must yield a **real public https host** — another reason local large-file URL testing is deployment-only.

---

## (F) Risks & Mitigations
| # | Risk | Impact | Mitigation |
|---|---|---|---|
| 1 | **Worker body limit (~100 MB)** | Large media POST fails (bytes mode) | **URL mode is primary** → media bypasses the worker entirely; bytes mode is small-file/local only, guarded by 413. |
| 2 | **Local URL unreachable** | Deepgram can't fetch miniflare `localhost` | Documented §E: bytes-mode local, or URL-mode via public sample / deployed worker. |
| 3 | **Worker wall-clock on very long media** | Sync request held open | Reasonable lengths return in time; optional async-callback path (Phase L6). |
| 4 | **Privacy** — `/api/images/{key}` is fully public | Uploaded meeting media publicly readable | Unguessable UUID keys (already); add expiring/signed access + R2 lifecycle deletion (Phase L6); document for owner. |
| 5 | **Cost** — Deepgram bills per audio-minute | Spend on long uploads | Surface size/duration before transcribe; usage logging like existing AI-cost logs. |
| 6 | **MIME support is Deepgram-defined** | Exotic formats rejected | Pass `Content-Type`/URL through; surface Deepgram error verbatim; curl-verify common formats (Task L1.2). |
| 7 | **Diarization speaker mismatch** vs live | Indices may not align | Append by default; optional Replace/Append (`replace` flag). |
| 8 | **`start`/`end` absent from model** | Timing lost | Fold `start` into `timestamp` (no schema change); ordering preserved. |
| 9 | **Stale GitNexus index** | Impact analysis unavailable | `npx gitnexus analyze` before/after. |

---

## (G) Phased Task Graph (5-part schema) — LARGE-FILE-FIRST

### Phase L1: Worker Dual-Mode Pre-Recorded Endpoint
- [ ] **Task L1.1**: Add `/api/meetings/transcribe-file` (URL mode primary + bytes mode secondary)
    - *File*: `cloudflare_backend/cloudflare_worker.js`
    - *Logic/Target*: Add a `POST` handler (sibling to `/api/meetings/stream-stt` at **line 137** and `/api/upload` at **line 763**). Branch on `request.headers.get("content-type")`: if it includes `application/json` → parse `{url,language,meetingId}` and Deepgram-POST `Content-Type: application/json` body `{"url":url}` (**URL mode**); else read `await request.arrayBuffer()`, enforce a ~90 MB guard (413), and Deepgram-POST with the echoed `Content-Type` and raw body (**bytes mode**). Both call `https://api.deepgram.com/v1/listen?model=nova-3&language=th&diarize=true&utterances=true&punctuate=true&smart_format=true` with `Authorization: Token ${env.DEEPGRAM_API_KEY}`. Return `{success:true,mode,result:<deepgram json>}`; map Deepgram non-200 → 502 with body. High-verbosity `[Network]`/`[Error]` logs (mode, url/size, Deepgram status+body).
    - *Why*: Single route bypasses the 100 MB limit (URL) while staying locally testable (bytes); keeps `DEEPGRAM_API_KEY` server-side; reuses the proven worker→Deepgram auth + Thai params.
    - *Verification*: **[AUTONOMOUS]** Local bytes: `curl -X POST "http://localhost:8787/api/meetings/transcribe-file?language=th&meetingId=t" -H "Content-Type: audio/mpeg" --data-binary @small_th.mp3` → `success:true,mode:"bytes"` with non-empty `result.results.channels[0].alternatives[0].transcript`. Local URL via public sample: `curl … -H "Content-Type: application/json" -d '{"url":"https://dpgr.am/spacewalk.wav","language":"th","meetingId":"t"}'` → `mode:"url"`. Oversized bytes → 413.
- [ ] **Task L1.2**: Verify A/V MIME coverage + deployed URL-mode E2E
    - *File*: — (verification only)
    - *Logic/Target*: curl bytes mode with `video/mp4` & `audio/wav`; deploy worker and curl URL mode against a real `…/api/images/meetings/…` URL to confirm Deepgram reaches R2 and de-muxes video audio.
    - *Why*: Owner mandate requires large video; must prove server-side extraction + deployed reachability (untestable purely locally — §E).
    - *Verification*: **[AUTONOMOUS]** Deployed-worker curl returns non-empty Thai transcript for an `.mp4` and a large `.wav`; capture the Deepgram JSON as the test fixture for L2.

### Phase L2: STT Service — Pre-Recorded Ingestion
- [ ] **Task L2.1**: Add `ingestPrerecordedResult(...)` + pure parser to `SttStreamService`
    - *File*: `my_ai_assistant/lib/services/stt_stream_service.dart`
    - *Logic/Target*: Add pure `List<SpeakerUtterance> _utterancesFromPrerecorded(Map<String,dynamic> json, {DateTime? base})` — prefer `results.utterances[]` (`{speaker,transcript,start}` → `timestamp = base.add(Duration(ms:(start*1000).round()))`); else fall back to `results.channels[0].alternatives[0].words[]` reusing the `_handleTranscriptJson` speaker-grouping. Add `void ingestPrerecordedResult(Map json,{bool replace=false})` that (replace?clears:keeps) `_utterances`, appends the parsed list, clears `_interimUtterance`, `notifyListeners()`.
    - *Why*: Reuses the single canonical transcript model so uploaded transcripts render/persist identically to live STT; keeps conversion out of the UI; no `SpeakerUtterance` schema change (timing folded into `timestamp`).
    - *Verification*: **[AUTONOMOUS]** Dart test in `my_ai_assistant/test/` feeds the captured Deepgram pre-recorded JSON fixture (from L1.2) into `_utterancesFromPrerecorded` and asserts `getJsonTranscript()` yields the expected ordered `[{speaker,text,timestamp}]`; `python3 runner.py analyze` clean.

### Phase L3: Client API + Orchestration (URL-first, bytes fallback)
- [ ] **Task L3.1**: Add `uploadMeetingMedia(...)` + `transcribeMeetingFile(...)` to `ApiCloudflare`
    - *File*: `my_ai_assistant/lib/databases/api_cloudflare.dart`
    - *Logic/Target*: (a) `static Future<Map<String,dynamic>> uploadMeetingMedia(List<int> bytes, String filename, {String mimeType})` — thin wrapper over the existing `/api/upload` multipart with `folder:'meetings'` (generalizes the image-centric naming of `uploadImage` at **line 368**; carries the real audio/video mime). (b) `static Future<Map<String,dynamic>> transcribeMeetingFile({String? url, List<int>? bytes, String? mimeType, String language='th', String? meetingId})` — if `url!=null` POST JSON `{url,language,meetingId}` (`Content-Type: application/json`); else POST raw `bytes` with `Content-Type: mimeType` and `?language=&meetingId=`. Longer timeout (e.g. 180 s for large pre-recorded). Return parsed `result`/JSON.
    - *Why*: One reusable network surface for both modes paralleling the existing upload helper; generalizes media naming per owner request.
    - *Verification*: **[AUTONOMOUS]** `python3 runner.py analyze` clean; temporary driver calls both modes against deployed/local worker and prints transcript length.
- [ ] **Task L3.2**: Add orchestration service `MeetingTranscriptionService`
    - *File*: `my_ai_assistant/lib/services/meeting_transcription_service.dart` (NEW)
    - *Logic/Target*: `Future<Map<String,dynamic>> pickAndTranscribe({required String meetingId})` → FilePicker (`FileType.custom`, audio+video extensions) → **mode selection** (host is localhost/127.0.0.1/10.0.2.2 → bytes; else → URL: call `uploadMeetingMedia` then `transcribeMeetingFile(url:…)`) → return Deepgram `result` (+ the uploaded url for attachment). Expose progress/state callbacks; size-warn for bytes mode.
    - *Why*: Large-file-first selection logic + keeps `meetings_board_sheet.dart` under the 600–700-line anti-bloat mandate.
    - *Verification*: **[AUTONOMOUS]** `python3 runner.py analyze` clean; file < 300 lines.

### Phase L4: Meetings Sheet — Upload Entry Point + Ingest + Autosave
- [ ] **Task L4.1**: Add "Upload audio/video" control and wire ingestion
    - *File*: `my_ai_assistant/lib/ui/meetings/meetings_board_sheet.dart`
    - *Logic/Target*: In `_buildSttControls()` (**line 1715**), add a secondary button "Upload audio/video" (disabled while `_sttService.isRecording`). On tap: set a `_isTranscribing` flag (spinner, mirror `_isUploading` at **~line 1392**); call `MeetingTranscriptionService.pickAndTranscribe(meetingId: _selectedMeeting!.id)`; on success `_sttService.ingestPrerecordedResult(result)`, then **explicitly** `_selectedMeeting = _selectedMeeting!.copyWith(transcript: _sttService.getJsonTranscript())` + `_scheduleAutoSave()` (because `_onSttServiceChanged` only fires while recording — **~line 124**); optionally append the uploaded media URL to `_attachments`; success/error via existing notification style.
    - *Why*: Adds the file path beside live STT without disturbing the live pipeline; reuses debounced autosave + transcript rendering.
    - *Verification*: **[AUTONOMOUS]** `python3 runner.py analyze` clean; manual E2E on **deployed** web: pick a large Thai `.mp4` → transcript appears in the Transcript tab + "Saved" fires; local: pick a small clip (bytes mode) → same result.

### Phase L5: Verification & Docs
- [ ] **Task L5.1**: Full static analysis + dual-mode E2E + index refresh
    - *File*: — (verification only)
    - *Logic/Target*: `python3 runner.py analyze` (zero new errors). E2E: URL mode (large audio + large video) on **deployed** worker; bytes mode (small clip) locally. Confirm Thai accuracy parity with live STT. `npx gitnexus analyze` to refresh the stale index.
    - *Why*: Sovereign self-testing mandate; restore graph freshness.
    - *Verification*: **[AUTONOMOUS]** analyzer exits clean; curl + screen evidence of large-file transcript inserted + autosaved in both modes; `.gitnexus/meta.json` symbol count increases.

### Phase L6 (DEFERRED / optional): Async Callback + Privacy Hardening for very long media
- [ ] **Task L6.1**: Deepgram async callback + signed/expiring R2 access
    - *File*: `cloudflare_backend/cloudflare_worker.js` (+ client)
    - *Logic/Target*: For extreme-duration media, call Deepgram URL mode with `&callback=<worker callback route>`; add a callback route that writes the finished transcript into the meeting (D1) and notifies the client (reuse `BOARD_HUB` realtime). Add unguessable + expiring/signed access and R2 lifecycle deletion for `meetings/` objects.
    - *Why*: Removes worker wall-clock risk on very long recordings; closes the public-URL privacy gap (Risk #4).
    - *Verification*: **[AUTONOMOUS]** Upload a multi-hour recording; transcript lands asynchronously without a blocked worker request; expired URL returns 403/404.

---

## Files to Touch (summary)
| File | Change | Mode relevance |
|---|---|---|
| `cloudflare_backend/cloudflare_worker.js` | NEW route `/api/meetings/transcribe-file` (dual: JSON `{url}` primary + raw bytes secondary → Deepgram pre-recorded, Thai params) | both |
| `my_ai_assistant/lib/databases/api_cloudflare.dart` | NEW `uploadMeetingMedia(...)` (generalized media upload, folder `meetings`) + NEW `transcribeMeetingFile({url?,bytes?,…})` | both |
| `my_ai_assistant/lib/services/stt_stream_service.dart` | NEW `ingestPrerecordedResult(...)` + pure `_utterancesFromPrerecorded(...)` | both |
| `my_ai_assistant/lib/services/meeting_transcription_service.dart` | **NEW** orchestration (pick → mode-select → upload/transcribe → ingest) | both |
| `my_ai_assistant/lib/ui/meetings/meetings_board_sheet.dart` | NEW "Upload audio/video" control in `_buildSttControls()`; wire ingest + explicit `copyWith` + autosave | both |
| `my_ai_assistant/test/…` | NEW fixture test for pre-recorded parsing | — |
| `meeting_model.dart` | **No change** (transcript string reused; optional `attachments` URL entry) | — |
| `web/audio_recorder.js`, `web_audio_service.dart` | **No change** (live-capture only) | — |
| `cloudflare_backend/cloudflare_worker.js` `/api/upload` | OPTIONAL: generalize image-centric fallback defaults to accept audio/video naming | URL |
