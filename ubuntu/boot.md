# Dual Boot 启动配置记录

`Windows + Ubuntu` 双系统的启动，过程分 4 层：

1. `UEFI NVRAM BootOrder`
2. `EFI System Partition` 里的启动文件
3. `GRUB` 菜单生成逻辑
4. `GRUB` 默认启动项

这 4 层会一起决定“按下电源键后，最后进的是哪个系统”。

## 当前配置

当前是 Ubuntu 有限启动：

1. `UEFI BootOrder` 第一项是 `ubuntu`
2. `EFI fallback` 路径 `/EFI/Boot/bootx64.efi` 也是 Ubuntu 的 `shim`
3. `GRUB_TIMEOUT_STYLE=menu` 且 `GRUB_TIMEOUT=5`
4. `GRUB_DEFAULT="Windows Boot Manager (on /dev/nvme0n1p1)"`，进入 GRUB 后默认是 Windows

所以现在机器的整体行为是：

```text
正常开机
-> UEFI 先找 ubuntu
-> 进入 /EFI/ubuntu/shimx64.efi
-> shim 再进入 GRUB
-> GRUB 显示 5 秒菜单
-> 如果不选，默认进 Windows
```

联想 F11 进入 EFI/BIOS 后，在BIOS可以是设置启动配置顺序。

## 第一层：UEFI 在决定先找谁

如果只看 GRUB 菜单，很容易误以为“启动顺序全由 GRUB 决定”。其实第一跳不是 GRUB，而是主板固件。

当前 `efibootmgr -v` 的关键结果是：

- `BootCurrent: 0004`
- `BootOrder: 0004,0000,0001,0002,0005,0006,0007`

对应关系：

- `Boot0004`: `ubuntu`
- `Boot0000`: `Windows Boot Manager`
- `Boot0001`: `UEFI: PXE IPv4 Realtek PCIe GBE Family Controller`
- `Boot0002`: `UEFI: PXE IPv6 Realtek PCIe GBE Family Controller`
- `Boot0005`: `UEFI:CD/DVD Drive`
- `Boot0006`: `UEFI:Removable Device`
- `Boot0007`: `UEFI:Network Device`

这里最重要的信息只有两条：

- 当前主板优先启动 `ubuntu`
- 这次开机实际也是从 `ubuntu` 启动的

另外，这台机器当前没有 `BootNext`。这表示没有设置“一次性只在下次启动时生效”的临时目标，开机行为完全受 `BootOrder` 控制。

补充：Windows 点“更新并重启”时，通常会先把下一次启动改到自己的启动链路里。做法可能是临时改 `BootNext`，也可能由 Windows Boot Manager/BCD 接管后续流程，所以这类重启不等同于一次普通冷启动，通常不会被当前 `BootOrder` 直接打断。

检查命令：

```bash
efibootmgr -v
```

如果以后想临时只让下次进 Windows：

```bash
sudo efibootmgr -n 0000
```

如果想把 Windows 永久提到 UEFI 第一顺位：

```bash
sudo efibootmgr -o 0000,0004,0001,0002,0005,0006,0007
```

如果想恢复 Ubuntu 第一顺位：

```bash
sudo efibootmgr -o 0004,0000,0001,0002,0005,0006,0007
```

## 第二层：EFI 分区里到底放了什么

UEFI 读到的不是 Linux 文件系统里的 `/boot/grub/grub.cfg`，而是 EFI 分区里的 `.efi` 文件。

这台机器当前的 EFI 分区挂载在：

```text
/boot/efi
```

`/etc/fstab` 里的实际配置是：

```text
/dev/disk/by-uuid/143A-C1BE /boot/efi vfat defaults 0 1
```

也就是说，Ubuntu 和 Windows 的启动入口都放在这一块 EFI System Partition 里。

当前最关键的文件是这几组：

Ubuntu：

```text
/boot/efi/EFI/ubuntu/shimx64.efi
/boot/efi/EFI/ubuntu/grubx64.efi
/boot/efi/EFI/ubuntu/grub.cfg
```

Windows：

```text
/boot/efi/EFI/Microsoft/Boot/bootmgfw.efi
/boot/efi/EFI/Microsoft/Boot/BCD
```

可以这样理解：

- `shimx64.efi` 是 Ubuntu 在 Secure Boot 场景里最常见的第一入口
- `grubx64.efi` 才是真正的 GRUB EFI 程序
- `bootmgfw.efi` 是 Windows Boot Manager 的入口
- `BCD` 是 Windows 自己的启动配置数据库

Ubuntu 那个 EFI 目录里的 `grub.cfg` 不是完整菜单，它只是一个跳板，内容核心是：

```text
search.fs_uuid 057adfa3-11d6-4cdf-9cd6-f74537e7efe6 root
set prefix=($root)'/boot/grub'
configfile $prefix/grub.cfg
```

它的作用是：

- 先找到 Ubuntu 的根分区
- 再去加载真正的 `/boot/grub/grub.cfg`

## 第三层：为什么 fallback 也会影响最终启动结果

很多文章只讲 `BootOrder`，但实际维护时，`EFI fallback` 路径也很重要。

标准 fallback 路径是：

```text
/boot/efi/EFI/Boot/bootx64.efi
```

这台机器当前还有：

```text
/boot/efi/EFI/Boot/mmx64.efi
/boot/efi/EFI/Boot/fbx64.efi
```

关键点在于：这台机器的

- `/EFI/Boot/bootx64.efi`
- `/EFI/ubuntu/shimx64.efi`

哈希相同。

这表示：

- `bootx64.efi` 现在其实就是 Ubuntu 的 `shim`

所以如果将来遇到下面这些情况：

- 主板忽略了 NVRAM 启动项
- 某次固件升级重置了启动顺序
- 主板重新扫描 EFI 分区后走默认 fallback 路径

机器依然很可能先进入 Ubuntu，而不是直接进 Windows。

这个设计的好处是恢复能力更强：只要 Ubuntu 还能进，就可以从 Linux 侧直接修 `BootOrder`、重跑 `update-grub`，或者检查 EFI 分区里的启动文件。

检查命令：

```bash
sha256sum /boot/efi/EFI/Boot/bootx64.efi /boot/efi/EFI/ubuntu/shimx64.efi /boot/efi/EFI/Microsoft/Boot/bootmgfw.efi
```

对这台机器来说，这一层是个很关键但又很容易被忽略的细节。

## 第四层：GRUB 菜单和默认项

当 UEFI 已经进入 Ubuntu 的 `shim` 之后，接下来才轮到 GRUB 决定显示什么菜单、默认选哪一项。

当前 `/etc/default/grub` 的关键值是：

```text
GRUB_DEFAULT="Windows Boot Manager (on /dev/nvme0n1p1)"
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
GRUB_DISABLE_OS_PROBER=false
```

含义分别是：

- `GRUB_DEFAULT="Windows Boot Manager (on /dev/nvme0n1p1)"`：默认启动 Windows 启动项
- `GRUB_TIMEOUT_STYLE=menu`：显示 GRUB 菜单
- `GRUB_TIMEOUT=5`：等待 5 秒
- `GRUB_DISABLE_OS_PROBER=false`：允许探测 Windows 并为它生成启动项

这台机器当前实际菜单顺序已经验证过：

```text
0: Ubuntu
submenu: Advanced options for Ubuntu
1: Windows Boot Manager (on /dev/nvme0n1p1)
```

你也可以用数字来代替字符串配置 GRUB_DEFULT, 但是建议用字符串，更加稳定。

检查命令：

```bash
sudo awk -F"'" '/^menuentry /{print i++ ": " $2} /^submenu /{print "submenu: " $2}' /boot/grub/grub.cfg
```

这里要特别分清两件事：

- `UEFI BootOrder` 决定先进入哪个 EFI 程序
- `GRUB_DEFAULT` 决定进入 GRUB 后默认启动谁

这不是一个层级的问题。

如果只是想“开机后等 5 秒给我选 Ubuntu 还是 Windows”，最稳的是让 GRUB 来做，不要指望 UEFI 固件一定支持同样的等待和选择逻辑。主板有些会提供 `Boot Delay` 之类选项，但那通常只是 POST 延迟，不等于完整的启动菜单选择。

## 关闭 memtest86+

把 `/etc/grub.d/20_memtest86+` 关掉了，所以 GRUB 顶层菜单从原来的 5 项调整成了 3 项，`Windows Boot Manager` 也从第 5 个提前到了第 3 个。

```bash
sudo chmod -x /etc/grub.d/20_memtest86+
sudo update-grub
```

这次调整的核心原因很简单：

- `memtest86+` 只用于内存排障
- 日常双系统开机基本用不上
- 去掉它以后，菜单更短，Windows 位置也更靠前

这台机器当前的 GRUB 与菜单生成最相关的是：

- `/etc/grub.d/10_linux`
- `/etc/grub.d/30_os-prober`
- `/etc/grub.d/30_uefi-firmware`

## 如果想默认进 Windows

编辑：

```text
/etc/default/grub
```

把：

```text
// 原来：
GRUB_DEFAULT=0
// 改成：
GRUB_DEFAULT="Windows Boot Manager (on /dev/nvme0n1p1)"
// 更新：
sudo update-grub
```

原因很直接：菜单顺序以后可能变化，但标题字符串更稳。

## 如果默认还是 Ubuntu

保持：

```text
GRUB_DEFAULT=0
sudo update-grub
```

## 排查启动问题

如果以后遇到“为什么这次没有进我预期的系统”，我通常按这个顺序检查：

### 1. 先看 UEFI 层

```bash
efibootmgr -v
```

看：

- `BootOrder`
- `BootCurrent`
- 有没有 `BootNext`

### 2. 再看 fallback 路径是不是还指向 Ubuntu

```bash
sha256sum /boot/efi/EFI/Boot/bootx64.efi /boot/efi/EFI/ubuntu/shimx64.efi /boot/efi/EFI/Microsoft/Boot/bootmgfw.efi
```

### 3. 再看 GRUB 默认项

```bash
grep ^GRUB_DEFAULT= /etc/default/grub
```

### 4. 再看 GRUB 菜单到底是怎么生成的

```bash
sudo grep -E "^menuentry |^submenu " /boot/grub/grub.cfg
```

或者：

```bash
sudo awk -F"'" '/^menuentry /{print i++ ": " $2} /^submenu /{print "submenu: " $2}' /boot/grub/grub.cfg
```

### 5. 改完配置后别忘了重生成 GRUB

```bash
sudo update-grub
```

## 回滚方法

如果以后想恢复 `memtest86+`：

```bash
sudo chmod +x /etc/grub.d/20_memtest86+
sudo update-grub
```

如果以后想把 Ubuntu 放回 UEFI 第一顺位：

```bash
sudo efibootmgr -o 0004,0000,0001,0002,0005,0006,0007
```

或者开机 F11 进入 BIOS 手动调整。

## 常见问题

### `grubenv` 为什么会突然坏

`grubenv` 是 GRUB 用来记录启动状态的小环境块。如果上一次写入被打断，或者 GRUB 相关更新/关机流程没有正常结束，它就可能变成 `invalid environment block`。这类问题通常重建文件就能恢复，不是 `BootOrder` 本身坏了。

## 经验

对个人双系统台式机，先分清楚哪层影响：

- 改 UEFI 第一项
- 改 EFI fallback
- 改 GRUB 菜单生成
- 改 GRUB 默认项

一旦层次清楚，双系统启动再针对性调整。
