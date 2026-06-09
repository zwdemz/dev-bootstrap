#!/bin/bash
#
# dev-bootstrap - One-click dev environment setup
# ============================================================
# Supports: nvm/node, java, go, maven, gradle, docker
# Mirrors pre-configured for China (Tsinghua / Aliyun / USTC / Huawei)
#
# Usage:
#   ./install.sh                  # interactive menu
#   ./install.sh all              # install everything
#   ./install.sh nvm,java,go      # install selected components
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
  install_maven
  install_gradle
  install_docker
  config_mirrors
  summary
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
      maven)        install_maven ;;
      gradle)       install_gradle ;;
      docker)       install_docker ;;
      mirror)       config_mirrors ;;
      *)            warn "Unknown component: $item (valid: nvm, java, go, maven, gradle, docker, mirror)" ;;
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
  echo "  Maven:  $(mvn --version 2>&1 | head -1 || echo 'not installed')"
  echo "  Gradle: $(gradle --version 2>&1 | head -1 || echo 'not installed')"
  echo "  Docker: $(docker --version 2>/dev/null || echo 'not installed')"
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
  echo "  8) Mirrors only"
  echo "  0) Exit"
  echo -e "${CYAN}============================================${NC}"
  read -rp "Select [0-8]: " choice
  echo ""
  case $choice in
    1) install_all ;;
    2) ensure_base; install_nvm; config_mirrors; summary ;;
    3) ensure_base; install_java; config_mirrors; summary ;;
    4) ensure_base; install_go; config_mirrors; summary ;;
    5) ensure_base; install_maven; config_mirrors; summary ;;
    6) ensure_base; install_gradle; config_mirrors; summary ;;
    7) ensure_base; install_docker; summary ;;
    8) config_mirrors; summary ;;
    0) exit 0 ;;
    *) warn "Invalid choice" && menu ;;
  esac
}

# ---- argument parsing ----
if [ $# -ge 1 ]; then
  case "$1" in
    all)    install_all ;;
    mirror) config_mirrors ;;
    *)      install_selected "$1" ;;
  esac
else
  detect_os
  menu
fi
