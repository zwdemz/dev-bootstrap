# Contributing / 开发规范

## 提交签名（强制）

本仓库要求所有提交使用 **SSH 签名**，推送前由 `scripts/trusted-push.sh` 校验。

一次性配置：

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
git config --global tag.gpgsign true
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

`~/.ssh/allowed_signers`：

```
you@example.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...
```

并把公钥以 **Signing Key** 类型添加到 GitHub（Settings → SSH and GPG keys），确保提交显示 Verified。

## 推送流程

```bash
# 提交（签名）
git commit -S -m "feat: ..."

# 校验签名 + 同步状态后推送
./scripts/trusted-push.sh
```

`trusted-push.sh` 会检查：工作区干净、最新提交签名通过、未落后远端，然后推送并打印远端签名状态。

## 其它

- `install.sh` 是生成文件：修改 `lib/*.sh` 或 `src/main.sh` 后运行 `./build.sh`；
- 交互菜单通过 `/dev/tty` 读取，非交互场景用 `bash -s -- 8,10` 参数模式。
