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

## 中文输入法

当前桌面中文输入法使用 `Fcitx5 + Pinyin`。

已安装的主要组件：

- `fcitx5`
- `fcitx5-chinese-addons`
- `fcitx5-pinyin`
- `fcitx5-config-qt`
- `fcitx5-frontend-all`

当前输入法框架：

```text
~/.xinputrc
run_im fcitx5
```

GNOME Wayland 下按 Fcitx 官方建议配置环境变量。

配置文件：

```text
~/.pam_environment
```

内容：

```text
XMODIFIERS	DEFAULT=@im=fcitx
QT_IM_MODULE	DEFAULT=fcitx
QT_IM_MODULES	DEFAULT=wayland;fcitx
```

同步配置文件：

```text
~/.config/environment.d/im-fcitx5.conf
```

内容：

```text
XMODIFIERS=@im=fcitx
QT_IM_MODULE=fcitx
QT_IM_MODULES=wayland;fcitx
```

Fcitx5 使用用户级 autostart 启动：

```text
~/.config/autostart/org.fcitx.Fcitx5.desktop
```

GNOME Wayland 下候选框位置依赖 `Kimpanel`，已安装并启用这个 GNOME Shell extension：

```text
~/.local/share/gnome-shell/extensions/kimpanel@kde.org
```

当前启用的 GNOME Shell extension 包含：

```text
kimpanel@kde.org
```

安装与切换命令：

```bash
sudo apt update
sudo apt install -y fcitx5 fcitx5-chinese-addons fcitx5-config-qt fcitx5-frontend-all
im-config -n fcitx5
cp /usr/share/applications/org.fcitx.Fcitx5.desktop ~/.config/autostart/org.fcitx.Fcitx5.desktop
```

安装 `Kimpanel`：

```bash
wget -O /tmp/kimpanel.shell-extension.zip 'https://extensions.gnome.org/review/download/69345.shell-extension.zip'
gnome-extensions install --force /tmp/kimpanel.shell-extension.zip
gnome-extensions enable kimpanel@kde.org
```

如果 `gnome-extensions enable` 在当前会话里找不到新扩展，可以先把它加入 enabled list，注销后重新登录：

```bash
gsettings get org.gnome.shell enabled-extensions
gsettings set org.gnome.shell enabled-extensions "['ding@rastersoft.com', 'ubuntu-dock@ubuntu.com', 'tiling-assistant@ubuntu.com', 'snapd-search-provider@canonical.com', 'web-search-provider@ubuntu.com', 'kimpanel@kde.org']"
```

登录后打开 `Fcitx 5 Configuration`，添加：

- `Pinyin`

完成后需要注销并重新登录。

验证命令：

```bash
printenv | rg '^(XMODIFIERS|QT_IM_MODULE|QT_IM_MODULES)='
gnome-extensions list --enabled | rg 'kimpanel'
pgrep -a fcitx5
```

期望结果：

```text
XMODIFIERS=@im=fcitx
QT_IM_MODULE=fcitx
QT_IM_MODULES=wayland;fcitx
kimpanel@kde.org
```

常用说明：

- 默认可用 `Ctrl+Space` 在中英文输入之间切换
- 如果登录后输入法没有正常启动，可以执行 `fcitx5 -rd`
