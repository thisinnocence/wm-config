#!/usr/bin/env bash
set -euo pipefail

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
  printf 'fnm default: %s\n' "$(fnm list 2>/dev/null | sed -n 's/.*default.*/default/p' | head -n1 || true)"
fi
