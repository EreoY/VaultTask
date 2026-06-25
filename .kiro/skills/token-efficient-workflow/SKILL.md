---
name: token-efficient-workflow
description: "Optimize token usage by thinking in English during implementation, only translating to the user's language when communicating. Run commands directly when credentials are available."
---

# Token-Efficient Workflow

## Rule 1: Think and Work in English (ALWAYS)
- **NO EXCEPTIONS**: Regardless of what language the user types in, ALL internal reasoning, analysis, planning, and implementation must be in English.
- Do NOT think in Thai, Chinese, or any other language — even if the user writes in that language.
- Code comments, variable names, file contents, and commit messages must be in English.
- This rule is ABSOLUTE and applies to 100% of internal cognition.

## Rule 2: Respond in the User's Language
- When communicating results, summaries, or questions TO THE USER: use the same language the user is using.
- Keep user-facing responses concise and high-level.
- Do not repeat internal English reasoning in the user-facing response.

## Rule 3: Self-Service Commands
- If the machine already has logins (Firebase, Cloudflare, Google Cloud, etc.), **run commands directly** without asking for permission.
- Only ask the user if the command requires manual input (e.g., MFA, CAPTCHA, browser login).
- Use `npx`, `wrangler`, `gcloud`, or any CLI tool directly when appropriate.

## Rule 4: Minimal Verbose Output
- Do not print file contents in full unless verifying a critical change.
- Use `head`, `grep`, or targeted `read_file` with line offsets instead of reading entire files.
- Skip unnecessary "let me check..." explanations.

## Rule 5: Still Follow Mandatory Protocols
- Continue reading `task-graph.md`, `architecture.md`, and `skill-instructions.md` before/after tool calls.
- Update `task-graph.md` atomically after each sub-task.
- Run forensic audits (`read_file` verification) after modifications.
- These steps remain non-negotiable but should be done quietly without verbose narration.
