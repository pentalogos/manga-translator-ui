#!/bin/bash

# ==================== macOS 检查更新并启动 ====================
# 对应 Windows 的「步骤3-检查更新并启动.bat」
# =====================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# shellcheck source=macOS_common.sh
source "$SCRIPT_DIR/macOS_common.sh"

echo "=============================================="
echo "  Manga Translator UI - 检查更新并启动"
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
info "检查版本更新..."
if [ -f "packaging/check_version.py" ]; then
    run_env_python packaging/check_version.py --brief 2>/dev/null || true
else
    warn "版本检查脚本不存在，跳过"
fi

echo ""
echo "========================================"
info "启动应用程序..."
echo ""

if [ "${MANGAT_MACOS_DRY_RUN:-0}" = "1" ]; then
    echo "[DRY-RUN] python desktop_qt_ui/main.py"
    exit 0
fi

run_env_python desktop_qt_ui/main.py
