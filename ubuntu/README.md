# Ubuntu 双系统配置

本目录记录这台机器的 `Windows + Ubuntu 26.04 LTS` 双系统配置。目标是能快速恢复当前状态。

当前目标状态：

- UEFI 先进入 `ubuntu` shim/GRUB
- GRUB 显示 5 秒菜单
- 不手动选择时默认进入 Windows
- 需要时在 GRUB 菜单手动选择 Ubuntu
- Ubuntu 下隐藏 Windows NTFS 分区，避免误挂载和误写入

配置顺序：

1. [boot.md](boot.md): 配置 UEFI / GRUB 启动顺序
2. [driver.md](driver.md): 检查 NVIDIA 和 Wi-Fi driver
3. [ssd.md](ssd.md): 隐藏 Windows 分区，必要时只读挂载
4. [desktop.md](desktop.md): 配置桌面、字体、输入法、Dock、终端
5. [proxy.md](proxy.md): 可选，配置 Clash Verge proxy、GitHub SSH proxy、apt source

快速检查：

```bash
lsb_release -a
findmnt -no SOURCE,UUID,FSTYPE,TARGET /boot/efi
sudo efibootmgr -v
```
