#!/bin/bash
# ============================================================
# dev-bootstrap - main entry (concatenated with lib/*.sh by build.sh)
# ============================================================
# Usage:
#   ./install.sh                 # interactive numeric menu
#   ./install.sh 8,10,11         # install by numbers
#   ./install.sh python,rust     # install by names
#   ./install.sh all | list
#   curl -fsSL <url>/install.sh | bash -s -- 8,10
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"

# ---- entry points ----

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
Components (数字选项 / 名称):
   1  all           全部安装
   2  nvm, node     NVM + Node.js LTS
   3  java          OpenJDK 8 + 21（可切换）
   4  go            Go 最新稳定版
   5  maven         Maven
   6  gradle        Gradle
   7  docker        Docker Engine + Compose
   8  python, py    Python3 + pip + venv + uv
   9  rust          Rust (rustup + stable)
  10  tools, cli    build-essential/cmake/rg/fd/fzf/tmux/htop/jq/yq/httpie/neovim/sqlite3/zsh
  11  db, database  MySQL/PostgreSQL/Redis/SQLite 客户端
  12  php           PHP CLI + FPM + Composer
  13  mirror        仅配置国内镜像

用法:
  ./install.sh                 # 交互菜单（数字可多选，如 8,10,11）
  ./install.sh 8,10,11         # 按数字安装
  ./install.sh python,rust     # 按名称安装
  ./install.sh list            # 列出组件
  ./install.sh all             # 全量安装
  curl -fsSL <install.sh url> | bash -s -- 8,10
  wget -qO- <install.sh url> | bash
EOF
}

install_selected() {
  ensure_base
  IFS=',' read -ra items <<< "$1"
  for item in "${items[@]}"; do
    item="$(echo "$item" | xargs)"  # trim
    [ -z "$item" ] && continue
    case "$item" in
      1)            install_all; return ;;
      2|nvm|node)   install_nvm ;;
      3|java)       install_java ;;
      4|go)         install_go ;;
      5|maven)      install_maven ;;
      6|gradle)     install_gradle ;;
      7|docker)     install_docker ;;
      8|python|py)  install_python ;;
      9|rust)       install_rust ;;
      10|tools|cli) install_tools ;;
      11|db|database) install_db ;;
      12|php)       install_php ;;
      13|mirror)    config_mirrors ;;
      *)            warn "忽略未知组件: $item（运行 './install.sh list' 查看有效值）" ;;
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
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/scripts/switch-java.sh" ]; then
    echo "  Java switcher: $SCRIPT_DIR/scripts/switch-java.sh {8|21}"
  fi
  echo "  Run 'source ~/.bashrc' or restart your shell to apply PATH changes"
  echo -e "${GREEN}============================================${NC}"
}

# ---- interactive menu ----
menu() {
  echo ""
  echo -e "${CYAN}============================================${NC}"
  echo -e "${CYAN}  Dev Bootstrap - Environment Installer${NC}"
  echo -e "${CYAN}============================================${NC}"
  echo "   1) All"
  echo "   2) NVM + Node.js"
  echo "   3) Java (8 + 21)"
  echo "   4) Go"
  echo "   5) Maven"
  echo "   6) Gradle"
  echo "   7) Docker"
  echo "   8) Python (pip + uv)"
  echo "   9) Rust (rustup)"
  echo "  10) CLI & Build Toolchain"
  echo "  11) Database Clients"
  echo "  12) PHP + Composer"
  echo "  13) Mirrors only"
  echo "   0) Exit / q)"
  echo -e "${CYAN}============================================${NC}"

  local choice
  if ! read -rp "选择 [数字可多选，如 8,10,11；a=全部；q=退出]: " choice < /dev/tty 2>/dev/null; then
    err "当前没有可交互终端。请改用："
    echo "  ./install.sh 8,10,11"
    echo "  ./install.sh all"
    echo "  curl -fsSL <url> | bash -s -- 8,10"
    exit 1
  fi
  echo ""

  case "$choice" in
    0|q|Q) exit 0 ;;
    a|A|all) install_all; return ;;
  esac

  ensure_base
  IFS=', ' read -ra nums <<< "$choice"
  for n in "${nums[@]}"; do
    [ -z "$n" ] && continue
    case "$n" in
      1)  install_all; return ;;
      2)  install_nvm ;;
      3)  install_java ;;
      4)  install_go ;;
      5)  install_maven ;;
      6)  install_gradle ;;
      7)  install_docker ;;
      8)  install_python ;;
      9)  install_rust ;;
      10) install_tools ;;
      11) install_db ;;
      12) install_php ;;
      13) config_mirrors ;;
      *)  warn "忽略无效选项: $n" ;;
    esac
  done
  config_mirrors
  summary
}

# ---- argument parsing ----
if [ $# -ge 1 ]; then
  case "$1" in
    -h|--help|help) list_components ;;
    all)            install_all ;;
    list)           list_components ;;
    mirror)         config_mirrors ;;
    *)              install_selected "$1" ;;
  esac
else
  detect_os
  menu
fi
