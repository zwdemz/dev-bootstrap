#!/bin/bash
# ============================================================
# dev-bootstrap - Mirror configuration module
# Configures: pip, npm, go, maven, gradle
# ============================================================
# Env: PIP_MIRROR, NPM_MIRROR, GO_MIRROR

PIP_MIRROR="${PIP_MIRROR:-https://pypi.tuna.tsinghua.edu.cn/simple}"
NPM_MIRROR="${NPM_MIRROR:-https://registry.npmmirror.com}"
GO_MIRROR="${GO_MIRROR:-https://goproxy.cn,direct}"
MAVEN_MIRROR_URL="${MAVEN_MIRROR_URL:-https://maven.aliyun.com/repository/public}"

config_mirrors() {
  section "Mirror Configuration"

  # ---- pip ----
  if command -v pip3 &>/dev/null; then
    pip3 config set global.index-url "$PIP_MIRROR" 2>/dev/null && ok "pip mirror: $PIP_MIRROR"
  else
    warn "pip3 not found, skipping"
  fi

  # ---- npm ----
  if command -v npm &>/dev/null; then
    npm config set registry "$NPM_MIRROR" 2>/dev/null && ok "npm mirror: $NPM_MIRROR"
  else
    warn "npm not found, skipping"
  fi

  # ---- go ----
  if command -v go &>/dev/null; then
    go env -w GOPROXY="$GO_MIRROR" 2>/dev/null && ok "Go proxy: $GO_MIRROR"
  else
    warn "go not found, skipping"
  fi

  # ---- maven ----
  mkdir -p "$HOME/.m2"
  cat > "$HOME/.m2/settings.xml" << EOF
<settings>
  <mirrors>
    <mirror>
      <id>aliyun-maven</id>
      <name>Aliyun Maven Mirror</name>
      <url>${MAVEN_MIRROR_URL}</url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>
</settings>
EOF
  ok "Maven mirror configured"

  # ---- gradle ----
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
  ok "Gradle mirror configured"

  done_section "Mirror Configuration"
}
