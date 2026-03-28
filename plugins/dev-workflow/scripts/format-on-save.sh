#!/usr/bin/env bash
set -euo pipefail

# Post-edit hook: auto-format the file that was just edited/written
# Runs after Edit or Write tool completes

# Require jq for parsing hook input
if ! command -v jq &>/dev/null; then
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file_path // ""')

if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Auto-detect solution path: cloudstack.json > find *.sln
resolve_sln() {
  local sln
  sln=$(jq -r '.backend.solutionPath // empty' "$PROJECT_DIR/cloudstack.json" 2>/dev/null)
  if [[ -z "$sln" ]]; then
    sln=$(find "$PROJECT_DIR/src" -name "*.sln" -maxdepth 2 2>/dev/null | head -1)
  fi
  if [[ -z "$sln" ]]; then
    sln=$(find "$PROJECT_DIR" -name "*.sln" -maxdepth 3 2>/dev/null | head -1)
  fi
  echo "$sln"
}

# Auto-detect frontend path: cloudstack.json > common locations
resolve_frontend() {
  local fe
  fe=$(jq -r '.frontend.path // empty' "$PROJECT_DIR/cloudstack.json" 2>/dev/null)
  if [[ -z "$fe" ]]; then
    for candidate in "$PROJECT_DIR/web" "$PROJECT_DIR/frontend" "$PROJECT_DIR/client" "$PROJECT_DIR/app"; do
      if [[ -f "$candidate/package.json" ]]; then
        fe="$candidate"
        break
      fi
    done
  else
    fe="$PROJECT_DIR/$fe"
  fi
  echo "$fe"
}

case "$FILE_PATH" in
  *.cs)
    # Format single C# file via dotnet format
    SLN=$(resolve_sln)
    if [[ -n "$SLN" ]]; then
      dotnet format "$SLN" --include "$FILE_PATH" --verbosity quiet 2>/dev/null || true
    fi
    ;;
  *.ts|*.tsx|*.js|*.jsx)
    # Format single JS/TS file via ESLint fix
    FE_DIR=$(resolve_frontend)
    if [[ -n "$FE_DIR" && -d "$FE_DIR" ]]; then
      (cd "$FE_DIR" && npx eslint --fix "$FILE_PATH" 2>/dev/null) || true
    fi
    ;;
  *.tf)
    # Format single Terraform file
    terraform fmt "$FILE_PATH" 2>/dev/null || true
    ;;
  *.py)
    # Format single Python file
    if command -v ruff &>/dev/null; then
      ruff format "$FILE_PATH" 2>/dev/null || true
    elif command -v black &>/dev/null; then
      black --quiet "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.go)
    # Format single Go file
    if command -v gofmt &>/dev/null; then
      gofmt -w "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac

exit 0
