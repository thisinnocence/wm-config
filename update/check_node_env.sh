#!/usr/bin/env bash
set -euo pipefail

# 检查当前用户通过 fnm 管理的 Node.js 环境：
# - 面向用户级环境，不检查或更新 Ubuntu APT 安装的系统级 Node.js；
# - 不检查项目 package.json 中的依赖，也不执行 npm/pnpm 项目依赖升级；
# - 显示 fnm、node、npm、pnpm 的版本和实际路径，以及 fnm 当前版本和默认版本；
# - 自动切换到用户主目录，避免项目中的 .node-version、.nvmrc 或 package.json 影响检查；
# - 禁止使用 sudo/root 运行，否则 HOME、PATH 和 fnm 环境可能属于错误的用户；
# - 本脚本只执行诊断，不修改环境。更新用户级 Node.js 可依次执行：
#   fnm install --lts --use
#   fnm default "$(fnm current)"

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
    printf '%-6s %-12s %s\n' "$name" "${version:-unknown}" "$path"
  else
    printf '%-6s %-12s %s\n' "$name" "missing" "-"
  fi
}

echo "Node environment check"
echo "----------------------"
show_tool fnm
show_tool node
show_tool npm
show_tool pnpm

echo
if command -v fnm >/dev/null 2>&1; then
  printf 'fnm current: %s\n' "$(fnm current 2>/dev/null || echo unknown)"
  default_version="$(
    fnm list 2>/dev/null \
      | sed -nE 's/^[*[:space:]]*([^[:space:]]+).*[[:space:]]default$/\1/p' \
      | head -n1 \
      || true
  )"
  printf 'fnm default: %s\n' "${default_version:-unknown}"
fi
