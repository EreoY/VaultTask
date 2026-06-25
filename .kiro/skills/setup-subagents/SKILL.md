---
name: setup-subagents
description: "Copies subagent configurations from the global directory to the user workspace agents folder and registers all subagents."
---

# Setup Subagents Skill

This skill is used to initialize subagents when starting a new project.

## Workflow

1. **Copy Configurations**: Copy all agent files and folders from the global path `~/.gemini/antigravity-cli/agents/` to the user/workspace directory `~/.agents/agents/`. If the target directory (`~/.agents/agents/`) already exists but is missing any files, folders, or is not fully updated to match the global source (`~/.gemini/antigravity-cli/agents/`), it must be updated and synced to ensure it completely matches the global directory.
2. **Define Subagents**: Read all copied configuration files and automatically define (register) them in the active session.

### Strict Compliance Rules & Constraints

1. **No Self-Generation**: The Manager MUST NOT write, rewrite, synthesize, or invent system prompts, tool selections, or agent properties for the subagents.
2. **Exact Instantiation**: The Manager MUST read the exact contents of the JSON configuration files (definitions and configurations) and spawn/define the subagents exactly as configured in those files.
3. **No Assumptions**: Do not use fallback configurations or default system prompts when initializing these subagents. The JSON configuration files are the absolute single source of truth.
4. EXCEPTION FOR SETUP-SUBAGENTS: When executing this skill, the Manager (Antigravity) is authorized to perform direct file copy and read operations to register subagents quickly. Once completed, the Manager must immediately revert to the default constraint mode (no direct file reads, writes, or command executions).



## Folder Structure Map & Directory Layout

To ensure that the Manager and Coder agents can read and understand the exact layout of the `.agents` folder, the folder is mapped below.

### Directory Layout & Roles

The `~/.agents/agents/` directory is organized as follows:
- **Root JSON files**: These are the agent definition files used for registering each subagent.
- **Subdirectories**: Each subagent has a dedicated folder containing an `agent.json` file. This `agent.json` file controls the runtime and model configurations (e.g. Gemini model selections, system prompt configurations, and tool permissions).

### Explicit Paths of all 5 Subagents

1. **Sovereign Planner**
   - Root Definition File: `~/.agents/agents/planner.json`
   - Runtime Config Directory: `~/.agents/agents/planner/`
   - Runtime Configuration File: `~/.agents/agents/planner/agent.json`

2. **Sovereign Backend Coder**
   - Root Definition File: `~/.agents/agents/backend_coder.json`
   - Runtime Config Directory: `~/.agents/agents/backend_coder/`
   - Runtime Configuration File: `~/.agents/agents/backend_coder/agent.json`

3. **Sovereign Frontend Coder**
   - Root Definition File: `~/.agents/agents/frontend_coder.json`
   - Runtime Config Directory: `~/.agents/agents/frontend_coder/`
   - Runtime Configuration File: `~/.agents/agents/frontend_coder/agent.json`

4. **Sovereign Executor**
   - Root Definition File: `~/.agents/agents/executor.json`
   - Runtime Config Directory: `~/.agents/agents/executor/`
   - Runtime Configuration File: `~/.agents/agents/executor/agent.json`

5. **Sovereign QA (Quality Assurance)**
   - Root Definition File: `~/.agents/agents/qa.json`
   - Runtime Config Directory: `~/.agents/agents/qa/`
   - Runtime Configuration File: `~/.agents/agents/qa/agent.json`

