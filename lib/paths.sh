# protto paths
# ponytail: one source of truth for directories.

export REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SKILL_DIRS=(
  "$HOME/.hermes/skills"
  "$HOME/.claude/skills"
  "$HOME/.config/opencode/skills"
  "$HOME/.opencode/skills"
)

VERSION="0.1.0"
