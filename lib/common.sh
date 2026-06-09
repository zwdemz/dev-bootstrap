#!/bin/bash
# ============================================================
# dev-bootstrap - Common library
# ============================================================

export LC_ALL=C

# ---- colors ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
err()   { echo -e "${RED}[ERR]${NC}   $1"; }

# ---- sudo wrapper ----
run_sudo() {
  if [ "$EUID" -eq 0 ]; then
    eval "$*"
  else
    sudo env "PATH=$PATH" bash -c "$*"
  fi
}

# ---- OS detection ----
detect_os() {
  . /etc/os-release 2>/dev/null || true
  info "OS: $PRETTY_NAME ($VERSION_CODENAME)"
}

# ---- apt update wrapper ----
apt_update() {
  run_sudo apt update -qq 2>/dev/null || run_sudo apt update
}

# ---- header / footer ----
section() {
  echo ""
  echo -e "${CYAN}============================================${NC}"
  echo -e "${CYAN}  $1${NC}"
  echo -e "${CYAN}============================================${NC}"
}

done_section() {
  echo -e "${GREEN}  >> $1 done${NC}"
}

# ---- install base system dependencies ----
ensure_base() {
  section "System Base Dependencies"
  apt_update
  run_sudo apt install -y curl wget git unzip zip make jq \
    apt-transport-https ca-certificates gnupg lsb-release software-properties-common 2>&1 | tail -1
  done_section "System Base Dependencies"
}
