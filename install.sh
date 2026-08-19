#!/usr/bin/env bash
# dotfiles 一键安装脚本
# 安装 zellij / nvim / yazi 并链接配置到 $HOME
# 用法: ./install.sh [--dry-run]
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="${1:-}"

LINK_ONLY=0
case "${1:-}" in
  --link-only) LINK_ONLY=1 ;;
esac

say()  { printf '\033[1;32m[+] %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }

# 国内网络可用 GitHub 镜像前缀, 如: GITHUB_MIRROR=https://mirror.ghproxy.com/
GITHUB_MIRROR="${GITHUB_MIRROR:-}"

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  RUST_ARCH="x86_64" ;;
  aarch64) RUST_ARCH="aarch64" ;;
  *)       RUST_ARCH="$ARCH" ;;
esac

install_zellij() {
  command -v zellij >/dev/null 2>&1 && { say "zellij 已存在: $(zellij --version)"; return; }
  say "安装 zellij..."
  local ver
  ver="$(curl -s https://api.github.com/repos/zellij-org/zellij/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)"
  [ -n "$ver" ] || ver="v0.44.3"
  local url="${GITHUB_MIRROR}https://github.com/zellij-org/zellij/releases/download/${ver}/zellij-${RUST_ARCH}-unknown-linux-musl.tar.gz"
  local tmp
  tmp="$(mktemp -d)"
  curl -sL "$url" | tar xz -C "$tmp"
  install -m 755 "$tmp/zellij" "$HOME/.local/bin/zellij"
  rm -rf "$tmp"
  say "zellij ${ver} 已装到 ~/.local/bin"
}

install_yazi() {
  command -v yazi >/dev/null 2>&1 && { say "yazi 已存在: $(yazi --version)"; return; }

  say "安装 yazi: 优先 snap, 其次 GitHub release, 最后 cargo(yazi-build)..."
  if command -v snap >/dev/null 2>&1 && [ -n "${WSL_DISTRO_NAME:-}" ]; then
    warn "WSL 下 snap 版 yazi 需 XDG_RUNTIME_DIR 可写 (bashrc 已处理)"
    sudo snap install yazi --classic && return
  fi

  local ver url tmp
  ver="$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)"
  if [ -n "$ver" ]; then
    url="${GITHUB_MIRROR}https://github.com/sxyazi/yazi/releases/download/${ver}/yazi-${RUST_ARCH}-unknown-linux-musl.zip"
    tmp="$(mktemp -d)"
    if curl -sL "$url" -o "$tmp/yazi.zip"; then
      unzip -q -o "$tmp/yazi.zip" -d "$tmp"
      install -m 755 "$tmp/yazi-${RUST_ARCH}-unknown-linux-musl/yazi" "$HOME/.local/bin/yazi"
      rm -rf "$tmp"
      say "yazi 已装到 ~/.local/bin"
      return
    fi
    rm -rf "$tmp"
  fi

  CARGO_REGISTRIES_CRATES_IO_INDEX="sparse+https://rsproxy.cn/index/" \
    cargo install --locked yazi-build
  ~/.cargo/bin/yazi-build install
}

install_starship() {
  command -v starship >/dev/null 2>&1 && { say "starship 已存在: $(starship --version)"; return; }
  say "安装 starship..."
  local ver url tmp
  ver="$(curl -s https://api.github.com/repos/starship/starship/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)"
  [ -n "$ver" ] || ver="v1.25.1"
  url="${GITHUB_MIRROR}https://github.com/starship/starship/releases/download/${ver}/starship-${RUST_ARCH}-unknown-linux-musl.tar.gz"
  tmp="$(mktemp -d)"
  curl -sL "$url" | tar xz -C "$tmp"
  install -m 755 "$tmp/starship" "$HOME/.local/bin/starship"
  rm -rf "$tmp"
  say "starship ${ver} 已装到 ~/.local/bin"
}

setup_bashrc() {
  if ! grep -q "starship init" "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<'EOF'

# >>> dotfiles: PATH + starship >>>
export PATH="$HOME/.local/bin:$PATH"
eval "$(starship init bash)"
alias zj='zellij'
# <<< dotfiles <<<
EOF
    say "已向 ~/.bashrc 追加 PATH + starship + zj 别名"
  else
    say "~/.bashrc 已有 dotfiles 配置，跳过"
  fi
}

install_nvim() {
  command -v nvim >/dev/null 2>&1 && { say "nvim 已存在: $(nvim --version | head -1)"; return; }
  say "安装 neovim (apt)..."
  sudo apt-get update
  sudo apt-get install -y neovim
}

install_vim_plug() {
  if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    say "安装 vim-plug..."
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
      "${GITHUB_MIRROR}https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  fi
  say "运行 :PlugInstall 安装 vim 插件 (进入 nvim 后执行 PlugInstall)"
}

link() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$(readlink -f "$dst")" = "$src" ]; then
      say "已链接: $dst"
      return
    fi
    mv "$dst" "${dst}.bak.$(date +%Y%m%d%H%M%S)"
    warn "原文件已备份: ${dst}.bak.*"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  say "链接: $dst -> $src"
}

main() {
  mkdir -p "$HOME/.local/bin"
  if [ "$LINK_ONLY" -ne 1 ]; then
    install_zellij
    install_yazi
    install_starship
    install_nvim
    install_vim_plug
    setup_bashrc
  else
    say "--link-only: 跳过安装, 仅同步配置"
  fi

  link "$DOTFILES/starship.toml"            "$HOME/.config/starship.toml"
  link "$DOTFILES/zellij/config.kdl"        "$HOME/.config/zellij/config.kdl"
  link "$DOTFILES/zellij/layouts/codex.kdl" "$HOME/.config/zellij/layouts/codex.kdl"
  link "$DOTFILES/nvim/init.vim"            "$HOME/.config/nvim/init.vim"
  link "$DOTFILES/nvim/vimrc"               "$HOME/.vimrc"
  link "$DOTFILES/yazi/yazi.toml"           "$HOME/.config/yazi/yazi.toml"

  say "完成! 首次启动 nvim 后执行 :PlugInstall 安装插件"
  say "在 zellij 里按 Alt+y 即可弹出 yazi"
}

main
