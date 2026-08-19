# dotfiles

个人终端偏好库：zellij + nvim + yazi 三件套配置。

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
1. 安装 zellij（GitHub release 二进制到 `~/.local/bin`）
2. 安装 yazi（GitHub musl 静态版，老 glibc 系统也兼容）
3. 安装 starship 并写入 `~/.bashrc`（PATH + `eval "$(starship init bash)"` + `zj` 别名）
4. 安装 neovim（apt）
5. 安装 vim-plug
6. 将配置软链接到 `$HOME`（已有文件自动备份为 `.bak.*`）

国内网络拉不到 GitHub 时：

```bash
GITHUB_MIRROR=https://mirror.ghproxy.com/ ./install.sh
```

## 手动安装依赖

```bash
# zellij (官方 release)
curl -sL https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz | tar xz
sudo install zellij /usr/local/bin

# yazi (推荐 snap, 或官方 release, 或 cargo)
sudo snap install yazi --classic
# 或:
curl -sL https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip -o yazi.zip && unzip yazi.zip
# cargo 安装需先装 yazi-build: cargo install --locked yazi-build && yazi-build install

# 首次启动后
nvim +PlugInstall   # 安装 vim 插件
```

> WSL 下 snap 版 yazi 依赖 `XDG_RUNTIME_DIR` 可写目录，否则报
> `cannot create XDG_RUNTIME_DIR folder "/run/user/<uid>/": permission denied`。
> 在 `.bashrc` 里设置即可（本仓库配套的 bashrc 片段写法）：
> ```bash
> export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/run/user/$(id -u)}"
> mkdir -p "$XDG_RUNTIME_DIR"
> ```

## 使用备忘

- `zj` 进入 zellij（如需要，在 bashrc 加 `alias zj='zellij'`）
- zellij 中 `Alt+y` 弹出 yazi 文件管理器，`Alt+hjkl` 移动焦点，`Ctrl+g` 锁定
- zellij 滚动缓冲区编辑器为 nvim（`scrollback_editor "nvim"`）
