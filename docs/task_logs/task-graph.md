## Phase 227: Grouped Action Items with Sequential Numbered Categories [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **AI Prompt System Instruction Rules (`ai_summarize_sheet.dart`)**:
>    - In `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`, update prompt instructions in `_handleSummarize` (meeting and document modes) and `_handleRefine` to support **Grouped Action Items**:
>      - **Rule 4 Update**: Allow `## Action Items` section to be organized into numbered category headers (`1. กลุ่มหัวข้อแรก`, `2. กลุ่มหัวข้อถัดไป`, `3. ...`).
>      - Under each numbered category header, allow sub-checklist items (`- [ ] งานที่ 1`, `- [ ] งานที่ 2`).
>      - Sequential group numbers MUST count strictly in order (`1.`, `2.`, `3.`) without skips or resets within the Action Items section.
>      - **Rule 8 Update**: Sub-checklist items must start at the beginning of their own line (`- [ ] ข้อความ` or indented `  - [ ] ข้อความ`) under the numbered category header, and must not be combined on the same line as the category title.
> 2. **Markdown Block Editor Parser & Serializer Audit (`markdown_block_editor.dart`)**:
>    - **Check `parseMarkdownToBlocks()`**: Verify `todoUnchecked` and `todoChecked` regexes handle indented or non-indented checklist items (`- [ ]` / `- [x]`) under numbered category headers (`1. กลุ่มหัวข้อ`). Confirm `1. กลุ่ม...` parses as `type: 'numbered'` and sub-checklists parse as `type: 'todo'`.
>    - **Check `preserveCheckedItems()`**: Confirm matching logic normalizes text and preserves `isChecked: true` states across AI summary refinements even when items are grouped under numbered headers.
>    - **Fix `serializeBlocksToMarkdown()`**: Fix `serializeBlocksToMarkdown()` so `numberedIndex` does NOT reset when encountering `todo` or `bullet` blocks, and only resets upon major section breaks (`h1`, `h2`, `paragraph`).
>    - **Fix `_BlockRow` Numbered Prefix Indexing**: In `MarkdownBlockEditor.build()`, update the backwards lookup loop for `block.type == 'numbered'` so it skips over intervening `todo` and `bullet` blocks to calculate the correct sequential index (`1.`, `2.`, `3.`) relative to the current section.
> 3. **Static Analysis & Verification**:
>    - Run `flutter analyze` to ensure zero compilation or static analysis errors.

- [x] Task 227.1: Update system prompt instructions in `ai_summarize_sheet.dart` (`_handleSummarize` meeting/document prompts & `_handleRefine` prompt) for Grouped Action Items with sequential numbered categories (`1.`, `2.`, `3.`) and sub-checklists (`- [ ]`).
- [x] Task 227.2: Audit and fix `markdown_block_editor.dart` (`serializeBlocksToMarkdown()` and `_BlockRow` index calculation) so intervening `todo`/`bullet` blocks do not reset numbered category indexes (`1.`, `2.`), ensuring correct rendering, serialization, and checked state preservation (`preserveCheckedItems`).
- [x] Task 227.3: Perform static analysis (`flutter analyze`).

### Task 227.1: Update system prompt instructions in ai_summarize_sheet.dart for Grouped Action Items
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Update Rule 4 and Rule 8 in `_handleSummarize` (meeting and document prompts) and `_handleRefine` to permit numbered category headers (`1. กลุ่มหัวข้อแรก`, `2. กลุ่มหัวข้อถัดไป`) under `## Action Items` with sub-checklists (`- [ ]`), requiring sequential ordering (`1.`, `2.`, `3.`).
- **Why:** Provide flexibility for AI to organize action items into numbered category groups as requested by prompt directive.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Prompt explicitly specifies grouped action items format with sequential numbers.

### Task 227.2: Audit and fix markdown_block_editor.dart for Grouped Action Items support
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`
- **Action:** Audit `parseMarkdownToBlocks()` and `preserveCheckedItems()`. Update `serializeBlocksToMarkdown()` and `_BlockRow` index calculation so intervening `todo` and `bullet` blocks do not reset `numberedIndex`, allowing sequential numbered headers (`1.`, `2.`, `3.`) to increment correctly when separated by todo items.
- **Why:** Prevent UI and serialized Markdown from resetting category numbers back to `1.` after every checklist item.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Numbered headers increment correctly (`1.`, `2.`, `3.`) in both editor rendering and serialized Markdown string, with checkbox states preserved.

### Task 227.3: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`, `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`
- **Action:** Run `flutter analyze` and confirm 0 issues.
- **Why:** Maintain codebase health and ensure no lint warnings or syntax errors.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` returns zero errors.

## Phase 226: AI System Prompt Strict Checklist Scope & Prefix Placement Rules [x] Completed

> **Architecture Mandate:**
> 1. **AI Prompt Rules - Checklist Scope Rule (Rule A)**:
>    - In `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`, update prompt instructions in `_handleSummarize` (meeting and document modes) and `_handleRefine`:
>    - Add explicit Rule 7: Checklists (`- [ ]` / `- [x]`) are strictly allowed ONLY under the `## Action Items` section. All other sections (Summary, Topics, Key Points) MUST NOT contain checkboxes.
> 2. **AI Prompt Rules - Checklist Prefix Placement Rule (Rule B)**:
>    - In `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`, update prompt instructions in `_handleSummarize` and `_handleRefine`:
>    - Add explicit Rule 8: Checklists MUST ALWAYS sit at the VERY FRONT (beginning) of the line (`- [ ] <task_text>` or `- [x] <task_text>`). Checkboxes must NEVER be placed in the middle or at the end of a sentence, nor appended after numbered or bullet points.
> 3. **Static Analysis & Verification**:
>    - Run `flutter analyze` to ensure zero compilation or static analysis errors.

- [x] Task 226.1: Update prompt instructions in `ai_summarize_sheet.dart` (`_handleSummarize` meeting/document prompts & `_handleRefine` prompt) to enforce Rule A (Checklists allowed ONLY under `## Action Items` section).
- [x] Task 226.2: Update prompt instructions in `ai_summarize_sheet.dart` (`_handleSummarize` meeting/document prompts & `_handleRefine` prompt) to enforce Rule B (Checklists MUST sit at VERY FRONT of the line `- [ ] <task_text>`, NEVER middle/end/numbered line).
- [x] Task 226.3: Perform static analysis (`flutter analyze`).

### Task 226.1: Update prompt instructions in ai_summarize_sheet.dart to enforce Rule A (Checklists ONLY under ## Action Items)
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Add Rule 7 to system instruction strings in `_handleSummarize` and `_handleRefine`: "7. กฎตำแหน่งของเช็กลิสต์: สัญลักษณ์เช็กลิสต์ (- [ ] หรือ - [x] ) อนุญาตให้มีได้เฉพาะในหัวข้อ Action Items (## Action Items) เท่านั้น หัวข้ออื่นทั้งหมด (เช่น สรุปประเด็น, รายละเอียดการประชุม, ประเด็นสำคัญ) ห้ามใส่เช็กลิสต์เด็ดขาด".
- **Why:** Prevent AI from putting checkboxes in non-action item sections (Summary, Topics, Key Points).
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Prompt explicitly restricts checkboxes to the Action Items section.

### Task 226.2: Update prompt instructions in ai_summarize_sheet.dart to enforce Rule B (Checklists MUST sit at VERY FRONT of line)
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Add Rule 8 to system instruction strings in `_handleSummarize` and `_handleRefine`: "8. กฎการวางสัญลักษณ์เช็กลิสต์: สัญลักษณ์เช็กลิสต์ต้องอยู่ด้านหน้าสุดของบรรทัดเท่านั้น เช่น '- [ ] ข้อความ' ห้ามนำเช็กลิสต์ไปวางตรงกลางข้อความ ต่อท้ายข้อความ หรือต่อท้ายรายการลำดับตัวเลขเด็ดขาด".
- **Why:** Prevent AI from placing checkboxes at middle/end of sentences or numbered lines, ensuring Markdown parser can parse todo items reliably.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Prompt explicitly instructs AI to place checkboxes exclusively at line beginnings.

### Task 226.3: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Execute `flutter analyze` and confirm zero errors.
- **Why:** Ensure codebase health and quality standards.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` passes with 0 issues.

## Phase 225: Checklist Exemption from Numbered List Conversion (> 3 Items Rule) [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **AI Summarizer Prompt Rules Update (`ai_summarize_sheet.dart`)**:
>    - In `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`, update Rule 4 in prompt instructions for `_handleSummarize` (both meeting and document modes) and `_handleRefine`:
>      - Explicitly state that Action Items / checklist items (`- [ ]` / `- [x]`) are EXEMPT from the "more than 3 items -> numbered list" rule and MUST always remain as pure checkboxes (`- [ ]` / `- [x]`) regardless of item count.
> 2. **Markdown Block Parser Checklist Numbered Prefix Handling (`markdown_block_editor.dart`)**:
>    - In `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`, update `parseMarkdownToBlocks()` regexes for `todoUnchecked` and `todoChecked`:
>      - Change regex pattern to match numbered prefixes before brackets (e.g., `^\s*(?:[-*]|\d+[.)])\s*\[\s\]\s*(.*)$` and `^\s*(?:[-*]|\d+[.)])\s*\[[xX]\]\s*(.*)$`).
>      - This guarantees any line formatted like `1. [ ] item` or `1) [x] item` is correctly parsed as `type: 'todo'` and serialized as `- [ ] item` or `- [x] item`.
> 3. **Static Analysis & Verification**:
>    - Run `flutter analyze` to ensure zero compilation or static analysis errors.

- [x] Task 225.1: Update prompt instructions in `ai_summarize_sheet.dart` to explicitly exempt Action Items / checklist items (`- [ ]` / `- [x]`) from the > 3 items numbered list rule.
- [x] Task 225.2: Update `parseMarkdownToBlocks` regex in `markdown_block_editor.dart` to recognize numbered checkbox items (`1. [ ]`, `2. [x]`) as `type: 'todo'`.
- [x] Task 225.3: Perform static analysis (`flutter analyze`).

### Task 225.1: Update prompt instructions in ai_summarize_sheet.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Update Rule 4 in system prompt strings in `_handleSummarize` (lines 292-293) and `_handleRefine` (line 369) to state: "4. กฎการใช้รายการย่อย: หากมีย่อย ให้ใช้รายการ "- " ได้สูงสุดแค่ 3 ข้อเท่านั้น หากมีย่อยมากกว่า 3 ข้อขึ้นไป ให้ใช้รายการลำดับตัวเลข ("1. ", "2. ", "3. "...) แทน (ข้อยกเว้น: รายการ Action Items หรือเช็กลิสต์ ให้ใช้ "- [ ] " หรือ "- [x] " เป็นเช็กลิสต์เสมอ ไม่ว่าจะมียี่สิบหรือกี่ข้อก็ตาม ห้ามเปลี่ยนเป็นรายการลำดับตัวเลขเด็ดขาด)".
- **Why:** Resolve bug where AI converts Action Items into numbered lists (`1. `, `2. `) when count > 3.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** AI prompt explicitly instructs LLM to keep Action Items as checkboxes regardless of count.

### Task 225.2: Update parseMarkdownToBlocks regex in markdown_block_editor.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`
- **Action:** Modify `todoUnchecked` and `todoChecked` regex in `parseMarkdownToBlocks` to allow optional digits/number prefixes (e.g. `^\s*(?:[-*]|\d+[.)])\s*\[\s\]\s*(.*)$` and `^\s*(?:[-*]|\d+[.)])\s*\[[xX]\]\s*(.*)$`).
- **Why:** Ensure any fallback or legacy numbered checkboxes (e.g. `1. [ ] Item`) are parsed as `type: 'todo'` rather than being misclassified by `numberedRe` as `type: 'numbered'`.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Numbered todo items parse as `todo` blocks and serialize back to pure `- [ ]` checkboxes.

### Task 225.3: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`, `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Run `flutter analyze` and confirm 0 issues.
- **Why:** Ensure code quality and adherence to guidelines.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** `flutter analyze` reports zero errors.

## Phase 224: AI Summary Unchecked Checkbox Contrast & Session Stale State Synchronization [x] Completed

- **Status:** [x] Completed

> **Architecture Mandate:**
> 1. **Unchecked Checkbox High Contrast Styling (`markdown_block_editor.dart`)**:
>    - In `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`, update the `- [ ]` unchecked checkbox container decoration styling:
>      - Change border color from `GlassColors.outlineVariant.withOpacity(0.4)` to a crisp, clear 1.5px border: `GlassColors.onSurfaceVariant.withOpacity(0.6)`.
>      - Change background fill from `Colors.transparent` to a subtle container fill: `GlassColors.onSurfaceVariant.withOpacity(0.05)`.
>      - This guarantees empty checkbox boxes `- [ ]` are 100% visible on both Light and Dark backgrounds.
> 2. **Stale Summary Loading & Real-Time Session Sync (`ai_summarize_sheet.dart`)**:
>    - In `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`:
>      - In `_loadCurrentSessionMessages()`: Load the newest AI summary message (`msgs.where((m) => !m.isUser).firstOrNull`). When `widget.initialSummary` is present and non-empty, apply `preserveCheckedItems(widget.initialSummary!, newestAiMsg.text)` so user-checked checkboxes from the meeting/doc are not overwritten by stale DB states.
>      - If the merged summary text differs from `newestAiMsg.text`, update `newestAiMsg` in RAM (`_chatMessages`) and sync to Cloudflare DB immediately via `ApiCloudflare.insertChatMessage`.
>      - When checkbox items are toggled in `MarkdownBlockEditor` inside `AiSummarizeSheet` (in `onChanged`), update `_summaryOutput` and `_chatMessages` in RAM and call `ApiCloudflare.insertChatMessage` immediately to persist to DB. If no AI message exists yet in the session, create a new AI message and insert into RAM and DB.
> 3. **Static Analysis & Verification**:
>    - Run `flutter analyze` to ensure zero compilation or static analysis errors.

- [x] Task 224.1: Update `- [ ]` unchecked checkbox styling in `markdown_block_editor.dart` with 1.5px border (`GlassColors.onSurfaceVariant.withOpacity(0.6)`) and subtle fill (`GlassColors.onSurfaceVariant.withOpacity(0.05)`).
- [x] Task 224.2: Update `_loadCurrentSessionMessages()` in `ai_summarize_sheet.dart` to merge checked states from `widget.initialSummary` using `preserveCheckedItems` when loading session messages, and update RAM (`_chatMessages`) and DB when merged.
- [x] Task 224.3: Ensure `onChanged` in `ai_summarize_sheet.dart` syncs updated summary text to RAM & DB immediately when checkboxes are toggled (creating AI message in RAM/DB if none exists yet).
- [x] Task 224.4: Perform static analysis (`flutter analyze`).

### Task 224.1: Update unchecked checkbox styling in markdown_block_editor.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`
- **Action:** Update line 943 to use `GlassColors.onSurfaceVariant.withOpacity(0.6)` for border color when `!block.isChecked` with `width: 1.5`, and line 948 to use `GlassColors.onSurfaceVariant.withOpacity(0.05)` for fill color when `!block.isChecked`.
- **Why:** Resolve user report that empty checkboxes `- [ ]` are faint and invisible ("มองไม่เห็นเลยมองยากมากพอไม่มีการติ๊ก").
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Empty checkboxes render with clear 1.5px border and subtle fill.

### Task 224.2: Update _loadCurrentSessionMessages() to preserve checked state on session load
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** In `_loadCurrentSessionMessages()`, load `newestAiMsg` (`msgs.where((m) => !m.isUser).firstOrNull`). If `widget.initialSummary` is present and non-empty and `newestAiMsg` exists, run `preserveCheckedItems(widget.initialSummary!, newestAiMsg.text)` to preserve checked items. Set `_summaryOutput` to this merged text, and if changed, update `_chatMessages` in RAM and sync to DB via `ApiCloudflare.insertChatMessage`.
- **Why:** Resolve user report that opening AI Summary sheet loads stale summary without latest checked boxes.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Sheet loads latest AI summary with checked items preserved.

### Task 224.3: Sync updated summary to RAM & DB on checkbox toggles in ai_summarize_sheet.dart
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** In `MarkdownBlockEditor.onChanged` in `ai_summarize_sheet.dart`, update `_summaryOutput` and update/create AI message in `_chatMessages` RAM and call `ApiCloudflare.insertChatMessage` to persist to DB.
- **Why:** Ensure checkbox toggling in AI summary sheet immediately updates both RAM and Cloudflare DB.
- **Owner:** FrontendCoder
- **Verification:** **[AUTONOMOUS]** Toggling checkbox updates RAM and DB immediately.

### Task 224.4: Perform static analysis
- **Status:** [x] Completed
- **Target Files:** `my_ai_assistant/lib/ui/meetings/widgets/markdown_block_editor.dart`, `my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart`
- **Action:** Run `flutter analyze` and confirm zero errors.
- **Why:** Maintain codebase health and compliance with Sovereign guidelines.
- **Owner:** QA / Planner
- **Verification:** **[AUTONOMOUS]** Flutter analyze passes with 0 issues.
