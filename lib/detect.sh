# protto detect
# ponytail: infer project facts from existing files. No dependencies.

# Return a list of executable shell scripts in the project root.
find_root_scripts() {
  find . -maxdepth 1 -type f -perm +111 2>/dev/null | sed 's|^\./||' | sort
}

# Detect the main build command for the current stack.
detect_build_command() {
  if [[ -f "package.json" ]]; then
    if grep -q '"build"' package.json; then echo "npm run build"; else echo "npm install && npm test"; fi
  elif [[ -f "Cargo.toml" ]]; then
    echo "cargo build"
  elif [[ -f "pyproject.toml" ]]; then
    if grep -q "\[tool.poetry\]" pyproject.toml; then echo "poetry build"; else echo "python -m pytest"; fi
  elif [[ -f "setup.py" ]]; then
    echo "python setup.py test"
  elif [[ -f "go.mod" ]]; then
    echo "go build ./..."
  elif [[ -f "Makefile" ]]; then
    echo "make"
  elif find_root_scripts | grep -q '^protto$'; then
    # bash CLI project like protto itself
    echo "bash -n protto && bash -n lib/*.sh"
  else
    echo "echo 'TODO: add build command'"
  fi
}

# Detect the main test command.
detect_test_command() {
  if [[ -f "package.json" ]]; then
    if grep -q '"test"' package.json; then echo "npm test"; else echo "npm run build"; fi
  elif [[ -f "Cargo.toml" ]]; then
    echo "cargo test"
  elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
    echo "pytest"
  elif [[ -f "go.mod" ]]; then
    echo "go test ./..."
  elif [[ -f "Makefile" ]]; then
    echo "make test"
  elif [[ -f "tests/test.bash" ]]; then
    echo "./tests/test.bash"
  else
    echo "echo 'TODO: add test command'"
  fi
}

# Detect lint command.
detect_lint_command() {
  if [[ -f "package.json" ]]; then
    if grep -q '"lint"' package.json; then echo "npm run lint"; else echo "echo 'TODO: add lint command'"; fi
  elif [[ -f "pyproject.toml" ]]; then
    echo "ruff check ."
  else
    echo "echo 'TODO: add lint command'"
  fi
}

# Detect typecheck command.
detect_typecheck_command() {
  if [[ -f "tsconfig.json" ]]; then echo "npx tsc --noEmit"
  elif [[ -f "Cargo.toml" ]]; then echo "cargo check"
  elif [[ -f "pyproject.toml" ]] && grep -q "mypy" pyproject.toml; then echo "mypy ."
  else echo "echo 'TODO: add typecheck command'"
  fi
}

# Human-readable stack name for templates.
detect_stack_name() {
  if [[ -f "package.json" ]]; then echo "node"
  elif [[ -f "Cargo.toml" ]]; then echo "rust"
  elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then echo "python"
  elif [[ -f "go.mod" ]]; then echo "go"
  elif [[ -f "Makefile" ]]; then echo "make"
  else echo "bash"
  fi
}

# Returns a description of the architecture based on existing files.
detect_architecture() {
  local lines=""
  if [[ -f "package.json" ]]; then
    lines+="- package.json — node/npm project\n"
    [[ -d "src" ]] && lines+="- src/ — application source\n"
    [[ -d "test" ]] && lines+="- test/ — tests\n"
    [[ -f "README.md" ]] && lines+="- README.md — project overview\n"
  elif [[ -f "Cargo.toml" ]]; then
    lines+="- Cargo.toml — Rust workspace/crate\n"
    [[ -d "src" ]] && lines+="- src/ — Rust source\n"
    [[ -d "tests" ]] && lines+="- tests/ — integration tests\n"
  elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
    lines+="- Python package\n"
    [[ -d "src" ]] && lines+="- src/ — Python source\n"
    [[ -d "tests" ]] && lines+="- tests/ — pytest tests\n"
  elif [[ -f "go.mod" ]]; then
    lines+="- go.mod — Go module\n"
    [[ -d "cmd" ]] && lines+="- cmd/ — command entrypoints\n"
    [[ -d "pkg" ]] && lines+="- pkg/ — library code\n"
  else
    # Generic/bash project: describe what actually exists
    [[ -f "protto" ]] && lines+="- protto — main CLI entrypoint\n"
    [[ -d "lib" ]] && lines+="- lib/ — shell libraries\n"
    [[ -d "bin" ]] && lines+="- bin/ — executable scripts\n"
    [[ -d "tests" ]] && lines+="- tests/ — test suites\n"
    [[ -f "README.md" ]] && lines+="- README.md — project overview\n"
    [[ -d "docs" ]] && lines+="- docs/ — documentation\n"
    [[ -d ".claude" ]] && lines+="- .claude/ / .opencode/ — agent configuration\n"
  fi
  # Always include docs if it exists
  [[ -d "docs" ]] && [[ -f "package.json" || -f "Cargo.toml" || -f "pyproject.toml" || -f "go.mod" ]] && lines+="- docs/ — documentation\n"
  printf '%b' "$lines"
}

# Returns project title from package.json/Cargo.toml/pyproject.toml, or basename.
detect_title() {
  local title=""
  if [[ -f "package.json" ]]; then
    title=$(grep -m1 '"name"' package.json | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
  elif [[ -f "Cargo.toml" ]]; then
    title=$(grep -m1 '^name\s*=' Cargo.toml | sed -E 's/.*=\s*"([^"]+)".*/\1/')
  elif [[ -f "pyproject.toml" ]]; then
    title=$(grep -m1 '^name\s*=' pyproject.toml | sed -E 's/.*=\s*"([^"]+)".*/\1/')
  fi
  if [[ -z "$title" ]]; then
    title=$(basename "$(pwd)")
  fi
  echo "$title"
}

# Extract one-line description from README first paragraph.
detect_description() {
  if [[ -f "README.md" ]]; then
    awk '
      /^# / {
        while ((getline line) > 0) {
          if (line ~ /[^ \t]/) {
            sub(/^[ \t]*>[ \t]?/, "", line)
            print line
            exit
          }
        }
      }
    ' README.md
  elif [[ -f "package.json" ]]; then
    grep -m1 '"description"' package.json | sed -E 's/.*"description"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'
  elif [[ -f "pyproject.toml" ]]; then
    grep -m1 '^description\s*=' pyproject.toml | sed -E 's/.*=\s*"([^"]+)".*/\1/'
  fi
}

# Required environment based on stack.
detect_required_env() {
  if [[ -f "package.json" ]]; then echo "node, npm"
  elif [[ -f "Cargo.toml" ]]; then echo "rust, cargo"
  elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then echo "python3, pip"
  elif [[ -f "go.mod" ]]; then echo "go"
  else echo "bash >= 4.0"
  fi
}

# Optional environment based on available tools.
detect_optional_env() {
  local opts=""
  command -v git >/dev/null 2>&1 && opts+="git "
  (command -v graphify >/dev/null 2>&1 || python3 -c "import graphify" 2>/dev/null) && opts+="graphify "
  [[ -n "$opts" ]] && echo "${opts% }" || echo "none"
}

# True if graphify is available in PATH or in ~/.local/bin.
has_graphify() {
  command -v graphify >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/graphify" ]]
}
