#!/bin/bash
# ============================================================
# dev-bootstrap - Maven module
# ============================================================
# Env: MAVEN_MIRROR_URL

MAVEN_MIRROR_URL="${MAVEN_MIRROR_URL:-https://maven.aliyun.com/repository/public}"

install_maven() {
  section "Maven"

  apt_update
  run_sudo apt install -y maven 2>&1 | tail -1

  # configure mirror in settings.xml
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

  done_section "Maven"
  echo "  $(mvn --version 2>&1 | head -1)"
  echo "  Mirror: ${MAVEN_MIRROR_URL}"
}
