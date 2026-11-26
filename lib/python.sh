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
