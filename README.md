# GitLab Group Puller 

This is a small utility to **generate a bash script** that clones all repositories from a GitLab group, preserving the subgroup folder structure.  

When re-run, it will `git pull --ff-only` for repos that already exist locally, otherwise it will `git clone`.

It will skip repositories marked as `deletion_scheduled`.

## Usage

#### 1) Authenticate `glab` (only once)

```
glab auth login
```

#### 2) Generate a pull script for a group

```
./generate-pull-script.sh group_name
```

This produces: `pull_projects-group_name.sh`

#### 3) Run the generated pull script

Specify a destination root directory (if no arguments is passed it defaults to `$PWD`):

```
./pull_projects-pece_collab.sh ~/Projects
```

The script will **warn you once** where it’s going to dump everything and ask for a single confirmation before proceeding.

### What it does

For each repo in your GitLab group:

- If `<dest>/.git` exists → `git -C <dest> pull --ff-only`
- Else → `git clone <ssh_url> <dest>`

### Destination path (subgroups preserved)

The generated script **drops the top-level namespace component**, so `group/subgroup/repo` is saved as `<dest>/subgroup/repo` (not `<dest>/group/subgroup/repo`)

The script uses GitLab’s `path_with_namespace` to determine the local folder path. This means:

- Casing is preserved (uppercase/lowercase remains as-is)
- Dashes/underscores are preserved
- Spaces are replaced with underscores

## Requirements

- `envsubst` (from `gettext`)
- [`glab`](https://gitlab.com/gitlab-org/cli) (GitLab CLI)
- `jq`
- `git`

#### Install examples

On macOS (Homebrew):
```bash
brew install gettext git glab jq 
```

With conda/mamba:

```bash
mamba install -c conda-forge gettext git glab jq
```

Than authenticate in glab

```bash
glab auth login
```

If you opt to use SSH as the default git protocol, here is how to set it up:

### Setup GitLab protocol: SSH

#### 1) Generate an SSH key dedicated for GitLab

```
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

#### 3) Configure SSH to use your key (your approach)

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

```
ssh -T git@gitlab.com
```

You should see a `Welcome to GitLab,` message indicating authentication succeeded.