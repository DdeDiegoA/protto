#!/usr/bin/env bash
# Install protto CLI and agent skill wrappers.

set -euo pipefail

REPO="${REPO:-$(cd "$(dirname "$0")" && pwd)}"
TARGET_BIN="$HOME/.local/bin"
TARGET_LIB="$HOME/.local/share/protto"
SKILL_DIR_CC="$HOME/.claude/skills/protto"
SKILL_DIR_OC="$HOME/.config/opencode/skills/protto"

mkdir -p "$TARGET_BIN" "$TARGET_LIB/lib"

# CLI + libs
rm -rf "$TARGET_LIB"/*
cp "$REPO/protto" "$TARGET_LIB/protto"
cp -r "$REPO/lib" "$TARGET_LIB/lib"

# Wrapper script in PATH
cat > "$TARGET_BIN/protto" <<EOF
#!/usr/bin/env bash
exec "$TARGET_LIB/protto" "\$@"
EOF
chmod +x "$TARGET_BIN/protto"

# Claude Code skill wrapper
mkdir -p "$SKILL_DIR_CC"
cat > "$SKILL_DIR_CC/SKILL.md" <<'EOF'
---
name: protto
description: Bootstrap an agent-friendly project structure.
---

When the user says "inicia el proyecto", "protto init", or similar, run the shell command:

```bash
protto init
```

Then read the generated CLAUDE.md and docs/skills.md and continue with the user's intent.

If the user wants deeper planning, delegate to the `speckit` skill or `grill-me` if available.

For existing repositories, after `protto init`, run the `graphify` skill if available:

```bash
/graphify . --update --no-viz
```

Then run `protto analyze` to import the graphify report into `docs/architecture.md` and `docs/context.md`.
EOF

# OpenCode skill wrapper
mkdir -p "$SKILL_DIR_OC"
cat > "$SKILL_DIR_OC/SKILL.md" <<'EOF'
---
name: protto
description: Bootstrap an agent-friendly project structure.
---

When the user says "inicia el proyecto", "protto init", or similar, run the shell command:

```bash
protto init
```

Then read the generated AGENTS.md and docs/skills.md and continue with the user's intent.

If the user wants deeper planning, delegate to the `speckit` skill or `grill-me` if available.

For existing repositories, after `protto init`, run the `graphify` skill if available:

```bash
/graphify . --update --no-viz
```

Then run `protto analyze` to import the graphify report into `docs/architecture.md` and `docs/context.md`.
EOF

echo "protto installed to $TARGET_BIN"
echo "Skills installed:"
echo "  $SKILL_DIR_CC"
echo "  $SKILL_DIR_OC"
echo ""
echo "Ensure $TARGET_BIN is in PATH."
