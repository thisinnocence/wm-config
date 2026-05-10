# 双系统 SSD 配置

## 当前磁盘结构

当前是再同一块 NVMe SSD 配置的的 Windows 和 Ubuntu 分区。

```bash
# SSD
Disk: nvme0n1

# Windows 相关分区：
/dev/nvme0n1p3  NTFS  Windows    UUID=12363D8F363D7537
/dev/nvme0n1p4  NTFS  Data       UUID=224E3E0C4E3DD96D
/dev/nvme0n1p5  NTFS  WinRE_DRV  UUID=82D03E7FD03E798D

# Ubuntu 相关分区：
/dev/nvme0n1p1  vfat  SYSTEM  /boot/efi
/dev/nvme0n1p6  ext4          /
```

## Linux 下对 Windows 的配置

### 关闭自动挂载

Windows 分区原本没有被自动挂载，也没有写在 `/etc/fstab` 里。但 GNOME 可以在文件管理器里显示这些 NTFS 分区。
如果手动点击它们，Ubuntu 可能会挂载这些分区，这样就会存在误删、误改 Windows 文件的风险。 为了降低这个风险，
做了两类设置：

```bash
# 关闭 gnome 自动挂载
gsettings set org.gnome.desktop.media-handling automount false
gsettings set org.gnome.desktop.media-handling automount-open false
# 配置结果
automount=false       # 插入或检测到磁盘时，GNOME 不自动挂载
automount-open=false  # 挂载后 GNOME 不自动打开文件管理器窗口
```

### 隐藏 Windows 分区

创建了这个 udev 规则文件：

```text
/etc/udev/rules.d/99-hide-windows-partitions.rules
```

规则内容：

```text
ENV{ID_FS_UUID}=="12363D8F363D7537", ENV{UDISKS_IGNORE}="1", ENV{UDISKS_PRESENTATION_HIDE}="1"
ENV{ID_FS_UUID}=="224E3E0C4E3DD96D", ENV{UDISKS_IGNORE}="1", ENV{UDISKS_PRESENTATION_HIDE}="1"
ENV{ID_FS_UUID}=="82D03E7FD03E798D", ENV{UDISKS_IGNORE}="1", ENV{UDISKS_PRESENTATION_HIDE}="1"
```

含义：

- `UDISKS_IGNORE=1`：让 UDisks 忽略这些分区
- `UDISKS_PRESENTATION_HIDE=1`：让桌面环境隐藏这些分区

影响范围：

```text
只影响 Windows、Data、WinRE_DRV 这三个 NTFS 分区
```

不会影响：

```text
Ubuntu 根分区 /
EFI 分区 /boot/efi
其他外接 U 盘或移动硬盘
```

重新加载规则，执行：

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger --name-match=/dev/nvme0n1p3 --name-match=/dev/nvme0n1p4 --name-match=/dev/nvme0n1p5
```

验证 udev 属性：

```bash
udevadm info --query=property --name=/dev/nvme0n1p3
udevadm info --query=property --name=/dev/nvme0n1p4
udevadm info --query=property --name=/dev/nvme0n1p5
```

确认结果：

```bash
UDISKS_IGNORE=1
UDISKS_PRESENTATION_HIDE=1
```

验证 GNOME 是否还显示这些分区：

```bash
gio mount -l
```

结果：

```text
只显示整块 Drive，不再显示 Windows、Data、WinRE_DRV 这些 Volume
```

验证当前挂载状态：

```bash
findmnt -t ntfs,ntfs3,fuseblk,exfat,vfat -o TARGET,SOURCE,FSTYPE,OPTIONS
```

结果：

```text
只有 /boot/efi 挂载
Windows NTFS 分区没有挂载
```

### 临时访问 Windows 分区

不建议日常这样做。如果确实需要访问，可以手动挂载指定分区。

示例：

```bash
sudo mkdir -p /mnt/windows
sudo mount -t ntfs3 -o ro /dev/nvme0n1p3 /mnt/windows
```

说明：

- `ro` 表示 read-only
- read-only 挂载可以查看文件，但不会写入 Windows 分区

卸载：

```bash
sudo umount /mnt/windows
```

### 恢复windows分区显示

删除或禁用这个 udev 规则：

```bash
sudo mv /etc/udev/rules.d/99-hide-windows-partitions.rules /etc/udev/rules.d/99-hide-windows-partitions.rules.disabled
sudo udevadm control --reload-rules
sudo udevadm trigger
```

如果还想恢复 GNOME automount：

```bash
gsettings set org.gnome.desktop.media-handling automount true
gsettings set org.gnome.desktop.media-handling automount-open true
```
