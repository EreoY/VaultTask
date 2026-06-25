# Advanced RAG — 3-Agent Architecture Survey & Design Proposal

> **Status:** RESEARCH ONLY. No source code is being modified. No build approval is requested yet.
> **Scope:** Survey current retrieval/context architecture of the Calenda AI agent, then propose the owner's desired 3-agent (Main → Verifier → Query) Advanced RAG pattern and assess feasibility against the real Flutter/Dart + Cloudflare reality.

---

## (A) Current Retrieval Architecture — Findings (with evidence)

### A.1 The retrieval model today is **"full live-context dump"**, NOT RAG

There is **no vector store, no embeddings, no semantic search, no similarity ranking** anywhere in the codebase. A precise scan of every `.dart` and `.js` file for `embedding | vectorize | cosine | semantic search | knn | @cf/baai | text-embedding` returned **zero matches**. (The broad grep that returned 243 hits was entirely UI false-positives — e.g. `drag_indicator`, vector image assets, `firebase_options`.)

**Plain answer: There is no true RAG today. It is 100% live-context injection.**

### A.2 How the context window is assembled — `context_builder.dart`

`ContextBuilder.buildLiveContext()` (`my_ai_assistant/lib/ai_agent/memory/context_builder.dart:6`) builds the entire workspace as one plain-text blob and injects it into the **system message** on **every single turn**:

- Fetches **all** boards for the user — `ApiCloudflare.getBoards(uid)` (`:11`).
- For each board, writes columns, labels, **every member + role** (`:50-62`), then loops and writes **every task** in that board with ID/title/status/assignee/image-description (`:65-78`) via `ApiCloudflare.getTasksByBoard(b.id)` (`:67`).
- Optional `activeTask` block prepends the full task detail when chatting inside a task modal (`:18-35`).

**Implication:** Token cost scales linearly with total workspace size (boards × tasks × members). Nothing is filtered to the user's actual question — the model receives the whole graph every turn.

### A.3 The agent loop — `misty_agent.dart` (single, client-side agent)

`MistyAgent` is one client-side agent. `processMessage()` (`my_ai_assistant/lib/ai_agent/core/misty_agent.dart:198`):

1. Builds the full live context (`ContextBuilder.buildLiveContext`, `:209`) → `_buildSystemMessage` (`:39`) which concatenates `Persona.coreMandates + SkillTaskManager.rules + SkillVision.rules + context`.
2. `_callCfApi` (`:163`) posts to `${EnvConfig.backendUrl}/api/ai/chat` with `system + _history`, **all 16 tools** (`allAiTools.map(_convertTool)`, `:170`), `max_tokens: 1500`, model `google/gemma-4-26b-a4b-it` (`:23`).
3. **Tool orchestration is client-side.** Read-only tools (`query_*`, `list_*`, `check_*`, `show_*`, `get_actual_image`, `update_image_description`) are dispatched and executed locally in a big `if/else` (`:300-420`) against `QueryHandlers`/`UIHandlers`/etc.; mutating tools (`create_/update_/delete_/move_`) are deferred to `actionCalls` → draft cards.
4. **Phase 122 single-turn optimization** lives here: `canSkipSecondCall` (`:455-480`). If the model already returned text AND only read-only tools fired, the second LLM call is skipped to save tokens/latency. Otherwise a **second pass** runs, plus an **empty-reply recovery** third call (`:495-525`). So worst-case today is already **up to 3 LLM round-trips**.

### A.4 History / sliding window — `state_chat.dart`

The Phase 122 sliding window is in `_convertMessagesToAgentHistory` (`my_ai_assistant/lib/state_managers/state_chat.dart:804`): `msgs.take(14)` ≈ 7 turns (`:805`), reversed to chronological, then pushed into the agent via `setHistory` (`misty_agent.dart:35`, called from `state_chat.dart:169-170,436`). Image attachments are collapsed to **text descriptions** for older turns and only the latest user turn keeps inline base64.

### A.5 The query tools are thin and partly redundant — `query_handlers.dart` / `query_defs.dart`

- `query_team_tasks` (`query_handlers.dart:27`) genuinely re-fetches `ApiCloudflare.getTasksByBoard` — i.e. it re-queries data **already present** in the live-context dump.
- `query_board_members` (`:62`), `check_board_updates` (`:70`), `check_member_roles` (`:74`) are effectively **no-ops** returning canned strings like *"ดึงจาก live context ของระบบแล้ว"*.
- Tool **definitions** (`query_defs.dart`) are well-formed (`list_team_boards`, `query_team_tasks`, `query_board_members`, `check_board_updates`, `check_member_roles`, `check_conflict`).

**Conclusion:** Tools largely duplicate the context dump rather than narrow it. This is the strongest argument FOR a retrieval gate.

### A.6 The backend is a **stateless single-shot relay** — `cloudflare_worker.js`

`/api/ai/chat` (`cloudflare_backend/cloudflare_worker.js:1172`) receives `messages + tools`, injects server time (`:1211-1228`), normalizes image payloads, then **forwards once** to OpenRouter (`https://openrouter.ai/api/v1/chat/completions`, `:1251`) using model `google/gemma-4-26b-a4b-it` (`:1241`). It persists the assistant reply to D1 `chat_messages` (`:1295+`) and returns. **There is zero orchestration loop server-side** — every multi-call decision happens in Dart.

> **Architectural fact that drives the whole feasibility analysis:** Team boards/tasks live in **Cloudflare D1** (the worker has `env.DB`), but personal tasks live in **client-side SQLite** and live UI state lives in `StateBoards`/`StateTasks` in memory. The worker can read team data directly; it **cannot** see personal/local data.

---

## (B) Proposed 3-Agent Advanced RAG Design

### B.1 Roles (mirrors the Sovereign Manager crew pattern)

| Agent | Holds tools? | Holds full context? | Job |
|-------|-------------|---------------------|-----|
| **Main (Conversationalist)** | ❌ none | ❌ no raw dump | Talks to the user, plans intent, asks Verifier for facts, composes the final answer/drafts. Stays small & focused → less hallucination. |
| **Verifier (Quality Gate)** | ❌ (delegation only) | ❌ | Translates Main's information need into a fetch spec, commands the Query agent, then checks the returned data for **(a) correct FORMAT** and **(b) does it actually ANSWER the need**. Loops back to Query on failure; hands clean, minimal data to Main on pass. |
| **Query (Fetcher)** | ✅ all data tools | ❌ (only what it fetches) | The ONLY agent that touches `StateBoards`/`StateTasks`/D1. Executes `query_team_tasks`, `list_team_boards`, etc. Returns raw rows to Verifier. No reasoning beyond fetching. |

### B.2 Data-flow diagram

```text
                         ┌──────────────────────────────────────────┐
   user message ───────▶ │  MAIN AGENT  (no tools, no raw dump)      │
                         │  - understand intent                      │
                         │  - emit a "data need" (NL or JSON spec)   │
                         └───────────────┬──────────────────────────┘
                                         │ data need
                                         ▼
                         ┌──────────────────────────────────────────┐
                         │  VERIFIER AGENT  (quality gate)           │
                         │  - turn need into a fetch spec            │
                         └───────────────┬──────────────────────────┘
                                         │ fetch spec
                                         ▼
                         ┌──────────────────────────────────────────┐
                         │  QUERY AGENT  (the ONLY fetcher)          │
                         │  - run data tools vs D1 / StateTasks      │
                         └───────────────┬──────────────────────────┘
                                         │ raw data
                                         ▼
                         ┌──────────────────────────────────────────┐
                         │  VERIFIER checks raw data:                │
                         │   (a) correct FORMAT?                     │
                         │   (b) does it ANSWER the need?            │
                         └──────┬───────────────────────┬───────────┘
                       FAIL │ re-fetch (bounded loop)    │ PASS
                            ▼                            ▼
                  back to QUERY AGENT      ┌──────────────────────────┐
                  (max N retries)          │  clean, minimal facts ──▶ │
                                           │      MAIN AGENT           │
                                           │  - compose user answer    │
                                           │  - build draft cards      │
                                           └──────────────────────────┘
```

### B.3 How it maps to the existing system

- The **Query agent's tools already exist** — `QueryHandlers.handleQueryTeamTasks` etc. We are repurposing them, not inventing new retrieval. The Query agent is essentially "the only thing allowed to call `allAiTools` of the read-only family."
- The **Verifier's "answers-the-question" check** is the missing capability today — currently nothing validates that fetched data is sufficient before the model answers.
- The **Main agent** replaces today's monolithic `MistyAgent` system prompt: instead of `Persona + Skills + FULL DUMP + 16 tool schemas`, it would carry only `Persona + a single "ask_for_data" delegation tool`.

### B.4 Goal assessment

1. **Reduces context load on Main** — ✅ Strongly. Main no longer receives the full board/task dump (`context_builder.dart:65-78`) nor 16 tool schemas; it receives only the distilled facts the Verifier approved. This is the biggest structural win.
2. **Main stays focused / less hallucination** — ✅ Plausible. A small prompt with one delegation tool reduces "tool soup" confusion. Caveat: hallucination risk shifts to the Query/Verifier layer (wrong fetch spec → confidently-wrong clean data).
3. **Data-quality gate** — ✅ Genuinely new value. Today nothing checks sufficiency. This directly addresses the redundant/no-op query tools found in A.5.

---

## (C) Feasibility & Recommended Approach

### Option A — Client-side orchestration in Dart (3× model calls from `MistyAgent`)
- **How:** Add `MainAgent`, `VerifierAgent`, `QueryAgent` Dart classes; orchestrate the loop inside `MistyAgent.processMessage`, each making its own `/api/ai/chat` call.
- **Pros:** Query agent keeps full access to **both** D1 (team) **and** client-side SQLite/`StateTasks` (personal) — no data-visibility gap. Minimal backend change.
- **Cons:** Each agent step is a network round-trip to the worker → OpenRouter. 3–6 sequential calls = **3–6× latency** and **3–6× LLM cost**. Directly fights the Phase 122 single-turn optimization. Client carries orchestration complexity.

### Option B — Server-side orchestration in `cloudflare_worker.js` (new `/api/ai/agentic` endpoint)
- **How:** A new worker route (optionally a Durable Object) runs the Main→Verifier→Query loop server-side. The Query step reads **D1 directly** (`env.DB`) instead of round-tripping to the client.
- **Pros:** The big token win is real here — the heavy data dump never leaves the worker; Main sees only distilled facts. Query→Verifier loops are worker-internal (fast, no client latency per hop). Centralizes complexity in one place.
- **Cons / hard constraint:** The worker **cannot see personal tasks (client SQLite) or unsynced in-memory `StateTasks`**. Server-side RAG works cleanly for **team boards/tasks (D1)** only. Personal-data questions would still need a client-side query path or a sync step.

### ⭐ Recommendation (for discussion — not for build yet)

**Hybrid, phased, and start cheap:**

1. **First, do NOT necessarily make all three "agents" LLM calls.** The Verifier's format/sufficiency check can be **deterministic Dart/JS validation** (row count > 0, required fields present, IDs resolve) for the common cases — giving ~80% of the quality-gate benefit at near-zero added cost. Reserve an actual Verifier LLM call only when deterministic checks are ambiguous.
2. **Recommended target = Option B (server-side) for TEAM data**, because that is where the context-dump token cost actually lives (A.2/A.6) and where data is already in D1.
3. **Keep a thin client-side Query path for PERSONAL/SQLite data** (Option A fallback) so no feature regresses.
4. Use a **smaller/cheaper model** for the Query and Verifier roles (they don't need the conversational model) to contain cost.

This preserves the spirit of the owner's 3-agent design (delegation + quality gate + focused Main) while respecting the Phase 122 cost discipline.

---

## (D) Risk Analysis

| # | Risk | Severity | Mitigation |
|---|------|----------|------------|
| R1 | **Latency regression** vs Phase 122 single-turn — 3–6 sequential LLM hops. | High | Prefer server-side loop (Option B, intra-worker hops); make Verifier deterministic where possible; cap retry loop at N=1–2. |
| R2 | **LLM cost multiplies** (3–6× calls per user message). | High | Cheap model for Query/Verifier; deterministic Verifier; only invoke the loop when a data need is detected (skip for pure chit-chat). |
| R3 | **Personal/SQLite data invisible server-side.** | High | Keep client-side Query fallback; or sync personal tasks to D1 (separate decision). |
| R4 | **Hallucination shifts, not disappears** — bad fetch spec → confident wrong "clean data." | Medium | Verifier must echo the original need + cite row IDs; Main must answer only from provided facts. |
| R5 | **Complexity / maintainability** — multi-agent state, retry loops, two failure modes (format vs sufficiency). | Medium | Strong logging per Mandate §3; keep each agent ≤ one responsibility; file-size discipline (≤600–700 lines). |
| R6 | **Retry loop non-termination** (Verifier ↔ Query ping-pong). | Medium | Hard max-retry counter + a "best-effort" escape hatch that returns partial data with a flag. |
| R7 | **Redundancy with existing tools** — `query_team_tasks` already re-fetches; risk of double work. | Low | Consolidate read tools into the single Query agent; delete/neutralize no-op tools (A.5). |

---

## (E) Draft Phased Task Graph (NOT for execution — proposal only)

> Uses the mandated 5-part schema. **Status is `[ ] Proposed` for all — nothing is approved or built.**

### Phase RAG-1: Proof-of-Concept Retrieval Gate (lowest risk, validates the idea)
- [ ] **Task RAG-1.1**: Add a deterministic "sufficiency validator" helper
    - *File*: `my_ai_assistant/lib/ai_agent/memory/retrieval_validator.dart` (new)
    - *Logic/Target*: Create `class RetrievalValidator` with `ValidationResult validate(String need, List<Map> rows)` — checks row count, required fields, and ID resolvability. No LLM.
    - *Why*: Delivers ~80% of the Verifier's quality-gate value at zero LLM cost; de-risks before adding model calls (mitigates R1/R2).
    - *Verification*: **[AUTONOMOUS]** Unit test `test/test_retrieval_validator.dart` with empty/partial/complete row fixtures; assert pass/fail flags. Run `python3 runner.py analyze`.
- [ ] **Task RAG-1.2**: Replace no-op query handlers with real scoped fetches
    - *File*: `my_ai_assistant/lib/ai_agent/tools/handlers/query_handlers.dart`
    - *Logic/Target*: Make `handleQueryBoardMembers`/`handleCheckUpdates`/`handleCheckRoles` return real scoped data instead of canned strings (A.5).
    - *Why*: The Query agent needs genuine fetchers, not placeholders.
    - *Verification*: **[AUTONOMOUS]** Call each handler with a seeded board_id; assert non-canned, schema-correct output.

### Phase RAG-2: Server-side Query Agent for Team Data (Option B core)
- [ ] **Task RAG-2.1**: Add `/api/ai/retrieve` endpoint
    - *File*: `cloudflare_backend/cloudflare_worker.js`
    - *Logic/Target*: New route that accepts a `fetch_spec` and reads D1 directly (boards/tasks/members), returning compact JSON — no OpenRouter call.
    - *Why*: Moves the heavy dump off the Main agent's context window (A.2/A.6); biggest token win.
    - *Verification*: **[AUTONOMOUS]** `curl` the local wrangler endpoint with a sample spec; assert correct rows. Run `python3 runner.py dev` to host.
- [ ] **Task RAG-2.2**: Server-side Verifier (deterministic-first)
    - *File*: `cloudflare_backend/cloudflare_worker.js`
    - *Logic/Target*: After retrieve, run deterministic checks; only escalate to a cheap LLM Verifier call if ambiguous. Bounded retry (max 2).
    - *Why*: Quality gate without per-turn LLM cost explosion (R2/R6).
    - *Verification*: **[AUTONOMOUS]** Force an under-fetch fixture; assert one retry then escape-hatch with partial-data flag.

### Phase RAG-3: Lean Main Agent (context-window reduction payoff)
- [ ] **Task RAG-3.1**: Add a `request_data` delegation tool & strip the full dump from Main
    - *File*: `my_ai_assistant/lib/ai_agent/core/misty_agent.dart`, `my_ai_assistant/lib/ai_agent/memory/context_builder.dart`
    - *Logic/Target*: Behind a feature flag, build the Main system message WITHOUT `buildLiveContext`'s task dump and WITHOUT the 16 tool schemas — only `Persona` + one `request_data` tool. Route `request_data` to the Phase RAG-2 endpoint.
    - *Why*: Realizes Goals 1 & 2 (smaller context, fewer tools → less hallucination).
    - *Verification*: **[AUTONOMOUS]** Log token counts of system message before/after the flag; assert a measurable reduction. `python3 runner.py analyze`.
- [ ] **Task RAG-3.2**: A/B latency & cost telemetry
    - *File*: `cloudflare_backend/cloudflare_worker.js` (logging block)
    - *Logic/Target*: Log per-message LLM-call count, total tokens, wall-clock latency for legacy vs 3-agent path.
    - *Why*: Empirically prove the trade-off vs Phase 122 before committing (R1/R2).
    - *Verification*: **[AUTONOMOUS]** Run 5 sample queries each path; compare logged metrics.

### Phase RAG-4 (OPTIONAL / future): True semantic RAG
- [ ] **Task RAG-4.1**: Evaluate Cloudflare Vectorize + an embedding model for task/board semantic recall
    - *File*: design note only
    - *Logic/Target*: Assess embedding tasks/notes for "find me tasks about X" beyond exact filters.
    - *Why*: Only worthwhile once the 3-agent gate proves value; current need is filtering, not semantic recall.
    - *Verification*: **[AUTONOMOUS]** Prototype embed+query on a fixture; measure recall vs the deterministic Query agent.

---

*End of research document. Awaiting owner decision on direction (Option A vs B vs Hybrid) before any Approval Gate / build.*
