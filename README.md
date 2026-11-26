# Dev Bootstrap

One-click development environment setup for Ubuntu / Debian, with pre-configured China mirrors.

- **数字菜单**：运行后按数字选择要装的环境，可多选（如 `8,10,11`）
- **单文件**：`install.sh` 自包含，支持 `curl` / `wget` 一行安装
- **国内镜像**：Node / Python / Rust / PHP / Go / Maven / Gradle / Docker 均已配置

## 一行安装（curl / wget）

```bash
# 交互菜单（数字多选）
curl -fsSL https://raw.githubusercontent.com/zwdemz/dev-bootstrap/main/install.sh | bash
wget -qO- https://raw.githubusercontent.com/zwdemz/dev-bootstrap/main/install.sh | bash

# 非交互：按数字安装（8=Python, 10=CLI工具, 11=数据库客户端）
curl -fsSL https://raw.githubusercontent.com/zwdemz/dev-bootstrap/main/install.sh | bash -s -- 8,10,11
wget -qO- https://raw.githubusercontent.com/zwdemz/dev-bootstrap/main/install.sh | bash -s -- 8,10,11

# 按名称安装 / 全量
curl -fsSL https://raw.githubusercontent.com/zwdemz/dev-bootstrap/main/install.sh | bash -s -- python,rust,tools
wget -qO- https://raw.githubusercontent.com/zwdemz/dev-bootstrap/main/install.sh | bash -s -- all
```

> 国内访问 `raw.githubusercontent.com` 不稳定时，用代理前缀：
>
> ```bash
> curl -fsSL https://ghproxy.net/https://raw.githubusercontent.com/zwdemz/dev-bootstrap/main/install.sh | bash
> ```

## 本地使用

```bash
./install.sh              # 数字菜单，可多选：8,10,11
./install.sh list         # 列出数字/名称对照
./install.sh 8,10,11      # 按数字安装
./install.sh python,rust  # 按名称安装
./install.sh all          # 全量安装
./install.sh mirror       # 仅配置镜像
```

## 数字选项

| 数字 | 组件 | 说明 | 镜像 |
|------|------|------|------|
| 1 | all | 全部安装 | - |
| 2 | nvm / node | Node.js LTS | USTC / npmmirror |
| 3 | java | OpenJDK 8 + 21（可切换） | Ubuntu archive |
| 4 | go | Go 最新稳定版 | USTC / goproxy.cn |
| 5 | maven | Maven | Aliyun |
| 6 | gradle | Gradle | Huawei / Aliyun |
| 7 | docker | Docker Engine + Compose | USTC + registry mirrors |
| 8 | python / py | Python3 + pip + venv + uv | 清华 PyPI |
| 9 | rust | rustup + stable | rsproxy.cn |
| 10 | tools / cli | build-essential、cmake、ripgrep、fd、fzf、tmux、htop、jq、yq、httpie、neovim、sqlite3、zsh | Ubuntu archive |
| 11 | db / database | MySQL / PostgreSQL / Redis / SQLite 客户端 | Ubuntu archive |
| 12 | php | PHP CLI + FPM + Composer | Aliyun Composer |
| 13 | mirror | 仅配置国内镜像 | - |

## 环境变量

```bash
export JAVA_DEFAULT=8
export GO_VERSION=1.24.0
export GOPROXY=https://goproxy.cn,direct
export NVM_NODEJS_ORG_MIRROR=https://mirrors.ustc.edu.cn/node
export NPM_REGISTRY=https://registry.npmmirror.com
export PYTHON_PIP_INDEX=https://pypi.tuna.tsinghua.edu.cn/simple
export RUSTUP_DIST_SERVER=https://rsproxy.cn
export RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup
export COMPOSER_MIRROR=https://mirrors.aliyun.com/composer/
```

## 要求

- Ubuntu 20.04+ / Debian 11+（apt 系）
- 普通用户运行，脚本内部按需 `sudo`
- 全量安装建议 ≥10GB 磁盘

## 安装后

```bash
source ~/.bashrc
java -version && node -v && go version
python3 --version && uv --version && rustc --version
docker --version && mysql --version
```

Java 切换：

```bash
./scripts/switch-java.sh 8
./scripts/switch-java.sh 21
```

## 开发 / 构建

`install.sh` 是生成文件，由 `lib/*.sh` + `src/main.sh` 拼接而成：

```
.
├── build.sh            # 生成单文件 install.sh
├── install.sh          # 生成物（curl/wget 用这个）
├── src/main.sh         # 菜单、参数解析、汇总
├── lib/
│   ├── common.sh       # 颜色、日志、sudo、apt
│   ├── mirrors.sh      # 国内镜像
│   ├── nvm.sh java.sh go.sh python.sh rust.sh php.sh
│   ├── maven.sh gradle.sh docker.sh
│   ├── tools.sh db.sh
└── scripts/switch-java.sh
```

修改 `lib/` 或 `src/main.sh` 后重新生成：

```bash
./build.sh
```

## 可信推送（签名提交）

本仓库使用 **SSH 签名提交**，`scripts/trusted-push.sh` 会在推送前校验签名与同步状态：

```bash
./scripts/trusted-push.sh
# 或指定分支
./scripts/trusted-push.sh main
```

一次性配置（新机器）：

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
git config --global tag.gpgsign true
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

`~/.ssh/allowed_signers` 内容（邮箱与密钥）：

```
you@example.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...
```

提交时带 `-S`（或开启全局 `commit.gpgsign`）；并把公钥作为 **Signing Key** 添加到 GitHub（Settings → SSH and GPG keys → New SSH key → Key type: Signing Key），提交才会显示 **Verified**。

## 说明

- 数据库模块只装**客户端**；服务端建议 Docker 按需启动，避免和宿主机已有实例冲突。
- 交互菜单通过 `/dev/tty` 读取；`curl | bash` 时依然可以弹出数字菜单。
- 非交互场景请用 `bash -s -- 8,10` / `bash -s -- all`；纯管道且无终端时会提示改用参数模式。
