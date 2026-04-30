# Ubuntu 桌面配置

这份文件记录这台 Ubuntu GNOME Wayland 桌面上的用户级与系统级设置。

## 系统环境

```text
OS: Ubuntu 26.04 LTS
Desktop session: GNOME Wayland
User: michael
```

## Ubuntu Dock

这里仅保留必须通过命令或配置方式处理的项。像 dock 位置、是否自动隐藏、是否 panel mode 这类常见选项，可以直接在 Ubuntu Desktop 的 GUI 设置里调整，因此不再记录。

#### `click-action`

控制点击 dock 上应用图标时的行为。这个值不放在 Ubuntu Desktop 的常规 GUI 设置里，因此保留命令配置方式。

当前值：`minimize-or-previews`。含义：

- 如果应用当前只有一个活动窗口，点击后可以最小化
- 如果应用有多个窗口，点击后可以显示窗口预览
- 这种行为比 Ubuntu 默认设置更接近 macOS Dock

设置命令：

```bash
gsettings set org.gnome.shell.extensions.dash-to-dock click-action minimize-or-previews
```

运行下面这个命令可以检查当前的 `click-action`：

```bash
gsettings get org.gnome.shell.extensions.dash-to-dock click-action
```

### 恢复 Ubuntu 默认样式

如果想恢复 `click-action` 的默认值，可以执行：

```bash
gsettings reset org.gnome.shell.extensions.dash-to-dock click-action
```

如果 dock 没有立即更新： 注销后重新登录
