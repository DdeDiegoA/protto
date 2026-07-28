# protto utils
# ponytail: stdlib only. No jq, no python, no dependencies.

err() { echo "[protto] $*" >&2; }
die() { err "$*"; exit 1; }

timestamp() { date +%Y%m%d-%H%M%S; }

usage() {
  cat <<'EOF'
Usage: protto <command>
Commands:
  init              Create agent-friendly project structure
  list-skills       List skills found in standard directories
  analyze           Import graphify output or bootstrap a graphify run
  help              Show this help
EOF
}

backup_if_exists() {
  local f="$1"
  if [[ -f "$f" ]]; then
    local bak="${f}.bak.$(timestamp)"
    cp "$f" "$bak"
    echo "  backed up: $bak"
  fi
}

ensure_gitignore() {
  [[ -f ".gitignore" ]] || return 0
  for pat in CLAUDE.local.md AGENTS.local.md .env; do
    grep -qxF "$pat" .gitignore || echo "$pat" >> .gitignore
  done
}
