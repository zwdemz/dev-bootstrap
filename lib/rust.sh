#!/bin/bash
# ============================================================
# dev-bootstrap - Rust module (rustup + rsproxy mirror)
# ============================================================
# Env: RUSTUP_DIST_SERVER / RUSTUP_UPDATE_ROOT

RUSTUP_DIST_SERVER="${RUSTUP_DIST_SERVER:-https://rsproxy.cn}"
RUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-https://rsproxy.cn/rustup}"

install_rust() {
  section "Rust"

  export RUSTUP_DIST_SERVER RUSTUP_UPDATE_ROOT

  if command -v rustup >/dev/null 2>&1; then
    info "rustup already installed, updating toolchain..."
    rustup update stable 2>/dev/null || true
  else
    info "Installing rustup + stable toolchain (rsproxy)..."
    curl -sSf https://rsproxy.cn/rustup-init.sh -o /tmp/rustup-init.sh
    sh /tmp/rustup-init.sh -y --default-toolchain stable --profile default 2>&1 | tail -2
    rm -f /tmp/rustup-init.sh
  fi

  # shell 环境
  if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"
  fi
  grep -q 'cargo/env' "$HOME/.bashrc" 2>/dev/null || \
    echo '. "$HOME/.cargo/env"' >> "$HOME/.bashrc"
  export PATH="$HOME/.cargo/bin:$PATH"

  # crates.io 镜像（sparse 协议，速度快）
  mkdir -p "$HOME/.cargo"
  cat > "$HOME/.cargo/config.toml" <<'EOF'
[source.crates-io]
replace-with = 'rsproxy-sparse'

[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"

[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"

[net]
git-fetch-with-cli = true
EOF

  done_section "Rust"
  echo "  Rust:  $(rustc --version 2>/dev/null || echo 'N/A')"
  echo "  Cargo: $(cargo --version 2>/dev/null || echo 'N/A')"
}
