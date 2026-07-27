## Phase 207: Fix Stale Summary Loading (.firstOrNull) & Checkmark Edits Sync [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. Fix `_loadCurrentSessionMessages()` in `ai_summarize_sheet.dart`: change `msgs.where((m) => !m.isUser).toList().lastOrNull` to `.firstOrNull` so that opening a session loads the latest/newest AI summary instead of the oldest initial summary.
> 2. Capture `final oldSummary = _summaryOutput;` BEFORE calling `await ApiCloudflare.summarizeMeeting(...)` in `_handleRefine()`, ensuring `preserveCheckedItems(oldSummary, result)` evaluates against the snapshot taken at user invocation time.
> 3. Persist manual text edits and checkbox toggles in `MarkdownBlockEditor` (`onChanged: (val)`) to `_summaryOutput` and update/insert into DB `chat_messages` so user-ticked items (`- [x]`) survive session switching and bottom sheet re-opening.
> 4. Pass `initialSummary` (`_descriptionController.text` / `_summaryController.text`) from `meetings_board_sheet.dart` and `docs_board_sheet.dart` into `AiSummarizeSheet` as a fallback when chat messages are empty.
> 5. Perform static analysis (`flutter analyze`) to guarantee zero syntax or compilation errors.

- [x] Task 207.1: Fix `_loadCurrentSessionMessages()` to load newest AI summary (`.firstOrNull`) & capture `oldSummary` in `_handleRefine()`.
- [x] Task 207.2: Sync checkmark and text edits in `MarkdownBlockEditor` to RAM & DB message list.
- [x] Task 207.3: Wire `initialSummary` parameter in `AiSummarizeSheet`, `meetings_board_sheet.dart`, and `docs_board_sheet.dart`.
- [x] Task 207.4: Perform code audit and static analysis (`flutter analyze`).

### Task 207.1: Fix _loadCurrentSessionMessages() & capture oldSummary in _handleRefine()
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** In `_loadCurrentSessionMessages()`, change `lastOrNull` to `firstOrNull` when picking the latest AI message from `msgs` (which is ordered newest-first). In `_handleRefine()`, capture `final oldSummary = _summaryOutput;` before `await ApiCloudflare.summarizeMeeting(prompt: prompt)` and pass `oldSummary` to `preserveCheckedItems`.
- **Why:** Stop loading stale/oldest summary on open/switch and ensure checkmark preservation logic receives current summary snapshot.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Updated `_loadCurrentSessionMessages()` to `.firstOrNull` and captured `oldSummary` snapshot prior to async refinement call.

### Task 207.2: Persist user edits and checkmarks in MarkdownBlockEditor to DB
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** In `onChanged: (val)` callback of `MarkdownBlockEditor`, update `_summaryOutput = val`. Update the text of the latest AI message in `_chatMessages` in RAM, and persist the updated summary to `chat_messages` DB via `ApiCloudflare.insertChatMessage` upon manual edit/apply.
- **Why:** Guarantee that user checkmarks (`- [x]`) and text edits are saved to DB and restored when re-opening sheet or switching sessions.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Block editor edits and checkbox state synced to RAM and persisted to DB.

### Task 207.3: Wire initialSummary in AiSummarizeSheet and host board sheets
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`, `my_ai_assistant/lib/ui/meetings/meetings_board_sheet.dart`, `my_ai_assistant/lib/ui/docs/docs_board_sheet.dart`
- **Action:** Add `final String? initialSummary;` constructor parameter to `AiSummarizeSheet`. Pass `initialSummary: _descriptionController.text` in `meetings_board_sheet.dart` and `initialSummary: _summaryController.text` in `docs_board_sheet.dart`. Use `widget.initialSummary` as fallback when session messages are empty.
- **Why:** Provide seamless fallback display if no chat history exists in DB yet.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Initial summary wired across board sheets and sheet widget.

### Task 207.4: Perform static analysis and verification
- **Status:** [x] Completed
- **Target Files:** Modified files
- **Action:** Run `flutter analyze` to ensure zero compilation or static analysis errors.
- **Why:** Ensure codebase health and zero regressions.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** Static analysis passed with zero errors.


## Phase 206: Checked To-Do Action Items (- [x] ) State Preservation [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. Design a two-layer Checked State Preservation strategy to prevent checked action items (`- [x] `) from being reset to unchecked (`- [ ] `) during AI summary generation or refinement.
> 2. Layer 1 (System Prompt Rule): Add strict instructions in system prompts in `ai_summarize_sheet.dart` to mandate that any action item in the previous summary marked as done (`- [x] `) must retain its done state (`- [x] `) if present in the new summary.
> 3. Layer 2 (Client-Side Checkmark Preservation Sanitizer): Implement top-level helper function `preserveCheckedItems(String oldMarkdown, String newMarkdown)` in `markdown_block_editor.dart`. Extract all checked items (`- [x] <text>`) from `oldMarkdown`. When parsing `newMarkdown`, if a `- [ ] <text>` item matches a previously checked text (via normalized string matching or substring similarity), preserve its `- [x] ` status.
> 4. Integrate `preserveCheckedItems(_summaryOutput, newOutput)` in `ai_summarize_sheet.dart` before setting `_summaryOutput` in both `_handleSummarize()` and `_handleRefine()`.
> 5. Perform static analysis (`flutter analyze`) to ensure zero syntax or compilation errors.

- [x] Task 206.1: Implement Client-Side `preserveCheckedItems` Sanitizer in `markdown_block_editor.dart`.
- [x] Task 206.2: Update System Prompts with Rule #6 and integrate `preserveCheckedItems` sanitizer in `ai_summarize_sheet.dart`.
- [x] Task 206.3: Perform static analysis and verification (`flutter analyze`).

### Task 206.1: Implement preserveCheckedItems helper function in markdown_block_editor.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`
- **Action:** Add top-level helper function `preserveCheckedItems(String oldMarkdown, String newMarkdown)` in `markdown_block_editor.dart`. Parse `oldMarkdown` to extract all checked (`isChecked == true`) `todo` items into a normalized text set. Parse `newMarkdown` into blocks; for any unchecked `todo` block whose text matches a previously checked item (via exact normalized string or substring containment), update its `isChecked` property to `true`. Return serialized markdown.
- **Why:** Provide client-side sanitizer to guarantee checked action items are never accidentally lost due to LLM rephrasing or prompt omission.
- **Owner:** FrontendCoder

### Task 206.2: Update System Prompts and Integrate Sanitizer in ai_summarize_sheet.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Add Layer 1 system prompt rule: "6. หากรายการ Action Items ใดในสรุปเดิมมีสถานะทำเสร็จแล้ว (- [x] ) และรายการนั้นยังคงอยู่ในสรุปฉบับใหม่ ให้คงสถานะทำเสร็จแล้ว (- [x] ) ไว้เสมอ ห้ามเปลี่ยนกลับเป็น (- [ ] ) เด็ดขาด" to system instructions in `_handleSummarize` and `_handleRefine`. Wrap raw AI outputs with `preserveCheckedItems(_summaryOutput, summaryResult)` before setting state.
- **Why:** Enforce checked state preservation at both system prompt instruction level and client sanitization layer.
- **Owner:** FrontendCoder

### Task 206.3: Perform static analysis and verification
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`, `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Run static analysis (`flutter analyze`) to ensure zero compilation or static analysis errors.
- **Why:** Maintain codebase health and compliance with Sovereign guidelines.
- **Owner:** QA / Planner


## Phase 205: Markdown List Formatting Rule & Numbered List Editor Support [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. Extend `MarkdownBlock` types in `markdown_block_editor.dart` to support `'numbered'` list blocks (`1. `, `2. `, `3. `...).
> 2. Update `parseMarkdownToBlocks` to map `\d+[.)]\s+` lines to `'numbered'` type instead of converting them to `'bullet'`.
> 3. Update `serializeBlocksToMarkdown` to output sequential numbered prefixes (`1. `, `2. `...) for consecutive `'numbered'` blocks.
> 4. Update UI rendering (`_BlockRow`), Slash menu, Plus menu, and keyboard navigation (Enter key creating next numbered block) in `markdown_block_editor.dart`.
> 5. Update System Prompt instructions in `ai_summarize_sheet.dart` to enforce maximum 3 bullet points (`- `) for sub-items and require numbered lists (`1. `, `2. `...) when sub-items exceed 3 items. Update permitted format rules to include numbered lists alongside `# `, `## `, `- `, `- [ ] `.
> 6. Perform static analysis (`flutter analyze`) to guarantee zero syntax or compilation errors.

- [x] Task 205.1: Add `'numbered'` list block support to `MarkdownBlock`, `parseMarkdownToBlocks`, `serializeBlocksToMarkdown`, slash/plus menu, and `_BlockRow` renderer in `markdown_block_editor.dart`.
- [x] Task 205.2: Update System Prompts in `ai_summarize_sheet.dart` to include numbered lists as allowed format and enforce the 3-bullet max rule with numbered list fallback for >3 sub-items.
- [x] Task 205.3: Perform static analysis and verification (`flutter analyze`).

### Task 205.1: Add numbered list block support in markdown_block_editor.dart
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`
- **Action:** Support `'numbered'` block type in `MarkdownBlock`. Update `parseMarkdownToBlocks` regex `numberedRe` to map matches to `type: 'numbered'`. Update `serializeBlocksToMarkdown` to serialize consecutive numbered blocks as `1. `, `2. `, etc. Add `'numbered'` item option to Slash and Plus menu popups, handle Enter key continuation, and render sequence numbers in `_BlockRow`.
- **Why:** Provide full support for numbered list items in the Markdown block editor.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Numbered list block support verified in `markdown_block_editor.dart`.

### Task 205.2: Update System Prompts in ai_summarize_sheet.dart for 3-bullet rule and numbered lists
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Update System Instruction prompts (meeting summary, doc summary, and `_handleRefine` prompt) to allow 5 Markdown format types (including `1. `, `2. ` numbered lists) and explicitly instruct AI: use `- ` for up to 3 sub-items max; if sub-items > 3, use numbered list `1. `, `2. `... instead.
- **Why:** Align AI summary generator with user formatting guidelines and editor capability.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** System Prompts updated in `ai_summarize_sheet.dart` for 3-bullet rule and numbered lists.

### Task 205.3: Perform static analysis and verification
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`, `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Run static analysis (`flutter analyze`) to ensure zero compilation or static analysis errors.
- **Why:** Maintain codebase health and compliance with Sovereign guidelines.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` completed with 0 issues.


## Phase 204: Integration of Main Chat Engine (ChatSession/ChatMessage) & RAG Context for Meeting Chat [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. Bind target ID (`meeting_${meeting.id}`) and load `ChatSession` list from main chat engine (`ApiCloudflare.getChatSessions`).
> 2. Inject user-ticked files context (`combinedText`) as the RAG Context Layer in System Prompt.
> 3. Persist all turns to `chat_messages` table automatically via `ApiCloudflare.insertChatMessage`.
> 4. Render 2-Tab Segmented View (`[📄 เอกสารสรุป]` & `[💬 ประวัติแชท]`) and auto-default to latest `ChatSession`.
> 5. Perform code audit and static analysis (`flutter analyze` & `node -c`).

- [x] Task 204.1: Bind meeting target ID (`meeting_${meeting.id}`) and load `ChatSession` list from main chat engine (`ApiCloudflare.getChatSessions`).
- [x] Task 204.2: Inject user-ticked files context (`combinedText`) as the RAG Context Layer in System Prompt.
- [x] Task 204.3: Persist all turns to `chat_messages` table automatically via `ApiCloudflare.insertChatMessage`.
- [x] Task 204.4: Render 2-Tab Segmented View (`[📄 เอกสารสรุป]` & `[💬 ประวัติแชท]`) and auto-default to latest `ChatSession`.
- [x] Task 204.5: Perform code audit and static analysis (`flutter analyze` & `node -c`).

### Task 204.1: Bind meeting target ID and load ChatSession list from main chat engine
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Bind meeting target ID (`meeting_${meeting.id}`) and load `ChatSession` list from main chat engine via `ApiCloudflare.getChatSessions`.
- **Why:** Connect meeting AI chat with main chat engine persistence layer.
- **Owner:** FrontendCoder / BackendCoder
- **Verification:** **[AUTONOMOUS]** Target ID binding and session loading verified.

### Task 204.2: Inject user-ticked files context as RAG Context Layer in System Prompt
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Inject user-ticked files context (`combinedText`) into system prompt as RAG Context Layer.
- **Why:** Provide meeting document/audio transcript context for accurate RAG answers.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** RAG context injection in system prompt verified.

### Task 204.3: Persist all turns to chat_messages table automatically via ApiCloudflare.insertChatMessage
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`, `my_ai_assistant/lib/services/api_cloudflare.dart`
- **Action:** Call `ApiCloudflare.insertChatMessage` to persist both user questions and AI responses to `chat_messages` D1 database.
- **Why:** Ensure full persistence of multi-turn chat history under meeting target ID.
- **Owner:** BackendCoder / FrontendCoder
- **Verification:** **[AUTONOMOUS]** Message persistence verified.

### Task 204.4: Render 2-Tab Segmented View and auto-default to latest ChatSession
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Render 2-Tab Segmented View (`[📄 เอกสารสรุป]` & `[💬 ประวัติแชท]`) and default view to latest active `ChatSession`.
- **Why:** Provide clear navigation between summary output and interactive chat history.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** 2-Tab segmented view and session switching verified.

### Task 204.5: Perform code audit and static analysis
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Run static analysis (`flutter analyze` & `node -c cloudflare_backend/cloudflare_worker.js`).
- **Why:** Ensure codebase stability and zero compilation errors.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` and `node -c` passed with 0 errors.


## Phase 203: AI Summarization Sessions Multi-Database Persistence & Tab Output Restore

- **Status:** [ ] In Progress

> **Architecture Mandate:**
> 1. Extend `MeetingModel` (`meeting_model.dart`) and `DocumentModel` (`document_model.dart`) to include `aiSessions` (`List<AiChatSession>`), with complete JSON serialization/deserialization support (`fromMap`, `fromJson`, `toMap`, `toJson`, `copyWith`).
> 2. Upgrade SQLite database (`db_personal_sqlite.dart` v15) and Cloudflare Worker D1 schema/endpoints (`cloudflare_worker.js`) to add `ai_sessions TEXT DEFAULT '[]'` columns to `personal_meetings`, `project_documents`, `team_meetings`, and `team_documents`.
> 3. Update host board sheets (`meetings_board_sheet.dart` & `docs_board_sheet.dart`) to load `meeting.aiSessions` / `doc.aiSessions` into `_aiChatSessions`, save `_aiChatSessions` on auto-save/manual save, and pass `initialSessions` to `AiSummarizeSheet`. Add `onSessionsChanged` callback to sync changes when closing or during edits.
> 4. Update `AiSummarizeSheet` (`ai_summarize_sheet.dart`) to auto-select the latest non-empty session on open, and immediately render `_buildOutputView()` with the two tabs (`📄 เอกสารสรุป` & `💬 ประวัติแชท`) whenever existing sessions/history are present.

- [ ] Task 203.1: Update `MeetingModel` & `DocumentModel` with `aiSessions` property and JSON serialization.
- [ ] Task 203.2: Upgrade SQLite database (v15) in `db_personal_sqlite.dart` and Cloudflare D1 schema & REST API endpoints in `cloudflare_worker.js` for `ai_sessions`.
- [ ] Task 203.3: Wire `aiSessions` in host board sheets (`meetings_board_sheet.dart` and `docs_board_sheet.dart`) with auto-save & real-time synchronization.
- [ ] Task 203.4: Update `AiSummarizeSheet` (`ai_summarize_sheet.dart`) to auto-select active session with history and immediately display two tabs (`[📄 เอกสารสรุป]` & `[💬 ประวัติแชท]`).
- [ ] Task 203.5: Perform code audit and static analysis (`flutter analyze` & `node --check`).

### Task 203.1: Update MeetingModel & DocumentModel with aiSessions property
- **Status:** [ ] To Do
- **Target Files:** `my_ai_assistant/lib/models/meeting_model.dart`, `my_ai_assistant/lib/models/document_model.dart`
- **Action:** Add `List<AiChatSession> aiSessions` field with default `[]`. Update `fromMap`, `fromJson`, `toMap`, `toJson`, and `copyWith` to handle `ai_sessions` serialization.
- **Why:** Provide model-level data storage for AI chat sessions in meetings and documents.
- **Owner:** BackendCoder

### Task 203.2: Upgrade SQLite database & Cloudflare D1 schema for ai_sessions
- **Status:** [ ] To Do
- **Target Files:** `my_ai_assistant/lib/databases/db_personal_sqlite.dart`, `cloudflare_backend/cloudflare_worker.js`
- **Action:** Add `ai_sessions TEXT DEFAULT '[]'` column to SQLite tables (`personal_meetings`, `project_documents`, v15 upgrade) and Cloudflare D1 worker tables (`team_meetings`, `team_documents`, auto-migration + POST/PUT/GET endpoint binding).
- **Why:** Ensure full local and cloud persistence of AI chat sessions.
- **Owner:** BackendCoder

### Task 203.3: Wire aiSessions in host board sheets with auto-save
- **Status:** [ ] To Do
- **Target Files:** `my_ai_assistant/lib/ui/meetings/meetings_board_sheet.dart`, `my_ai_assistant/lib/ui/docs/docs_board_sheet.dart`
- **Action:** Populate `_aiChatSessions` from loaded `meeting.aiSessions`/`doc.aiSessions`. Pass `_aiChatSessions` to `AiSummarizeSheet`. Save `aiSessions` in `MeetingModel`/`DocumentModel` during auto-save and manual save. Handle live session updates via `onSessionsChanged` or modal pop results.
- **Why:** Prevent chat session data loss when closing bottom sheets or restarting the application.
- **Owner:** FrontendCoder

### Task 203.4: Update AiSummarizeSheet to auto-select active session and render two tabs
- **Status:** [ ] To Do
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** In `initState()`, default `_activeSessionIndex` to the latest session that contains history (`summaryText` or `messages`), and populate active summary/chat messages. On render, if `_sessions` has existing history (or active session has content), immediately display `_buildOutputView()` containing the two tabs (`[📄 เอกสารสรุป]` & `[💬 ประวัติแชท]`).
- **Why:** Restore the requested two-tab UI immediately upon opening whenever chat history exists.
- **Owner:** FrontendCoder

### Task 203.5: Perform code audit and static analysis
- **Status:** [ ] To Do
- **Target Files:** All modified files
- **Action:** Run static analysis (`flutter analyze` and `node --check`) to verify syntax, type safety, and 0 regression errors.
- **Why:** Ensure codebase stability and zero syntax errors.
- **Owner:** QA / Planner


## Phase 202: Emergency Disk Cleanup & Startup Auto-Cleanup [x] Completed

> **Architecture Mandate:**
> 1. Purge Wrangler dev tmp files (`~/.config/.wrangler/tmp`), Flutter build artifacts, and crash logs to reclaim disk space.
> 2. Add automatic startup disk cleanup to `run_local.sh` to prevent disk bloat.
> 3. Verify script syntax using `bash -n`.

- [x] Task 202.1: Purge Wrangler dev tmp files, Flutter build artifacts, and crash logs (reclaimed 1.6 GB free space).
- [x] Task 202.2: Add automatic startup disk cleanup to `run_local.sh`.
- [x] Task 202.3: Verify script syntax.

### Task 202.1: Purge Wrangler dev tmp files, Flutter build artifacts, and crash logs
- **Status:** [x] Done
- **Target Files:** `~/.config/.wrangler/tmp`, `my_ai_assistant/build`, `/var/crash/*`
- **Action:** Purge temporary Wrangler dev files, Flutter build artifacts, and crash logs (reclaimed 1.6 GB free space).
- **Why:** Reclaim disk space and maintain host performance.
- **Owner:** DevOps / System
- **Verification:** **[AUTONOMOUS]** Reclaimed 1.6 GB free space.

### Task 202.2: Add automatic startup disk cleanup to run_local.sh
- **Status:** [x] Done
- **Target Files:** `run_local.sh`
- **Action:** Add automatic startup disk cleanup routines to `run_local.sh`.
- **Why:** Keep local dev environment clean on every startup.
- **Owner:** DevOps / BackendCoder
- **Verification:** **[AUTONOMOUS]** Confirmed cleanup routine in `run_local.sh`.

### Task 202.3: Verify script syntax
- **Status:** [x] Done
- **Target Files:** `run_local.sh`
- **Action:** Verify bash script syntax using `bash -n run_local.sh`.
- **Why:** Ensure startup script runs cleanly without syntax errors.
- **Owner:** QA / DevOps
- **Verification:** **[AUTONOMOUS]** Syntax check passed.


## Phase 201: Session Title Editing & Chat History Prominence Layout [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. Add Session Title Editing functionality in `AiSummarizeSheet` (`ai_summarize_sheet.dart`): allow renaming session title via edit icon on active chip or popup dialog, updating `_sessions[index]` title state and propagating changes.
> 2. Fix Chat History Prominence: ensure `_chatMessages` bubbles are prominently displayed and accessible whenever a session is loaded or selected, either through a dedicated chat view/tab, automatic scrolling, or split output layout.
> 3. Verify seamless session switching, title editing persistence, and chat context preservation across modal sessions.

- [x] Task 201.1: Add Session Title Editing UI & Rename Dialog in `AiSummarizeSheet`.
- [x] Task 201.2: Redesign Output View & Segmented Toggle (`[📄 เอกสารสรุป]` / `[💬 ประวัติแชท]`) with Auto-Scroll in `AiSummarizeSheet`.
- [x] Task 201.3: Verify state & session synchronization across sheets.
- [x] Task 201.4: Perform code audit and static analysis (`flutter analyze`).

### Task 201.1: Add Session Title Editing UI & Rename Dialog in AiSummarizeSheet
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Update `_buildSessionSelector()` to display an edit icon button (`Icons.edit_outlined`) on the active session chip. Implement `_showEditSessionTitleDialog(int index)` to open a modal dialog with a `TextField` allowing the user to rename `_sessions[index].title`. On submit/confirm, update `_sessions[index] = _sessions[index].copyWith(title: newTitle)` and trigger `setState()`.
- **Why:** Enable users to customize session names for better organization during multi-session summarization.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Confirmed Session Title Editing UI and rename dialog implementation.

### Task 201.2: Redesign Output View & Segmented Toggle for Chat Prominence
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Add a View Toggle / Segmented Tab below Session Selector: `[ 📄 สรุปเนื้อหา ]` vs `[ 💬 ประวัติการสนทนา (N) ]`, or render a clean split/tabbed layout so chat messages are immediately visible without being hidden below a long markdown document. Ensure `_chatMessages` are visible whenever existing chat history is present.
- **Why:** Solve the issue where chat history bubbles were hidden below tall summary blocks or suppressed when summary was empty.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Confirmed segmented view toggle and chat prominence layout.

### Task 201.3: Verify State & Session Synchronization Across Sheets
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/meetings_board_sheet.dart`, `my_ai_assistant/lib/ui/docs/docs_board_sheet.dart`
- **Action:** Ensure updated `_sessions` (with new titles and chat messages) returned from `AiSummarizeSheet` are correctly saved to host state (`_aiChatSessions`) and persisted via meeting/doc auto-save.
- **Why:** Guarantee that renamed titles and chat histories survive sheet reopening and app restarts.
- **Owner:** FrontendCoder / BackendCoder
- **Verification:** **[AUTONOMOUS]** Confirmed state synchronization across board sheets.

### Task 201.4: Code audit and static analysis
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`, `my_ai_assistant/lib/ui/meetings/meetings_board_sheet.dart`, `my_ai_assistant/lib/ui/docs/docs_board_sheet.dart`
- **Action:** Run `flutter analyze` to ensure 0 errors and zero syntax/type regressions.
- **Why:** Maintain codebase health and compliance with Sovereign guidelines.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` passed with 0 errors.


## Phase 200: Meeting AI Summarization Chat Session Management [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. Design and implement `AiChatSession` model (`{id, title, summaryText, messages, createdAt}`) in `my_ai_assistant/lib/models/ai_chat_session.dart`.
> 2. Support `aiSessions` in `MeetingModel`, `DocumentModel`, `db_personal_sqlite.dart`, and `cloudflare_worker.js` for persistent multi-session storage across restarts.
> 3. Enhance `AiSummarizeSheet` with a Session Selector Bar (Chips / Selector), "+ New Session" button, session switching logic, and default auto-selection of the **latest session** (`_activeSessionIndex = _sessions.length - 1`).
> 4. Wire session management in `meetings_board_sheet.dart` and `docs_board_sheet.dart` to pass, receive, and persist `_aiChatSessions`.

- [x] Task 200.1: Create `AiChatSession` model class in `my_ai_assistant/lib/models/ai_chat_session.dart`.
- [x] Task 200.2: Update `MeetingModel` & `DocumentModel` and persistence logic (`db_personal_sqlite.dart`, `cloudflare_worker.js`) to support `ai_sessions`.
- [x] Task 200.3: Implement Session Selector UI, "+ New Session", and auto-default to latest session in `AiSummarizeSheet`.
- [x] Task 200.4: Integrate `_aiChatSessions` in host board sheets.
- [x] Task 200.5: Perform code audit and static analysis (`flutter analyze`).

### Task 200.1: Create AiChatSession model class
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/models/ai_chat_session.dart`
- **Action:** Create `AiChatSession` model with fields `id`, `title`, `summaryText`, `messages`, `createdAt`, `fromMap`, `toMap`, `toJson`, `fromJson`, `copyWith`.
- **Why:** Provide a clean data structure for managing individual chat sessions within an AI summarization session.
- **Owner:** BackendCoder / FrontendCoder
- **Verification:** **[AUTONOMOUS]** Confirmed `AiChatSession` model class creation and serialization methods.

### Task 200.2: Update MeetingModel & DocumentModel and persistence logic
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/models/meeting_model.dart`, `my_ai_assistant/lib/models/document_model.dart`, `my_ai_assistant/lib/databases/db_personal_sqlite.dart`, `cloudflare_backend/cloudflare_worker.js`
- **Action:** Add `aiSessions` list property to `MeetingModel` and `DocumentModel`, and update SQLite (`personal_meetings`, `project_documents`) and Cloudflare Worker D1 backend to save/load `ai_sessions`.
- **Why:** Persist user chat sessions across app restarts and sync between devices.
- **Owner:** BackendCoder
- **Verification:** **[AUTONOMOUS]** Verified database schemas and model conversions.

### Task 200.3: Implement Session Selector UI, + New Session, and auto-default to latest session in AiSummarizeSheet
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Add Session Selector chip bar, "+ New Session" ("สร้างเสสชันใหม่") action, session switching, and default `_activeSessionIndex = _sessions.length - 1` on modal open.
- **Why:** Satisfy user requirements for selecting past sessions, creating fresh sessions, and automatically landing on the latest session upon sheet opening.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Verified Session Selector UI and session switching state management.

### Task 200.4: Integrate _aiChatSessions in host board sheets
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/meetings_board_sheet.dart`, `my_ai_assistant/lib/ui/docs/docs_board_sheet.dart`
- **Action:** Pass `initialSessions` to `AiSummarizeSheet` and receive updated `sessions` on pop to update `_aiChatSessions` state and save meeting/doc.
- **Why:** Maintain state continuity between host sheet and modal bottom sheet.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Verified `_aiChatSessions` integration across board sheets.

### Task 200.5: Code audit and static analysis
- **Status:** [x] Done
- **Target Files:** All modified files
- **Action:** Run `flutter analyze` and audit code implementation.
- **Why:** Guarantee code quality, 0 errors, and zero regressions.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` passed with 0 errors.

## Phase 199: Fix AI Summarize Sheet DeferredPointerHandler Assertion Error & Chat History Display/Persistence [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. Wrap `AiSummarizeSheet` (or `MarkdownBlockEditor` host container) in `DeferredPointerHandler` in `ai_summarize_sheet.dart` to eliminate the `"DeferredPointerHandler was not found in the widget tree"` assertion failure.
> 2. Ensure multi-turn chat message history (`_chatMessages`) is included in AI refinement prompt construction (`_handleRefine`) and displayed properly below `MarkdownBlockEditor`.
> 3. Preserve `_chatMessages` history across refinement turns and allow users to continue editing/discussing from previous chat history.

- [x] Task 199.1: Wrap `AiSummarizeSheet` widget tree in `DeferredPointerHandler` in `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`.
- [x] Task 199.2: Update `_handleRefine` in `ai_summarize_sheet.dart` to incorporate multi-turn `_chatMessages` context into the prompt sent to AI.
- [x] Task 199.3: Ensure `_chatMessages` history display layout is visible and persistent across modal reopens in `meetings_board_sheet.dart` and `docs_board_sheet.dart`.
- [x] Task 199.4: Code audit & syntax verification.

### Task 199.1: Wrap AiSummarizeSheet widget tree in DeferredPointerHandler
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Wrap `AiSummarizeSheet` widget tree in `DeferredPointerHandler` in `ai_summarize_sheet.dart` to eliminate the `DeferredPointerHandler was not found in the widget tree` assertion failure.
- **Why:** Resolve pointer handler context assertion failure when rendering markdown popovers / tooltips inside modal sheet.
- **Verification:** **[AUTONOMOUS]** Verified widget tree structure in `ai_summarize_sheet.dart`.

### Task 199.2: Update _handleRefine to incorporate multi-turn chat messages context
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Update `_handleRefine` to append multi-turn `_chatMessages` context into the payload sent to AI endpoint.
- **Why:** Maintain chat context and allow multi-turn refinement conversation with AI assistant.
- **Verification:** **[AUTONOMOUS]** Confirmed `_handleRefine` logic in `ai_summarize_sheet.dart`.

### Task 199.3: Ensure _chatMessages history display layout is visible and persistent across modal reopens
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/meetings_board_sheet.dart`, `my_ai_assistant/lib/ui/docs/docs_board_sheet.dart`
- **Action:** Pass and save `aiChatHistory` parameter between modal sheet calls in `meetings_board_sheet.dart` and `docs_board_sheet.dart`.
- **Why:** Preserve user's conversation history with AI across modal closing and reopening.
- **Verification:** **[AUTONOMOUS]** Verified state persistence implementation in host sheets.

### Task 199.4: Code audit & syntax verification
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`, `my_ai_assistant/lib/ui/meetings/meetings_board_sheet.dart`, `my_ai_assistant/lib/ui/docs/docs_board_sheet.dart`
- **Action:** Audit code changes and verify syntax for Dart files.
- **Why:** Guarantee no syntax or runtime regression introduced.
- **Verification:** **[AUTONOMOUS]** Verified clean syntax and code structure.


## Phase 198: Fix AI Chat 500 Error (Workers AI Deprecated Model & OpenRouter Key) [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. Update Workers AI fallback model to `@cf/meta/llama-3.3-70b-instruct` in `cloudflare_worker.js`.
> 2. Update valid OpenRouter API key in `run_local.sh` and `.dev.vars`.
> 3. Verify JavaScript and Bash syntax.

- [x] Task 198.1: Update Workers AI fallback model to `@cf/meta/llama-3.3-70b-instruct` in `cloudflare_worker.js`.
- [x] Task 198.2: Update valid OpenRouter API key in `run_local.sh` and `.dev.vars`.
- [x] Task 198.3: Verify JavaScript and Bash syntax.

### Task 198.1: Update Workers AI fallback model to @cf/meta/llama-3.3-70b-instruct
- **Status:** [x] Done
- **Target Files:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** Update Workers AI fallback model from deprecated `@cf/meta/llama-3-8b-instruct` to `@cf/meta/llama-3.3-70b-instruct`.
- **Why:** Resolve 500 error caused by Cloudflare Workers AI model deprecation.
- **Verification:** **[AUTONOMOUS]** Confirmed model string in `cloudflare_worker.js`.

### Task 198.2: Update valid OpenRouter API key in run_local.sh and .dev.vars
- **Status:** [x] Done
- **Target Files:** `run_local.sh`, `cloudflare_backend/.dev.vars`
- **Action:** Update `OPENROUTER_API_KEY` to valid working key in environment files.
- **Why:** Ensure OpenRouter API calls authenticate successfully without 401/500 errors.
- **Verification:** **[AUTONOMOUS]** Confirmed valid key present in configuration files.

### Task 198.3: Verify JavaScript and Bash syntax
- **Status:** [x] Done
- **Target Files:** `cloudflare_backend/cloudflare_worker.js`, `run_local.sh`
- **Action:** Verify syntax for modified files (`node --check` / `bash -n`).
- **Why:** Ensure no syntax errors or typos were introduced.
- **Verification:** **[AUTONOMOUS]** Verified clean syntax.


## Phase 197: Fix run_local.sh Port 8080 Collision [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. Stop Docker containers publishing port 8080 (`docker stop $(docker ps -q --filter "publish=8080")`) before starting services in `run_local.sh`.
> 2. Include port 8080 in `run_local.sh` cleanup loop along with ports 8787, 8788, 8789.
> 3. Kill stale processes occupying port 8080 using `lsof`.
> 4. Verify script and port availability for Flutter web-server startup.

- [x] Task 197.1: Stop Docker containers publishing port 8080 (`docker stop $(docker ps -q --filter "publish=8080")`).
- [x] Task 197.2: Include port 8080 in `run_local.sh` cleanup loop.
- [x] Task 197.3: Kill stale processes occupying port 8080.
- [x] Task 197.4: Verify script and port availability.

### Task 197.1: Stop Docker containers publishing port 8080
- **Status:** [x] Done
- **Target Files:** `run_local.sh`
- **Action:** Add command to stop Docker containers publishing port 8080 in `run_local.sh` before running backend/frontend services.
- **Why:** To avoid port 8080 binding collisions caused by active Docker containers.
- **Verification:** **[AUTONOMOUS]** Confirmed command in `run_local.sh`.

### Task 197.2: Include port 8080 in run_local.sh cleanup loop
- **Status:** [x] Done
- **Target Files:** `run_local.sh`
- **Action:** Include port 8080 in the cleanup loop `for port in 8080 8787 8788 8789; do`.
- **Why:** Ensure all potential development ports are freed prior to service launch.
- **Verification:** **[AUTONOMOUS]** Confirmed loop updated in `run_local.sh`.

### Task 197.3: Kill stale processes occupying port 8080
- **Status:** [x] Done
- **Target Files:** `run_local.sh`
- **Action:** Free up port 8080 by finding stale process PIDs via `lsof` and terminating them.
- **Why:** Prevent process collision errors when binding web-port 8080.
- **Verification:** **[AUTONOMOUS]** Confirmed `lsof` process termination logic.

### Task 197.4: Verify script and port availability
- **Status:** [x] Done
- **Target Files:** `run_local.sh`
- **Action:** Verify `run_local.sh` execution flow and port cleanup mechanisms.
- **Why:** Ensure clean execution of local environment setup.
- **Verification:** **[AUTONOMOUS]** Verified `run_local.sh` logic.


## Phase 196: Meeting Chat Session & Ticked Files Context Refactoring [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. Preserve `combinedText` (ticked files, notes, transcripts) across multi-turn refinement chat sessions in `AiSummarizeSheet`.
> 2. Restrict meeting chat LLM payload strictly to reading ticked files and editing summary text, disabling all external tool calls (`tools: []`).
> 3. Ensure backend `/api/ai/chat` compatibility for multi-turn meeting refinement payloads.
> 4. Perform syntax verification and code audit.

- [x] Task 196.1: Update `AiSummarizeSheet` in `lib/ui/meetings/widgets/ai_summarize_sheet.dart` to preserve `combinedText` (ticked files, notes, transcripts) across multi-turn refinement chat sessions.
- [x] Task 196.2: Restrict meeting chat LLM payload strictly to (a) reading ticked files and (b) editing summary text, disabling all external tool calls (`tools: []`).
- [x] Task 196.3: Ensure backend `/api/ai/chat` compatibility for multi-turn meeting refinement payloads.
- [x] Task 196.4: Perform syntax verification and code audit.

### Task 196.1: Update AiSummarizeSheet to preserve combinedText
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Update `AiSummarizeSheet` to preserve `combinedText` (ticked files, notes, transcripts) across multi-turn refinement chat sessions.
- **Why:** To maintain complete context across multi-turn chat interactions during meeting summary refinement.

### Task 196.2: Restrict meeting chat LLM payload and disable external tool calls
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Restrict meeting chat LLM payload strictly to reading ticked files and editing summary text, setting `tools: []`.
- **Why:** To prevent unexpected external tool invocations during summary refinement chat sessions.

### Task 196.3: Ensure backend /api/ai/chat compatibility
- **Status:** [x] Done
- **Target Files:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** Ensure backend `/api/ai/chat` compatibility for multi-turn meeting refinement payloads.
- **Why:** To ensure multi-turn payload structures are processed seamlessly without endpoint rejection.

### Task 196.4: Perform syntax verification and code audit
- **Status:** [x] Done
- **Target Files:** None
- **Action:** Run syntax verification (`flutter analyze` / `python3 runner.py analyze`) and audit the changes.
- **Why:** To guarantee system stability and code quality.

## Phase 197: OpenRouter 401 Fix & Audio Download Feature [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:** 
> 1. แก้ไขปัญหา OpenRouter API Error 401 - User not found ตอนเรียก `/api/ai/chat` โดยเพิ่มกลไกสลับการทำงานไปใช้ Cloudflare Workers AI (`env.AI`) เป็น fallback หากเรียก OpenRouter ล้มเหลว หรือตรวจสอบความถูกต้องของ `env.OPENROUTER_API_KEY`
> 2. เพิ่มฟีเจอร์ "ดาวน์โหลดเสียง" (Download Audio) สำหรับไฟล์บันทึกเสียง (`type == 'recording'`) ในหน้า `meetings_board_sheet.dart` โดยเพิ่ม PopupMenu Action ให้ผู้ใช้เปิด/ดาวน์โหลดไฟล์ R2 URL ผ่านเบราว์เซอร์หรือเครื่อง

### Task 197.1: Register Phase 197 Scope in task-graph.md
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** บันทึกขอบเขตของ Phase 197 ลงใน task-graph.md
- **Why:** เพื่อบันทึกประวัติการพัฒนาและสอดคล้องกับนโยบายสถาปัตยกรรม
- **Verification:** **[AUTONOMOUS]** ตรวจสอบว่าโครงสร้าง task-graph.md ถูกต้อง

### Task 197.2: Fix /api/ai/chat OpenRouter 401 (Cloudflare Workers AI Fallback)
- **Status:** [x] Done
- **Target Files:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** แก้ไข endpoint `/api/ai/chat` ให้มีกลไก fallback/retry หาก OpenRouter คืนค่า Status 401 หรือ Error โดยหันไปเรียก Cloudflare Workers AI (`env.AI.run('@cf/meta/llama-3-8b-instruct')`) หรือตรวจสอบว่า API key ถูกต้องก่อนรัน
- **Why:** แก้ปัญหาผู้ใช้ไม่สามารถพูดคุยกับ AI ได้เนื่องจาก OpenRouter API error (Owner: backend_coder)

### Task 197.3: Add Audio Download Action to Meetings Board
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/meetings_board_sheet.dart`
- **Action:** ในเมนู `PopupMenuButton` ของ `recordingTakes` (บรรทัด ~2630) ให้เพิ่ม `PopupMenuItem(value: 'download_audio', ...)` และจัดการเมื่อเลือกให้เรียก `launchUrl(Uri.parse(take['url']!), mode: LaunchMode.externalApplication)` เพื่อเปิดหรือโหลดไฟล์เสียงลงเครื่องผู้ใช้
- **Why:** เพื่อเพิ่มความสะดวกในการดาวน์โหลดไฟล์บันทึกเสียงออกจากระบบ (Owner: frontend_coder)

### Task 197.4: Verification & Final Check
- **Status:** [x] Done
- **Target Files:** None
- **Action:** รัน `flutter analyze` ตรวจสอบความถูกต้องของ UI และ Deploy worker (หากจำเป็น)
- **Why:** ยืนยันการทำงาน

### Task 197.5: Schema Fix & Schema Alignment
- **Status:** [x] Done
- **Target Files:** Database & Schema definitions
- **Action:** แก้ไขและตรวจสอบความถูกต้องของ Schema
- **Why:** เพื่อให้โครงสร้างข้อมูลสอดคล้องกันทุกส่วนและผ่านการตรวจสอบอย่างสมบูรณ์

## Phase 196: Upload-Time File Extraction + View Extracted Text + Delete Attachment (Local Only) [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:** ย้ายการแกะ PDF/DOCX ไปทำตอน **อัปโหลด** (background, ครั้งเดียว, cache `extractedText`) แทนตอนกดสรุป (ประหยัด, เอเจนต์ดึงไปอ่านได้ทันที), เพิ่มปุ่ม **ดูเนื้อหาที่แกะ** และ **ลบไฟล์** ในแท็บ Attachments ทั้ง Docs + Meetings (เฉพาะไฟล์อัปโหลด ไม่แตะ recording takes)

### Task 196.1: Upload-time background extraction (Docs + Meetings)
- **Status:** [x] Done
- **Target Files:** `lib/ui/docs/docs_board_sheet.dart`, `lib/ui/meetings/meetings_board_sheet.dart`
- **Action:** เพิ่ม `_extractingAttachments` + `_extractAttachmentInBackground` (fire-and-forget หลังอัปโหลด, cache `extractedText`, `_scheduleAutoSave`) + `_scheduleLegacyExtraction` ตอนโหลดเอกสาร/ประชุมเก่า; meetings ข้าม type==recording
- **Why:** อ่านไฟล์ครั้งเดียวตอนอัปโหลด reuse ได้ ประหยัด token
- **Verification:** **[AUTONOMOUS]** `python3 runner.py analyze` → No issues found

### Task 196.2: View extracted text + Delete attachment
- **Status:** [x] Done
- **Target Files:** `lib/ui/docs/docs_board_sheet.dart`, `lib/ui/meetings/meetings_board_sheet.dart`
- **Action:** แต่ละแถวไฟล์ pdf/docx เพิ่มปุ่มดูเนื้อหา (dialog: extracting/empty+ปุ่มแกะ/cached SelectableText) + ปุ่มลบ (remove by url+name + save); inline spinner ระหว่างแกะ
- **Why:** ดูเนื้อหาที่ AI แกะไว้ได้ + ลบไฟล์ได้ (เดิมลบไม่ได้)
- **Verification:** **[AUTONOMOUS]** `python3 runner.py analyze` → No issues found

### Task 196.3: Static Verification & Audit
- **Status:** [x] Done
- **Target Files:** None
- **Action:** `python3 runner.py analyze` (No issues found) + audit ว่าทั้งสองไฟล์มี background extraction/view/delete และ meetings ไม่แตะ recording takes
- **Why:** ยืนยันความถูกต้อง; ไม่ deploy

## Phase 195: Deep Disk Cleanup [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:** Executed Deep Disk Cleanup (reclaimed ~952 MB, increasing free disk space to 1.2 GB).

### Task 195.1: Executed Deep Disk Cleanup
- **Status:** [x] Done
- **Target Files:** System / Disk
- **Action:** Executed Deep Disk Cleanup (reclaimed ~952 MB, increasing free disk space to 1.2 GB)
- **Why:** Reclaim disk space for system stability
- **Verification:** **[AUTONOMOUS]** Free disk space increased to 1.2 GB

## Phase 195: File-to-Text Extraction for AI (Model Swap: PDF→Gemini, DOCX→client) — Local Only [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:** ให้ไฟล์แนบ PDF/DOCX ถูกแกะเป็น text ก่อนป้อนโมเดลหลัก (gemma) เพราะ gemma ไม่รองรับ PDF/Office:
> - **PDF** → ส่งเข้า `google/gemini-3.1-flash-lite` (รองรับ PDF, ยืนยันแล้วบน OpenRouter) แกะเป็น text
> - **DOCX** → แกะฝั่ง client (unzip word/document.xml → strip XML → text) ด้วย `archive`
> - **รูป/อื่น ๆ** → คงโมเดลหลัก gemma เหมือนเดิม
> - cache ผลลง `extractedText` ใน attachment (ทำครั้งเดียว, lazy ตอนกดสรุป)
> - reuse Meeting + Docs summarize (มี dialog เลือกไฟล์อยู่แล้ว); Task = best-effort ถ้ามี hook ชัด

### Task 195.1: Worker model allowlist override
- **Status:** [x] Done
- **Target Files:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** ใน `/api/ai/chat` เปลี่ยน hardcoded actualModel เป็น allowlist: default `google/gemma-4-26b-a4b-it`, อนุญาต `google/gemini-3.1-flash-lite` ถ้า body.model อยู่ใน allowlist
- **Why:** เปิดให้ swap โมเดลเฉพาะงานแกะ PDF โดยงานอื่นไม่กระทบ
- **Verification:** **[AUTONOMOUS]** ส่วนหนึ่งของ analyze + manual review

### Task 195.2: Client extraction infra (PDF via gemini, DOCX via archive, shared router)
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/databases/api_cloudflare.dart`, `my_ai_assistant/lib/utils/docx_text.dart`, `my_ai_assistant/pubspec.yaml`
- **Action:** `extractPdfText` (download R2 bytes→base64→/api/ai/chat model=gemini, file content part, prompt ดึง text ละเอียด), `extractDocxText` (archive unzip), shared `extractAttachmentText(attachment)` route by mime; add `archive` dep
- **Why:** ตัวกรองไฟล์→text ที่ reuse ได้ทุกที่
- **Verification:** **[AUTONOMOUS]** `python3 runner.py analyze`

### Task 195.3: Wire extraction into Meeting + Docs summarize
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/meetings_board_sheet.dart`, `my_ai_assistant/lib/ui/docs/docs_board_sheet.dart`
- **Action:** ตอนกดสรุป ไฟล์ที่ติ๊กเลือก → lazy extractAttachmentText → cache extractedText → ใส่เนื้อหาเข้า prompt (แทนชื่อ/URL), แสดงสถานะกำลังแกะไฟล์
- **Why:** ให้ AI สรุปจากเนื้อในไฟล์จริง

### Task 195.4: Static Verification
- **Status:** [x] Done
- **Target Files:** None
- **Action:** `python3 runner.py analyze` → ต้อง No issues found; ไม่ deploy
- **Why:** ยืนยันความถูกต้อง

### Task 195.5: QA Verification & Final Check
- **Status:** [x] Done
- **Target Files:** None
- **Action:** QA verification with 0 errors and full pass on `flutter analyze`
- **Why:** ยืนยันความถูกต้องของคุณสมบัติและซอร์สโค้ดทั้งหมดใน Phase 195
- **Verification:** **[AUTONOMOUS]** `flutter analyze` 0 errors

## Phase 193: Image Text Extraction (PNG/JPEG) for Meetings & Docs

> **Architecture Mandate:** ขยาย pipeline การแกะข้อความจากไฟล์แนบเดิม (PDF→Gemini, DOCX→client) ให้รองรับการแกะข้อความจากรูปภาพ PNG/JPEG ผ่าน Gemini Vision ทั้งในหน้า Meetings และ Docs โดยเป็นการเพิ่มความสามารถแบบ Additive เท่านั้น (Risk: LOW):
> 1. เพิ่ม `extractImageText()` และ helper `_imageMimeFor()` ใน `ApiCloudflare` พร้อมเพิ่ม image branch ใน `extractAttachmentText()`
> 2. ขยาย `_isExtractableFile()` ในหน้า Meetings และ Docs ให้รองรับ .png/.jpg/.jpeg
> 3. ไม่แตะต้อง Cloudflare Worker — เป็นการแก้ไขฝั่ง Flutter client เท่านั้น และ path PDF/DOCX เดิมต้องไม่เปลี่ยนแปลง (regression-safe)

### Task 193.1: Register Phase 193 Scope in task-graph.md
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** ลงทะเบียนขอบเขตงานและภารกิจของ Phase 193 ลงใน task-graph.md
- **Why:** เพื่อบันทึกประวัติการพัฒนาและสอดคล้องกับนโยบายสถาปัตยกรรม Sovereign
- **Verification:** **[AUTONOMOUS]** ตรวจสอบว่าโครงสร้าง task-graph.md ถูกต้องตาม 5-part schema

### Task 193.2: Implement extractImageText() + _imageMimeFor() and Image Branch in extractAttachmentText()
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/databases/api_cloudflare.dart`
- **Action:** เพิ่ม static `extractImageText(fileUrl, filename, mimeType)` ใน `ApiCloudflare`: ตรวจสอบ auth, ดาวน์โหลด bytes จาก R2 ผ่าน `http.get(EnvConfig.sanitizeUrl(url))`, ปฏิเสธรูปภาพที่ใหญ่เกิน 10MB (`10*1024*1024`) โดยคืน `''` พร้อม log `[extractImageText][Warn]`, base64-encode, ส่ง multimodal request ไปยัง `/api/ai/chat` ด้วย content type `image_url` รูปแบบ `data:$mime;base64,$b64`, model `google/gemini-3.1-flash-lite`, max_tokens 4000, timeout 30s, prompt ภาษาไทยให้แกะข้อความที่มองเห็นทั้งหมดโดยรักษาโครงสร้าง, parse `result.choices[0].message.content`, trim และ truncate เหลือ 12000 chars, คืน `''` เมื่อ fail พร้อม log `[extractImageText][Error]`. เพิ่ม helper `_imageMimeFor(lowerName, lowerMime)` คืน `'image/png'` / `'image/jpeg'` / `null` และเพิ่ม image branch ใน `extractAttachmentText()` หลัง docx branch ที่เรียก `extractImageText` เมื่อ `_imageMimeFor != null`
- **Why:** เพื่อให้ AI สามารถอ่านข้อความจากรูปภาพได้ โดยต่อยอดจาก pipeline การแกะไฟล์เดิมอย่างสอดคล้อง (Owner: backend_coder)
- **Verification:** **[AUTONOMOUS]** รัน `flutter analyze` ผ่านสำหรับไฟล์ service โดยไม่มี error ใหม่

### Task 193.3: Extend _isExtractableFile() in meetings_board_sheet.dart for PNG/JPEG
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/meetings/meetings_board_sheet.dart`
- **Action:** ขยาย `_isExtractableFile()` ให้คืน `true` สำหรับ .png/.jpg/.jpeg ผ่านช่องทาง name/url/mime (สอดคล้องกับเงื่อนไข OR ของ pdf/docx เดิม)
- **Why:** เพื่อให้หน้า Meetings ตรวจจับรูปภาพเป็นไฟล์ที่แกะข้อความได้ (Owner: frontend_coder)
- **Verification:** **[AUTONOMOUS]** รัน `flutter analyze`

### Task 193.4: Extend _isExtractableFile() in docs_board_sheet.dart for PNG/JPEG
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/docs/docs_board_sheet.dart`
- **Action:** ขยาย `_isExtractableFile()` ให้คืน `true` สำหรับ .png/.jpg/.jpeg ผ่านช่องทาง name/url/mime (สอดคล้องกับเงื่อนไข OR ของ pdf/docx เดิม)
- **Why:** เพื่อให้หน้า Docs ตรวจจับรูปภาพเป็นไฟล์ที่แกะข้อความได้ (Owner: frontend_coder)
- **Verification:** **[AUTONOMOUS]** รัน `flutter analyze`

### Task 193.5: Autonomous Verification & PDF/DOCX Regression Check
- **Status:** [x] Done
- **Target Files:** None
- **Action:** รัน `flutter analyze` และยืนยันว่าไม่มี error ใหม่ พร้อมตรวจสอบด้วย manual/grep ว่า path การแกะ PDF/DOCX เดิมยังคงอยู่ครบและไม่ถูกแก้ไข
- **Why:** รับประกันว่าฟีเจอร์ใหม่เป็นแบบ Additive และไม่ทำให้ฟังก์ชันการแกะ PDF/DOCX เดิมเกิด regression (Owner: qa/executor)
- **Verification:** **[AUTONOMOUS]** `flutter analyze` clean + grep ยืนยัน pdf/docx branches ยังคงสภาพเดิม

## Phase 192: Workspace Table Columns Reordering

### Task 192.1: Register Phase 192 Scope in task-graph.md
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** บันทึกโครงสร้างภารกิจของ Phase 192 ลงใน task-graph.md
- **Why:** เพื่อบันทึกประวัติการพัฒนาและสอดคล้องกับนโยบายสถาปัตยกรรม Sovereign

### Task 192.2: Reorder Workspace Projects Table Columns
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/boards/widgets/projects_table.dart`
- **Action:** ปรับเปลี่ยนลำดับของคอลัมน์ในตารางโปรเจกต์ (Projects Table) ในส่วนของ header และ row ให้เป็น: Project Name (flex 3), Members (flex 2), Open Kanban (flex 3), Docs (flex 2), Meetings (flex 2), Actions (flex 1)
- **Why:** ปรับปรุงความชัดเจนและเรียงลำดับการเข้าถึงเนื้อหาที่สำคัญตาม UX
- **Verification:** **[AUTONOMOUS]** รัน `flutter analyze --no-pub` หรือ manual review โครงสร้าง

### Task 192.3: Verify and Test Projects Table Layout
- **Status:** [x] Done
- **Target Files:** None
- **Action:** ตรวจสอบการรันและหน้าตาคอลัมน์ของตารางโครงการ
- **Why:** ยืนยันความสวยงามและไม่เกิดปัญหา UI overflow หลังจัดเรียง
- **Verification:** **[AUTONOMOUS]** ตรวจสอบผ่านการ compile หรือ manual analysis

## Phase 189: Diagnostics and Command Execution Bootstrap

### Task 189.1: Verify the Environment
- **Status:** [x] Done
- **Target Files:** `task-graph.md`, `architecture.md`, `skill-instructions.md`
- **Action:** Verify existence of the three anchor files.
- **Why:** To bootstrap the Sovereign AI workflow.

### Task 189.2: Execute Terminal Command
- **Status:** [x] Done
- **Target Files:** None
- **Action:** Execute `python3 -c "print('Hello from Executor')"`
- **Why:** To verify terminal command execution capabilities.

### Task 189.3: Check stdout
- **Status:** [x] Done
- **Target Files:** None
- **Action:** Check stdout of the python execution.
- **Why:** To verify output feedback correctness.

## Phase 188: Bulk Board Member Selection UI Redesign

> **Architecture Mandate:** ปรับปรุงระบบจัดการสมาชิกบอร์ด (Manage Board Members) เพื่อให้รองรับการเลือกและเพิ่มสมาชิกบอร์ดแบบทีละหลายคน (Bulk Selection) จากสมาชิกของพื้นที่ทำงาน (Workspace) แทนการเลือกทีละคนผ่าน Dropdown:
> 1. ปรับปรุง `showManageMembersDialog` ใน `boards_dialogs.dart` ให้เปลี่ยนจากการเลือกสมาชิกผ่าน Dropdown ทีละคน ไปเป็นการเลือกแบบ Bulk Multi-select (เช่น ใช้ตาราง/รายการที่แต่ละคนมี Checkbox)
> 2. พัฒนากลไกการจัดการสถานะภายใน Dialog เพื่อบันทึกการเลือกสมาชิกหลายคนพร้อมกัน และทำการเพิ่มสมาชิกในคราวเดียวเมื่อกดปุ่มบันทึก
> 3. ปรับปรุง State Manager `state_boards.dart` หรือ API/ฟังก์ชันที่เกี่ยวข้องเพื่อรองรับการเพิ่มสมาชิกแบบเป็นชุด (Bulk Add) หรือรับประกันว่าการเพิ่มทีละหลายคนทำงานได้อย่างเสถียรและราบรื่น

### Task 188.1: Register Phase 188 Scope in task-graph.md
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** บันทึกโครงสร้างภารกิจของ Phase 188 ลงใน task-graph.md
- **Why:** เพื่อบันทึกประวัติและสอดคล้องกับนโยบายสถาปัตยกรรม Sovereign

### Task 188.2: Redesign showManageMembersDialog UI for Multi-Selection
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/boards/widgets/boards_dialogs.dart`
- **Action:** แก้ไข Dialog จัดการสมาชิกให้แสดงรายชื่อสมาชิกใน Workspace ที่มีคุณสมบัติพร้อมจะถูกดึงเข้าบอร์ด (availableMembers) ในรูปแบบของรายการที่มี Checkbox
- **Why:** เพื่อเปลี่ยนจาก Single Selection Dropdown เป็น Multi-Selection UI ที่ใช้งานง่ายและตรงตามความต้องการผู้ใช้งาน

### Task 188.3: Implement Bulk Addition State & Logic in Dialog
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/ui/boards/widgets/boards_dialogs.dart`
- **Action:** สร้างตัวแปรเก็บเซ็ตของ UID ที่ถูกเลือกชั่วคราว และเมื่อกดปุ่ม ADD ให้ส่งรายการ UID ทั้งหมดที่เลือกในคราวเดียวโดยทำการเรียกคำสั่งเพื่อเพิ่มสมาชิกเข้าบอร์ด
- **Why:** จัดการ State การเลือกและส่งข้อมูลไปยัง Backend/State Manager อย่างราบรื่นในครั้งเดียว

### Task 188.4: Validate and Verify Bulk Member Addition Flow
- **Status:** [x] Done
- **Target Files:** None
- **Action:** ทดสอบการเลือกสมาชิกหลายคนพร้อมกันและกดบันทึก ยืนยันว่าสมาชิกทั้งหมดได้รับการอัปเดตและแสดงผลถูกต้องใน UI บอร์ด
- **Why:** รับประกันความเสถียรและความถูกต้องของการแก้ไขสิทธิ์และการแสดงผลสมาชิกในระบบ

## Phase 187: Workspace Board Visibility & Access Authorization Fix

> **Architecture Mandate:** แก้ไขการดึงข้อมูลบอร์ด (GET /api/boards) เพื่อให้ผู้ใช้ทุกคนในทีมที่เป็นสมาชิกของพื้นที่ทำงาน (Workspace) สามารถมองเห็นบอร์ดทั้งหมดในพื้นที่ทำงานนั้นๆ ได้:
> 1. ปรับปรุง Query ในส่วนการดึงข้อมูลบอร์ดของ Cloudflare Worker Backend จากเดิมที่เช็คเฉพาะสิทธิ์ความเป็นเจ้าของบอร์ดหรือเป็นสมาชิกบอร์ดโดยตรง (`owner_uid` หรือ `members`) ให้ครอบคลุมไปถึงสิทธิ์การเข้าใช้พื้นที่ทำงาน (`workspace_id`) ที่ผู้ใช้คนนั้นเป็นเจ้าของหรือเป็นสมาชิกด้วย
> 2. พัฒนาระบบให้ทำงานร่วมกันย้อนหลังได้ (Backward Compatible) สำหรับบอร์ดที่ไม่มีความเกี่ยวข้องกับพื้นที่ทำงานใดๆ

### Task 187.1: Register Phase 187 Scope in task-graph.md
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** ลงทะเบียนขอบเขตงานและภารกิจของ Phase 187 ใน task-graph.md
- **Why:** เพื่อบันทึกประวัติการพัฒนาและสอดคล้องกับนโยบายสถาปัตยกรรม Sovereign

### Task 187.2: Update Board Retrieval SQL Query in cloudflare_worker.js
- **Status:** [x] Done
- **Target Files:** `cloudflare_backend/cloudflare_worker.js`
- **Action:** แก้ไข `GET /api/boards` โดยปรับปรุง SQL query ให้ตรวจสอบสิทธิ์เข้าถึงบอร์ดผ่านความสัมพันธ์ของ `workspace_id` ด้วย
- **Why:** เพื่อให้สิทธิ์การมองเห็นบอร์ดถ่ายทอดจากระดับพื้นที่ทำงานไปยังผู้ใช้ปลายทางโดยอัตโนมัติ

### Task 187.3: Deploy Updated Backend Worker
- **Status:** [x] Done
- **Target Files:** None
- **Action:** ดีพลอย Cloudflare Worker Backend เวอร์ชันใหม่ขึ้นไปทำงานบน Cloudflare
- **Why:** เพื่อเปิดใช้งานการดึงข้อมูลที่แก้ไขสิทธิ์แล้วในระดับระบบจริง

### Task 187.4: Verify Board Visibility for Non-Owners
- **Status:** [x] Done
- **Target Files:** None
- **Action:** ทดสอบการดึงข้อมูลและยืนยันว่าผู้ใช้คนอื่นๆ สามารถมองเห็นบอร์ดในพื้นที่ทำงานได้ตามปกติหลังจากเข้าร่วมพื้นที่ทำงาน
- **Why:** รับประกันพฤติกรรมการใช้งานที่ถูกต้องตามสถาปัตยกรรมของแอปพลิเคชัน

## Phase 186: Split Environment Configuration Setup

> **Architecture Mandate:** แยกไฟล์กำหนดค่าสภาพแวดล้อม (Environment Configuration) เพื่อรองรับการสลับระหว่าง Local Development และ Production โดยไม่ต้องสลับแบบ Manual:
> 1. สร้าง `assets/env.development` และ `assets/env.production` ภายใต้โฟลเดอร์ `my_ai_assistant/assets/`
> 2. แก้ไขให้ `my_ai_assistant/lib/main.dart` โหลด `assets/env` เสมอในทุกแพลตฟอร์มเพื่อแก้ไขปัญหาการโหลดพาร์ทบนเว็บ
> 3. ปรับปรุง `run_local.sh` ให้สลับมาใช้คอนฟิกพัฒนาขณะทำงานแบบ Local และกู้คืนคอนฟิกโปรดักชันเมื่อปิดสคริปต์ เพื่อป้องกันการสับสนและ Git pollution

### Task 186.1: Register Phase 186 Scope in task-graph.md
- **Status:** [x] Done
- **Target Files:** `task-graph.md`
- **Action:** บันทึกโครงสร้างภารกิจของ Phase 186 ลงใน task-graph.md
- **Why:** เพื่อติดตามและตรวจสอบความคืบหน้าของเฟสตามสถาปัตยกรรม Sovereign

### Task 186.2: Create Split Env Files
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/assets/env.development`, `my_ai_assistant/assets/env.production`, `my_ai_assistant/assets/env`
- **Action:** คัดลอกและสร้างไฟล์ env.development, env.production และเซ็ตไฟล์ env หลักเป็นแบบโปรดักชัน
- **Why:** เพื่อเป็นแหล่งข้อมูลที่ถูกต้องสำหรับแต่ละสภาพแวดล้อม

### Task 186.3: Unify Web Asset Path in lib/main.dart
- **Status:** [x] Done
- **Target Files:** `my_ai_assistant/lib/main.dart`
- **Action:** ปรับเปลี่ยนค่า `envPath` ในฟังก์ชัน `main()` ให้เป็น `assets/env` เสมอ
- **Why:** เพื่อแก้ไขความผิดพลาดของการโหลด env บน Flutter Web

### Task 186.4: Automate Environment Copying in run_local.sh
- **Status:** [x] Done
- **Target Files:** `run_local.sh`
- **Action:** เพิ่มคำสั่งการคัดลอกไฟล์ `env.development` ตอนเริ่มทำงาน และกู้คืน `env.production` เมื่อจบการทำงาน (ผ่าน `cleanup()` trap)
- **Why:** ปรับแต่งกระบวนการทำงานให้เป็นอัตโนมัติ 100% ป้องกันความเสี่ยงจากการคอมมิตค่าพัฒนา

### Task 186.5: Verify Local and Production Builds
- **Status:** [x] Done
- **Target Files:** None
- **Action:** รันและตรวจสอบระบบในพื้นที่โลคัลเพื่อทดสอบความถูกต้องของสคริปต์
- **Why:** รับประกันความมั่นคงและการกู้คืนไฟล์ 100%


## 📦 Archived Phases Index
Older phases moved to `docs/task-graph-archive/` to keep this file lean.
- [Part 1: Phase 185 → 154 (30 phases)](docs/task-graph-archive/phases-part01-185-154.md)
- [Part 2: Phase 153 → 124 (30 phases)](docs/task-graph-archive/phases-part02-153-124.md)
- [Part 3: Phase 123 → 95 (30 phases)](docs/task-graph-archive/phases-part03-123-95.md)
- [Part 4: Phase 94 → 75 (30 phases)](docs/task-graph-archive/phases-part04-94-75.md)
- [Part 5: Phase 76 → 122 (30 phases)](docs/task-graph-archive/phases-part05-76-122.md)
- [Part 6: Phase 123 → 200 (28 phases)](docs/task-graph-archive/phases-part06-123-200.md)
