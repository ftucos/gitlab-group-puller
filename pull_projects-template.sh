#!/usr/bin/env sh
set -euo pipefail

GROUP="$GROUP"

# Usage: ./pull_projects-$GROUP.sh [/path/to/dump]

# use the first argument if provided, otherwise use the current working directory.
# Where to dump everything (optional arg). Defaults to current directory.
CLONE_ROOT="${1:-$PWD}"
CLONE_ROOT="$(cd "$CLONE_ROOT" && pwd -P)"

# Ask confirmation about output directory (prettier terminal output)
line='------------------------------------------------------------'
bold=$(tput bold 2>/dev/null || true); reset=$(tput sgr0 2>/dev/null || true)
cyan=$(tput setaf 6 2>/dev/null || true); yellow=$(tput setaf 3 2>/dev/null || true)

printf '\n%s\n' "$line"
printf '%s%sGitLab Group Puller%s\n' "$cyan" "$bold" "$reset"
printf '%s\n' "$line"
printf '%sGroup:%s        %s\n' "$bold" "$reset" "$GROUP"
printf '%sDestination:%s  %s\n' "$bold" "$reset" "$CLONE_ROOT"
printf '%sOutput tree:%s  %s/%s\n' "$bold" "$reset" "$CLONE_ROOT" "$GROUP"
printf '%s\n\n' "$line"
printf '%s%sProceed?%s Type %syes%s to continue: ' "$yellow" "$bold" "$reset" "$bold" "$reset"

read -r reply
if [[ "$reply" != "yes" ]]; then
  printf '\n%sAborted.%s\n' "$yellow" "$reset"
  exit 0
fi
printf '\n'

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

