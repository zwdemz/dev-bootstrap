#!/bin/bash
# ============================================================
# switch-java - Switch between Java 8 and Java 21
# ============================================================
# Usage: ./switch-java.sh [8|21]

JAVA8_HOME=/usr/lib/jvm/java-8-openjdk-amd64
JAVA21_HOME=/usr/lib/jvm/java-21-openjdk-amd64

case "$1" in
  8)
    sudo update-alternatives --set java "$JAVA8_HOME/jre/bin/java"
    sudo update-alternatives --set javac "$JAVA8_HOME/bin/javac"
    sed -i '/^export JAVA_HOME=/d' ~/.bashrc ~/.profile 2>/dev/null
    echo "export JAVA_HOME=$JAVA8_HOME" >> ~/.bashrc
    echo "Switched to Java 8 (JAVA_HOME=$JAVA8_HOME)"
    ;;
  21)
    sudo update-alternatives --set java "$JAVA21_HOME/bin/java"
    sudo update-alternatives --set javac "$JAVA21_HOME/bin/javac"
    sed -i '/^export JAVA_HOME=/d' ~/.bashrc ~/.profile 2>/dev/null
    echo "export JAVA_HOME=$JAVA21_HOME" >> ~/.bashrc
    echo "Switched to Java 21 (JAVA_HOME=$JAVA21_HOME)"
    ;;
  *)
    echo "Usage: $0 {8|21}"
    echo "Current:"
    java -version 2>&1 | head -1
    echo "JAVA_HOME=$JAVA_HOME"
    ;;
esac
