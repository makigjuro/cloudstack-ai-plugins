#!/usr/bin/env bash
# new-project.sh — Create a new project from the cloud-app-blueprint reference starter (examples/dotnet-react-azure).
#
# Copies the starter, renames every "Starter"/"starter" identifier (solution, namespaces,
# projects, files, images, Azure resource prefix, compose project, npm package), rewrites
# the few lines that only make sense inside the plugins repo, and initializes git.
#
# Usage: new-project.sh <Name> [--short <id>] [--dir <path>] [--from <starter-dir>] [--ref <git-ref>] [--no-git]
#
#   <Name>    Project name: PascalCase or kebab-case (AcmeShop, acme-shop). Becomes the .NET
#             namespace prefix (AcmeShop.Orders.Host) after converting to PascalCase.
#   --short   Lowercase resource prefix for Azure names, images and compose: 2-7 chars,
#             [a-z][a-z0-9]*. Defaults to the name lowercased with separators removed when that
#             fits; 7 is the limit because the state storage account
#             (<short>tfstatestagingweu) must be at most 24 chars.
#   --dir     Target directory (default: ./<kebab-name>). Must not exist or be empty.
#   --from    Local starter directory to copy instead of downloading (e.g. a clone's examples/dotnet-react-azure).
#   --ref     Git ref to download (default: tag v<plugin version> if it exists, else main).
#   --no-git  Skip git init and the initial commit.
#
# Exit codes:
#   0 — project created (summary on stdout)
#   1 — error (download, copy, or leftover "starter" references after renaming)
#   2 — invalid name or short name; the message says what to pass
#   3 — target directory exists and is not empty

set -euo pipefail

REPO_URL="https://github.com/makigjuro/cloud-app-blueprint"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NAME=""
SHORT=""
DIR=""
FROM=""
REF=""
GIT=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --short)  SHORT="$2"; shift 2 ;;
    --dir)    DIR="$2"; shift 2 ;;
    --from)   FROM="$2"; shift 2 ;;
    --ref)    REF="$2"; shift 2 ;;
    --no-git) GIT=false; shift ;;
    -*)       echo "Unknown arg: $1" >&2; exit 1 ;;
    *)
      if [[ -n "$NAME" ]]; then echo "Unexpected arg: $1" >&2; exit 1; fi
      NAME="$1"; shift ;;
  esac
done

if [[ -z "$NAME" ]]; then
  echo "usage: $0 <Name> [--short <id>] [--dir <path>] [--from <starter-dir>] [--ref <git-ref>] [--no-git]" >&2
  exit 2
fi

# --- Names -------------------------------------------------------------------

# PascalCase: split on - _ space, capitalize each part, keep the rest as typed (AcmeShop stays AcmeShop).
PASCAL="$(printf '%s' "$NAME" | perl -pe 's/(?:^|[-_ ]+)([a-zA-Z0-9])/\U$1/g')"
# kebab-case: AcmeShop -> acme-shop, acme_shop -> acme-shop.
KEBAB="$(printf '%s' "$NAME" | perl -pe 's/([a-z0-9])([A-Z])/$1-$2/g; s/[_ ]+/-/g; $_ = lc')"

if [[ ! "$PASCAL" =~ ^[A-Z][A-Za-z0-9]*$ ]]; then
  echo "Invalid name '$NAME': use letters and digits, starting with a letter (e.g. AcmeShop or acme-shop)." >&2
  exit 2
fi
if [[ "$PASCAL" == "Starter" ]]; then
  echo "Invalid name '$NAME': pick a name other than Starter." >&2
  exit 2
fi

if [[ -z "$SHORT" ]]; then
  SHORT="$(printf '%s' "$KEBAB" | tr -d '-')"
fi
if [[ ! "$SHORT" =~ ^[a-z][a-z0-9]{1,6}$ ]]; then
  echo "Short name '$SHORT' does not fit Azure naming: pass --short with 2-7 lowercase letters/digits, starting with a letter (e.g. --short acme)." >&2
  exit 2
fi

DIR="${DIR:-./$KEBAB}"
if [[ -e "$DIR" ]] && [[ -n "$(ls -A "$DIR" 2>/dev/null)" ]]; then
  echo "Target '$DIR' exists and is not empty." >&2
  exit 3
fi

# --- Source ------------------------------------------------------------------

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [[ -n "$FROM" ]]; then
  if [[ ! -f "$FROM/blueprint.json" || ! -d "$FROM/src" ]]; then
    echo "'$FROM' does not look like the starter (no blueprint.json or src/)." >&2
    exit 1
  fi
  SOURCE="$FROM"
  ORIGIN="local copy at $FROM"
else
  if [[ -z "$REF" ]]; then
    VERSION="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$SCRIPT_DIR/../.claude-plugin/plugin.json" | head -1)"
    if [[ -n "$VERSION" ]] && git ls-remote --exit-code --tags "$REPO_URL" "refs/tags/v$VERSION" >/dev/null 2>&1; then
      REF="v$VERSION"
    else
      REF="main"
    fi
  fi
  echo "Downloading the starter ($REF) from $REPO_URL ..." >&2
  git clone --quiet --depth 1 --filter=blob:none --sparse --branch "$REF" "$REPO_URL" "$WORK/repo" >&2
  git -C "$WORK/repo" sparse-checkout set examples/dotnet-react-azure >&2
  SOURCE="$WORK/repo/examples/dotnet-react-azure"
  ORIGIN="$REPO_URL ($REF, $(git -C "$WORK/repo" rev-parse --short HEAD))"
fi

# --- Copy --------------------------------------------------------------------

mkdir -p "$DIR"
DIR="$(cd "$DIR" && pwd)"

# Build output, dependencies, caches and local secrets never travel with the template.
rsync -a \
  --exclude '.git' --exclude 'bin/' --exclude 'obj/' --exclude 'node_modules/' --exclude 'dist/' \
  --exclude 'coverage/' --exclude 'TestResults/' --exclude '.terraform/' --exclude '.terragrunt-cache/' \
  --exclude '*.tfstate' --exclude '*.tfstate.*' --exclude '.env' --exclude '.env.local' \
  "$SOURCE/" "$DIR/"

# --- Rename paths (deepest first, so parents are renamed after their children) -

find "$DIR" -depth -name '*Starter*' | while IFS= read -r path; do
  base="$(basename "$path")"
  mv "$path" "$(dirname "$path")/${base//Starter/$PASCAL}"
done

# --- Rewrite contents --------------------------------------------------------

DOCS_URL="$REPO_URL/blob/main/docs/"
export PASCAL SHORT DOCS_URL

# README: drop the lines that describe the starter as a template.
if [[ -f "$DIR/README.md" ]]; then
  perl -0pi -e '
    s/^# \.NET \+ React \+ Azure starter\n/# $ENV{PASCAL}\n/m;
    s/^A small, complete app built on the /Built on the /m;
    s/ It.s what the plugins scaffold into, and it shows the shape of a real project:/ It starts with:/;
    s/^Start a new project from it with .*\n\n//m;
    s/^The workflows are written as if `examples\/dotnet-react-azure` were the repo root.*\n\n//m;
    s/^From this directory, with the plugins installed:/With the plugins installed:/m;
  ' "$DIR/README.md"
fi

# Every text file: plugins-repo notes and links first, then the generic rename.
find "$DIR" -type f -not -path '*/.git/*' -print0 | xargs -0 grep -Il --null '' 2>/dev/null | xargs -0 perl -0pi -e '
  s/^# NOTE: this starter lives in examples\/dotnet-react-azure.*?copy the starter out to use them as-is\.\n//msg;
  s{\]\((?:\.\./)+docs/}{]($ENV{DOCS_URL}}g;
  s{Build context: examples/dotnet-react-azure}{Build context: repository root}g;
  s{from `examples/dotnet-react-azure`}{from the repository root}g;
  s{app_location: examples/dotnet-react-azure/web}{app_location: web}g;
  s/Reference starter for the cloud-app-blueprint architecture/Built on the cloud-app-blueprint reference architecture/g;
  s/\bThis starter\b/This app/g;
  s/\bthe starter\b/the app/g;
  s/Starter/$ENV{PASCAL}/g;
  s/starter/$ENV{SHORT}/g;
'

# --- Check -------------------------------------------------------------------

LEFTOVERS="$(grep -rIni 'starter\|examples/' "$DIR" --exclude-dir=.git || true)"
if [[ -n "$LEFTOVERS" ]]; then
  echo "Renaming left references to the starter:" >&2
  echo "$LEFTOVERS" >&2
  exit 1
fi

# --- Git ---------------------------------------------------------------------

GIT_STATUS="skipped (--no-git)"
if $GIT && git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
  GIT_STATUS="skipped: $DIR is inside an existing git repository"
elif $GIT; then
  git -C "$DIR" init --quiet --initial-branch=main
  git -C "$DIR" add -A
  git -C "$DIR" commit --quiet -m "create $KEBAB from the cloud-app-blueprint starter" -m "Source: $ORIGIN"
  GIT_STATUS="initialized on main with one commit"
fi

cat <<EOF
Created $PASCAL in $DIR
  namespace prefix : $PASCAL (src/$PASCAL.sln)
  resource prefix  : $SHORT (images $SHORT-orders, $SHORT-gateway; Azure names $SHORT-<type>-<env>-weu)
  source           : $ORIGIN
  git              : $GIT_STATUS
EOF
