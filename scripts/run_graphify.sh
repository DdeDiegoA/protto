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
