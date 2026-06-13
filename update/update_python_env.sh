#!/usr/bin/env bash
set -euo pipefail

# 更新当前用户通过 uv 管理的 Python 开发环境
# - 仅更新用户目录中的 uv、uv 管理的 Python runtime 和 uv tool，不使用 sudo
# - 不修改 Ubuntu APT 安装的 System Python，也不使用 pip 更新系统或用户 site-packages
# - 不读取或修改项目 pyproject.toml、uv.lock、requirements.txt、.python-version 或 .venv
# - 在 HOME 下的临时空目录中运行，并使用 --no-config 禁止发现项目和用户配置文件
# - uv、Python 安装目录、工具目录、命令入口和缓存目录都必须位于 HOME 内
# - 若 uv 不属于当前用户，或检测到已激活的 venv/Conda 环境，将不做修改并直接退出
# - 更新完成后显示 uv、当前 shell Python、uv 管理的 Python runtime 和 uv tool 信息

HOME_REAL=""
WORK_DIR=""
UV_BIN=""
UV_CACHE_DIR_VALUE=""
UV_PYTHON_BIN_DIR_VALUE=""
UV_PYTHON_INSTALL_DIR_VALUE=""
UV_TOOL_BIN_DIR_VALUE=""
UV_TOOL_DIR_VALUE=""

unsupported_environment() {
  local reason="$1"

  echo "error: unsupported Python environment: $reason" >&2
  echo "tip: this updater only supports a user-level uv environment; nothing was changed." >&2
  exit 1
}

require_user_path() {
  local label="$1"
  local path="$2"
  local resolved_path

  resolved_path="$(readlink -m "$path")"
  if [[ "$resolved_path" != "$HOME_REAL/"* ]]; then
    unsupported_environment "$label is outside the current user's home directory: $resolved_path"
  fi
}

uv_cmd() {
  "$UV_BIN" --no-config "$@"
}

# 更新前安全检查（preflight）：确认权限、uv 所有权及所有写入目录均属于当前用户
preflight() {
  if (( EUID == 0 )); then
    echo "error: do not run this user-level updater with sudo or as root" >&2
    exit 1
  fi

  if [[ -z "${HOME:-}" || ! -d "$HOME" ]]; then
    echo "error: HOME is not set to a valid directory" >&2
    exit 1
  fi

  if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    unsupported_environment "a Python virtual environment is active: $VIRTUAL_ENV"
  fi
  if [[ -n "${CONDA_PREFIX:-}" ]]; then
    unsupported_environment "a Conda environment is active: $CONDA_PREFIX"
  fi

  HOME_REAL="$(readlink -f "$HOME")"
  if ! command -v uv >/dev/null 2>&1; then
    unsupported_environment "uv is not installed or is not available on PATH"
  fi
  UV_BIN="$(readlink -f "$(command -v uv)")"
  require_user_path "uv" "$UV_BIN"

  # 使用空目录和 --no-config，确保 uv 不会发现项目或用户级 uv.toml 配置
  WORK_DIR="$(mktemp -d "$HOME/.python-env-update.XXXXXX")"
  trap 'rm -rf "$WORK_DIR"' EXIT
  cd "$WORK_DIR"

  # 清除可能强制 uv 进入项目目录或指定 Python 目标的环境变量
  unset UV_CONFIG_FILE UV_PROJECT UV_PYTHON UV_WORKING_DIR

  # 只有 standalone installer 安装的 uv 支持 self update，dry-run 不会修改环境
  if ! uv_cmd self update --dry-run >/dev/null 2>&1; then
    unsupported_environment "uv does not support self-update; use the original package manager to upgrade it"
  fi

  UV_PYTHON_INSTALL_DIR_VALUE="$(uv_cmd python dir)"
  UV_PYTHON_BIN_DIR_VALUE="$(uv_cmd python dir --bin)"
  UV_TOOL_DIR_VALUE="$(uv_cmd tool dir)"
  UV_TOOL_BIN_DIR_VALUE="$(uv_cmd tool dir --bin)"
  UV_CACHE_DIR_VALUE="$(uv_cmd cache dir)"

  require_user_path "uv Python installation directory" "$UV_PYTHON_INSTALL_DIR_VALUE"
  require_user_path "uv Python executable directory" "$UV_PYTHON_BIN_DIR_VALUE"
  require_user_path "uv tool directory" "$UV_TOOL_DIR_VALUE"
  require_user_path "uv tool executable directory" "$UV_TOOL_BIN_DIR_VALUE"
  require_user_path "uv cache directory" "$UV_CACHE_DIR_VALUE"

  # 固定已经验证过的用户级目录，避免环境变量在更新期间把写入位置改到 HOME 外
  export UV_PYTHON_INSTALL_DIR="$UV_PYTHON_INSTALL_DIR_VALUE"
  export UV_PYTHON_BIN_DIR="$UV_PYTHON_BIN_DIR_VALUE"
  export UV_TOOL_DIR="$UV_TOOL_DIR_VALUE"
  export UV_TOOL_BIN_DIR="$UV_TOOL_BIN_DIR_VALUE"
  export UV_CACHE_DIR="$UV_CACHE_DIR_VALUE"
}

update_uv() {
  echo "Updating uv..."
  uv_cmd self update
  hash -r

  UV_BIN="$(readlink -f "$(command -v uv)")"
  require_user_path "updated uv" "$UV_BIN"
}

update_managed_python() {
  local installed_python

  installed_python="$(uv_cmd python list --only-installed --managed-python)"
  if [[ -z "$installed_python" ]]; then
    echo "No uv-managed Python runtime is installed; skipping Python runtime updates."
    return
  fi

  echo "Updating uv-managed Python runtimes..."
  uv_cmd python upgrade --managed-python
}

update_uv_tools() {
  local installed_tools

  installed_tools="$(uv_cmd tool list)"
  if [[ "$installed_tools" == "No tools installed" || -z "$installed_tools" ]]; then
    echo "No uv tools are installed; skipping tool updates."
    return
  fi

  echo "Updating uv tools..."
  uv_cmd tool upgrade --all
}

show_tool() {
  local name="$1"

  if command -v "$name" >/dev/null 2>&1; then
    local path
    path="$(command -v "$name")"
    local version
    version="$("$name" --version 2>/dev/null || true)"
    printf '%-8s %-20s %s\n' "$name" "${version:-unknown}" "$path"
  else
    printf '%-8s %-20s %s\n' "$name" "missing" "-"
  fi
}

show_environment() {
  echo
  echo "Updated Python user environment"
  echo "-------------------------------"
  show_tool uv
  show_tool python
  show_tool python3
  show_tool pip
  show_tool pip3

  printf '\nuv Python directory: %s\n' "$UV_PYTHON_INSTALL_DIR_VALUE"
  uv_cmd python list --only-installed

  echo
  printf 'uv tool directory: %s\n' "$UV_TOOL_DIR_VALUE"
  uv_cmd tool list --show-paths
}

main() {
  preflight
  update_uv
  update_managed_python
  update_uv_tools
  show_environment
}

main "$@"
