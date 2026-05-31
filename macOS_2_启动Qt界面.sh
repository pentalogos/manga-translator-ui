#!/bin/bash

# ==================== macOS Qt 界面启动脚本 ====================
# 对应 Windows 的「步骤2-启动Qt界面.bat」
# =====================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# shellcheck source=macOS_common.sh
source "$SCRIPT_DIR/macOS_common.sh"

echo "=============================================="
echo "  Manga Translator UI - Qt 界面启动"
echo "=============================================="
echo ""

ensure_project_root

if ! init_conda; then
    fail "未找到可用的 Conda"
    echo "   请先运行 ./macOS_1_首次安装.sh 安装"
    exit 1
fi

activate_project_env

if ! run_env_python -c "import PyQt6" 2>/dev/null; then
    fail "PyQt6 未安装"
    echo "   请运行 ./macOS_1_首次安装.sh 或 ./macOS_4_更新维护.sh 安装依赖"
    exit 1
fi

echo ""
info "启动 Qt 界面..."
echo ""

if [ "${MANGAT_MACOS_DRY_RUN:-0}" = "1" ]; then
    echo "[DRY-RUN] python desktop_qt_ui/main.py"
    exit 0
fi

run_env_python desktop_qt_ui/main.py
