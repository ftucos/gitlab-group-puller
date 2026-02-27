#!/usr/bin/env bash
set -ue -o pipefail

# ── Usage ────────────────────────────────────────────────────────
# ./pull_projects.sh <gitlab_group> [/path/to/destination]
#
# Fetches all (non-archived) repositories from a GitLab group,
# generates a preview log, asks for confirmation, then clones
# or pulls each repo preserving the subgroup folder structure.
# ─────────────────────────────────────────────────────────────────

# ── Arguments ────────────────────────────────────────────────────
GROUP="${1:-}"
if [[ -z "$GROUP" ]]; then
  echo "Usage: $0 <gitlab_group> [/path/to/destination]" >&2
  exit 1
fi

CLONE_ROOT="${2:-$PWD}"
CLONE_ROOT="$(cd "$CLONE_ROOT" && pwd -P)"

# ── Terminal styling ─────────────────────────────────────────────
line='------------------------------------------------------------'
bold=$(tput bold 2>/dev/null || true); reset=$(tput sgr0 2>/dev/null || true)
cyan=$(tput setaf 6 2>/dev/null || true); yellow=$(tput setaf 3 2>/dev/null || true)
green=$(tput setaf 2 2>/dev/null || true); red=$(tput setaf 1 2>/dev/null || true)

# ── Fetch repository list from GitLab ────────────────────────────
printf '\n%sFetching repository list for group %s%s%s …\n' \
  "$cyan" "$bold" "$GROUP" "$reset"

REPO_LIST=$(
  glab repo list -g "$GROUP" \
    --include-subgroups \
    --archived=false \
    --per-page 10000 \
    --output json \
  | jq -r --arg group "$GROUP" '
    .[]
    | (.name_with_namespace                # subgroup/repo name
        | split("/")
        | .[1:]                            # trim off the top-level group name
        | map(gsub("^\\s+|\\s+$"; ""))     # trim whitespace
        | join("/")
        | gsub(" *- *"; "-")               # normalize " - " into "-"
        | gsub("[ \t\n]"; "_")             # replace remaining whitespace, tabs and newline with underscores for a safe folder name
      ) as $dest
    | (.ssh_url_to_repo) + "\t" + $dest
  '
)

if [[ -z "$REPO_LIST" ]]; then
  printf '%s%sNo repositories found in group "%s".%s\n' "$red" "$bold" "$GROUP" "$reset"
  exit 1
fi

REPO_COUNT=$(echo "$REPO_LIST" | wc -l | tr -d ' ')

# ── Generate preview log ────────────────────────────────────────
TIMESTAMP=$(date +%Y_%m_%d-%Hh%Mm%Ss)
LOG_FILE="pull_projects-${GROUP}-${TIMESTAMP}.log"

{
  printf '=%.0s' {1..60}; printf '\n'
  printf 'GitLab Group Puller — Preview Log\n'
  printf '=%.0s' {1..60}; printf '\n'
  printf 'Group:        %s\n' "$GROUP"
  printf 'Destination:  %s\n' "$CLONE_ROOT"
  printf 'Timestamp:    %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
  printf 'Repositories: %s\n' "$REPO_COUNT"
  printf '=%.0s' {1..60}; printf '\n\n'

  while IFS=$'\t' read -r url dest; do
    full_path="${CLONE_ROOT}/${dest}"
	# if the folder exists, label it as [PULL], otherwise [CLONE]
    if [ -d "${full_path}/.git" ]; then
      action="PULL"
    else
      action="CLONE"
    fi
    printf '[%s]  %s\n' "$action" "$full_path"
    printf '        ← %s\n\n' "$url"
  done <<< "$REPO_LIST"
} > "$LOG_FILE"

# ── Display summary & ask for confirmation ───────────────────────
printf '\n%s\n' "$line"
printf '%s%sGitLab Group Puller%s\n' "$cyan" "$bold" "$reset"
printf '%s\n' "$line"
printf '%sGroup:%s        %s\n' "$bold" "$reset" "$GROUP"
printf '%sDestination:%s  %s\n' "$bold" "$reset" "$CLONE_ROOT"
printf '%sRepositories:%s %s\n' "$bold" "$reset" "$REPO_COUNT"
printf '%sPreview log:%s  %s\n' "$bold" "$reset" "$LOG_FILE"
printf '%s\n\n' "$line"
printf '%s%sProceed?%s Type %syes%s to continue: ' "$yellow" "$bold" "$reset" "$bold" "$reset"

read -r reply
if [[ "$reply" != "yes" ]]; then
  printf '\n%sAborted.%s\n' "$yellow" "$reset"
  exit 0
fi
printf '\n'

# ── Clone or update each repository ─────────────────────────────
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

cd "$CLONE_ROOT"

while IFS=$'\t' read -r url dest; do
  printf '%s→ %s%s\n' "$bold" "$dest" "$reset"
  update_repo "$url" "$dest"
  printf '\n'
done <<< "$REPO_LIST"

printf '%s%sDone.%s All %s repositories processed.\n\n' "$green" "$bold" "$reset" "$REPO_COUNT"
