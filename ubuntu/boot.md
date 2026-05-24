# 双系统启动配置

当前本机目标：

- UEFI 第一启动项是 `ubuntu`，让机器先进入 GRUB
- GRUB 菜单显示 5 秒
- GRUB 默认启动 Windows
- GRUB 菜单顺序是 Windows -> Ubuntu -> Ubuntu advanced

## 检查

```bash
# 查看 UEFI 启动项和 BootOrder
sudo efibootmgr -v

# 查看 EFI 分区设备、UUID、文件系统和挂载点
findmnt -no SOURCE,UUID,FSTYPE,TARGET /boot/efi

# 查看 GRUB 默认项、菜单显示方式、等待时间和 os-prober 状态
grep -E '^GRUB_(DEFAULT|TIMEOUT_STYLE|TIMEOUT|DISABLE_OS_PROBER)=' /etc/default/grub

# 查看自定义 Windows 菜单脚本是否可执行、memtest 是否已禁用
ls -l /etc/grub.d/06_windows /etc/grub.d/20_memtest86+

# 查看生成后的 GRUB 顶层菜单顺序
sudo awk -F"'" '/^menuentry /{print i++ ": " $2} /^submenu /{print "submenu: " $2}' /boot/grub/grub.cfg
```

当前关键值：

```bash
# EFI 分区挂载点、设备和 UUID
/boot/efi: /dev/nvme0n1p1, UUID=143A-C1BE

# Windows Boot Manager 在 EFI 分区内的路径
Windows Boot Manager: /EFI/Microsoft/Boot/bootmgfw.efi

# 自定义 GRUB Windows 菜单项标题，要和 GRUB_DEFAULT 保持一致
GRUB Windows entry: Windows Boot Manager (on /dev/nvme0n1p1)
```

## 配置 GRUB 默认进 Windows

为了让 GRUB 菜单里 Windows 固定排在 Ubuntu 前面，这里手动创建一个 `/etc/grub.d/06_windows`。
GRUB 生成菜单时会按 `/etc/grub.d/` 里的文件名顺序执行脚本，`06_windows` 会早于 `10_linux` 执行，
所以它生成的 Windows 菜单项会显示在 Ubuntu 前面。

这个菜单项不直接启动 Windows 分区，而是通过 `chainloader` 跳转到 EFI 分区里的 Windows Boot Manager：
`/EFI/Microsoft/Boot/bootmgfw.efi`。同时关闭 `os-prober`，避免 GRUB 再自动生成一个重复的 Windows 项。

创建 `/etc/grub.d/06_windows`：

```bash
sudo vim /etc/grub.d/06_windows
```

这个文件的作用：

- 给 GRUB 增加一个固定的 Windows 启动菜单项
- 通过 EFI 分区 UUID 找到正确的 EFI System Partition
- 通过 `chainloader` 跳转到 Windows Boot Manager
- 文件名以 `06_` 开头，让它排在 `10_linux` 前面执行，从而让 Windows 菜单项显示在 Ubuntu 前面

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
# 让 06_windows 可执行，update-grub 才会执行它并生成 Windows 菜单项
sudo chmod +x /etc/grub.d/06_windows

# 禁用 memtest 脚本，避免 GRUB 顶层菜单出现 memtest 项
sudo chmod -x /etc/grub.d/20_memtest86+

# 重新生成 /boot/grub/grub.cfg
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

不要照抄编号到其他机器，必须以 `efibootmgr -v` 的实际结果为准，并保留其他启动项的相对顺序。
联想主机也可以开机按 `F11` 进入启动菜单。

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
