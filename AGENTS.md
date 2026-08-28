# IPRC environment guide

Last verified: 2026-08-28.

Read this file before changing this account's shell, Conda, editor, or CLI setup. The account uses two login nodes with separate HOME/workspace filesystems and one shared NFS runtime.

## Hosts and storage

| Role | Hostname | OS | SSH name from the user's workstation |
|---|---|---|---|
| Legacy login node | `Login-Node2` | CentOS 7 | `iprc` |
| New login node | `RockyOS8-Login0` | Rocky Linux 8 | `r8iprc` |

- The two nodes have different physical `/home/S/wenzhiyang` and `/workspace/S/wenzhiyang`.
- `/nfs_global/S/wenzhiyang` is the same NFS directory on both nodes and is the source of truth for shared configuration and runtimes.
- Do not assume a file in HOME or workspace is visible from the other node.
- Secrets, history, caches, and machine state stay local: `.ssh`, `.gnupg`, `.bash_history`, `.cache`, `.local/state`, and `.vscode-server` must not be moved into the shared tree.

## Shared layout

```text
/nfs_global/S/wenzhiyang/
├── dotfiles/                         # Git worktree, branch iprc
├── runtime/
│   ├── common/
│   │   ├── bin/                      # starship, yazi, ya, zellij, nvim
│   │   ├── opt/nvim-v0.11.5-x86_64/
│   │   └── vim/                      # vim-plug and eight shared plugins
│   ├── platform/
│   │   ├── centos7-x86_64/bin/       # per-OS overrides when needed
│   │   └── rocky8-x86_64/bin/
│   └── conda-common/                 # shared Miniconda installation
└── migration-backups/20260828-1740/ # pre-migration manifests and shell backups
```

The shell PATH order is platform override, common runtime, then local user paths. Portable tools should be installed once in `runtime/common`. Only put a tool in a platform directory after proving the common binary is incompatible.

## Shell startup

- Each node has a small physical `~/.bashrc` copied from `dotfiles/shell/bashrc-loader`.
- The loader sources `/nfs_global/S/wenzhiyang/dotfiles/shell/bashrc`.
- Keeping the loader local gives a basic PATH and warning if NFS is unavailable.
- CentOS defines `rocky` as an alias for SSH to `RockyOS8-Login0`.
- `which conda` is intentionally handled by the shared Bash configuration so it prints the real executable instead of a function body.
- After changing shared shell configuration, test a fresh login shell on both nodes. An already-open shell may require `exec bash -l`.

## Conda

- Shared installation: `/nfs_global/S/wenzhiyang/runtime/conda-common`.
- Default environment: `test`.
- The interactive shell automatically activates `test`; set `IPRC_CONDA_AUTO_ACTIVATE=0` to disable that behavior temporarily.
- `~/anaconda3` is only a compatibility symlink to the shared Miniconda path. It is not the deleted legacy Anaconda installation.
- The old physical installations under each node's `/workspace/S/wenzhiyang/anaconda3` were removed after environment manifests were backed up.
- Conda 25.7.0 and the shared `test` environment were verified on glibc 2.17 and glibc 2.28. The environment includes Python 3.12.14, Git, and GitHub CLI.
- Conda appears as a Bash function after initialization; this is required for `conda activate`.
- Avoid running simultaneous package mutations against the same shared environment from both login nodes.

Useful checks:

```bash
which conda
conda --version
conda info --base
echo "$CONDA_PREFIX"
python --version
```

## Shared CLI and editor tools

The following commands are installed once in `runtime/common` and have compatibility symlinks under each node's `~/.local/bin`:

- Starship 1.25.1
- Yazi and `ya` 26.8.15
- Zellij 0.44.3
- Neovim 0.11.5, using the old-glibc-compatible build

Neovim uses one shared vim-plug installation and one shared plugin directory. The installed plugins are `auto-pairs`, `indentLine`, `nerdcommenter`, `nerdtree`, `tagbar`, `vim-airline`, `vim-airline-themes`, and `vim-illuminate`.

Configuration symlinks for Starship, Zellij, Yazi, Vim, and Neovim resolve into the shared dotfiles repository.

## Git branches and deployment

- `main` is the generic, user-local, no-sudo installer. It must not contain IPRC hostnames, usernames, NFS paths, Conda setup, or cluster-specific shell logic.
- `iprc` contains the IPRC/NFS deployment and is the branch checked out by `/nfs_global/S/wenzhiyang/dotfiles`.
- Do not switch the server worktree to `main`; that would remove the shared shell configuration.
- Keep all installation user-scoped. Never introduce `sudo`, `yum`, `dnf`, `apt`, or writes to `/usr`, `/opt`, or other system-managed paths.
- Preserve unrelated dirty changes and stage only files belonging to the requested task.

GitHub access from the login nodes may time out. The established deployment workflow is:

1. Edit and test the appropriate branch on the user's workstation.
2. Commit and push that branch to GitHub from the workstation.
3. Create a Git bundle locally and transfer it to the migration-backup directory.
4. Fetch and fast-forward the NFS worktree with the shared Conda Git executable.
5. Verify that the NFS worktree remains clean and tracks `origin/iprc`.

For release archives, download once on the workstation when server networking fails, verify the artifact, transfer it to NFS, and execute the same NFS copy from both nodes.

## Cluster cautions

- These are login nodes; do not run experiments or heavy compute workloads on them.
- Submit CentOS 7 jobs from the legacy login node and Rocky 8 jobs from the Rocky login node unless the cluster documentation explicitly says otherwise.
- The two systems share Slurm but not their software stacks.
- A `LC_ALL=C.UTF-8` warning can appear on CentOS because that locale is unavailable there. It is unrelated to Conda or the shared runtime.
- Before deleting or replacing anything, resolve symlinks and verify the exact physical filesystem. Identical-looking HOME/workspace paths refer to different storage on the two nodes.

## Minimal verification

Run this in a fresh login shell on both nodes after environment changes:

```bash
for cmd in conda python git gh starship yazi ya zellij nvim; do
  printf '%-10s %s\n' "$cmd" "$(command -v "$cmd")"
done
conda --version
yazi --version
ya --version
zellij --version
nvim --headless -c qall
git -C /nfs_global/S/wenzhiyang/dotfiles status --short --branch
```
