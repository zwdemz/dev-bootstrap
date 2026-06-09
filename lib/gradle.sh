#!/bin/bash
# ============================================================
# dev-bootstrap - Gradle module
# ============================================================
# Env: GRADLE_VERSION, GRADLE_MIRROR (download mirror)

GRADLE_VERSION="${GRADLE_VERSION:-9.5.1}"
GRADLE_MIRROR="${GRADLE_MIRROR:-https://mirrors.huaweicloud.com/gradle}"

install_gradle() {
  section "Gradle"

  run_sudo apt purge -y gradle 2>/dev/null || true

  info "Downloading Gradle ${GRADLE_VERSION}..."
  DL_URL="${GRADLE_MIRROR}/gradle-${GRADLE_VERSION}-bin.zip"
  FALLBACK_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

  curl -sL "$DL_URL" -o /tmp/gradle.zip 2>/dev/null || \
    curl -sL "$FALLBACK_URL" -o /tmp/gradle.zip

  run_sudo mkdir -p /opt/gradle
  run_sudo unzip -q /tmp/gradle.zip -d /opt/gradle
  run_sudo ln -sf "/opt/gradle/gradle-${GRADLE_VERSION}/bin/gradle" /usr/local/bin/gradle
  rm -f /tmp/gradle.zip

  # init.gradle with mirror config
  mkdir -p "$HOME/.gradle"
  cat > "$HOME/.gradle/init.gradle" << 'EOF'
allprojects {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/public' }
        maven { url 'https://maven.aliyun.com/repository/central' }
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/gradle-plugin' }
        mavenCentral()
    }
}
rootProject {
    buildscript {
        repositories {
            maven { url 'https://maven.aliyun.com/repository/public' }
            maven { url 'https://maven.aliyun.com/repository/central' }
            maven { url 'https://maven.aliyun.com/repository/google' }
            maven { url 'https://maven.aliyun.com/repository/gradle-plugin' }
            mavenCentral()
        }
    }
}
EOF

  done_section "Gradle"
  echo "  $(gradle --version 2>&1 | head -1)"
}
