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

创建 `/etc/udev/rules.d/99-hide-windows-partitions.rules`：

```text
ENV{ID_FS_UUID}=="12363D8F363D7537", ENV{UDISKS_IGNORE}="1", ENV{UDISKS_PRESENTATION_HIDE}="1"
ENV{ID_FS_UUID}=="224E3E0C4E3DD96D", ENV{UDISKS_IGNORE}="1", ENV{UDISKS_PRESENTATION_HIDE}="1"
ENV{ID_FS_UUID}=="82D03E7FD03E798D", ENV{UDISKS_IGNORE}="1", ENV{UDISKS_PRESENTATION_HIDE}="1"
```

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
