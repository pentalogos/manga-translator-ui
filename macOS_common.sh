#!/bin/bash

# Shared helpers for the macOS launcher scripts.
# Keep macOS_1_首次安装.sh self-contained because the documented quick install
# downloads that file by itself before the repository is cloned.

if [ -z "${SCRIPT_DIR:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

CONDA_ENV_NAME="${CONDA_ENV_NAME:-manga-env}"
CONDA_ENV_PATH="${CONDA_ENV_PATH:-$SCRIPT_DIR/conda_env}"
LOCAL_CONDA_DIRS=(
    "$SCRIPT_DIR/Miniforge3"
    "$SCRIPT_DIR/Miniconda3"
    "$HOME/miniforge3"
    "$HOME/miniconda3"
    "$HOME/anaconda3"
    "/opt/homebrew/Caskroom/miniforge/base"
    "/opt/homebrew/anaconda3"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONDA_BIN=""
CONDA_ROOT=""
CONDA_ENV_MODE=""
ENV_PATH=""
ENV_PYTHON=""
USE_DIRECT_ENV_PYTHON=0

info() {
    echo -e "${BLUE}[*] $*${NC}"
}

ok() {
    echo -e "${GREEN}[OK] $*${NC}"
}

warn() {
    echo -e "${YELLOW}[警告] $*${NC}"
}

fail() {
    echo -e "${RED}[错误] $*${NC}" >&2
}

resolve_conda_root() {
    local candidate="$1"
    local root

    if [ ! -x "$candidate" ]; then
        return 1
    fi

    if ! "$candidate" --version >/dev/null 2>&1; then
        return 1
    fi

    root="$("$candidate" info --base 2>/dev/null || true)"
    if [ -z "$root" ]; then
        root="$(cd "$(dirname "$candidate")/.." && pwd)"
    fi

    if [ ! -x "$root/bin/conda" ]; then
        return 1
    fi

    CONDA_BIN="$root/bin/conda"
    CONDA_ROOT="$root"
    return 0
}

find_conda() {
    local dir
    local command_conda

    for dir in "${LOCAL_CONDA_DIRS[@]}"; do
        if resolve_conda_root "$dir/bin/conda"; then
            return 0
        fi
    done

    if [ -n "${CONDA_EXE:-}" ] && resolve_conda_root "$CONDA_EXE"; then
        return 0
    fi

    command_conda="$(command -v conda 2>/dev/null || true)"
    if [ -n "$command_conda" ] && resolve_conda_root "$command_conda"; then
        return 0
    fi

    return 1
}

init_conda() {
    local hook

    if ! find_conda; then
        return 1
    fi

    export PATH="$CONDA_ROOT/bin:$PATH"
    hook="$("$CONDA_BIN" shell.bash hook 2>/dev/null || true)"
    if [ -n "$hook" ]; then
        eval "$hook"
    elif [ -f "$CONDA_ROOT/etc/profile.d/conda.sh" ]; then
        # shellcheck source=/dev/null
        source "$CONDA_ROOT/etc/profile.d/conda.sh"
    else
        return 1
    fi

    ok "Conda 已初始化: $CONDA_ROOT"
    return 0
}

resolve_env_path() {
    local env_list
    local found_path

    ENV_PATH=""
    CONDA_ENV_MODE=""

    if [ -x "$CONDA_ROOT/envs/$CONDA_ENV_NAME/bin/python" ]; then
        ENV_PATH="$CONDA_ROOT/envs/$CONDA_ENV_NAME"
        CONDA_ENV_MODE="named"
        return 0
    fi

    env_list="$(conda env list 2>/dev/null || true)"
    found_path="$(printf '%s\n' "$env_list" | awk -v name="$CONDA_ENV_NAME" '$1 == name {print $NF; exit}')"
    if [ -n "$found_path" ] && [ -x "$found_path/bin/python" ]; then
        ENV_PATH="$found_path"
        CONDA_ENV_MODE="named"
        return 0
    fi

    if [ -x "$CONDA_ENV_PATH/bin/python" ]; then
        ENV_PATH="$CONDA_ENV_PATH"
        CONDA_ENV_MODE="legacy"
        return 0
    fi

    return 1
}

apply_env_runtime_path() {
    export PATH="$ENV_PATH/bin:$ENV_PATH/condabin:$PATH"
    export CONDA_PREFIX="$ENV_PATH"
    if [ "$CONDA_ENV_MODE" = "named" ]; then
        export CONDA_DEFAULT_ENV="$CONDA_ENV_NAME"
    else
        export CONDA_DEFAULT_ENV="$ENV_PATH"
    fi
}

activate_project_env() {
    if ! resolve_env_path; then
        fail "未检测到 Conda 环境"
        echo "   请先运行 ./macOS_1_首次安装.sh 安装"
        return 1
    fi

    ENV_PYTHON="$ENV_PATH/bin/python"
    USE_DIRECT_ENV_PYTHON=0

    if [ "$CONDA_ENV_MODE" = "named" ]; then
        if conda activate "$CONDA_ENV_NAME" 2>/dev/null; then
            ok "已激活环境: $CONDA_ENV_NAME"
            return 0
        fi
    else
        if conda activate "$ENV_PATH" 2>/dev/null; then
            ok "已激活环境: $ENV_PATH"
            return 0
        fi
    fi

    warn "Conda 激活失败，改用环境内 Python 直接运行"
    apply_env_runtime_path
    USE_DIRECT_ENV_PYTHON=1
    ok "已使用环境路径: $ENV_PATH"
}

run_env_python() {
    if [ "$USE_DIRECT_ENV_PYTHON" = "1" ]; then
        "$ENV_PYTHON" "$@"
    else
        python "$@"
    fi
}

ensure_project_root() {
    cd "$SCRIPT_DIR" || return 1
    if [ ! -d "desktop_qt_ui" ] || [ ! -d "manga_translator" ] || [ ! -f "packaging/VERSION" ]; then
        fail "当前目录不是完整项目目录: $SCRIPT_DIR"
        return 1
    fi
}
