#!/bin/bash
# ============================================================
# dev-bootstrap - Java (OpenJDK 8 + 21) module
# ============================================================
# Env: JAVA_DEFAULT (8 or 21)

JAVA8_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
JAVA21_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
JAVA_DEFAULT="${JAVA_DEFAULT:-21}"

install_java() {
  section "Java (OpenJDK 8 + 21)"

  apt_update
  run_sudo apt install -y openjdk-8-jdk openjdk-21-jdk 2>&1 | tail -1

  # set default JAVA_HOME
  case "$JAVA_DEFAULT" in
    8)  DEFAULT_HOME="$JAVA8_HOME" ;;
    *)  DEFAULT_HOME="$JAVA21_HOME" ;;
  esac

  grep -q "^export JAVA_HOME=" "$HOME/.bashrc" 2>/dev/null && \
    sed -i "s|^export JAVA_HOME=.*|export JAVA_HOME=$DEFAULT_HOME|" "$HOME/.bashrc" || \
    echo "export JAVA_HOME=$DEFAULT_HOME" >> "$HOME/.bashrc"

  grep -q "\$JAVA_HOME/bin" "$HOME/.bashrc" 2>/dev/null || \
    echo 'export PATH=$PATH:$JAVA_HOME/bin' >> "$HOME/.bashrc"

  done_section "Java (OpenJDK 8 + 21)"
  echo "  $(java -version 2>&1 | head -1)"
  echo "  JAVA_HOME: $DEFAULT_HOME"
}
