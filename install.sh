#!/bin/bash
# ============================================================
# dev-bootstrap - generated single-file installer (do not edit)
# Sources: lib/*.sh + src/main.sh ; rebuild: ./build.sh
# ============================================================

# ==================== lib/common.sh ====================
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

# ==================== lib/mirrors.sh ====================
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

# ==================== lib/nvm.sh ====================
#!/bin/bash
# ============================================================
# dev-bootstrap - NVM + Node.js module
# ============================================================
# Env: NVM_NODEJS_ORG_MIRROR, NPM_REGISTRY

NVM_VERSION="0.40.2"
NVM_NODEJS_ORG_MIRROR="${NVM_NODEJS_ORG_MIRROR:-https://mirrors.ustc.edu.cn/node}"
NPM_REGISTRY="${NPM_REGISTRY:-https://registry.npmmirror.com}"

install_nvm() {
  section "NVM + Node.js"

  # remove apt-installed nodejs if any
  run_sudo apt purge -y nodejs npm 2>/dev/null || true

  export NVM_DIR="$HOME/.nvm"

  if [ -d "$NVM_DIR/.git" ]; then
    info "NVM already exists, updating..."
    (cd "$NVM_DIR" && git pull --ff-only 2>/dev/null) || true
  else
    info "Installing NVM v${NVM_VERSION}..."
    curl -sL "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" -o /tmp/nvm-install.sh
    [ -f /tmp/nvm-install.sh ] && bash /tmp/nvm-install.sh 2>/dev/null
  fi

  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

  export NVM_NODEJS_ORG_MIRROR="$NVM_NODEJS_ORG_MIRROR"

  info "Installing Node.js LTS..."
  nvm install --lts 2>/dev/null || nvm install 22 2>/dev/null || true
  nvm alias default lts/* 2>/dev/null || true

  npm config set registry "$NPM_REGISTRY" 2>/dev/null

  done_section "NVM + Node.js"
  echo "  Node: $(node -v 2>/dev/null || echo 'N/A')"
  echo "  NPM:  $(npm -v 2>/dev/null || echo 'N/A')"
}

# ==================== lib/java.sh ====================
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

# ==================== lib/go.sh ====================
#!/bin/bash
# ============================================================
# dev-bootstrap - Go module
# ============================================================
# Env: GO_VERSION (e.g. 1.24.0 or "latest"), GOPROXY

GO_VERSION="${GO_VERSION:-latest}"
GOPROXY="${GOPROXY:-https://goproxy.cn,direct}"

install_go() {
  section "Go"

  # fetch latest version if requested
  if [ "$GO_VERSION" = "latest" ]; then
    GO_VERSION=$(curl -sL "https://go.dev/dl/?mode=json" 2>/dev/null | \
      python3 -c "import sys,json; print(json.load(sys.stdin)[0]['version'][2:])" 2>/dev/null || echo "1.24.0")
  fi
  info "Go version: ${GO_VERSION}"

  run_sudo apt purge -y golang-go 2>/dev/null || true

  # download (prefer USTC mirror)
  DL_URL="https://mirrors.ustc.edu.cn/golang/go${GO_VERSION}.linux-amd64.tar.gz"
  FALLBACK_URL="https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"

  info "Downloading Go ${GO_VERSION}..."
  curl -sL "$DL_URL" -o /tmp/go.tar.gz 2>/dev/null || \
    curl -sL "$FALLBACK_URL" -o /tmp/go.tar.gz

  run_sudo rm -rf /usr/local/go
  run_sudo tar -C /usr/local -xzf /tmp/go.tar.gz
  rm -f /tmp/go.tar.gz

  # PATH
  grep -q "/usr/local/go/bin" "$HOME/.bashrc" 2>/dev/null || \
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$HOME/.bashrc"

  # GOPROXY
  grep -q "GOPROXY" "$HOME/.bashrc" 2>/dev/null && \
    sed -i "s|^export GOPROXY=.*|export GOPROXY=${GOPROXY}|" "$HOME/.bashrc" || \
    echo "export GOPROXY=${GOPROXY}" >> "$HOME/.bashrc"

  export PATH=$PATH:/usr/local/go/bin
  export GOPROXY=${GOPROXY}

  done_section "Go"
  echo "  $(go version 2>/dev/null || echo 'N/A')"
  echo "  GOPROXY: ${GOPROXY}"
}

# ==================== lib/python.sh ====================
#!/bin/bash
# ============================================================
# dev-bootstrap - Python module
# ============================================================
# Env: PYTHON_PIP_INDEX (default: Tsinghua PyPI mirror)

PYTHON_PIP_INDEX="${PYTHON_PIP_INDEX:-https://pypi.tuna.tsinghua.edu.cn/simple}"

install_python() {
  section "Python"

  run_sudo apt install -y python3 python3-pip python3-venv python3-dev 2>&1 | tail -1

  # pip 国内镜像（用户级）
  mkdir -p "$HOME/.config/pip"
  cat > "$HOME/.config/pip/pip.conf" <<EOF
[global]
index-url = ${PYTHON_PIP_INDEX}
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF

  # uv：快速的 Python 包/项目管理器
  if ! command -v uv >/dev/null 2>&1; then
    info "Installing uv..."
    pip3 install --user -i "$PYTHON_PIP_INDEX" uv 2>/dev/null || \
      run_sudo pip3 install --break-system-packages -i "$PYTHON_PIP_INDEX" uv 2>/dev/null || true
  fi

  grep -q 'HOME/.local/bin' "$HOME/.bashrc" 2>/dev/null || \
    echo 'export PATH=$HOME/.local/bin:$PATH' >> "$HOME/.bashrc"
  export PATH="$HOME/.local/bin:$PATH"

  done_section "Python"
  echo "  Python: $(python3 --version 2>/dev/null || echo 'N/A')"
  echo "  Pip:    $(pip3 --version 2>/dev/null | awk '{print $2}' || echo 'N/A')"
  echo "  uv:     $(uv --version 2>/dev/null || echo 'N/A')"
  echo "  Index:  ${PYTHON_PIP_INDEX}"
}

# ==================== lib/rust.sh ====================
#!/bin/bash
# ============================================================
# dev-bootstrap - Rust module (rustup + rsproxy mirror)
# ============================================================
# Env: RUSTUP_DIST_SERVER / RUSTUP_UPDATE_ROOT

RUSTUP_DIST_SERVER="${RUSTUP_DIST_SERVER:-https://rsproxy.cn}"
RUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-https://rsproxy.cn/rustup}"

install_rust() {
  section "Rust"

  export RUSTUP_DIST_SERVER RUSTUP_UPDATE_ROOT

  if command -v rustup >/dev/null 2>&1; then
    info "rustup already installed, updating toolchain..."
    rustup update stable 2>/dev/null || true
  else
    info "Installing rustup + stable toolchain (rsproxy)..."
    curl -sSf https://rsproxy.cn/rustup-init.sh -o /tmp/rustup-init.sh
    sh /tmp/rustup-init.sh -y --default-toolchain stable --profile default 2>&1 | tail -2
    rm -f /tmp/rustup-init.sh
  fi

  # shell 环境
  if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"
  fi
  grep -q 'cargo/env' "$HOME/.bashrc" 2>/dev/null || \
    echo '. "$HOME/.cargo/env"' >> "$HOME/.bashrc"
  export PATH="$HOME/.cargo/bin:$PATH"

  # crates.io 镜像（sparse 协议，速度快）
  mkdir -p "$HOME/.cargo"
  cat > "$HOME/.cargo/config.toml" <<'EOF'
[source.crates-io]
replace-with = 'rsproxy-sparse'

[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"

[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"

[net]
git-fetch-with-cli = true
EOF

  done_section "Rust"
  echo "  Rust:  $(rustc --version 2>/dev/null || echo 'N/A')"
  echo "  Cargo: $(cargo --version 2>/dev/null || echo 'N/A')"
}

# ==================== lib/php.sh ====================
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

# ==================== lib/maven.sh ====================
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

# ==================== lib/gradle.sh ====================
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

# ==================== lib/tools.sh ====================
#!/bin/bash
# ============================================================
# dev-bootstrap - CLI & build toolchain module
# ============================================================

install_tools() {
  section "CLI & Build Toolchain"

  apt_update
  run_sudo apt install -y \
    build-essential cmake pkg-config autoconf automake libtool bison re2c \
    ripgrep fd-find fzf tmux htop tree ncdu jq yq httpie neovim sqlite3 zsh 2>&1 | tail -1

  # Ubuntu 的 fd 命令名是 fdfind，补一个 fd 软链
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    run_sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
  fi

  done_section "CLI & Build Toolchain"
  echo "  gcc:   $(gcc --version 2>/dev/null | head -1 || echo 'N/A')"
  echo "  cmake: $(cmake --version 2>/dev/null | head -1 || echo 'N/A')"
  echo "  rg:    $(rg --version 2>/dev/null | head -1 || echo 'N/A')"
  echo "  jq:    $(jq --version 2>/dev/null || echo 'N/A')"
  echo "  nvim:  $(nvim --version 2>/dev/null | head -1 || echo 'N/A')"
}

# ==================== lib/db.sh ====================
#!/bin/bash
# ============================================================
# dev-bootstrap - Database clients module
# ============================================================
# 只安装客户端，不启动服务端，避免和已有数据库冲突。
# 需要服务端时建议用 Docker：
#   docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=... -p 3306:3306 mysql:8
#   docker run -d --name postgres -e POSTGRES_PASSWORD=... -p 5432:5432 postgres:16
#   docker run -d --name redis -p 6379:6379 redis:7

install_db() {
  section "Database Clients"

  apt_update
  run_sudo apt install -y default-mysql-client postgresql-client redis-tools sqlite3 2>&1 | tail -1

  done_section "Database Clients"
  echo "  mysql:  $(mysql --version 2>/dev/null | head -1 || echo 'N/A')"
  echo "  psql:   $(psql --version 2>/dev/null || echo 'N/A')"
  echo "  redis:  $(redis-cli --version 2>/dev/null || echo 'N/A')"
  echo "  sqlite: $(sqlite3 --version 2>/dev/null | head -1 || echo 'N/A')"
}

# ==================== lib/docker.sh ====================
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
