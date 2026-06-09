#!/bin/bash
# ============================================================
# dev-bootstrap - NVM + Node.js module
# ============================================================
# Env: NVM_NODEJS_ORG_MIRROR, NPM_REGISTRY

NVM_VERSION="0.40.2"
NVM_NODEJS_ORG_MIRROR="${NVM_NODEJS_ORG_MIRROR:-https://mirrors.ustc.edu.cn/node}"
NPM_REGISTRY="${NPM_REGISTRY:-https://registry.npmmirror.com}"

install_nvm() {
  section "NVM + Node.js"

  # remove apt-installed nodejs if any
  run_sudo apt purge -y nodejs npm 2>/dev/null || true

  export NVM_DIR="$HOME/.nvm"

  if [ -d "$NVM_DIR/.git" ]; then
    info "NVM already exists, updating..."
    (cd "$NVM_DIR" && git pull --ff-only 2>/dev/null) || true
  else
    info "Installing NVM v${NVM_VERSION}..."
    curl -sL "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" -o /tmp/nvm-install.sh
    [ -f /tmp/nvm-install.sh ] && bash /tmp/nvm-install.sh 2>/dev/null
  fi

  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

  export NVM_NODEJS_ORG_MIRROR="$NVM_NODEJS_ORG_MIRROR"

  info "Installing Node.js LTS..."
  nvm install --lts 2>/dev/null || nvm install 22 2>/dev/null || true
  nvm alias default lts/* 2>/dev/null || true

  npm config set registry "$NPM_REGISTRY" 2>/dev/null

  done_section "NVM + Node.js"
  echo "  Node: $(node -v 2>/dev/null || echo 'N/A')"
  echo "  NPM:  $(npm -v 2>/dev/null || echo 'N/A')"
}
