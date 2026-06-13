#!/usr/bin/env bash
set -euo pipefail

# 检查当前用户的 Python 命令解析及 uv 管理环境：
# - 面向用户级工具和 uv 管理的 Python，不检查或更新 Ubuntu APT 系统软件包；
# - 不读取项目依赖状态，也不更新项目虚拟环境、pyproject.toml 或锁文件；
# - 显示当前 PATH 解析到的 uv、python、python3、pip、pip3 版本和实际路径；
# - 自动切换到用户主目录，避免项目中的 pyproject.toml 或 uv.toml 影响检查；
# - 已激活的虚拟环境仍会影响 PATH，运行前应先退出该环境；
# - 禁止使用 sudo/root 运行，否则 HOME、PATH 和 uv 环境可能属于错误的用户；
# - 列出 uv 可识别的前 12 个 Python 安装；查询失败时仅警告，不修改环境。

if (( EUID == 0 )); then
  echo "error: do not run this user-level environment check with sudo or as root" >&2
  exit 1
fi

if [[ -z "${HOME:-}" || ! -d "$HOME" ]]; then
  echo "error: HOME is not set to a valid directory" >&2
  exit 1
fi
cd "$HOME"

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

echo "Python environment check"
echo "------------------------"
show_tool uv
show_tool python
show_tool python3
show_tool pip
show_tool pip3

echo
if command -v uv >/dev/null 2>&1; then
  echo "uv python list (first 12):"
  if ! uv python list | sed -n '1,12p'; then
    echo "warning: unable to list uv-managed Python installations" >&2
  fi
fi
