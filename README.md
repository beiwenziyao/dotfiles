# dotfiles

个人终端偏好库：zellij + nvim + yazi 三件套配置。安装过程只修改当前用户的 `$HOME`，不需要管理员权限，也不调用系统包管理器。

## 包含内容

| 目录 | 内容 | 链接位置 |
|---|---|---|
| `zellij/` | `config.kdl`（Alt+y 弹 yazi、Alt+hjkl 焦点移动、codex_neon 主题）+ `layouts/codex.kdl` | `~/.config/zellij/` |
| `nvim/` | `init.vim` + `vimrc`（vim-plug: NERDTree/Tagbar/airline 等） | `~/.config/nvim/`、`~/.vimrc` |
| `yazi/` | 最小配置（编辑打开走 nvim） | `~/.config/yazi/yazi.toml` |
| `starship.toml` | 彩色提示符（codex 配色分段显示 user/dir/git/env/time） | `~/.config/starship.toml` |
| `shell/` | IPRC 共享 Bash 配置、共享 Conda 初始化与本地入口模板 | 由 `~/.bashrc` 加载 |

## 一键安装

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles && ./install.sh
```

脚本会：
1. 安装 zellij（GitHub release 二进制到 `~/.local/bin`）
2. 安装 yazi（GitHub musl 静态版，老 glibc 系统也兼容）
3. 安装 starship，并让 `~/.bashrc` 加载仓库中的共享 shell 配置
4. 安装 neovim（程序目录放在 `~/.local/opt`，命令链接到 `~/.local/bin`；CentOS 7 等旧 glibc 系统使用已验证的 v0.11.5 兼容构建）
5. 安装 vim-plug
6. 将配置软链接到 `$HOME`（已有文件自动备份为 `.bak.*`）

脚本不会写入 `/usr`、`/opt` 等系统目录。需要系统预先提供 Bash、curl、tar、unzip 等基础工具；缺少这些工具时脚本会报错退出，而不会尝试修改系统环境。

## IPRC 双登录节点共享配置

CentOS 7 与 Rocky 8 共用以下 NFS 路径：

    /nfs_global/S/wenzhiyang/dotfiles
    /nfs_global/S/wenzhiyang/runtime/conda-common

两边的 `~/dotfiles` 与 `~/anaconda3` 分别链接到上述目录；每台节点保留一个很薄的本地 `~/.bashrc`，负责加载 `shell/bashrc`。默认进入交互式 Bash 后自动激活共享的 `test` 环境。临时禁用自动激活可在启动 shell 前设置 `IPRC_CONDA_AUTO_ACTIVATE=0`。

`.ssh`、`.gnupg`、`.bash_history`、`.cache`、`.local/state` 和 `.vscode-server` 等凭据或机器状态仍留在各自的 HOME，不放到共享目录。

国内网络拉不到 GitHub 时：

```bash
GITHUB_MIRROR=https://mirror.ghproxy.com/ ./install.sh
```

只同步配置、不安装程序：

```bash
./install.sh --link-only
```

安装完成后首次启动 nvim，执行 `:PlugInstall` 安装插件。

## 使用备忘

- `zj` 进入 zellij（如需要，在 bashrc 加 `alias zj='zellij'`）
- zellij 中 `Alt+y` 弹出 yazi 文件管理器，`Alt+hjkl` 移动焦点，`Ctrl+g` 锁定
- zellij 滚动缓冲区编辑器为 nvim（`scrollback_editor "nvim"`）
