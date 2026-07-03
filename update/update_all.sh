#!/usr/bin/env bash
set -euo pipefail

# 更新 Ubuntu 系统软件包
# - 刷新 APT 软件源索引并执行完整系统升级
# - full-upgrade 可能为解决依赖变化而删除已安装包
#   这里使用 -y 会跳过确认，执行前需确认当前机器可以接受这种行为
# - 自动删除不再需要的依赖，并清理过期的软件包缓存
# - autoremove 也可能删除曾作为依赖安装的软件包
#   如有手动保留需求，应先用 apt-mark manual 标记
# - 需要 sudo 权限，任一命令失败时立即终止

sudo apt-get update
sudo apt-get full-upgrade -y

sudo apt-get autoremove -y
sudo apt-get autoclean
