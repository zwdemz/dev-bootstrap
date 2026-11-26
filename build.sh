#!/bin/bash
# 生成单文件 install.sh（可直接 curl/wget 执行）
set -e
cd "$(dirname "$0")"

OUT=install.sh
LIBS=(
  lib/common.sh
  lib/mirrors.sh
  lib/nvm.sh
  lib/java.sh
  lib/go.sh
  lib/python.sh
  lib/rust.sh
  lib/php.sh
  lib/maven.sh
  lib/gradle.sh
  lib/tools.sh
  lib/db.sh
  lib/docker.sh
)

{
  echo '#!/bin/bash'
  echo '# ============================================================'
  echo '# dev-bootstrap - generated single-file installer (do not edit)'
  echo '# Sources: lib/*.sh + src/main.sh ; rebuild: ./build.sh'
  echo '# ============================================================'
  echo ''
  for f in "${LIBS[@]}"; do
    echo "# ==================== $f ===================="
    cat "$f"
    echo
  done
  cat src/main.sh
} > "$OUT"
chmod +x "$OUT"
echo "built $OUT ($(wc -l < "$OUT") lines)"
