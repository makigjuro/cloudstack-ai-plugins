#!/usr/bin/env bash
# resolve-test-projects.sh — Map changed files to affected .NET test project paths.
#
# Configuration is read from cloudstack.json at the repo root (via jq):
#   .backend.services[]      — name, path, projectPrefix, aliases[], testProjects.unit[]/integration[]
#   .backend.sharedPaths[]   — foundational paths; a change here means run the full suite
#   .repository.defaultBranch — default diff base (falls back to "main")
# When jq or cloudstack.json is missing, degrades to convention-based discovery
# (tests/ and src/tests/ directories, fuzzy name matching).
#
# Usage: resolve-test-projects.sh [--mode unit|integration|all] [--service slug] [--diff-base ref]
#
# Exit codes:
#   0 — found targeted projects (paths on stdout), or prints NO_TESTS_AFFECTED
#       when only non-source files changed
#   1 — error
#   2 — run full suite (shared dependency changed or fallback)

set -euo pipefail

MODE="unit"
SERVICE=""
DIFF_BASE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)       MODE="$2"; shift 2 ;;
    --service)    SERVICE="$2"; shift 2 ;;
    --diff-base)  DIFF_BASE="$2"; shift 2 ;;
    *)            echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel)"
CONFIG="$REPO_ROOT/cloudstack.json"

lower()  { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
squash() { lower "$1" | tr -d '._-'; }

# --- Load configuration (graceful degradation without jq/cloudstack.json) ---
HAVE_CONFIG=false
SERVICE_TABLE=""   # rows: name \t path \t prefix \t aliases \t unitFlag \t unitList \t intFlag \t intList
SHARED_PATHS=""

if command -v jq >/dev/null 2>&1 && [[ -f "$CONFIG" ]]; then
  if SERVICE_TABLE="$(jq -r '
      (.backend.services // [])[] |
      [ .name,
        .path,
        .projectPrefix,
        ((.aliases // []) | join(",")),
        (if (.testProjects // {}) | has("unit") then "explicit" else "convention" end),
        ((.testProjects.unit // []) | join(",")),
        (if (.testProjects // {}) | has("integration") then "explicit" else "convention" end),
        ((.testProjects.integration // []) | join(","))
      ] | @tsv' "$CONFIG" 2>/dev/null)"; then
    HAVE_CONFIG=true
    SHARED_PATHS="$(jq -r '(.backend.sharedPaths // [])[]' "$CONFIG" 2>/dev/null)" || SHARED_PATHS=""
    if [[ -z "$DIFF_BASE" ]]; then
      DIFF_BASE="$(jq -r '.repository.defaultBranch // empty' "$CONFIG" 2>/dev/null)" || DIFF_BASE=""
    fi
  fi
fi
[[ -z "$DIFF_BASE" ]] && DIFF_BASE="main"

# --- Service alias normalization (config-driven) ---
# Matches slug against service name, path basename, and aliases —
# case-insensitively and ignoring '.', '-', '_' (so dm, DeviceManager,
# device-manager all resolve to the same service).
normalize_service() {
  local squashed name path prefix aliases rest alias
  squashed="$(squash "$1")"
  [[ -z "$squashed" ]] && return 0
  while IFS=$'\t' read -r name path prefix aliases rest; do
    [[ -z "$name" ]] && continue
    if [[ "$(squash "$name")" == "$squashed" ]]; then echo "$name"; return 0; fi
    if [[ "$(squash "$(basename "$path")")" == "$squashed" ]]; then echo "$name"; return 0; fi
    for alias in $(printf '%s' "$aliases" | tr ',' ' '); do
      if [[ "$(squash "$alias")" == "$squashed" ]]; then echo "$name"; return 0; fi
    done
  done <<< "$SERVICE_TABLE"
}

# --- Test project resolution ---
# kind filter: directory names containing "integration" (any case) are
# integration projects; everything else counts as unit.
matches_kind() {
  local lowerbase kind="$2"
  lowerbase="$(lower "$(basename "$1")")"
  case "$kind" in
    integration) [[ "$lowerbase" == *integration* ]] ;;
    unit)        [[ "$lowerbase" != *integration* ]] ;;
    *)           return 0 ;;
  esac
}

# Convention-based discovery: tests/{prefix}.Tests*, tests/{prefix}.*.Tests*,
# and {servicePath}/tests/* — filtered to directories that exist.
convention_tests() {
  local prefix="$1" svcpath="$2" kind="$3" d rel
  {
    if [[ -n "$prefix" ]]; then
      for d in "$REPO_ROOT/tests/$prefix".Tests* "$REPO_ROOT/tests/$prefix".*.Tests* \
               "$REPO_ROOT/src/tests/$prefix".Tests* "$REPO_ROOT/src/tests/$prefix".*.Tests*; do
        [[ -d "$d" ]] && echo "$d"
      done
    fi
    if [[ -n "$svcpath" && -d "$REPO_ROOT/$svcpath/tests" ]]; then
      for d in "$REPO_ROOT/$svcpath/tests"/*/; do
        [[ -d "$d" ]] && echo "${d%/}"
      done
    fi
  } | while IFS= read -r d; do
    rel="${d#"$REPO_ROOT"/}"
    matches_kind "$rel" "$kind" && echo "$rel" || true
  done | sort -u
}

emit_mode_tests() {
  local path="$1" prefix="$2" flag="$3" list="$4" kind="$5"
  if [[ "$flag" == "explicit" ]]; then
    # Explicit empty list means the service has no tests of this kind
    [[ -n "$list" ]] && printf '%s\n' "$list" | tr ',' '\n' || true
  else
    convention_tests "$prefix" "$path" "$kind"
  fi
}

emit_tests_for_service() {
  local svc="$1" row name path prefix aliases uflag ulist iflag ilist
  row="$(printf '%s\n' "$SERVICE_TABLE" | awk -F'\t' -v n="$svc" '$1==n {print; exit}')"
  [[ -z "$row" ]] && return 0
  IFS=$'\t' read -r name path prefix aliases uflag ulist iflag ilist <<< "$row"
  if [[ "$MODE" == "unit" || "$MODE" == "all" ]]; then
    emit_mode_tests "$path" "$prefix" "$uflag" "$ulist" unit
  fi
  if [[ "$MODE" == "integration" || "$MODE" == "all" ]]; then
    emit_mode_tests "$path" "$prefix" "$iflag" "$ilist" integration
  fi
}

# Fuzzy discovery when no config is available: match test directory names
# under tests/ and src/tests/ against the squashed slug.
fuzzy_tests_for_slug() {
  local squashed d name rel
  squashed="$(squash "$1")"
  for d in "$REPO_ROOT/tests"/*/ "$REPO_ROOT/src/tests"/*/; do
    [[ -d "$d" ]] || continue
    rel="${d%/}"; rel="${rel#"$REPO_ROOT"/}"
    name="$(squash "$(basename "$rel")")"
    [[ "$name" == *"$squashed"* ]] || continue
    if [[ "$MODE" == "all" ]]; then
      echo "$rel"
    elif matches_kind "$rel" "$MODE"; then
      echo "$rel"
    fi
  done | sort -u
}

# Filter to paths that actually exist
filter_existing() {
  while IFS= read -r p; do
    [[ -n "$p" && -d "$REPO_ROOT/$p" ]] && echo "$p" || true
  done
}

# --- Explicit service mode ---
if [[ -n "$SERVICE" ]]; then
  if [[ "$HAVE_CONFIG" == true ]]; then
    NORMALIZED="$(normalize_service "$SERVICE")"
    if [[ -n "$NORMALIZED" ]]; then
      RESULTS="$(emit_tests_for_service "$NORMALIZED" | filter_existing)"
      if [[ -n "$RESULTS" ]]; then
        echo "$RESULTS"
        exit 0
      fi
      # An explicitly-declared empty testProjects list means the service has
      # no tests of this kind — a valid state, not an error
      row="$(printf '%s\n' "$SERVICE_TABLE" | awk -F'\t' -v n="$NORMALIZED" '$1==n {print; exit}')"
      IFS=$'\t' read -r _n _p _pre _al uflag ulist iflag ilist <<< "$row"
      if [[ "$MODE" == "integration" && "$iflag" == "explicit" && -z "$ilist" ]] || \
         [[ "$MODE" == "unit" && "$uflag" == "explicit" && -z "$ulist" ]]; then
        echo "NO_TESTS_AFFECTED"
        exit 0
      fi
      echo "No test projects found for $SERVICE (mode=$MODE)" >&2
      exit 1
    fi
    # Not a service — maybe a shared/foundational project (e.g. "domain").
    # Emit its own tests if any exist by convention, otherwise full suite.
    SQUASHED="$(squash "$SERVICE")"
    while IFS= read -r sp; do
      [[ -z "$sp" ]] && continue
      sp="${sp%/}"
      if [[ "$(squash "$(basename "$sp")")" == *"$SQUASHED"* ]]; then
        RESULTS="$(convention_tests "$(basename "$sp")" "" "$MODE" | filter_existing)"
        if [[ -n "$RESULTS" ]]; then
          echo "$RESULTS"
          exit 0
        fi
        exit 2
      fi
    done <<< "$SHARED_PATHS"
    echo "Unknown service: $SERVICE" >&2
    exit 1
  fi
  # No config — fuzzy match against conventional test directories
  RESULTS="$(fuzzy_tests_for_slug "$SERVICE" | filter_existing)"
  if [[ -n "$RESULTS" ]]; then
    echo "$RESULTS"
    exit 0
  fi
  echo "No test projects found for $SERVICE (mode=$MODE)" >&2
  exit 1
fi

# --- Auto-detect mode: gather changed files ---
CHANGED_FILES="$(
  {
    git diff --name-only "${DIFF_BASE}"...HEAD 2>/dev/null || true
    git diff --name-only 2>/dev/null || true
    git diff --name-only --cached 2>/dev/null || true
  } | sort -u
)"

if [[ -z "$CHANGED_FILES" ]]; then
  # No changes detected — fallback to full suite
  exit 2
fi

# Source roots: top-level directories that contain application code. A changed
# file under a source root that maps to no known service falls back to the
# full suite; files outside source roots (docs, deploy, CI) are ignored.
SOURCE_ROOTS="$(
  {
    echo "src"
    if [[ "$HAVE_CONFIG" == true ]]; then
      printf '%s\n' "$SERVICE_TABLE" | awk -F'\t' 'NF {split($2, a, "/"); print a[1]}'
      while IFS= read -r sp; do
        [[ -n "$sp" ]] && echo "${sp%%/*}"
      done <<< "$SHARED_PATHS"
    fi
  } | sort -u
)"

path_in_list() {
  local file="$1" p
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    p="${p%/}"
    case "$file" in
      "$p"/*) return 0 ;;
    esac
  done <<< "$2"
  return 1
}

# --- Map files to services ---
SERVICES_HIT=""
DIRECT_TEST_DIRS=""
HAS_SOURCE_CHANGES=false

SERVICE_PATH_MAP="$(printf '%s\n' "$SERVICE_TABLE" | awk -F'\t' 'NF {print $2 "\t" $1}')"

while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  # Foundational/shared paths — run the full suite
  if [[ -n "$SHARED_PATHS" ]] && path_in_list "$file" "$SHARED_PATHS"; then
    exit 2
  fi

  # Direct test file change — resolve to its project dir
  case "$file" in
    src/tests/*/*)
      DIRECT_TEST_DIRS="${DIRECT_TEST_DIRS}src/tests/$(echo "$file" | cut -d/ -f3)"$'\n'
      HAS_SOURCE_CHANGES=true
      continue
      ;;
    tests/*/*)
      DIRECT_TEST_DIRS="${DIRECT_TEST_DIRS}tests/$(echo "$file" | cut -d/ -f2)"$'\n'
      HAS_SOURCE_CHANGES=true
      continue
      ;;
  esac

  # Service source paths
  MATCHED=false
  if [[ -n "$SERVICE_PATH_MAP" ]]; then
    while IFS=$'\t' read -r spath sname; do
      [[ -z "$spath" ]] && continue
      case "$file" in
        "${spath%/}"/*)
          SERVICES_HIT="${SERVICES_HIT}${sname}"$'\n'
          HAS_SOURCE_CHANGES=true
          MATCHED=true
          break
          ;;
      esac
    done <<< "$SERVICE_PATH_MAP"
  fi
  [[ "$MATCHED" == true ]] && continue

  # Unknown file under a source root — fallback to full suite
  if path_in_list "$file" "$SOURCE_ROOTS"; then
    exit 2
  fi

  # Non-source files (docs, deploy, CI, etc.) — ignored
done <<< "$CHANGED_FILES"

if [[ "$HAS_SOURCE_CHANGES" == false ]]; then
  # Only non-source files changed
  echo "NO_TESTS_AFFECTED"
  exit 0
fi

# Deduplicate services and collect test projects
RESULTS="$(
  {
    printf '%s' "$SERVICES_HIT" | sort -u | while IFS= read -r svc; do
      if [[ -n "$svc" ]]; then emit_tests_for_service "$svc"; fi
    done
    printf '%s' "$DIRECT_TEST_DIRS"
  } | sort -u | filter_existing
)"

if [[ -z "$RESULTS" ]]; then
  exit 2
fi

echo "$RESULTS"
exit 0
