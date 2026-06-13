#!/usr/bin/env bash
set -euo pipefail

# 更新 Ubuntu 系统软件包
# - 刷新 APT 软件源索引并执行完整系统升级
# - 自动删除不再需要的依赖，并清理过期的软件包缓存
# - 需要 sudo 权限，任一命令失败时立即终止

sudo apt-get update
sudo apt-get full-upgrade -y

sudo apt-get autoremove -y
sudo apt-get autoclean
