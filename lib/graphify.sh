# protto graphify integration
# ponytail: detect graphify output, import it, or generate a bootstrap script.

GRAPHIFY_DIR="graphify-out"
GRAPHIFY_REPORT="$GRAPHIFY_DIR/GRAPH_REPORT.md"

graphify_report_exists() {
  [[ -f "$GRAPHIFY_REPORT" ]]
}

graphify_installed() {
  # Only count as installed if a usable CLI or Python module exists in PATH/python.
  command -v graphify >/dev/null 2>&1 || python3 -c "import graphify" 2>/dev/null
}

# Extract a section from the report. Usage: extract_section FILE START_HEADING END_HEADING (without #)
extract_section() {
  local file="$1" start="$2" end="$3"
  awk -v s="$start" -v e="$end" '
    BEGIN { in_section = 0 }
    /^#/ {
      if (tolower($0) ~ ("^#+ " tolower(s) "$")) { in_section = 1; next }
      if (in_section && tolower($0) ~ ("^#+ " tolower(e) "$")) { exit }
    }
    in_section { print }
  ' "$file"
}

# Import graphify report into docs/architecture.md and docs/context.md
import_graphify() {
  if ! graphify_report_exists; then
    echo "[protto] no graphify report found at $GRAPHIFY_REPORT; run scripts/run_graphify.sh or protto analyze --generate" >&2
    return 1
  fi

  local nodes edges communities
  nodes=$(grep -m1 -E "^Graph:.*nodes" "$GRAPHIFY_REPORT" | sed -E 's/.*Graph: ([0-9]+) nodes.*/\1/')
  edges=$(grep -m1 -E "^Graph:.*edges" "$GRAPHIFY_REPORT" | sed -E 's/.*Graph: [0-9]+ nodes, ([0-9]+) edges.*/\1/')
  communities=$(grep -m1 -E "^Graph:.*communities" "$GRAPHIFY_REPORT" | sed -E 's/.*Graph: [0-9]+ nodes, [0-9]+ edges, ([0-9]+) communities.*/\1/')

  {
    echo "# Architecture"
    echo "> Auto-generated from graphify report."
    echo ""
    [[ -n "$nodes" ]] && echo "- **Graph stats:** $nodes nodes, $edges edges, $communities communities"
    echo ""
    echo "## God Nodes"
    extract_section "$GRAPHIFY_REPORT" "God Nodes" "Community Cohesion" | sed '/^$/d' | head -30
    echo ""
    echo "## Knowledge Gaps"
    extract_section "$GRAPHIFY_REPORT" "Knowledge Gaps" "Suggested Questions" | sed '/^$/d' | head -30
  } > docs/architecture.md

  {
    echo "# Context"
    echo "> Current phase, latest decisions, and next steps."
    echo ""
    echo "- Knowledge graph generated with graphify (see docs/architecture.md)."
    echo "- Stats: $nodes nodes, $edges edges, $communities communities"
    echo ""
    echo "## Surprising Connections"
    extract_section "$GRAPHIFY_REPORT" "Surprising Connections" "Knowledge Gaps" | sed '/^$/d' | head -30
  } > docs/context.md

  echo "[protto] imported graphify report into docs/architecture.md and docs/context.md"
}

# Generate a bootstrap script to run graphify on the project.
generate_graphify_script() {
  mkdir -p scripts
  cat > scripts/run_graphify.sh <<'EOF'
#!/usr/bin/env bash
# Bootstrap graphify for this project.
# If graphify is installed as a CLI/Python package, run AST-only extraction.
# Otherwise, delegate to Claude Code with the graphify skill.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if command -v graphify >/dev/null 2>&1 || python3 -c "import graphify" 2>/dev/null; then
  echo "[graphify] graphify detected; running AST-only extraction..."
  python3 -c "
import sys, json
from pathlib import Path
from graphify.detect import detect
from graphify.extract import collect_files, extract
from graphify.build import build_from_json
from graphify.cluster import cluster
from graphify.export import to_json, to_html
from graphify.report import generate

root = Path('.')
detect = detect(root)
code_files = []
for f in detect.get('files', {}).get('code', []):
    code_files.extend(collect_files(Path(f)) if Path(f).is_dir() else [Path(f)])
if not code_files:
    print('No code files found')
    sys.exit(1)
ast = extract(code_files, cache_root=root, parallel=False)
G = build_from_json(ast)
communities = cluster(G)
report = generate(G, communities, {}, {}, [], [], detect, {'input':0,'output':0}, '.')
Path('graphify-out').mkdir(exist_ok=True)
Path('graphify-out/GRAPH_REPORT.md').write_text(report, encoding='utf-8')
to_json(G, communities, 'graphify-out/graph.json')
to_html(G, communities, 'graphify-out/graph.html')
print(f'Graph: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges, {len(communities)} communities')
"
  echo "[graphify] done. Run 'protto analyze' to import results."
else
  echo "[graphify] not installed. Delegate to Claude Code:"
  echo "  /graphify . --update --no-viz"
  echo "Then run: protto analyze"
  exit 1
fi
EOF
  chmod +x scripts/run_graphify.sh
  echo "[protto] generated scripts/run_graphify.sh"
}

# Main analyze command.
# If graphify output exists, import it. Otherwise, generate bootstrap script.
run_analyze() {
  if graphify_report_exists; then
    import_graphify
    return 0
  fi

  if graphify_installed; then
    echo "[protto] graphify available; running scripts/run_graphify.sh..."
    generate_graphify_script
    ./scripts/run_graphify.sh && import_graphify
  else
    echo "[protto] graphify not installed; generating bootstrap script."
    generate_graphify_script
    echo "[protto] run: ./scripts/run_graphify.sh or /graphify in Claude Code, then: protto analyze"
  fi
}
