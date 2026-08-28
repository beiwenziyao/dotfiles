#!/usr/bin/env bash
# dotfiles 一键安装脚本
# 在共享 NFS runtime 安装 zellij / nvim / yazi / starship 并链接配置到 $HOME
# 用法: ./install.sh [--link-only]
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -n "${DOTFILES_RUNTIME_ROOT:-}" ]; then
  RUNTIME_ROOT="$DOTFILES_RUNTIME_ROOT"
elif [ -d /nfs_global/S/wenzhiyang ] && [ -w /nfs_global/S/wenzhiyang ]; then
  RUNTIME_ROOT=/nfs_global/S/wenzhiyang/runtime/common
else
  RUNTIME_ROOT="$HOME/.local"
fi
BIN_DIR="$RUNTIME_ROOT/bin"
OPT_DIR="$RUNTIME_ROOT/opt"
VIM_RUNTIME="$RUNTIME_ROOT/vim"

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
  if [ -x "$BIN_DIR/zellij" ]; then say "zellij 已存在: $("$BIN_DIR/zellij" --version)"; return; fi
  say "安装 zellij..."
  local ver tmp tarball
  ver="$(github_version zellij-org/zellij v0.44.3)"
  tmp="$(mktemp -d)"
  tarball="$tmp/zellij.tar.gz"
  github_fetch "zellij-org/zellij/releases/download/${ver}/zellij-${RUST_ARCH}-unknown-linux-musl.tar.gz" "$tarball"
  tar xzf "$tarball" -C "$tmp"
  install -m 755 "$tmp/zellij" "$BIN_DIR/zellij"
  rm -rf "$tmp"
  say "zellij ${ver} 已装到 $BIN_DIR"
}

install_yazi() {
  if [ -x "$BIN_DIR/yazi" ] && [ -x "$BIN_DIR/ya" ]; then
    say "yazi/ya 已存在: $("$BIN_DIR/yazi" --version | head -1)"
    return
  fi

  say "安装 yazi/ya..."
  local ver tmp zip
  ver="$(github_version sxyazi/yazi v26.8.15)"
  tmp="$(mktemp -d)"
  zip="$tmp/yazi.zip"
  if github_fetch "sxyazi/yazi/releases/download/${ver}/yazi-${RUST_ARCH}-unknown-linux-musl.zip" "$zip"; then
    unzip -q -o "$zip" -d "$tmp"
    install -m 755 "$tmp/yazi-${RUST_ARCH}-unknown-linux-musl/yazi" "$BIN_DIR/yazi"
    install -m 755 "$tmp/yazi-${RUST_ARCH}-unknown-linux-musl/ya" "$BIN_DIR/ya"
    rm -rf "$tmp"
    say "yazi/ya ${ver} 已装到 $BIN_DIR"
    return
  fi
  rm -rf "$tmp"
  warn "yazi/ya 下载失败"
  return 1
}

install_starship() {
  if [ -x "$BIN_DIR/starship" ]; then say "starship 已存在: $("$BIN_DIR/starship" --version)"; return; fi
  say "安装 starship..."
  local ver tmp tarball
  ver="$(github_version starship/starship v1.25.1)"
  tmp="$(mktemp -d)"
  tarball="$tmp/starship.tar.gz"
  github_fetch "starship/starship/releases/download/${ver}/starship-${RUST_ARCH}-unknown-linux-musl.tar.gz" "$tarball"
  tar xzf "$tarball" -C "$tmp"
  install -m 755 "$tmp/starship" "$BIN_DIR/starship"
  rm -rf "$tmp"
  say "starship ${ver} 已装到 $BIN_DIR"
}

install_nvim() {
  if [ -x "$BIN_DIR/nvim" ]; then say "nvim 已存在: $("$BIN_DIR/nvim" --version | head -1)"; return; fi
  [ -n "$NVIM_ARCH" ] || { warn "暂不支持为 $ARCH 自动安装 Neovim"; return 1; }

  local repo="neovim/neovim" glibc_version="" glibc_major="" glibc_minor=""
  local ver tmp tarball extracted install_dir actual_ver
  if [ "$RUNTIME_ROOT" = /nfs_global/S/wenzhiyang/runtime/common ]; then
    repo="neovim/neovim-releases"
    say "共享 runtime 使用 Neovim v0.11.5 旧 glibc 兼容构建"
  elif command -v getconf >/dev/null 2>&1; then
    glibc_version="$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}')"
    IFS=. read -r glibc_major glibc_minor _ <<< "$glibc_version"
    if [[ "$glibc_major" =~ ^[0-9]+$ && "$glibc_minor" =~ ^[0-9]+$ ]] &&
       (( glibc_major < 2 || (glibc_major == 2 && glibc_minor < 28) )); then
      repo="neovim/neovim-releases"
      say "检测到 glibc ${glibc_version}，使用 Neovim v0.11.5 旧 glibc 兼容构建"
    fi
  fi

  say "安装 neovim 到 $OPT_DIR..."
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

  install_dir="$OPT_DIR/nvim-${ver}-${NVIM_ARCH}"
  mkdir -p "$OPT_DIR"
  if [ -e "$install_dir" ]; then
    [ -x "$install_dir/bin/nvim" ] || { warn "安装目录已存在但不完整: $install_dir"; return 1; }
  else
    mv "$extracted" "$install_dir"
  fi
  ln -sfn "../opt/nvim-${ver}-${NVIM_ARCH}/bin/nvim" "$BIN_DIR/nvim"
  rm -rf "$tmp"
  say "neovim ${actual_ver} 已装到 $install_dir"
}

install_vim_plug() {
  if [ ! -f "$VIM_RUNTIME/autoload/plug.vim" ]; then
    say "安装 vim-plug..."
    mkdir -p "$VIM_RUNTIME/autoload"
    if raw_fetch "junegunn/vim-plug/master/plug.vim" "$VIM_RUNTIME/autoload/plug.vim"; then
      say "vim-plug 已安装"
    else
      warn "vim-plug 下载失败(网络), 继续执行"
    fi
  fi
  if [ -f "$VIM_RUNTIME/autoload/plug.vim" ]; then
    link "$VIM_RUNTIME/autoload/plug.vim" "$HOME/.vim/autoload/plug.vim"
  fi
  say "运行 :PlugInstall 安装 vim 插件 (进入 nvim 后执行 PlugInstall)"
}

setup_bashrc() {
  local begin="# >>> dotfiles: shared shell >>>"
  if ! grep -Fq "$begin" "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<'EOF'

# >>> dotfiles: shared shell >>>
if [ -r "$HOME/dotfiles/shell/bashrc" ]; then
  . "$HOME/dotfiles/shell/bashrc"
fi
# <<< dotfiles: shared shell <<<
EOF
    say "已向 ~/.bashrc 追加共享 shell 配置入口"
  else
    say "~/.bashrc 已有 dotfiles 配置，跳过"
  fi
}

link() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
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
  mkdir -p "$BIN_DIR" "$OPT_DIR" "$VIM_RUNTIME"
  export PATH="$BIN_DIR:$PATH"
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

  local cmd
  for cmd in starship yazi ya zellij nvim; do
    [ -x "$BIN_DIR/$cmd" ] && link "$BIN_DIR/$cmd" "$HOME/.local/bin/$cmd"
  done

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
