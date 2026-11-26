#!/bin/bash
# ============================================================
# dev-bootstrap - CLI & build toolchain module
# ============================================================

install_tools() {
  section "CLI & Build Toolchain"

  apt_update
  run_sudo apt install -y \
    build-essential cmake pkg-config autoconf automake libtool bison re2c \
    ripgrep fd-find fzf tmux htop tree ncdu jq yq httpie neovim sqlite3 zsh 2>&1 | tail -1

  # Ubuntu 的 fd 命令名是 fdfind，补一个 fd 软链
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    run_sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
  fi

  done_section "CLI & Build Toolchain"
  echo "  gcc:   $(gcc --version 2>/dev/null | head -1 || echo 'N/A')"
  echo "  cmake: $(cmake --version 2>/dev/null | head -1 || echo 'N/A')"
  echo "  rg:    $(rg --version 2>/dev/null | head -1 || echo 'N/A')"
  echo "  jq:    $(jq --version 2>/dev/null || echo 'N/A')"
  echo "  nvim:  $(nvim --version 2>/dev/null | head -1 || echo 'N/A')"
}
