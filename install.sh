#!/bin/bash
#
# dev-bootstrap - One-click dev environment setup
# ============================================================
# Components:
#   node/nvm, java, go, python, rust, maven, gradle,
#   tools (CLI + 编译工具链), db (数据库客户端), php, docker, mirror
# Mirrors pre-configured for China (Tsinghua / Aliyun / USTC / Huawei / rsproxy)
#
# Usage:
#   ./install.sh                  # interactive menu
#   ./install.sh all              # install everything
#   ./install.sh nvm,java,go      # install selected components
#   ./install.sh list             # list components
#   ./install.sh mirror           # config mirrors only
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# source all modules
for f in "$LIB_DIR"/*.sh; do
  [ -f "$f" ] && source "$f"
done

# ---- main entry points ----

install_all() {
  ensure_base
  install_nvm
  install_java
  install_go
  install_python
  install_rust
  install_maven
  install_gradle
  install_tools
  install_db
  install_docker
  config_mirrors
  summary
}

list_components() {
  cat <<'EOF'
Components:
  nvm, node      NVM + Node.js LTS (npmmirror)
  java           OpenJDK 8 + 21，可用 scripts/switch-java.sh 切换
  go             Go 最新稳定版 (USTC 下载 + goproxy.cn)
  python         Python 3 + pip + venv + uv (清华 PyPI)
  rust           rustup + stable 工具链 (rsproxy 镜像)
  maven          Maven (Aliyun 仓库)
  gradle         Gradle (Huawei 下载 + Aliyun 仓库)
  tools          build-essential / cmake / ripgrep / fd / fzf / tmux /
                 htop / jq / yq / httpie / neovim / sqlite3 / zsh
  db             MySQL / PostgreSQL / Redis / SQLite 客户端
  php            PHP CLI + FPM + Composer (Aliyun 镜像)
  docker         Docker Engine + Compose
  mirror         仅配置国内镜像

Examples:
  ./install.sh all
  ./install.sh python,rust,tools
  ./install.sh db
EOF
}

install_selected() {
  ensure_base
  IFS=',' read -ra items <<< "$1"
  for item in "${items[@]}"; do
    item="$(echo "$item" | xargs)"  # trim
    case "$item" in
      nvm|node)     install_nvm ;;
      java)         install_java ;;
      go)           install_go ;;
      python|py)    install_python ;;
      rust)         install_rust ;;
      maven)        install_maven ;;
      gradle)       install_gradle ;;
      tools|cli)    install_tools ;;
      db|database)  install_db ;;
      php)          install_php ;;
      docker)       install_docker ;;
      mirror)       config_mirrors ;;
      *)            warn "Unknown component: $item (run './install.sh list' to see valid names)" ;;
    esac
  done
  summary
}

summary() {
  echo ""
  echo -e "${GREEN}============================================${NC}"
  echo -e "${GREEN}  Installation Summary${NC}"
  echo -e "${GREEN}============================================${NC}"
  echo "  Node:   $(node -v 2>/dev/null || echo 'not installed')"
  echo "  NPM:    $(npm -v 2>/dev/null || echo 'not installed')"
  echo "  Java:   $(java -version 2>&1 | head -1 || echo 'not installed')"
  echo "  Go:     $(go version 2>/dev/null || echo 'not installed')"
  echo "  Python: $(python3 --version 2>/dev/null || echo 'not installed')"
  echo "  uv:     $(uv --version 2>/dev/null || echo 'not installed')"
  echo "  Rust:   $(rustc --version 2>/dev/null || echo 'not installed')"
  echo "  PHP:    $(php -v 2>/dev/null | head -1 || echo 'not installed')"
  echo "  Maven:  $(mvn --version 2>&1 | head -1 || echo 'not installed')"
  echo "  Gradle: $(gradle --version 2>&1 | head -1 || echo 'not installed')"
  echo "  Docker: $(docker --version 2>/dev/null || echo 'not installed')"
  echo "  DB cli: $(mysql --version 2>/dev/null | head -1 || echo 'not installed')"
  echo ""
  echo "  Java switcher: $SCRIPT_DIR/scripts/switch-java.sh {8|21}"
  echo "  Run 'source ~/.bashrc' or restart your shell to apply PATH changes"
  echo -e "${GREEN}============================================${NC}"
}

# ---- interactive menu ----
menu() {
  echo ""
  echo -e "${CYAN}============================================${NC}"
  echo -e "${CYAN}  Dev Bootstrap - Environment Installer${NC}"
  echo -e "${CYAN}============================================${NC}"
  echo "  1) All"
  echo "  2) NVM + Node.js"
  echo "  3) Java (8 + 21)"
  echo "  4) Go"
  echo "  5) Maven"
  echo "  6) Gradle"
  echo "  7) Docker"
  echo "  8) Python (pip + uv)"
  echo "  9) Rust (rustup)"
  echo " 10) CLI & Build Toolchain"
  echo " 11) Database Clients"
  echo " 12) PHP + Composer"
  echo " 13) Mirrors only"
  echo "  0) Exit"
  echo -e "${CYAN}============================================${NC}"
  read -rp "Select [0-13]: " choice
  echo ""
  case $choice in
    1) install_all ;;
    2) ensure_base; install_nvm; config_mirrors; summary ;;
    3) ensure_base; install_java; config_mirrors; summary ;;
    4) ensure_base; install_go; config_mirrors; summary ;;
    5) ensure_base; install_maven; config_mirrors; summary ;;
    6) ensure_base; install_gradle; config_mirrors; summary ;;
    7) ensure_base; install_docker; summary ;;
    8) ensure_base; install_python; config_mirrors; summary ;;
    9) ensure_base; install_rust; summary ;;
    10) ensure_base; install_tools; summary ;;
    11) ensure_base; install_db; summary ;;
    12) ensure_base; install_php; summary ;;
    13) config_mirrors; summary ;;
    0) exit 0 ;;
    *) warn "Invalid choice" && menu ;;
  esac
}

# ---- argument parsing ----
if [ $# -ge 1 ]; then
  case "$1" in
    all)    install_all ;;
    list)   list_components ;;
    mirror) config_mirrors ;;
    *)      install_selected "$1" ;;
  esac
else
  detect_os
  menu
fi
