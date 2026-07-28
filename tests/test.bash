#!/usr/bin/env bash
# protto self-check
# ponytail: one assert function, stdlib only.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROG="$ROOT/protto"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0

assert() {
  local cond="$1" msg="$2"
  if eval "$cond"; then
    PASS=$((PASS+1))
    echo "  ✓ $msg"
  else
    FAIL=$((FAIL+1))
    echo "  ✗ $msg"
  fi
}

assert_file_exists() {
  if ls "$1" >/dev/null 2>&1; then
    PASS=$((PASS+1))
    echo "  ✓ $2"
  else
    FAIL=$((FAIL+1))
    echo "  ✗ $2"
  fi
}

cd "$WORK"

# Simulate a bash project like protto itself for detection tests
mkdir -p lib tests
printf '%s\n' '#!/usr/bin/env bash' > protto
chmod +x protto
printf '%s\n' '#!/usr/bin/env bash' > tests/test.bash
printf '%s\n' '# protto' > README.md

# Test 1: init creates structure
"$PROG" init >/dev/null 2>&1
assert '[[ -f CLAUDE.md ]]' 'CLAUDE.md created'
assert '[[ -f AGENTS.md ]]' 'AGENTS.md created'
assert '[[ -d .claude/agents ]]' '.claude/agents created'
assert '[[ -d .opencode/skills ]]' '.opencode/skills created'
assert '[[ -f .claude/settings.json ]]' '.claude/settings.json created'
assert '[[ -f docs/skills.md ]]' 'docs/skills.md created'

# Test 2: init refuses overwrite without --force
assert '! "$PROG" init >/dev/null 2>&1' 'init refuses overwrite without --force'

# Test 3: generated CLAUDE.md contains dynamic project info for bash project
assert 'grep -q "bash -n protto && bash -n lib/" CLAUDE.md' 'CLAUDE.md contains detected build command'
assert 'grep -q "./tests/test.bash" CLAUDE.md' 'CLAUDE.md contains detected test command'
assert 'grep -q "protto" CLAUDE.md' 'CLAUDE.md contains project title'

# Test 4: settings.json contains real commands
assert 'grep -q "bash -n protto" .claude/settings.json' 'settings.json uses detected build command'
assert 'grep -q "./tests/test.bash" .claude/settings.json' 'settings.json uses detected test command'
assert 'python3 -m json.tool .claude/settings.json >/dev/null' 'settings.json is valid JSON'

# Test 5: AGENTS.md is adapted for OpenCode
assert '! grep -q "\\.claude" AGENTS.md' 'AGENTS.md does not reference .claude'
assert 'grep -q "\\.opencode" AGENTS.md' 'AGENTS.md references .opencode'

# Test 6: init --force overwrites and backs up
BEFORE=$(cat CLAUDE.md)
"$PROG" init --force >/dev/null 2>&1
set +e
files=(CLAUDE.md.bak.*)
set -e
[[ -f "${files[0]}" ]] && PASS=$((PASS+1)) && echo "  ✓ backup created on --force" || { FAIL=$((FAIL+1)); echo "  ✗ backup created on --force"; }
AFTER=$(cat CLAUDE.md)
[[ "$BEFORE" == "$AFTER" ]] && PASS=$((PASS+1)) && echo "  ✓ recreated CLAUDE.md matches template" || { FAIL=$((FAIL+1)); echo "  ✗ recreated CLAUDE.md matches template"; }

# Test 6: list-skills exits 0
"$PROG" list-skills >/dev/null 2>&1
assert '[[ $? -eq 0 ]]' 'list-skills exits 0'

# Test 7: invalid command exits non-zero
! "$PROG" bogus >/dev/null 2>&1
assert '[[ $? -eq 0 ]]' 'invalid command fails'

# Test 9: analyze command bootstraps graphify script when no report exists
cd "$WORK"
rm -rf scripts graphify-out
"$PROG" analyze >/dev/null 2>&1 || true
assert '[[ -f scripts/run_graphify.sh ]]' 'analyze generates graphify bootstrap script when no report exists'

# Test 10: analyze imports graphify report when it exists
cd "$WORK"
mkdir -p graphify-out
cat > graphify-out/GRAPH_REPORT.md <<'REPORT'
# Graphify Report

Graph: 42 nodes, 55 edges, 7 communities

## God Nodes
- main
- lib/detect.sh

## Community Cohesion

## Knowledge Gaps
- missing tests

## Suggested Questions

## Surprising Connections
- main -> lib/graphify.sh
REPORT
"$PROG" analyze >/dev/null 2>&1
assert 'grep -q "42 nodes" docs/architecture.md' 'analyze imports graphify stats into docs/architecture.md'
assert 'grep -q "missing tests" docs/architecture.md' 'analyze imports graphify gaps into docs/architecture.md'

# Test 11: analyze imports surprising connections
assert 'grep -q "main -> lib/graphify.sh" docs/context.md' 'analyze imports surprising connections into docs/context.md'
echo ""
echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
