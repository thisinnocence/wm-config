#!/usr/bin/env bash
set -euo pipefail

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
  uv python list | sed -n '1,12p'
fi
