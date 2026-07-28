# protto

> Agent-friendly project setup for Claude Code, OpenCode, and Hermes.

`protto` creates the meta-layer that makes any project usable by an AI agent: boot files, hooks, skills, rules, and docs. It does not scaffold application code.

## Install

```bash
./install.sh
```

Ensure `~/.local/bin` is in your PATH.

## Usage

```bash
protto init              # bootstrap agent files in current directory
protto list-skills       # show skills found in standard directories
protto help              # show usage
```

## What it creates

- `CLAUDE.md` / `AGENTS.md` — project boot instructions
- `.claude/` / `.opencode/` — agent configs, skills, rules, commands
- `docs/architecture.md`, `docs/context.md`, `docs/skills.md`
- Hook skeletons in `settings.json`
- `.gitignore` entries for local override files

## Agent skill wrappers

After install, agents can respond to "inicia el proyecto" by running `protto init`.

## License

MIT
