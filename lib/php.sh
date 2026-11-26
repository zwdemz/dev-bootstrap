#!/bin/bash
# ============================================================
# dev-bootstrap - PHP module
# ============================================================

COMPOSER_MIRROR="${COMPOSER_MIRROR:-https://mirrors.aliyun.com/composer/}"

install_php() {
  section "PHP"

  apt_update
  run_sudo apt install -y php-cli php-fpm php-mysql php-curl php-mbstring \
    php-xml php-zip php-gd composer 2>&1 | tail -1

  # Composer 阿里云镜像
  if command -v composer >/dev/null 2>&1; then
    composer config -g repos.packagist composer "$COMPOSER_MIRROR" 2>/dev/null || true
  fi

  done_section "PHP"
  echo "  PHP:      $(php -v 2>/dev/null | head -1 || echo 'N/A')"
  echo "  Composer: $(composer --version 2>/dev/null | head -1 || echo 'N/A')"
  echo "  Mirror:   ${COMPOSER_MIRROR}"
}
