#!/usr/bin/env bash
# trusted-push.sh [branch] — 校验签名后推送
set -euo pipefail

BRANCH="${1:-main}"

fail() { echo "[trusted-push] $*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || fail "未找到 git"

[ -z "$(git status --porcelain)" ] || fail "工作区不干净，请先提交或 stash"

tip_sig="$(git log -1 --format='%G?')"
[ "$tip_sig" = "G" ] || fail "最新提交未通过签名校验（%G?=${tip_sig}）"

git fetch -q origin "$BRANCH"
git merge-base --is-ancestor "origin/$BRANCH" HEAD \
  || fail "当前分支落后于 origin/$BRANCH，请先 rebase/merge"

echo "[trusted-push] 签名校验通过，推送 HEAD -> origin/$BRANCH"
git push origin "HEAD:$BRANCH"

echo "[trusted-push] 远端最新提交："
git log -1 --format='%h %G? %s' "origin/$BRANCH"
