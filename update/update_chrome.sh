#!/bin/sh

set -eu

# 安装或更新 Google Chrome Stable：
# - 刷新 APT 软件源，并安装或升级 google-chrome-stable；
# - Chrome 软件源必须已经配置，执行安装需要 sudo 权限；
# - 显示操作前后的版本，并区分首次安装、版本未变和升级成功。

green="$(printf '\033[32m')"
yellow="$(printf '\033[33m')"
reset="$(printf '\033[0m')"

old_version="$(google-chrome-stable --version 2>/dev/null || true)"
was_installed=0
if dpkg-query -W -f='${Status}\n' google-chrome-stable 2>/dev/null \
  | grep -qx 'install ok installed'; then
  was_installed=1
fi

sudo apt-get update
sudo apt-get install -y google-chrome-stable

new_version="$(google-chrome-stable --version 2>/dev/null || true)"

printf 'Old version: %s%s%s\n' "$yellow" "${old_version:-unknown}" "$reset"
printf 'New version: %s%s%s\n' "$green" "${new_version:-unknown}" "$reset"

if [ "$was_installed" -eq 0 ]; then
  printf 'Status: %sinstalled%s\n' "$green" "$reset"
elif [ "$old_version" = "$new_version" ]; then
  printf 'Status: %sunchanged%s\n' "$yellow" "$reset"
else
  printf 'Status: %supdated%s\n' "$green" "$reset"
fi
