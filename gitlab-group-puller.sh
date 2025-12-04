#!/usr/bin/env bash

set -ue -o pipefail

# GitLab group to list repositories from
GROUP="breast_cancer_CDK12"

# Output path for the generated bash script (note: "~" won’t expand inside quotes)
OUT_FILE="pull_projects-${GROUP}.sh"

# Write the script header
cat > "$OUT_FILE" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

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

EOF

# List all repos in the group (including subgroups) as JSON, then transform JSON into bash script lines
glab repo list -g "$GROUP" --include-subgroups --per-page 1000 --output json \
| jq -r --arg group "$GROUP" '
  # mark as `keep` only repost not scheduled for deletion
  def keep: (.ssh_url_to_repo | contains("deletion_scheduled") | not);

  (
    .[] | select(keep)
    | (.name_with_namespace               # subgroup/repo name
         | gsub(" *- *"; "-")             # normalize " - " into "-"
         | gsub(" */ *"; "/")             # normalize " / " into "/"
         | gsub("[ \t\n]"; "_")           # replace whitespace, tabs and newline with underscores for a safe folder name
      ) as $dest
    | "update_repo " + (.ssh_url_to_repo | @sh) + " " + ($dest | @sh) # shell-escape/quote the path and folder name
  )
' >> "$OUT_FILE"

# Make the generated script executable
chmod +x "$OUT_FILE"