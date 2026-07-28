# protto generators
# ponytail: plain here-docs. No templating engine for 4 files.

gen_dirs() {
  mkdir -p .claude/agents .claude/skills .claude/rules .claude/commands
  mkdir -p .opencode/agents .opencode/skills .opencode/rules .opencode/commands
  mkdir -p docs
}

gen_claude_md() {
  local title desc build test lint typecheck
  title=$(detect_title)
  desc=$(detect_description)
  build=$(detect_build_command)
  test=$(detect_test_command)
  lint=$(detect_lint_command)
  typecheck=$(detect_typecheck_command)
  cat > CLAUDE.md <<EOF
# $title
> ${desc:-Project initialized with protto.}

## Build & Test
- Build: \`$build\`
- Test: \`$test\`
- Lint: \`$lint\`
- Typecheck: \`$typecheck\`

## Architecture
$(detect_architecture)

## Gotchas
- \`lib/detect.sh\` uses POSIX tools (no jq/python). Keep it dependency-free.
- \`collect_skills\` emits newline-separated names; consume with while-read.
- Backup files use \`.bak.<timestamp>\`; clean them up before committing.

## Environment
- Required: \`$(detect_required_env)\`
- Optional: \`$(detect_optional_env)\`

## Available Skills
- Invoke skills with their trigger description. Add personal skills here as needed.
- See \`docs/skills.md\` for the list detected by protto.

## Docs
- \`docs/architecture.md\` — high-level design
- \`docs/context.md\` — current state and decisions
- \`docs/skills.md\` — skills available to this project

## Post-Setup
- Run \`protto analyze\` to import graphify output or bootstrap it.
EOF

  # ponytail: append dynamic post-setup suggestions so the agent reads them on boot
  suggest_all >> CLAUDE.md
}

gen_agents_md() {
  # AGENTS.md mirrors CLAUDE.md but points to opencode paths instead of claude paths.
  perl -pe 's/CLAUDE\.md/AGENTS.md/g; s/\.claude/.opencode/g' CLAUDE.md > AGENTS.md
  # Clean up the duplicated agent-config line so AGENTS.md reads naturally.
  perl -i -pe 's/^- \.opencode\/ \/ \.opencode\/ — agent configuration$/- .opencode\/ — agent configuration/' AGENTS.md
}

gen_settings_json() {
  local build_cmd test_cmd
  build_cmd=$(detect_build_command)
  test_cmd=$(detect_test_command)
  # Escape the command for JSON string
  build_cmd_json=$(printf '%s' "$build_cmd" | sed 's|\\|\\\\|g; s|"|\\"|g')
  test_cmd_json=$(printf '%s' "$test_cmd" | sed 's|\\|\\\\|g; s|"|\\"|g')
  cat > .claude/settings.json <<EOF
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "${build_cmd_json}",
        "timeout": 15
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "${test_cmd_json}",
        "timeout": 120
      }]
    }]
  }
}
EOF
  cat > .opencode/settings.json <<EOF
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "${build_cmd_json}",
        "timeout": 15
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "${test_cmd_json}",
        "timeout": 120
      }]
    }]
  }
}
EOF
}

gen_docs() {
  local ctx=""
  if graphify_report_exists; then
    ctx="graphify report already present. Run \`protto analyze\` to import it into CLAUDE.md."
  elif has_graphify; then
    ctx="graphify is available. Run \`protto analyze\` to generate a knowledge graph of this repository."
  else
    ctx="No graphify detected. Install graphify or run \`protto analyze\` to bootstrap."
  fi
  cat > docs/architecture.md <<EOF
# Architecture
> Start with one paragraph. Link to deeper files instead of copying.

$ctx
EOF
  cat > docs/context.md <<EOF
# Context
> Current phase, latest decisions, and next steps. Keep it short.

- Project initialized with protto.
EOF
}

gen_skills_md() {
  local out="docs/skills.md"
  {
    echo "# Available Skills"
    echo "> Detected by protto on $(date +%Y-%m-%d)."
    echo ""
    local skills
    skills=$(collect_skills)
    if [[ -z "$skills" ]]; then
      echo "No skills detected."
    else
      echo "## Personal Skills"
      echo ""
      echo "$skills" | while read -r name; do echo "- \`$name\`"; done
    fi
    echo ""
    echo "## Agent Skills"
    echo "Add skills you install under \`.claude/skills/\` or \`.opencode/skills/\`."
    # ponytail: append dynamic suggestions so the agent knows what to run next
    suggest_all
  } > "$out"
}
