#!/bin/bash

# ==================== macOS 更新维护 ====================
# 对应 Windows 的「步骤4-更新维护.bat」
# =====================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# shellcheck source=macOS_common.sh
source "$SCRIPT_DIR/macOS_common.sh"

echo "=============================================="
echo "  Manga Translator UI - 更新维护"
echo "=============================================="
echo ""

ensure_project_root

if ! init_conda; then
    fail "未找到可用的 Conda"
    echo "   请先运行 ./macOS_1_首次安装.sh 安装"
    exit 1
fi

activate_project_env

echo ""
info "启动维护菜单..."
echo ""

if [ ! -f "packaging/launch.py" ]; then
    fail "维护脚本不存在: packaging/launch.py"
    exit 1
fi

if [ "${MANGAT_MACOS_DRY_RUN:-0}" = "1" ]; then
    echo "[DRY-RUN] python packaging/launch.py --maintenance"
    exit 0
fi

run_env_python packaging/launch.py --maintenance
