# Ubuntu / Windows Dual Boot 启动记录

这份文件记录这台台式机上 Ubuntu 与 Windows 双系统的启动菜单现状、推荐做法和对应命令。

## 当前实际情况

当前 UEFI BootOrder 里，`ubuntu` 在 `Windows Boot Manager` 前面。

当前 GRUB 顶层可见菜单顺序是：

1. `Ubuntu`
2. `Advanced options for Ubuntu`
3. `Memory test (mt86+x64)`
4. `Memory test (mt86+x64, serial console)`
5. `Windows Boot Manager (on /dev/nvme0n1p1)`
6. `UEFI Firmware Settings`

说明：

- `Windows` 出现在第 5 个，不是异常
- 前面多出来的两个 `test` 项来自 `/etc/grub.d/20_memtest86+`
- `Advanced options for Ubuntu` 是 Ubuntu 默认生成的 submenu，也会占一行

## 推荐做法

对这种个人台式机 `Windows + Ubuntu` 双系统，建议：

- 保留 `Ubuntu`
- 保留 `Advanced options for Ubuntu`
- 关闭 `memtest86+` 菜单生成
- 默认启动项用标题，不用数字

这样做的好处：

- 启动菜单更短，`Windows` 会提升到第 3 个
- `Advanced options for Ubuntu` 还在，内核回退能力保留
- 默认项用标题更稳，不会因为菜单顺序变化而失效
- 不需要手改 `grub.cfg` 生成逻辑，后续升级更稳

不建议为了让 `Windows` 变成第 2 个去硬改脚本顺序。那样通常要改 `/etc/grub.d/10_linux` 或自定义 GRUB 脚本，维护成本更高，也更容易被系统更新覆盖。

## 目标效果

关闭 `memtest86+` 后，顶层菜单通常会变成：

1. `Ubuntu`
2. `Advanced options for Ubuntu`
3. `Windows Boot Manager (on /dev/nvme0n1p1)`
4. `UEFI Firmware Settings`

如果还想默认进入 Windows，建议直接把默认项设成标题字符串：

```text
Windows Boot Manager (on /dev/nvme0n1p1)
```

## 配置步骤

### 1. 关闭 `memtest86+`

说明：

- `/etc/grub.d/20_memtest86+` 是 GRUB 的菜单生成脚本
- 它会添加 `Memory test` 项，用于排查内存条或内存稳定性问题
- 它不是 Ubuntu 或 Windows 正常启动所必需的
- 如果机器运行稳定、平时不做硬件排障，关闭它通常没有副作用

执行：

```bash
sudo chmod -x /etc/grub.d/20_memtest86+
sudo update-grub
```

执行后，`Windows` 通常会从第 5 个提升到第 3 个。

### 2. 把默认启动项设为 Windows

编辑：

```text
/etc/default/grub
```

把：

```text
GRUB_DEFAULT=0
```

改成：

```text
GRUB_DEFAULT="Windows Boot Manager (on /dev/nvme0n1p1)"
```

然后执行：

```bash
sudo update-grub
```

说明：

- 用标题比用数字更稳
- 以后即使菜单前面多了或少了别的项，默认项仍然会指向 Windows

### 3. 保持菜单可见 5 秒

当前这台机器已经是：

```text
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
```

这套值适合双系统台式机，不建议改成隐藏菜单。

## 验证方法

查看当前 GRUB 顶层菜单项：

```bash
sudo awk -F"'" '/^menuentry /{print i++ ": " $2} /^submenu /{print "submenu: " $2}' /boot/grub/grub.cfg
```

更接近屏幕实际顺序的检查方式：

```bash
sudo grep -E "^menuentry |^submenu " /boot/grub/grub.cfg
```

检查默认项：

```bash
grep ^GRUB_DEFAULT= /etc/default/grub
```

检查 `memtest86+` 是否已经禁用：

```bash
ls -l /etc/grub.d/20_memtest86+
```

如果没有执行权限，说明它不会再参与生成菜单。

## 回滚方法

如果以后想恢复 `memtest86+`：

```bash
sudo chmod +x /etc/grub.d/20_memtest86+
sudo update-grub
```

如果以后想恢复 Ubuntu 为默认启动项：

```text
GRUB_DEFAULT=0
```

然后执行：

```bash
sudo update-grub
```

## 实践建议

对个人台式机双系统，更稳妥的习惯通常是：

- 默认启动自己最常用的系统
- 另一个系统通过 GRUB 菜单进入
- 尽量不手改 `/boot/grub/grub.cfg`
- 尽量少改 `/etc/grub.d/` 的脚本内容本身
- 只调整启用状态和 `/etc/default/grub`

这比“强行把 Windows 调到第 2 个”更接近社区里的稳妥做法。
