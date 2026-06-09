#!/bin/bash
# ============================================================
# dev-bootstrap - Go module
# ============================================================
# Env: GO_VERSION (e.g. 1.24.0 or "latest"), GOPROXY

GO_VERSION="${GO_VERSION:-latest}"
GOPROXY="${GOPROXY:-https://goproxy.cn,direct}"

install_go() {
  section "Go"

  # fetch latest version if requested
  if [ "$GO_VERSION" = "latest" ]; then
    GO_VERSION=$(curl -sL "https://go.dev/dl/?mode=json" 2>/dev/null | \
      python3 -c "import sys,json; print(json.load(sys.stdin)[0]['version'][2:])" 2>/dev/null || echo "1.24.0")
  fi
  info "Go version: ${GO_VERSION}"

  run_sudo apt purge -y golang-go 2>/dev/null || true

  # download (prefer USTC mirror)
  DL_URL="https://mirrors.ustc.edu.cn/golang/go${GO_VERSION}.linux-amd64.tar.gz"
  FALLBACK_URL="https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"

  info "Downloading Go ${GO_VERSION}..."
  curl -sL "$DL_URL" -o /tmp/go.tar.gz 2>/dev/null || \
    curl -sL "$FALLBACK_URL" -o /tmp/go.tar.gz

  run_sudo rm -rf /usr/local/go
  run_sudo tar -C /usr/local -xzf /tmp/go.tar.gz
  rm -f /tmp/go.tar.gz

  # PATH
  grep -q "/usr/local/go/bin" "$HOME/.bashrc" 2>/dev/null || \
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$HOME/.bashrc"

  # GOPROXY
  grep -q "GOPROXY" "$HOME/.bashrc" 2>/dev/null && \
    sed -i "s|^export GOPROXY=.*|export GOPROXY=${GOPROXY}|" "$HOME/.bashrc" || \
    echo "export GOPROXY=${GOPROXY}" >> "$HOME/.bashrc"

  export PATH=$PATH:/usr/local/go/bin
  export GOPROXY=${GOPROXY}

  done_section "Go"
  echo "  $(go version 2>/dev/null || echo 'N/A')"
  echo "  GOPROXY: ${GOPROXY}"
}
