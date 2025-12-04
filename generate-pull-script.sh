#!/usr/bin/env bash

set -ue -o pipefail

# Usage: ./generate-pull-script.sh <gitlab_group>
export GROUP="${1:-}"
if [[ -z "$GROUP" ]]; then
  echo "Usage: $0 <gitlab_group>" >&2
  exit 1
fi

# Output path for the generated bash script (note: "~" won’t expand inside quotes)
OUT_FILE="pull_projects-${GROUP}.sh"

# Write the script header passing the group name
envsubst '$GROUP' < pull_projects-template.sh > "$OUT_FILE"

# List all repos in the group (including subgroups) as JSON, then transform JSON into bash script lines
glab repo list -g "$GROUP" --include-subgroups --per-page 1000 --output json \
| jq -r --arg group "$GROUP" '
  # mark as `keep` only repost not scheduled for deletion
  def keep: (.ssh_url_to_repo | contains("deletion_scheduled") | not);

  (
    .[] | select(keep)
    | (.name_with_namespace                 # subgroup/repo name
         | split("/")
         | .[1:]                            # trim off the top-level group name
         | map(gsub("^\\s+|\\s+$"; ""))     # trim whitespace
         | join("/")   
         | gsub(" *- *"; "-")               # normalize " - " into "-"
         | gsub("[ \t\n]"; "_")             # replace remaining whitespace, tabs and newline with underscores for a safe folder name
      ) as $dest
    | "update_repo " + (.ssh_url_to_repo | @sh) + " " + ($dest | @sh) # shell-escape/quote the path and folder name
  )
' >> "$OUT_FILE"

# Make the generated script executable
chmod +x "$OUT_FILE"