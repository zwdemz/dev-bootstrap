#!/bin/bash
# ============================================================
# dev-bootstrap - Docker module
# ============================================================
# Env: DOCKER_MIRROR (apt repo mirror), DOCKER_REGISTRY_MIRRORS

DOCKER_MIRROR="${DOCKER_MIRROR:-https://mirrors.ustc.edu.cn/docker-ce}"
DOCKER_REGISTRY_MIRRORS="${DOCKER_REGISTRY_MIRRORS:-[\"https://docker.mirrors.ustc.edu.cn\",\"https://hub-mirror.c.163.com\",\"https://mirror.ccs.tencentyun.com\"]}"

install_docker() {
  section "Docker"

  run_sudo apt purge -y docker docker-engine docker.io containerd runc 2>/dev/null || true

  # GPG key
  info "Adding Docker GPG key..."
  curl -fsSL "${DOCKER_MIRROR}/linux/ubuntu/gpg" 2>/dev/null | \
    run_sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 2>/dev/null || \
    curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | \
    run_sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  # apt source
  CODENAME=$(lsb_release -cs 2>/dev/null || echo "jammy")
  ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
  echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] ${DOCKER_MIRROR}/linux/ubuntu ${CODENAME} stable" | \
    run_sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt_update
  run_sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>&1 | tail -1

  # add user to docker group
  run_sudo usermod -aG docker "$USER" 2>/dev/null || true

  # registry mirrors daemon.json
  run_sudo mkdir -p /etc/docker
  cat << EOJSON | run_sudo tee /etc/docker/daemon.json > /dev/null
{
  "registry-mirrors": ${DOCKER_REGISTRY_MIRRORS}
}
EOJSON

  run_sudo systemctl daemon-reload
  run_sudo systemctl enable docker 2>/dev/null || true
  run_sudo systemctl restart docker 2>/dev/null || true

  done_section "Docker"
  echo "  $(docker --version 2>/dev/null || echo 'N/A')"
}
