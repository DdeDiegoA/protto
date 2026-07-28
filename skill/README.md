# protto Skill

Skill wrapper for the `protto` CLI. It lets Claude Code and OpenCode run project-setup commands as agent-native slash commands.

## What It Does

`/protto init` runs `protto init --force` in the current working directory, generating:

- `CLAUDE.md` / `AGENTS.md`
- `.claude/` and `.opencode/` config trees
- `docs/architecture.md`, `docs/context.md`, `docs/decisions.md`, `docs/skills.md`
- Hook-aware `settings.json`

`/protto analyze` imports a `graphify` report (`graphify-out/GRAPH_REPORT.md`) or creates a bootstrap script so the agent can run `/graphify` itself.

`/protto list-skills` lists skills detected in `~/.hermes/skills/`, `~/.claude/skills/`, and `~/.opencode/skills/`.

## Installation

Run from the repo root:

```bash
./install.sh
```

This installs:

- `~/.local/bin/protto` — the CLI.
- `~/.local/share/protto/` — supporting libraries.
- `~/.claude/skills/protto/SKILL.md` — Claude Code skill wrapper.
- `~/.opencode/skills/protto/SKILL.md` — OpenCode skill wrapper.

## Usage

### In an agent session

```
/protto init            # create agent-friendly project structure
/protto list-skills     # show available skills
/protto analyze         # import graphify output
/protto help            # show CLI help
```

### From the terminal

```bash
protto init --force     # same as /protto init
protto list-skills
protto analyze
```

## Validation

To verify the skill works after install:

```bash
cd /tmpm -rf protto-test
mkdir protto-test
cd protto-test
protto init --force
ls -la CLAUDE.md AGENTS.md .claude .opencode docs
python3 -m json.tool .claude/settings.json
python3 -m json.tool .opencode/settings.json
grep -q ".opencode" AGENTS.md && echo "AGENTS.md cross-LLM OK"
grep -q "## 2026-" docs/decisions.md && echo "decisions OK"
```

## Files

| File | Description |
|------|-------------|
| `SKILL.md` | Agent skill definition. |
| `README.md` | This file. |

## See Also

- Repository: `~/Programacion/proyectos/protto`
- CLI source: `~/Programacion/proyectos/protto/protto`
