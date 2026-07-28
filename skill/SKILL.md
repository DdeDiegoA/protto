---
name: protto
description: Use when initializing or upgrading an agent-friendly project structure for Claude Code and OpenCode. Generates CLAUDE.md, AGENTS.md, hooks, docs, agents, commands, and rules from repo facts.
version: 1.0.0
author: Diego Arenas
license: MIT
metadata:
  hermes:
    tags: [protto, claude-code, opencode, project-setup, agent-config]
    related_skills: [project-bootstrap, grill-me, speckit-specify]
---

# protto — Agent-Friendly Project Setup

## Overview

`protto` bootstraps the meta-layer that makes a project usable by coding agents (Claude Code, OpenCode, Hermes). It does **not** scaffold application code. It reads what already exists in the repo and generates:

- `CLAUDE.md` / `AGENTS.md` — project boot prompts.
- `.claude/` and `.opencode/` — `settings.json`, agents, commands, rules.
- `docs/` — architecture, context, decisions, and skills inventory.
- `.gitignore` entries for local override files.

The output is context-aware: build, test, lint, typecheck, and architecture sections are filled from existing files.

## When to Use

- Starting a new repo that will be worked on by Claude Code or OpenCode.
- An existing repo has no `CLAUDE.md` / `AGENTS.md` / `.claude/` / `.opencode/`.
- You want a standardized review agent (`/review`), baseline rules, and a decisions log.
- Before kicking off `speckit-specify`, `grill-me`, or `proyecto-lean` so the agent already knows the project.

## Installation

```bash
cd ~/Programacion/proyectos/protto
./install.sh
```

This installs the `protto` CLI to `~/.local/bin/protto` and the agent skill wrappers to `~/.claude/skills/protto/` and `~/.opencode/skills/protto/`.

## Usage

### As a CLI

```bash
protto init            # create structure; fail if boot files exist
protto init --force    # overwrite, with timestamped backups
protto list-skills     # show skills detected in standard dirs
protto analyze         # import graphify output or bootstrap it
protto help            # usage
```

### As an Agent Skill

After install, agents can invoke:

- `/protto init` — run `protto init --force` in the current project.
- `/protto list-skills` — show detected skills.
- `/protto analyze` — import or bootstrap graphify knowledge graph.

## What Gets Generated

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Boot prompt for Claude Code. Build/test/arch/gotchas/env/docs pointers. |
| `AGENTS.md` | Boot prompt for OpenCode. Mirror of `CLAUDE.md` with `.opencode` paths. |
| `.claude/settings.json` / `.opencode/settings.json` | Hooks: `PostToolUse` (build), `Stop` (test). |
| `.claude/agents/reviewer.md` / `.opencode/agents/reviewer.md` | Review subagent definition. |
| `.claude/commands/review.md` / `.opencode/commands/review.md` | `/review` slash command. |
| `.claude/rules/baseline.md` / `.opencode/rules/baseline.md` | Scoped baseline coding rules. |
| `docs/architecture.md` | High-level structure, build/test, entrypoints. |
| `docs/context.md` | Current phase, latest decisions, next steps. |
| `docs/decisions.md` | Decision log with an initial baseline entry. |
| `docs/skills.md` | Inventory of skills detected in standard directories. |

## Design Principles

- **No stack scaffolding.** protto never installs dependencies or creates framework code.
- **Detect, don’t ask.** Build/test/lint/typecheck/architecture are inferred from existing files.
- **Cross-LLM.** Both Claude Code and OpenCode receive equivalent configs.
- **Human-readable.** Generated docs are meant to be read and edited by humans, not just agents.
- **Traceable.** Decisions, architecture, and context are linked so a user can follow the project state.

## Verification Checklist

- [ ] `protto init` creates `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.opencode/`, `docs/`.
- [ ] `protto init --force` backs up existing `CLAUDE.md` and `AGENTS.md`.
- [ ] Generated `settings.json` is valid JSON and contains detected build/test commands.
- [ ] `AGENTS.md` references `.opencode`, not `.claude`.
- [ ] `docs/decisions.md` contains a baseline decision entry.
- [ ] `docs/architecture.md` links to `docs/decisions.md` and `docs/context.md`.
- [ ] Running `./tests/test.bash` in the protto repo passes.

## See Also

- `README.md` in the protto repository for CLI details.
- `Tecnologia/Claude-Code/Guia-Gestion-Proyectos.md` in the vault for the research-backed conventions this tool implements.
