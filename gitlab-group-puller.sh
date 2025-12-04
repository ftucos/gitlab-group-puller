#!/usr/bin/env bash

set -ue -o pipefail

# GitLab group to list repositories from
GROUP="breast_cancer_CDK12"

# Output path for the generated bash script (note: "~" won’t expand inside quotes)
OUT_FILE="pull_projects-${GROUP}.sh"

# List all repos in the group (including subgroups) as JSON, then transform JSON -> bash script lines
glab repo list -g "$GROUP" --include-subgroups --per-page 1000 --output json \
| jq -r '
  # mark as `keep` only repost not scheduled for deletion
  def keep: (.ssh_url_to_repo | contains("deletion_scheduled") | not);

  # Add bash shebang as first line
  "#!/usr/bin/env bash",

  # For each repository object in the JSON array, emit one "git clone <ssh_url> <folder>" line
  (.[] | select(keep) | [				 # filter out repos scheduled for deletion
      "git clone",
      (.ssh_url_to_repo | @sh),          # repo SSH URL, shell-escaped/quoted for safety
      (.name_with_namespace              # subgroup/repo name
        | gsub(" *- *"; "-")             # normalize " - " into "-"
		| gsub(" */ *"; "/")             # normalize " / " into "/"
        | gsub("[ \t\n]"; "_")           # replace whitespace, tabs and newline with underscores for a safe folder name
        | @sh                            # shell-escape/quote the folder name
      )
    ] | join(" "))                       # join the pieces with spaces
' > "$OUT_FILE"

# Make the generated script executable
chmod +x "$OUT_FILE"