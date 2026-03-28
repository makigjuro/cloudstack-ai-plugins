#!/usr/bin/env bash
set -euo pipefail

# Pre-commit hook: lint and format changed files
# Called by Claude Code PreToolUse hook on git commit

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Only intercept git commit commands
if [[ "$COMMAND" != *"git commit"* ]]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
ERRORS=()

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

# Get staged files by type
STAGED_CS=$(git -C "$PROJECT_DIR" diff --cached --name-only --diff-filter=ACM -- '*.cs' 2>/dev/null || true)
STAGED_TS=$(git -C "$PROJECT_DIR" diff --cached --name-only --diff-filter=ACM -- '*.ts' '*.tsx' '*.js' '*.jsx' 2>/dev/null || true)
STAGED_TF=$(git -C "$PROJECT_DIR" diff --cached --name-only --diff-filter=ACM -- '*.tf' 2>/dev/null || true)
STAGED_HELM=$(git -C "$PROJECT_DIR" diff --cached --name-only --diff-filter=ACM -- 'deploy/charts/*' 2>/dev/null || true)
STAGED_PY=$(git -C "$PROJECT_DIR" diff --cached --name-only --diff-filter=ACM -- '*.py' 2>/dev/null || true)
STAGED_GO=$(git -C "$PROJECT_DIR" diff --cached --name-only --diff-filter=ACM -- '*.go' 2>/dev/null || true)

# 1. dotnet format on staged C# files
if [[ -n "$STAGED_CS" ]]; then
  SLN=$(resolve_sln)
  if [[ -n "$SLN" ]]; then
    if ! dotnet format "$SLN" --verify-no-changes --verbosity quiet 2>/dev/null; then
      dotnet format "$SLN" --verbosity quiet 2>/dev/null || true
      echo "$STAGED_CS" | while IFS= read -r f; do
        [[ -f "$PROJECT_DIR/$f" ]] && git -C "$PROJECT_DIR" add "$f"
      done
      ERRORS+=("dotnet format: auto-fixed C# formatting issues and re-staged files")
    fi
  fi
fi

# 2. ESLint on staged JS/TS files
if [[ -n "$STAGED_TS" ]]; then
  FE_DIR=$(resolve_frontend)
  if [[ -n "$FE_DIR" && -d "$FE_DIR" ]]; then
    if ! (cd "$FE_DIR" && npx eslint --quiet $STAGED_TS 2>/dev/null); then
      (cd "$FE_DIR" && npx eslint --fix $STAGED_TS 2>/dev/null) || true
      echo "$STAGED_TS" | while IFS= read -r f; do
        [[ -f "$PROJECT_DIR/$f" ]] && git -C "$PROJECT_DIR" add "$f"
      done
      ERRORS+=("eslint: auto-fixed TypeScript/JavaScript lint issues and re-staged files")
    fi
  fi
fi

# 3. terraform fmt on staged .tf files
if [[ -n "$STAGED_TF" ]]; then
  INFRA_DIR="$PROJECT_DIR/infra"
  if [[ -d "$INFRA_DIR" ]]; then
    if ! terraform fmt -check -recursive "$INFRA_DIR" >/dev/null 2>&1; then
      terraform fmt -recursive "$INFRA_DIR" >/dev/null 2>&1 || true
      echo "$STAGED_TF" | while IFS= read -r f; do
        [[ -f "$PROJECT_DIR/$f" ]] && git -C "$PROJECT_DIR" add "$f"
      done
      ERRORS+=("terraform fmt: auto-fixed Terraform formatting and re-staged files")
    fi
  fi
fi

# 4. helm lint on staged chart changes
if [[ -n "$STAGED_HELM" ]]; then
  CHART_DIRS=$(echo "$STAGED_HELM" | grep -oP 'deploy/charts/[^/]+' | sort -u)
  for chart_dir in $CHART_DIRS; do
    if [[ -f "$PROJECT_DIR/$chart_dir/Chart.yaml" ]]; then
      if ! helm lint "$PROJECT_DIR/$chart_dir" --quiet 2>/dev/null; then
        ERRORS+=("helm lint: $chart_dir has lint errors (cannot auto-fix)")
      fi
    fi
  done
fi

# 5. Python formatting on staged .py files
if [[ -n "$STAGED_PY" ]]; then
  if command -v ruff &>/dev/null; then
    if ! ruff check --quiet $STAGED_PY 2>/dev/null; then
      ruff format $STAGED_PY 2>/dev/null || true
      ruff check --fix $STAGED_PY 2>/dev/null || true
      echo "$STAGED_PY" | while IFS= read -r f; do
        [[ -f "$PROJECT_DIR/$f" ]] && git -C "$PROJECT_DIR" add "$f"
      done
      ERRORS+=("ruff: auto-fixed Python formatting/lint issues and re-staged files")
    fi
  elif command -v black &>/dev/null; then
    black --check --quiet $STAGED_PY 2>/dev/null || {
      black --quiet $STAGED_PY 2>/dev/null || true
      echo "$STAGED_PY" | while IFS= read -r f; do
        [[ -f "$PROJECT_DIR/$f" ]] && git -C "$PROJECT_DIR" add "$f"
      done
      ERRORS+=("black: auto-fixed Python formatting issues and re-staged files")
    }
  fi
fi

# 6. Go formatting on staged .go files
if [[ -n "$STAGED_GO" ]]; then
  if command -v gofmt &>/dev/null; then
    UNFORMATTED=$(gofmt -l $STAGED_GO 2>/dev/null || true)
    if [[ -n "$UNFORMATTED" ]]; then
      gofmt -w $STAGED_GO 2>/dev/null || true
      echo "$STAGED_GO" | while IFS= read -r f; do
        [[ -f "$PROJECT_DIR/$f" ]] && git -C "$PROJECT_DIR" add "$f"
      done
      ERRORS+=("gofmt: auto-fixed Go formatting issues and re-staged files")
    fi
  fi
fi

# Report results
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  MSG=$(printf '%s\n' "${ERRORS[@]}")

  # Check if any are non-auto-fixable
  if echo "$MSG" | grep -q "cannot auto-fix"; then
    echo "$MSG" >&2
    exit 2  # Block commit
  fi

  # All were auto-fixed — allow commit to proceed
  echo "$MSG" >&2
  exit 0
fi

exit 0
