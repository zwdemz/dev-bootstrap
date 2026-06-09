# Dev Bootstrap

One-click development environment setup for Ubuntu, with pre-configured China mirrors.

## Components

| Component    | Description                   | Mirror                          |
|--------------|-------------------------------|---------------------------------|
| **NVM + Node.js** | Node Version Manager + LTS  | USTC (download), npmmirror (npm) |
| **Java**     | OpenJDK 8 + 21 (switchable)  | cn.archive.ubuntu.com (apt)      |
| **Go**       | Latest stable Go              | USTC (download), goproxy.cn      |
| **Maven**    | Maven build tool              | Aliyun (repository)              |
| **Gradle**   | Gradle build tool             | Huawei (download), Aliyun (repo) |
| **Docker**   | Docker Engine + Compose       | USTC (apt + registry mirrors)    |

## Quick Start

```bash
# interactive menu
./install.sh

# install everything
./install.sh all

# install specific components (comma-separated)
./install.sh nvm,java,go,docker

# configure mirrors only (for already installed tools)
./install.sh mirror
```

## Environment Variables

Override defaults by exporting before running:

```bash
# Java
export JAVA_DEFAULT=8                          # default Java version (8 or 21)

# Go
export GO_VERSION=1.23.0                       # specific Go version
export GOPROXY=https://goproxy.cn,direct       # Go proxy

# Docker
export DOCKER_MIRROR=https://mirrors.ustc.edu.cn/docker-ce
export DOCKER_REGISTRY_MIRRORS='["https://docker.mirrors.ustc.edu.cn","https://hub-mirror.c.163.com"]'

# Mirrors
export PIP_MIRROR=https://pypi.tuna.tsinghua.edu.cn/simple
export NPM_MIRROR=https://registry.npmmirror.com
export MAVEN_MIRROR_URL=https://maven.aliyun.com/repository/public
export GRADLE_MIRROR=https://mirrors.huaweicloud.com/gradle
```

## Post-Install

- Run `source ~/.bashrc` or restart your shell to apply PATH changes
- Switch Java: `scripts/switch-java.sh {8|21}`
- Log out and back in to use Docker without sudo (after `install.sh docker`)
