# 双系统启动配置

当前本机目标：

- UEFI 第一启动项是 `ubuntu`，让机器先进入 GRUB
- GRUB 菜单显示 5 秒
- GRUB 默认启动 Windows
- GRUB 菜单顺序是 Windows -> Ubuntu -> Ubuntu advanced

## 检查

```bash
sudo efibootmgr -v
findmnt -no SOURCE,UUID,FSTYPE,TARGET /boot/efi
grep -E '^GRUB_(DEFAULT|TIMEOUT_STYLE|TIMEOUT|DISABLE_OS_PROBER)=' /etc/default/grub
ls -l /etc/grub.d/06_windows /etc/grub.d/20_memtest86+
sudo awk -F"'" '/^menuentry /{print i++ ": " $2} /^submenu /{print "submenu: " $2}' /boot/grub/grub.cfg
```

当前关键值：

```text
/boot/efi: /dev/nvme0n1p1, UUID=143A-C1BE
Windows Boot Manager: /EFI/Microsoft/Boot/bootmgfw.efi
GRUB Windows entry: Windows Boot Manager (on /dev/nvme0n1p1)
```

## 配置 GRUB 默认进 Windows

创建 `/etc/grub.d/06_windows`：

```bash
sudo vim /etc/grub.d/06_windows
```

内容：

```bash
#!/bin/sh
set -e

cat <<'GRUB_EOF'
menuentry 'Windows Boot Manager (on /dev/nvme0n1p1)' --class windows --class os {
    insmod part_gpt
    insmod fat
    search --no-floppy --fs-uuid --set=root 143A-C1BE
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
GRUB_EOF
```

编辑 `/etc/default/grub`：

```bash
GRUB_DEFAULT="Windows Boot Manager (on /dev/nvme0n1p1)"
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
GRUB_DISABLE_OS_PROBER=true
```

应用配置：

```bash
sudo chmod +x /etc/grub.d/06_windows
sudo chmod -x /etc/grub.d/20_memtest86+
sudo update-grub
```

说明：

- `06_windows` 排在 `10_linux` 前面，所以 Windows 显示在 Ubuntu 前面
- `GRUB_DISABLE_OS_PROBER=true` 是为了避免 `30_os-prober` 再自动生成重复的 Windows 项
- 不要直接编辑 `/boot/grub/grub.cfg`，它是生成文件

## 配置 UEFI 先进入 GRUB

只有当开机绕过 GRUB、直接进 Windows 时才需要调整 UEFI BootOrder。

先查当前编号：

```bash
sudo efibootmgr -v
```

当前本机编号：

```text
Boot0004: ubuntu
Boot0000: Windows Boot Manager
BootOrder: 0004,0000,0001,0002,0005,0006,0007
```

让 UEFI 先进入 Ubuntu shim/GRUB：

```bash
sudo efibootmgr -o 0004,0000,0001,0002,0005,0006,0007
```

如果想临时跳过 GRUB，固件默认直接进 Windows：

```bash
sudo efibootmgr -o 0000,0004,0001,0002,0005,0006,0007
```

不要照抄编号到其他机器，必须以 `efibootmgr -v` 的实际结果为准，并保留其他启动项的相对顺序。联想主机也可以开机按 `F11` 进入启动菜单。

## 切换默认系统

默认进 Windows：

```bash
GRUB_DEFAULT="Windows Boot Manager (on /dev/nvme0n1p1)"
```

默认进 Ubuntu：

```bash
GRUB_DEFAULT="Ubuntu"
```

修改 `/etc/default/grub` 后都要执行：

```bash
sudo update-grub
```

## 恢复 os-prober 自动生成 Windows 项

如果不想维护 `/etc/grub.d/06_windows`：

```bash
sudo rm /etc/grub.d/06_windows
sudo vim /etc/default/grub
```

设置：

```bash
GRUB_DISABLE_OS_PROBER=false
```

然后：

```bash
sudo update-grub
```
