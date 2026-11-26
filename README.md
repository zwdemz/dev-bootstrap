# Dev Bootstrap

One-click development environment setup for Ubuntu / Debian, with pre-configured China mirrors.

## Components

| Component | Description | Mirror |
|-----------|-------------|--------|
| **NVM + Node.js** | Node Version Manager + LTS | USTC / npmmirror |
| **Java** | OpenJDK 8 + 21 (switchable) | Ubuntu archive |
| **Go** | Latest stable Go | USTC / goproxy.cn |
| **Python** | Python 3 + pip + venv + uv | Tsinghua PyPI |
| **Rust** | rustup + stable toolchain | rsproxy.cn |
| **PHP** | PHP CLI + FPM + Composer | Aliyun Composer |
| **Maven** | Build tool | Aliyun repository |
| **Gradle** | Build tool | Huawei / Aliyun |
| **CLI Tools** | build-essential, cmake, ripgrep, fd, fzf, tmux, htop, jq, yq, httpie, neovim, sqlite3, zsh | Ubuntu archive |
| **DB Clients** | MySQL / PostgreSQL / Redis / SQLite clients | Ubuntu archive |
| **Docker** | Docker Engine + Compose | USTC + registry mirrors |

## Quick Start

```bash
# interactive menu
./install.sh

# install everything (languages + toolchain + clients + docker)
./install.sh all

# install specific components (comma-separated)
./install.sh nvm,java,go
./install.sh python,rust,tools
./install.sh db

# list components
./install.sh list

# configure mirrors only (for already installed tools)
./install.sh mirror
```

## Component Aliases

| Alias | Component |
|-------|-----------|
| `node`, `nvm` | Node.js |
| `py`, `python` | Python + uv |
| `cli`, `tools` | CLI & build toolchain |
| `db`, `database` | MySQL/PostgreSQL/Redis/SQLite clients |
| `mirror` | mirrors only |

## Environment Variables

Override defaults by exporting before running:

```bash
# Java
export JAVA_DEFAULT=8                  # 8 or 21

# Go
export GO_VERSION=1.24.0              # or "latest"
export GOPROXY=https://goproxy.cn,direct

# Node
export NVM_NODEJS_ORG_MIRROR=https://mirrors.ustc.edu.cn/node
export NPM_REGISTRY=https://registry.npmmirror.com

# Python
export PYTHON_PIP_INDEX=https://pypi.tuna.tsinghua.edu.cn/simple

# Rust
export RUSTUP_DIST_SERVER=https://rsproxy.cn
export RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup

# PHP
export COMPOSER_MIRROR=https://mirrors.aliyun.com/composer/
```

## Requirements

- Ubuntu 20.04+ / Debian 11+（目前 apt 系；macOS 需自行调整）
- 普通用户运行，脚本内部按需 `sudo`
- 建议至少 10GB 可用磁盘（全量安装）

## After Install

```bash
source ~/.bashrc      # 或重新登录
java -version
node -v
go version
python3 --version && uv --version
rustc --version
docker --version
mysql --version
```

Java 版本切换：

```bash
./scripts/switch-java.sh 8
./scripts/switch-java.sh 21
```

## Project Layout

```
.
├── install.sh          # 入口：菜单 / all / list / 指定组件
├── lib/
│   ├── common.sh       # 颜色、日志、sudo、apt 封装
│   ├── mirrors.sh      # 国内镜像配置
│   ├── nvm.sh          # Node.js
│   ├── java.sh         # OpenJDK 8/21
│   ├── go.sh           # Go
│   ├── python.sh       # Python + uv
│   ├── rust.sh         # Rust + crates 镜像
│   ├── php.sh          # PHP + Composer
│   ├── maven.sh        # Maven
│   ├── gradle.sh       # Gradle
│   ├── tools.sh        # CLI / 编译工具链
│   ├── db.sh           # 数据库客户端
│   └── docker.sh       # Docker + Compose
└── scripts/
    └── switch-java.sh  # Java 版本切换
```

## Notes

- 数据库模块只装**客户端**，服务端建议用 Docker 按需启动，避免和宿主机已有实例冲突。
- Docker 使用国内镜像加速；如拉取失败，可配置代理或使用 `docker pull` 备用源。
- 所有安装步骤尽量幂等，可重复执行。
