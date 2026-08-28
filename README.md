# dotfiles

个人终端偏好库：zellij + nvim + yazi 三件套配置。所有程序、插件和配置都安装在当前用户目录，不需要管理员权限，也不调用系统包管理器。

## 包含内容

| 目录 | 内容 | 链接位置 |
|---|---|---|
| `zellij/` | `config.kdl`（Alt+y 弹 yazi、Alt+hjkl 焦点移动、codex_neon 主题）+ `layouts/codex.kdl` | `~/.config/zellij/` |
| `nvim/` | `init.vim` + `vimrc`（vim-plug: NERDTree/Tagbar/airline 等） | `~/.config/nvim/`、`~/.vimrc` |
| `yazi/` | 最小配置（编辑打开走 nvim） | `~/.config/yazi/yazi.toml` |
| `starship.toml` | 彩色提示符（codex 配色分段显示 user/dir/git/env/time） | `~/.config/starship.toml` |

## 一键安装

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles && ./install.sh
```

脚本会：
1. 安装 zellij（GitHub release 的 musl 构建）
2. 安装 yazi 和配套的 `ya`（GitHub musl 构建）
3. 安装 starship，并向 `~/.bashrc` 添加用户级 PATH、提示符初始化和 `zj` 别名
4. 安装 neovim（CentOS 7 等旧 glibc 系统使用已验证的 v0.11.5 兼容构建）
5. 安装 vim-plug；插件默认放在 `~/.local/vim/plugged`
6. 将配置软链接到 `$HOME`（已有文件自动备份为 `.bak.*`）

脚本不会写入 `/usr`、`/opt` 等系统目录。需要系统预先提供 Bash、curl、tar、unzip 等基础工具；缺少这些工具时脚本会报错退出，而不会尝试修改系统环境。

默认运行目录为 `~/.local`。如需安装到其他用户可写目录，可在执行时指定：

```bash
DOTFILES_RUNTIME_ROOT=/path/to/runtime ./install.sh
```

该变量也会用于确定 Vim/Neovim 插件目录。自定义路径需要在后续 shell 中继续导出 `DOTFILES_RUNTIME_ROOT`。

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
