#!/usr/bin/env bash
set -euo pipefail

GROUP="$GROUP"

# Usage: ./pull_projects-$GROUP.sh [/path/to/dump]

# use the first argument if provided, otherwise use the current working directory.
# Where to dump everything (optional arg). Defaults to current directory.
CLONE_ROOT="${1:-$PWD}"
CLONE_ROOT="$(cd "$CLONE_ROOT" && pwd -P)"

# Ask confirmation about output directory
echo "About to clone/pull GitLab group: $GROUP"
echo "Destination root:"
echo "  $CLONE_ROOT"
echo "Everything will be placed under:"
echo "  $CLONE_ROOT/$GROUP"
echo
read -r -p "Proceed? Type 'yes' to continue: " reply
if [[ "$reply" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi
echo

# Function to clone or update a repository
update_repo() {
  local url="$1"
  local dest="$2"

  if [ -d "$dest/.git" ]; then
    git -C "$dest" pull --ff-only
  else
    mkdir -p "$(dirname "$dest")"
    git clone "$url" "$dest"
  fi
}

