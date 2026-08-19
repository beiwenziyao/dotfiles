# dotfiles

个人终端偏好库：zellij + nvim + yazi 三件套配置。

## 包含内容

| 目录 | 内容 | 链接位置 |
|---|---|---|
| `zellij/` | `config.kdl`（Alt+y 弹 yazi、Alt+hjkl 焦点移动、codex_neon 主题）+ `layouts/codex.kdl` | `~/.config/zellij/` |
| `nvim/` | `init.vim` + `vimrc`（vim-plug: NERDTree/Tagbar/airline 等） | `~/.config/nvim/`、`~/.vimrc` |
| `yazi/` | 最小配置（编辑打开走 nvim） | `~/.config/yazi/yazi.toml` |

## 一键安装

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles && ./install.sh
```

脚本会：
1. 安装 zellij（GitHub release 二进制到 `~/.local/bin`）
2. 安装 yazi（cargo + rsproxy.cn 国内镜像）
3. 安装 neovim（apt）
4. 安装 vim-plug
5. 将配置软链接到 `$HOME`（已有文件自动备份为 `.bak.*`）

国内网络拉不到 GitHub 时：

```bash
GITHUB_MIRROR=https://mirror.ghproxy.com/ ./install.sh
```

## 手动安装依赖

```bash
# zellij (官方 release)
curl -sL https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz | tar xz
sudo install zellij /usr/local/bin

# yazi (cargo, 国内镜像)
CARGO_REGISTRIES_CRATES_IO_INDEX="sparse+https://rsproxy.cn/index/" cargo install --locked yazi-fm yazi-cli

# 首次启动后
nvim +PlugInstall   # 安装 vim 插件
```

## 使用备忘

- `zj` 进入 zellij（如需要，在 bashrc 加 `alias zj='zellij'`）
- zellij 中 `Alt+y` 弹出 yazi 文件管理器，`Alt+hjkl` 移动焦点，`Ctrl+g` 锁定
- zellij 滚动缓冲区编辑器为 nvim（`scrollback_editor "nvim"`）
