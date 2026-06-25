# Strategic Diagnostic Report — Markdown-Based Agent Rendering

> Author: Sovereign Planner (READ-ONLY survey). No source code was modified.
> Scope: AI chat agent display/creation pipeline in `my_ai_assistant`.
> Repo (gitnexus): `calenda_flow`. Date: 2026-06-25.

---

## A. STRATEGIC DIAGNOSTIC REPORT

### Question 1 — CURRENT CAPABILITY AUDIT
**Can the AI chat agent CREATE task cards and DISPLAY structured content today? → YES (both), via two distinct mechanisms.**

**(1a) CREATE task cards → YES, via the interactive Draft flow.**
- The agent never writes to the DB directly during a turn. When it emits `create_team_task` / `update_team_task` / `move_team_task` / `delete_team_task`, `misty_agent.dart` routes these into `actionCalls` (NOT executed immediately) — see the `else { actionCalls.add(fCall); }` branch in `processMessage`, `misty_agent.dart:~352`.
- `DraftBuilder.tryBuildComposite` (`utils/draft_builder.dart:5`) aggregates those calls into a single `synthetic_batch` `FunctionCall` and returns an `AiReply` with `pendingCall`.
- State layer converts that into a `ProposalDraft` (`models/chat_model.dart`, `ProposalDraft` + `TaskDraftItem`) attached to the `ChatMessage` (`message.draft`).
- UI renders `ProposalDraftCard` (`draft_cards.dart:9`) with interactive checkboxes (`Checkbox`/`updateDraftIsCompleted`), editable title/description (`ImeSafeTextField`), and date/label/column/member pickers. On confirm → `state.submitDraft()` → `MistyAgent.executePending` → `TeamHandlers.handleCreate/Update/Delete/Move` writes to D1/SQLite. Confirmation re-renders as `ConfirmedActionCard` (`draft_cards.dart`).
- Evidence chain: `misty_agent.dart:~352, ~430` → `draft_builder.dart:5` → `chat_model.dart ProposalDraft` → `chat_bubbles.dart:~368 ProposalDraftCard` → `draft_cards.dart`.

**(1b) DISPLAY structured content → YES, via two tools + already-on Markdown text.**
- `show_ui_content` (`ui_defs.dart:5`): accepts `title/type/data_json`; rendered by `StructuredUIBubble` (`structured_ui_bubbles.dart:14`) supporting `table`, `status_summary`, `plan_review`, `empty_state`.
- `show_tasks_from_ids` (`ui_defs.dart:26`): accepts `title/task_ids`; rendered by `_TaskIdsDataView` inside `StructuredUIBubble` — looks up live `TaskModel`/board/workspace/assignee from `StateTasks`/`StateBoards`, renders an interactive 5-column table, and each row `onTap` opens `TaskEditModal.show(... collaborationPreview: true)` (`structured_ui_bubbles.dart:~610 _openTaskEditor`).
- Both tools are pure UI side-effects: their handlers (`ui_handlers.dart`) just return a confirmation string; the real render is intercepted in `AssistantMessageBubble` by filtering `message.toolCalls` for tool name (`chat_bubbles.dart:327` and `:~345`).
- **Markdown text is ALREADY rendered**: `AssistantMessageBubble` renders `message.text` through `MarkdownBody` (`flutter_markdown ^0.7.7+1`) at `chat_bubbles.dart:299`. So plain agent prose with `**bold**`, lists, and GFM tables already renders as formatted Markdown today.

**Registry confirms exactly 16 tools** (`registry.dart`): 14 named functional tools + `UIDefs.showUIContent` + `UIDefs.showTasksFromIds`.
> Side observation (not central): `misty_agent.dart` still branches on `list_team_boards`, `analyze_uploaded_image`, `get_actual_image` which are NOT in `allAiTools` — dead/legacy routing the model can never trigger. Candidate cleanup, separate from this initiative.

---

### Question 2 — MARKDOWN BLOCK EDITOR REUSE
**Feasibility: HIGH for the *parser*, MEDIUM-LOW for the *editor widget* (read-only display path is the safe target).**

- `markdown_block_editor.dart` exposes **three independently reusable, widget-free pieces**:
  - `MarkdownBlock` model (id/type/text/isChecked); types: `paragraph`, `h1`, `h2`, `bullet`, `todo`.
  - `parseMarkdownToBlocks(String)` — pure function, line-based parse of `#`, `##`, `- [ ]`, `- [x]`, `- `, `* `, paragraph.
  - `serializeBlocksToMarkdown(List<MarkdownBlock>)` — pure inverse.
- `MarkdownBlockEditor` (the StatefulWidget) is **fully editable**: it owns `TextEditingController`s/`FocusNode`s per block, Enter/Backspace block-splitting, drag-reorder via `DeferPointer`, and a `+`/slash insertion menu. It is **heavyweight and write-oriented** — designed for Meetings notes and Task description editing.
- Task modal usage (`task_edit_modal.dart:637` and `:788`) is **editable**: `MarkdownBlockEditor(initialMarkdown: _descMarkdown, onChanged: …)` wired to `_scheduleAutoSave()` (debounced, Phase 184) and `_syncChecklistFromMarkdown` (`task_edit_modal.dart:384` uses `parseMarkdownToBlocks`). Meetings reuses the same editor for Summary/Notes.

**Assessment for chat:**
- For **agent OUTPUT in chat**, we want **READ-ONLY rendering**, not the full block editor. Two viable routes:
  1. **Keep the existing `MarkdownBody`** (already live at `chat_bubbles.dart:299`) and simply *encourage* the agent to emit richer Markdown. Zero new widgets. Tables/lists/headings render via GFM. — *Lowest risk.*
  2. **Add a thin read-only block renderer** that reuses `parseMarkdownToBlocks` to render heading/bullet/checklist blocks with the same visual language as Meetings/Tasks (consistent "block" look, non-editable, non-persisted). — *Consistency win, moderate effort.*
- The full editable `MarkdownBlockEditor` should **NOT** be dropped into the chat result area: it manages controllers, auto-save timers, and drag state that have no meaning for an immutable agent reply, and would fight the chat scroll physics.

**Mandate alignment:**
- `architecture.md §2 "Universal UI Display Container"` frames `show_ui_content` as the "Beautiful Container" fallback and mandates rendering specialized UI from `message.toolCalls` — a Markdown renderer is compatible as an *additional* informational lane, not a replacement for the interactive lanes.
- `skill-instructions.md §2 "Structured Presentation Protocol"` currently **forbids raw JSON** and says prefer `show_ui_content`. `skill_task_manager.dart:11` explicitly says *"ห้ามพิมพ์เป็น Markdown เปล่าๆ เพื่อความเสถียร"* (do not print bare Markdown, for stability) — **BUT** `persona.dart` simultaneously instructs *"เมื่อแสดงรายการงาน ต้องใช้ Markdown Table เท่านั้น"* (must use Markdown tables). **This is a live contradiction in the prompt today** and is a root reason behind inconsistent agent output. Resolving it is part of the plan.

---

### Question 3 — TOOL REDUCTION HYPOTHESIS
**Verdict: PARTIALLY TRUE. Markdown can absorb the *informational* display tool, but interactive tools MUST stay.**

**Can collapse / simplify:**
- `show_ui_content` (`table` / `status_summary` / `plan_review` / `empty_state`) is the prime candidate. Every one of its 4 variants is **read-only, non-interactive, non-persisted** — exactly what GFM Markdown (already rendered by `MarkdownBody`) can express: tables → GFM tables; status_summary → bold key/value list; plan_review → numbered/bulleted list; empty_state → a short italic line. Removing it eliminates 1 of 16 tools and removes the brittle `data_json` JSON-string contract (a frequent failure point — JSON escaping inside a tool arg).

**MUST stay (cannot be Markdown):**
- `show_tasks_from_ids` — renders **clickable rows that open `TaskEditModal`** and resolves live workspace/board/assignee/deadline by ID from app state. Pure Markdown is static text; it cannot open editors or reflect live DB state. **KEEP.**
- The **Draft create/edit/delete flow** (`ProposalDraftCard` / `ConfirmedActionCard` + `create/update/move/delete_team_task`) — needs interactive checkboxes, date/label/member pickers, conflict detection, and **DB persistence on confirm**. Markdown checkboxes are not wired to handlers or D1. **KEEP unchanged.**

**Net effect:** tool count 16 → potentially **15** (drop `show_ui_content`), plus a meaningful reduction in *cognitive/contract load* for the model (no `data_json` JSON authoring). This is a modest tool-count reduction but a **large reliability/readability gain** for informational answers.

**Balanced recommendation:**
- **Use Markdown** for: explanations, plans/summaries the user only reads, generic/non-task tables, empty states, "what I found" recaps.
- **Keep structured tools** for: real existing tasks that must be clickable (`show_tasks_from_ids`), and any data-mutating proposal (draft cards).

---

## B. PROPOSED TASK GRAPH — "Phase 186: Markdown-First Informational Rendering"

> Principle: **additive & reversible.** Do NOT touch the draft/create flow or `show_tasks_from_ids` rendering. Land prompt+style changes first (behavioral), keep `show_ui_content` as a deprecated fallback for ≥1 release before removal.

### Phase 186: Markdown-First Informational Rendering

- [ ] **Task 186.1**: Register Phase 186 scope in task-graph.md
    - *File*: `task-graph.md`
    - *Logic/Target*: Append Phase 186 with this 5-part structure; do not degrade existing phases.
    - *Why*: Rule 0 atomic tracking before any code change.
    - *Verification*: **[AUTONOMOUS]** `grep -n "Phase 186" task-graph.md` returns the new header.

- [ ] **Task 186.2**: Resolve the prompt contradiction (Markdown vs show_ui_content)
    - *File*: `my_ai_assistant/lib/ai_agent/skills/skill_task_manager.dart`, `my_ai_assistant/lib/ai_agent/skills/persona.dart`
    - *Logic/Target*: In `SkillTaskManager.rules` replace the line *"show_ui_content = ... ห้ามพิมพ์เป็น Markdown เปล่าๆ"* with a rule that **informational/read-only output (plans, summaries, generic tables, empty states) MUST be emitted as plain Markdown text**, while **real existing tasks MUST use `show_tasks_from_ids`** and **data changes MUST go through create/update/move/delete (draft)**. Align `Persona.coreMandates` so the Markdown-table instruction and the tool rules no longer conflict. Explicitly forbid raw JSON in chat text (retain that guard).
    - *Why*: The single biggest behavioral lever; removes the contradiction that currently makes the model oscillate between bare Markdown and `show_ui_content`.
    - *Verification*: **[AUTONOMOUS]** Run a scripted chat turn ("สรุปภาพรวมงานของฉัน") against the dev backend via `python3 runner.py` harness or a curl to `/api/ai/chat`; assert the response `content` contains Markdown (e.g. `|` table or `- ` bullets) and NOT a `show_ui_content` tool_call.

- [ ] **Task 186.3**: Harden chat Markdown rendering (tables/checklist/headings) + GFM extension set
    - *File*: `my_ai_assistant/lib/ui/chat/widgets/chat_bubbles.dart`
    - *Logic/Target*: In `_AssistantMessageBubbleState.build`, extend the existing `MarkdownBody` (line ~299) `MarkdownStyleSheet` to style `tableHead`, `tableBody`, `tableBorder`, `h1`, `h2`, `listBullet`, `blockquote`; pass an explicit `extensionSet: md.ExtensionSet.gitHubFlavored` (import `package:markdown/markdown.dart as md`) so GFM tables render deterministically across versions. Keep `selectable: true`.
    - *Why*: Guarantees the agent's Markdown looks premium and matches Meetings/Tasks tone; removes version-dependent table rendering ambiguity.
    - *Verification*: **[AUTONOMOUS]** `flutter analyze --no-pub` (0 new errors) via `python3 runner.py analyze`; add a widget test feeding a GFM table + `- [ ]` string into `AssistantMessageBubble` and `expect(find.byType(Table), findsOneWidget)` (or markdown table finder).

- [ ] **Task 186.4** *(OPTIONAL / consistency)*: Add read-only `ChatMarkdownBlockView` reusing the block parser
    - *File*: `my_ai_assistant/lib/ui/chat/widgets/chat_markdown_block_view.dart` (NEW), consumed in `chat_bubbles.dart`
    - *Logic/Target*: New stateless widget that calls `parseMarkdownToBlocks(message.text)` (imported from `markdown_block_editor.dart`) and renders heading/bullet/checklist/paragraph blocks **read-only** with the Meetings/Tasks visual language (NO controllers, NO drag, NO onChanged). Feature-flag it behind a const `kUseBlockChatRenderer = false` so `MarkdownBody` stays default until visually approved.
    - *Why*: Achieves the owner's "same block system as Meetings/Tasks" look without importing the heavy editable widget; reuses the existing pure parser (zero duplication).
    - *Verification*: **[AUTONOMOUS]** `flutter analyze --no-pub`; widget test rendering a 4-block markdown string asserts 4 block rows and a checked `Icons.check_box` for `- [x]`.

- [ ] **Task 186.5**: Soft-deprecate `show_ui_content` (keep renderer, stop recommending it)
    - *File*: `my_ai_assistant/lib/ai_agent/tools/definitions/ui_defs.dart`, `my_ai_assistant/lib/ai_agent/tools/handlers/query_handlers.dart`
    - *Logic/Target*: Update `show_ui_content` description to: *"DEPRECATED for informational output — emit Markdown text instead. Only retained for legacy."* Keep it in `registry.dart` and keep `StructuredUIBubble` rendering intact (backward compat for already-saved messages). Keep `query_handlers.dart:38` guidance that real tasks use `show_tasks_from_ids`.
    - *Why*: Steers the model away from the JSON tool without breaking historical messages still containing `show_ui_content` tool_calls.
    - *Verification*: **[AUTONOMOUS]** Replay a stored chat message JSON containing a `show_ui_content` tool_call through `StructuredUIBubble` in a widget test → still renders (no regression).

- [ ] **Task 186.6**: Regression guard for the interactive lanes (NO behavior change)
    - *File*: (test only) `my_ai_assistant/test/chat_render_regression_test.dart` (NEW)
    - *Logic/Target*: Tests asserting: (a) a `create_team_task` turn still produces a `ProposalDraft`/`ProposalDraftCard`; (b) a `show_tasks_from_ids` tool_call still renders the clickable `_TaskIdsDataView`. Confirms Markdown changes did not leak into interactive paths.
    - *Why*: The interactive draft + clickable task table are the HIGH-value, fragile paths; lock them with tests before/after.
    - *Verification*: **[AUTONOMOUS]** `flutter test test/chat_render_regression_test.dart` passes.

- [ ] **Task 186.7**: Static verification + detect_changes scope audit
    - *File*: none (verification)
    - *Logic/Target*: `python3 runner.py analyze` (flutter analyze) and `gitnexus_detect_changes` to confirm only chat-render + skills/prompt files changed.
    - *Why*: SOP V3 §4 autonomous verification; ensure no unintended blast radius.
    - *Verification*: **[AUTONOMOUS]** analyze clean; detect_changes shows only the files listed in 186.2–186.6.

- [ ] **Task 186.8** *(deferred, separate PR)*: Remove `show_ui_content` from `allAiTools` after ≥1 release
    - *File*: `my_ai_assistant/lib/ai_agent/tools/registry.dart` (+ dead-branch cleanup in `misty_agent.dart`)
    - *Logic/Target*: Drop `UIDefs.showUIContent` from `allAiTools` (16→15) once telemetry shows the model no longer relies on it; optionally also prune dead `list_team_boards`/`analyze_uploaded_image`/`get_actual_image` branches.
    - *Why*: Realizes the tool-count reduction safely, only after Markdown path is proven.
    - *Verification*: **[AUTONOMOUS]** `grep -c "showUIContent" registry.dart` == 0; full chat regression suite green.

---

## C. RISK + RECOMMENDATION

### Impact / Blast Radius (manually traced — gitnexus Dart symbols not in index)
- `StructuredUIBubble` — **LOW**: 1 consumer (`chat_bubbles.dart`). Defined `structured_ui_bubbles.dart:14`.
- `AssistantMessageBubble` — **LOW**: 1 consumer (`aether_chat_view.dart:236`). Defined `chat_bubbles.dart:220`.
- `show_ui_content` / `show_tasks_from_ids` — **MEDIUM** coupling: touched in `ui_defs.dart`, `misty_agent.dart` (routing + skip logic ~324/345/470), `chat_bubbles.dart` (render), `skill_task_manager.dart`, `query_handlers.dart` (prompts). Well contained; no UI consumer outside chat.
- `MarkdownBlockEditor` / parser — reused by Meetings + Task modal. **Do NOT modify the editor or the pure parser**; the plan only *imports* the parser read-only. Touching `parseMarkdownToBlocks`/`serializeBlocksToMarkdown` would be **HIGH** (affects Meetings + Tasks autosave). The plan explicitly avoids editing them.

### HIGH / CRITICAL call-outs
- **CRITICAL — Do not route create/update/delete through Markdown.** Data mutation must stay in the draft→confirm→handler→D1 path (`ProposalDraftCard` → `submitDraft` → `executePending` → `TeamHandlers`). Markdown checkboxes have no persistence wiring. Any attempt to "let the agent just print a checklist to create tasks" would silently lose data. The plan keeps this lane untouched.
- **HIGH — `show_tasks_from_ids` must remain a tool.** It is the only path that yields clickable rows opening `TaskEditModal` with live ID lookup. Replacing it with Markdown breaks navigation + live data.
- **MEDIUM — Prompt contradiction must be fixed first (186.2).** Leaving `skill_task_manager.dart` (forbid Markdown) vs `persona.dart` (require Markdown table) in conflict will make any rendering change behave non-deterministically.
- **MEDIUM — GFM table rendering version risk.** Pin `extensionSet: gitHubFlavored` (186.3) so tables don't silently stop rendering on a `flutter_markdown`/`markdown` bump.
- **LOW — Backward compat.** Old saved messages may carry `show_ui_content` tool_calls; keep `StructuredUIBubble` alive (186.5) so history still renders.

### Recommendation (summary for the owner)
1. **Yes**, make the agent answer informational content in Markdown — it already renders via `MarkdownBody`; the win is *consistency + reliability*, not a big tool cut.
2. The realistic tool reduction is **16 → 15** (retire `show_ui_content`), plus removing the brittle `data_json` JSON contract. Keep `show_tasks_from_ids` and the entire draft/create flow.
3. Land it **incrementally**: prompt fix (186.2) + render hardening (186.3) first; optional block-style view (186.4) for the exact Meetings/Tasks look; deprecate then later remove `show_ui_content` (186.5 → 186.8). All steps are reversible and gated by `flutter analyze` + widget regression tests.
