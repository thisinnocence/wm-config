# 双系统 SSD 配置

本机在同一块 NVMe SSD 上安装 Windows 和 Ubuntu。目标是在 Ubuntu 中隐藏 Windows NTFS 分区，避免误挂载、误删或误写入。

当前分区：

```text
/dev/nvme0n1p1  vfat  SYSTEM     /boot/efi
/dev/nvme0n1p3  NTFS  Windows    UUID=12363D8F363D7537
/dev/nvme0n1p4  NTFS  Data       UUID=224E3E0C4E3DD96D
/dev/nvme0n1p5  NTFS  WinRE_DRV  UUID=82D03E7FD03E798D
/dev/nvme0n1p6  ext4             /
```

原则：日常不要从 Ubuntu 写入 Windows NTFS 分区，尤其 Windows Fast Startup / hibernation 未关闭时。

- 建议在 Windows 11 中关闭 Fast Startup 和 hibernation：以管理员身份打开 Windows Terminal，执行 `powercfg /h off`。
- 也可以在 `Control Panel -> Power Options -> Choose what the power buttons do` 中关闭 `Turn on fast startup`。

为什么建议做上面操作呢？

Windows Fast Startup / hibernation 会让 Windows 分区处于类似“休眠中”的状态，NTFS 元数据可能还没有完全关闭。
这时从 Ubuntu 写入 Windows 分区，可能导致 Windows 文件系统状态不一致，轻则下次 Windows 启动自动修复，重则出现文件损坏。
关闭它们后，Windows 每次关机都会完整卸载 NTFS 分区，双系统之间切换更安全。

## 关闭 GNOME automount

```bash
gsettings set org.gnome.desktop.media-handling automount false
gsettings set org.gnome.desktop.media-handling automount-open false
```

检查：

```bash
gsettings get org.gnome.desktop.media-handling automount
gsettings get org.gnome.desktop.media-handling automount-open
```

## 隐藏 Windows 分区

先确认 Windows 分区的 UUID：

```bash
lsblk -f
```

本机需要隐藏的是 Windows、Data、WinRE_DRV 这三个 NTFS 分区，所以规则里使用它们的 `ID_FS_UUID` 精确匹配。
这样只会影响这三块 Windows 分区，不会影响 Ubuntu 根分区、EFI 分区或外接 U 盘。

创建 `/etc/udev/rules.d/99-hide-windows-partitions.rules`：

```text
ENV{ID_FS_UUID}=="12363D8F363D7537", ENV{UDISKS_IGNORE}="1", ENV{UDISKS_PRESENTATION_HIDE}="1"
ENV{ID_FS_UUID}=="224E3E0C4E3DD96D", ENV{UDISKS_IGNORE}="1", ENV{UDISKS_PRESENTATION_HIDE}="1"
ENV{ID_FS_UUID}=="82D03E7FD03E798D", ENV{UDISKS_IGNORE}="1", ENV{UDISKS_PRESENTATION_HIDE}="1"
```

含义：

- `ID_FS_UUID` 是分区文件系统 UUID，可以通过 `lsblk -f` 或 `udevadm info --query=property --name=/dev/nvme0n1p3` 查到
- `UDISKS_IGNORE=1` 让 UDisks 忽略这些分区
- `UDISKS_PRESENTATION_HIDE=1` 让桌面文件管理器隐藏这些分区

重新加载：

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger --name-match=/dev/nvme0n1p3 --name-match=/dev/nvme0n1p4 --name-match=/dev/nvme0n1p5
```

检查当前挂载状态，期望只有 `/boot/efi`，没有 Windows NTFS 分区：

```bash
findmnt -t ntfs,ntfs3,fuseblk,exfat,vfat -o TARGET,SOURCE,FSTYPE,OPTIONS
```

## 临时只读访问 Windows 分区

不建议日常访问。确实需要时只读挂载：

```bash
sudo mkdir -p /mnt/windows
sudo mount -t ntfs3 -o ro /dev/nvme0n1p3 /mnt/windows
```

卸载：

```bash
sudo umount /mnt/windows
```

## 恢复 Windows 分区显示

```bash
sudo mv /etc/udev/rules.d/99-hide-windows-partitions.rules /etc/udev/rules.d/99-hide-windows-partitions.rules.disabled
sudo udevadm control --reload-rules
sudo udevadm trigger
gsettings set org.gnome.desktop.media-handling automount true
gsettings set org.gnome.desktop.media-handling automount-open true
```
