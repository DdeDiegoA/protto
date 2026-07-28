# Protto — Feature Spec

## Overview

`protto` is a CLI tool that bootstraps an agent-friendly project structure. It is designed to be invoked by an agent (Claude Code, OpenCode, or Hermes) when the user says something like *"inicia este proyecto"*.

The tool does **not** scaffold application code (no Next.js, no Django). It creates the meta-layer that makes the project usable by agents: configuration files, hooks, documentation pointers, and skill references.

## Goal

When run, `protto` should:

1. Detect the project context (git state, existing agent directories, user skills).
2. Ask the user (or accept flags) for project intent if needed.
3. Generate a minimal but complete agent-friendly setup for **Claude Code** and **OpenCode**.
4. List available user skills and reference them in the generated `CLAUDE.md` / `AGENTS.md`.
5. Leave the project ready for the agent to continue with normal tasks, optionally delegating to `speckit` or `grill-me`.

## Non-Goals

- Application scaffolding (framework setup, dependency installation).
- Interactive project wizard with many questions.
- Replacing existing CLAUDE.md / AGENTS.md without backup.
- Installing global dependencies.

## User Scenarios

### Scenario A: New project

User clones or creates an empty directory. Agent runs `protto init`. The tool creates `.claude/`, `.opencode/`, `CLAUDE.md`, `AGENTS.md`, and `docs/` with sensible defaults.

### Scenario B: Existing project

User has a repo with code but no agent setup. Agent runs `protto init --force`. The tool backs up existing `CLAUDE.md` / `AGENTS.md` and creates the standard structure.

### Scenario C: Skill-aware setup

User has personal skills in `~/.hermes/skills/` and `~/.claude/skills/`. `protto` lists them and asks which to include as references in the boot file. The agent then knows it can use them.

## Functional Requirements

| ID | Requirement | Acceptance |
|---|---|---|
| R1 | Single executable script (`protto`) with subcommands `init`, `list-skills`, `help`. | `chmod +x protto && ./protto init` works on macOS/Linux. |
| R2 | `init` creates `.claude/` and `.opencode/` directories with agents, skills, rules, commands subdirs. | Directories exist after run. |
| R3 | `init` generates `CLAUDE.md` and `AGENTS.md` with minimal viable structure per `Guia-Gestion-Proyectos`. | Files contain build/test placeholders, architecture map, gotchas, env, docs pointers. |
| R4 | `init` generates `.claude/settings.json` and `.opencode/settings.json` with the three essential hooks (format, test-on-stop, secret-scan). | Valid JSON files are created. |
| R5 | `init` reads `~/.hermes/skills/` and `~/.claude/skills/` and lists available skills. | User sees a checklist. |
| R6 | Selected skills are referenced in `CLAUDE.md` / `AGENTS.md` under "Available Skills". | Skill names and paths are listed. |
| R7 | `init` creates `docs/architecture.md` and `docs/context.md` with starter content. | Files exist. |
| R8 | `init` appends `CLAUDE.local.md` and `AGENTS.local.md` to `.gitignore` if `.gitignore` exists. | Lines are present, no duplicates. |
| R9 | `init` backs up existing boot files before overwriting unless `--force` is passed. | Backups named `CLAUDE.md.bak.<timestamp>`. |
| R10 | Skill wrappers for Claude Code (`~/.claude/skills/protto/SKILL.md`) and OpenCode (`~/.opencode/skills/protto/SKILL.md`) installable via `install.sh`. | Agent can run `/protto` or equivalent command. |

## Success Criteria

- A user can run `protto init` in a new directory and have a project ready for Claude Code or OpenCode in under 5 seconds.
- The generated `CLAUDE.md` is under 200 lines.
- The tool works on macOS and Linux without additional dependencies beyond bash and standard POSIX tools.

## Assumptions

- User has bash, find, sed, jq preferred but optional (script should work without jq).
- Claude Code config lives in `~/.claude/` and OpenCode in `~/.opencode/` or `~/.config/opencode/`.
- Personal skills are stored in `~/.hermes/skills/` and `~/.claude/skills/`.

## Out of Scope

- Windows native support (WSL works).
- Python/Node package distribution.
- Auto-detection of framework/language stack.

## Dependencies

- None runtime.

## Risks

| Risk | Mitigation |
|---|---|
| Overwriting user files | Backup unless `--force`. |
| Assumes wrong skill directories | Check multiple standard paths, skip silently if missing. |
| Boot file grows too large | Keep template under 120 lines; only append selected skills. |
