# 双系统启动配置

这台机器是 `Windows + Ubuntu` 双系统。当前最终效果是：

- 正常开机默认进入 Windows
- GRUB 菜单显示 5 秒
- GRUB 顶层菜单顺序是 Windows -> Ubuntu -> Ubuntu advanced
- 需要时可以在 GRUB 菜单里手动选择 Ubuntu

当前实际 GRUB 菜单：

```text
0: Windows Boot Manager (on /dev/nvme0n1p1)
1: Ubuntu
submenu: Advanced options for Ubuntu
```

## 整体启动链路

这台机器的启动链路分 4 层：

1. `UEFI NVRAM BootOrder`
2. `EFI System Partition` 里的 EFI 程序
3. `GRUB` 菜单生成逻辑
4. `GRUB` 默认启动项

当前启动路径是：

```text
正常开机
-> UEFI 按 BootOrder 先进入 ubuntu
-> /EFI/ubuntu/shimx64.efi 启动
-> shim 进入 GRUB
-> GRUB 显示 5 秒菜单
-> 不手动选择时，默认进入 Windows Boot Manager
-> Windows 启动
```

这里要区分两个概念：

- 固件层面，`BootOrder` 第一项仍然是 `ubuntu`
- 用户可见的最终默认启动系统是 Windows

保留 `ubuntu` 作为 UEFI 第一项的原因是让机器先进入 GRUB。这样开机时既默认进 Windows，又保留一个稳定的 Ubuntu/Windows 选择菜单。

## EFI 配置

### 检查 UEFI 配置

当前 `efibootmgr -v` 的关键结果：

```text
BootCurrent: 0004
BootOrder: 0004,0000,0001,0002,0005,0006,0007
```

对应关系：

- `Boot0004`: `ubuntu`
- `Boot0000`: `Windows Boot Manager`
- `Boot0001`: `UEFI: PXE IPv4 Realtek PCIe GBE Family Controller`
- `Boot0002`: `UEFI: PXE IPv6 Realtek PCIe GBE Family Controller`
- `Boot0005`: `UEFI:CD/DVD Drive`
- `Boot0006`: `UEFI:Removable Device`
- `Boot0007`: `UEFI:Network Device`

检查命令：

```bash
sudo efibootmgr -v
```

如果要跳过 GRUB，让固件默认直接进入 Windows：

```bash
sudo efibootmgr -o 0000,0004,0001,0002,0005,0006,0007
```

恢复当前状态，也就是先进入 Ubuntu shim/GRUB：

```bash
sudo efibootmgr -o 0004,0000,0001,0002,0005,0006,0007
```

联想主机可以通过开机按 `F11` 进入 EFI/BIOS 启动菜单，并在 BIOS 中调整启动顺序。

### 检查 EFI 分区

当前 EFI 分区：

```text
/boot/efi
```

设备和 UUID：

```text
/dev/nvme0n1p1 143A-C1BE
```

`/etc/fstab` 中的配置：

```text
/dev/disk/by-uuid/143A-C1BE /boot/efi vfat defaults 0 1
```

关键 EFI 文件：

```bash
/boot/efi/EFI/ubuntu/shimx64.efi   # buntu 在 Secure Boot 场景里的第一入口
/boot/efi/EFI/ubuntu/grubx64.efi   # 是 GRUB EFI 程序
/boot/efi/EFI/ubuntu/grub.cfg      # 是 grub 配置
/boot/efi/EFI/Microsoft/Boot/bootmgfw.efi # 是 Windows Boot Manager 入口
/boot/efi/EFI/Microsoft/Boot/BCD          #  Windows 启动配置数据库
```

Ubuntu EFI 目录里的 `grub.cfg` 只是跳板，不是完整菜单。它会找到 Ubuntu 根分区，然后加载真正的 `/boot/grub/grub.cfg`。

检查 EFI fallback 文件：

```bash
sha256sum /boot/efi/EFI/Boot/bootx64.efi /boot/efi/EFI/ubuntu/shimx64.efi /boot/efi/EFI/Microsoft/Boot/bootmgfw.efi
```

如果 `/EFI/Boot/bootx64.efi` 和 `/EFI/ubuntu/shimx64.efi` 哈希相同，说明 fallback 路径也会进入 Ubuntu shim/GRUB。

## GRUB 配置

### GRUB 默认项配置

当前 `/etc/default/grub` 的关键配置：

```bash
GRUB_DEFAULT="Windows Boot Manager (on /dev/nvme0n1p1)"  # 这条指定默认启动 Windows
GRUB_TIMEOUT_STYLE=menu  # 表示显示 GRUB 菜单
GRUB_TIMEOUT=5           # 表示等待 5 秒
GRUB_DISABLE_OS_PROBER=true  # 表示不让 `30_os-prober` 自动生成 Windows 项，避免和自定义 Windows 项重复
```

使用标题字符串作为 `GRUB_DEFAULT`，建议不要使用数字索引。数字索引依赖菜单顺序，后续菜单变化时更容易跑偏。

检查命令：

```bash
grep -E '^GRUB_(DEFAULT|TIMEOUT_STYLE|TIMEOUT|DISABLE_OS_PROBER)=' /etc/default/grub
```

### GRUB 显示OS启动顺序

GRUB 顶层菜单顺序由 `/etc/grub.d/` 里的脚本文件名顺序决定，不由 `/etc/default/grub` 决定。

当前相关脚本和状态：

```bash
/etc/grub.d/06_windows        # 可执行，负责生成 Windows 第一项
/etc/grub.d/10_linux          # 可执行，负责生成 Ubuntu 和 Advanced options
/etc/grub.d/20_memtest86+     # 不可执行，不生成 memtest 菜单项(手工取消的可执行权限)
/etc/grub.d/30_os-prober      # 可执行，但因为 `GRUB_DISABLE_OS_PROBER=true`，不会生成 Windows 项
/etc/grub.d/30_uefi-firmware
```

检查生成后的菜单：

```bash
$ sudo awk -F"'" '/^menuentry /{print i++ ": " $2} /^submenu /{print "submenu: " $2}' /boot/grub/grub.cfg
0: Windows Boot Manager (on /dev/nvme0n1p1)
1: Ubuntu
submenu: Advanced options for Ubuntu
```

### 配置 Windows 作为首位

当前通过 `/etc/grub.d/06_windows` 手动生成 Windows 菜单项。 新增此文件，配置如下内容：

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

其中：

- `143A-C1BE` 是 EFI 分区 UUID
- `/EFI/Microsoft/Boot/bootmgfw.efi` 是 Windows Boot Manager
- `06_windows` 排在 `10_linux` 前面，所以 Windows 显示在 Ubuntu 前面

然后设置执行 可执行 权限。然后编辑 `/etc/default/grub`：

```bash
GRUB_DEFAULT="Windows Boot Manager (on /dev/nvme0n1p1)"
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
GRUB_DISABLE_OS_PROBER=true    # 这个改成了 true, 就是不让自动生成了，我们手工配置了 06_windows
```

最后重新生成 GRUB：

```bash
sudo update-grub
```

注：配置前可以先确认 EFI 分区 UUID 和 Windows Boot Manager 路径：

```bash
findmnt -no SOURCE,UUID /boot/efi
ls -l /boot/efi/EFI/Microsoft/Boot/bootmgfw.efi
```

不建议把 `/etc/grub.d/30_os-prober` 改名成 `06_os-prober`。那样会修改发行版包管理的脚本文件，GRUB 包升级时更容易被覆盖或引入重复项。

如果要取消 windows 作为首位，恢复由 `os-prober` 自动生成 Windows，按照如下操作即可：

```bash
sudo rm /etc/grub.d/06_windows
sudo vim /etc/default/grub
```

设置：

```bash
GRUB_DISABLE_OS_PROBER=false
```

然后重新生成 GRUB：

```bash
sudo update-grub
```

### 取消 memtest86+ 执行权限

配置 `/etc/grub.d/20_memtest86+` 不可执行, 让 GRUB 不生成 memtest 顶层菜单项。

```bash
sudo chmod -x /etc/grub.d/20_memtest86+
sudo update-grub
```

### 配置默认进入 Ubuntu

```bash
sudo vim /etc/default/grub
```

设置：

```text
GRUB_DEFAULT=1
```

然后重新生成 GRUB：

```bash
sudo update-grub
```

注意：当前菜单里 Ubuntu 是第 1 项，所以 `GRUB_DEFAULT=1` 表示默认进入 Ubuntu。

## 启动问题排查

启动结果不符合预期时，按这个顺序排查：

1. 检查 UEFI BootOrder
2. 检查 EFI fallback 文件
3. 检查 `/etc/default/grub`
4. 检查 `/etc/grub.d/` 脚本顺序和执行权限
5. 检查生成后的 `/boot/grub/grub.cfg`
6. 重新执行 `sudo update-grub`
