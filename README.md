# GitLab Group Puller

A single-command utility to **clone and/or update all repositories** from a GitLab group, preserving the subgroup folder structure.

- **New** repos are `git cloned`.
- **Existing** repos are `git pull --ff-only`.
- **Archived** repos are skipped.

Before any Git operation a **preview log** is generated so you can review exactly what will happen.

## Usage

#### 1) Authenticate `glab` (only once)

```bash
glab auth login
```

#### 2) Pull a group

```bash
./pull_projects.sh <gitlab_group> [/path/to/destination]
```

| Argument | Required | Default |
|---|---|---|
| `gitlab_group` | yes | — |
| `/path/to/destination` | no | current directory (`$PWD`) |

**Example:**

```bash
./pull_projects.sh pece_lab_workspace ~/Projects
```

The script will:

1. Fetch the full repository list from the GitLab API.
2. Write a timestamped preview log (`pull_projects-<group>-<timestamp>.log`) showing every repo's destination and whether it will be cloned or pulled.
3. Display a summary and ask for confirmation before proceeding.

### Destination path (subgroups preserved)

The script **drops the top-level namespace component**, so `group/subgroup/repo` is saved as `<dest>/subgroup/repo` (not `<dest>/group/subgroup/repo`).

The local folder path is derived from `name_with_namespace`. This means:

- Casing is preserved (uppercase/lowercase remains as-is)
- Dashes/underscores are preserved
- Spaces are replaced with underscores

## Requirements

- [`glab`](https://gitlab.com/gitlab-org/cli) (GitLab CLI)
- `jq`
- `git`

#### Install examples

On macOS (Homebrew):

```bash
brew install git glab jq
```

With conda/mamba:

```bash
mamba install -c conda-forge git glab jq
```

Then authenticate in glab:

```bash
glab auth login
```

If you opt to use SSH as the default git protocol, here is how to set it up:

### Setup GitLab protocol: SSH

#### 1) Generate an SSH key dedicated for GitLab

```bash
ssh-keygen -t ed25519 -C "your.email@example.com" -f ~/.ssh/gitlab
```

This creates:

- Private key: `~/.ssh/gitlab`
- Public key:  `~/.ssh/gitlab.pub`

#### 2) Add your public key to GitLab

Copy the public key: `cat ~/.ssh/gitlab.pub`

Then in GitLab go to:

- **User Settings → SSH Keys → Add new key**
- Paste the key and save.

#### 3) Configure SSH to use your key

Add this to `~/.ssh/config`:

```
Host gitlab.com
  HostName gitlab.com
  User git
  IdentityFile ~/.ssh/gitlab
  IdentitiesOnly yes
  AddKeysToAgent yes
```

#### 4) Test SSH authentication

```bash
ssh -T git@gitlab.com
```

You should see a `Welcome to GitLab,` message indicating authentication succeeded.

## Shared HPC environments

On a shared HPC where multiple users commit and pull into the same destination folder, git may throw an error:

```
fatal: unsafe repository ('/path/to/destination/repo' is owned by someone else)
```

To fix this, mark the entire destination tree as safe in your git config:

```bash
git config --global --add safe.directory /path/to/destination/*
```

> **Note:** The wildcard (`/*`) syntax requires **git ≥ 2.46.0**.

On older versions of git you have two alternatives:

1. **Trust all directories globally** (less secure):

   ```bash
   git config --global --add safe.directory "*"
   ```

2. **Register each repository individually:**

   ```bash
   find /path/to/destination -type d -name .git -print0 \
     | xargs -0 -I{} git config --global --add safe.directory "$(dirname "{}")"
   ```

It is also useful to tell git to ignore file permission (mode) changes, which are common on shared filesystems:

```bash
git config --global core.fileMode false
```