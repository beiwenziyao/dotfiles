#!/usr/bin/env bash
# dotfiles 一键安装脚本
# 在当前用户目录安装 zellij / nvim / yazi / starship 并链接配置到 $HOME
# 用法: ./install.sh [--link-only]
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LINK_ONLY=0
case "${1:-}" in
  --link-only) LINK_ONLY=1 ;;
esac

say()  { printf '\033[1;32m[+] %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }

# ---------------------------------------------------------------------------
# 下载: 国内镜像优先, 逐个尝试, 直连 GitHub 兜底 (自动"测速择优")
# 可用镜像: ghfast.top, gh-proxy.com; 自定义前缀用环境变量 GITHUB_MIRROR=
# ---------------------------------------------------------------------------
MIRRORS=(
  "https://ghfast.top/https://github.com/"
  "https://gh-proxy.com/https://github.com/"
)
RAW_MIRRORS=(
  "https://ghfast.top/https://raw.githubusercontent.com/"
  "https://gh-proxy.com/https://raw.githubusercontent.com/"
)
if [ -n "${GITHUB_MIRROR:-}" ]; then
  MIRRORS=("$GITHUB_MIRROR" "${MIRRORS[@]}")
  RAW_MIRRORS=("${GITHUB_MIRROR}https://raw.githubusercontent.com/" "${RAW_MIRRORS[@]}")
fi

# github_fetch <仓库路径> <输出文件>   例: github_fetch "zellij-org/zellij/releases/download/v0.44.3/zellij-x86_64-unknown-linux-musl.tar.gz" /tmp/z
github_fetch() {
  local path="$1" out="$2" base
  for base in "${MIRRORS[@]}" "https://github.com/"; do
    if curl -fsSL --retry 2 --retry-all-errors --connect-timeout 8 --max-time 240 -o "$out" "${base}${path}" 2>/dev/null; then
      [ -s "$out" ] && { say "  源: ${base}" ; return 0; }
    fi
  done
  warn "所有镜像及直连均失败"
  return 1
}

# raw_fetch <raw路径> <输出文件>   例: raw_fetch "junegunn/vim-plug/master/plug.vim" /tmp/plug.vim
raw_fetch() {
  local path="$1" out="$2" base
  for base in "${RAW_MIRRORS[@]}" "https://raw.githubusercontent.com/"; do
    if curl -fsSL --retry 2 --retry-all-errors --connect-timeout 8 --max-time 120 -o "$out" "${base}${path}" 2>/dev/null; then
      [ -s "$out" ] && { say "  源: ${base}"; return 0; }
    fi
  done
  warn "所有镜像及直连均失败"
  return 1
}

# github_version <repo> <默认版本>
github_version() {
  local ver
  ver="$(curl -fsS --connect-timeout 8 --max-time 20 "https://api.github.com/repos/$1/releases/latest" 2>/dev/null | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)"
  [ -n "$ver" ] || ver="$2"
  printf '%s' "$ver"
}

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)
    RUST_ARCH="x86_64"
    NVIM_ARCH="x86_64"
    ;;
  aarch64|arm64)
    RUST_ARCH="aarch64"
    NVIM_ARCH="arm64"
    ;;
  *)
    RUST_ARCH="$ARCH"
    NVIM_ARCH=""
    ;;
esac

install_zellij() {
  if [ -x "$HOME/.local/bin/zellij" ]; then say "zellij 已存在: $("$HOME/.local/bin/zellij" --version)"; return; fi
  say "安装 zellij..."
  local ver tmp tarball
  ver="$(github_version zellij-org/zellij v0.44.3)"
  tmp="$(mktemp -d)"
  tarball="$tmp/zellij.tar.gz"
  github_fetch "zellij-org/zellij/releases/download/${ver}/zellij-${RUST_ARCH}-unknown-linux-musl.tar.gz" "$tarball"
  tar xzf "$tarball" -C "$tmp"
  install -m 755 "$tmp/zellij" "$HOME/.local/bin/zellij"
  rm -rf "$tmp"
  say "zellij ${ver} 已装到 ~/.local/bin"
}

install_yazi() {
  if [ -x "$HOME/.local/bin/yazi" ]; then say "yazi 已存在: $("$HOME/.local/bin/yazi" --version)"; return; fi
  command -v yazi >/dev/null 2>&1 && { say "yazi 已在 PATH: $(yazi --version)"; return; }

  say "安装 yazi: 优先 GitHub release, 失败时使用 cargo(yazi-build)..."
  local ver tmp zip
  ver="$(github_version sxyazi/yazi v26.8.15)"
  tmp="$(mktemp -d)"
  zip="$tmp/yazi.zip"
  if github_fetch "sxyazi/yazi/releases/download/${ver}/yazi-${RUST_ARCH}-unknown-linux-musl.zip" "$zip"; then
    unzip -q -o "$zip" -d "$tmp"
    install -m 755 "$tmp/yazi-${RUST_ARCH}-unknown-linux-musl/yazi" "$HOME/.local/bin/yazi"
    rm -rf "$tmp"
    say "yazi ${ver} 已装到 ~/.local/bin"
    return
  fi
  rm -rf "$tmp"

  CARGO_REGISTRIES_CRATES_IO_INDEX="sparse+https://rsproxy.cn/index/" \
    cargo install --locked yazi-build
  ~/.cargo/bin/yazi-build install
}

install_starship() {
  if [ -x "$HOME/.local/bin/starship" ]; then say "starship 已存在: $("$HOME/.local/bin/starship" --version)"; return; fi
  say "安装 starship..."
  local ver tmp tarball
  ver="$(github_version starship/starship v1.25.1)"
  tmp="$(mktemp -d)"
  tarball="$tmp/starship.tar.gz"
  github_fetch "starship/starship/releases/download/${ver}/starship-${RUST_ARCH}-unknown-linux-musl.tar.gz" "$tarball"
  tar xzf "$tarball" -C "$tmp"
  install -m 755 "$tmp/starship" "$HOME/.local/bin/starship"
  rm -rf "$tmp"
  say "starship ${ver} 已装到 ~/.local/bin"
}

install_nvim() {
  if [ -x "$HOME/.local/bin/nvim" ]; then say "nvim 已存在: $("$HOME/.local/bin/nvim" --version | head -1)"; return; fi
  command -v nvim >/dev/null 2>&1 && { say "nvim 已存在: $(nvim --version | head -1)"; return; }
  [ -n "$NVIM_ARCH" ] || { warn "暂不支持为 $ARCH 自动安装 Neovim"; return 1; }

  local repo="neovim/neovim" glibc_version="" glibc_major="" glibc_minor=""
  local ver tmp tarball extracted install_dir actual_ver
  if command -v getconf >/dev/null 2>&1; then
    glibc_version="$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}')"
    IFS=. read -r glibc_major glibc_minor _ <<< "$glibc_version"
    if [[ "$glibc_major" =~ ^[0-9]+$ && "$glibc_minor" =~ ^[0-9]+$ ]] &&
       (( glibc_major < 2 || (glibc_major == 2 && glibc_minor < 28) )); then
      repo="neovim/neovim-releases"
      say "检测到 glibc ${glibc_version}，使用 Neovim v0.11.5 旧 glibc 兼容构建"
    fi
  fi

  say "安装 neovim 到 ~/.local/opt..."
  if [ "$repo" = "neovim/neovim-releases" ]; then
    # 兼容构建仓库的最新标签偶尔会包含开发版；固定到已验证的稳定版本。
    ver="${NVIM_VERSION:-v0.11.5}"
  else
    ver="${NVIM_VERSION:-$(github_version "$repo" v0.12.5)}"
  fi
  tmp="$(mktemp -d)"
  tarball="$tmp/nvim.tar.gz"
  github_fetch "$repo/releases/download/${ver}/nvim-linux-${NVIM_ARCH}.tar.gz" "$tarball"
  tar xzf "$tarball" -C "$tmp"
  extracted="$tmp/nvim-linux-${NVIM_ARCH}"
  [ -x "$extracted/bin/nvim" ] || { warn "Neovim 压缩包内容不完整"; return 1; }
  actual_ver="$("$extracted/bin/nvim" --version | awk 'NR == 1 { print $2 }')"
  if [ "$actual_ver" != "$ver" ]; then
    warn "Neovim 版本校验失败: 期望 $ver，实际 $actual_ver"
    rm -rf "$tmp"
    return 1
  fi

  install_dir="$HOME/.local/opt/nvim-${ver}-${NVIM_ARCH}"
  mkdir -p "$HOME/.local/opt"
  if [ -e "$install_dir" ]; then
    [ -x "$install_dir/bin/nvim" ] || { warn "安装目录已存在但不完整: $install_dir"; return 1; }
  else
    mv "$extracted" "$install_dir"
  fi
  ln -sfn "$install_dir/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$tmp"
  say "neovim ${actual_ver} 已装到 $install_dir"
}

install_vim_plug() {
  if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    say "安装 vim-plug..."
    mkdir -p "$HOME/.vim/autoload"
    if raw_fetch "junegunn/vim-plug/master/plug.vim" "$HOME/.vim/autoload/plug.vim"; then
      say "vim-plug 已安装"
    else
      warn "vim-plug 下载失败(网络), 继续执行; 稍后可: curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://ghfast.top/https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    fi
  fi
  say "运行 :PlugInstall 安装 vim 插件 (进入 nvim 后执行 PlugInstall)"
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
  export PATH="$HOME/.local/bin:$PATH"   # 让本会话及后续重跑都能识别已装二进制
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
