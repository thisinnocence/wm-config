# Ubuntu 桌面配置

这份文件记录这台 Ubuntu GNOME Wayland 桌面上的用户级与系统级设置。

## 系统环境

```text
OS: Ubuntu 26.04 LTS
Desktop session: GNOME Wayland
User: michael
```

## 中文字体

```bash
sudo apt install fonts-noto-cjk fonts-noto-cjk-extra
fc-cache -fv
```

## Ubuntu Dock

这里仅保留必须通过命令或配置方式处理的项。像 dock 位置、是否自动隐藏、是否 panel mode 这类常见选项，可以直接在 Ubuntu Desktop 的 GUI 设置里调整，因此不再记录。

### `click-action`

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

### 恢复 Ubuntu 默认

如果想恢复 `click-action` 的默认值，可以执行：

```bash
gsettings reset org.gnome.shell.extensions.dash-to-dock click-action
```

如果 dock 没有立即更新： 注销后重新登录

## Flameshot 截图

当前使用 GNOME 自定义全局快捷键调用 `flameshot`。

快捷键：

- `F1`：截图

对应命令：

```text
F1 -> flameshot gui
```

GNOME custom keybindings：

```text
/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/
```

PS: `Flameshot` 的 `--pin` 在当前 `GNOME Wayland` 还不能很好的兼容。

## Codex CLI 贴图

在 GNOME Wayland 下，`Codex CLI` 的 TUI 粘贴图片功能依赖图形会话剪贴板访问。

遇到的问题：

```text
Failed to paste image: clipboard unavailable: Unknown error while interacting with the clipboard: X11 server connection timed out because it was unreachable
```

已安装的剪贴板工具：

- `wl-clipboard`
- `xclip`

根因：

- 当前 `codex` 会话跑在受限沙箱里，外层有 `bwrap`
- 虽然环境变量里有 `WAYLAND_DISPLAY` / `DISPLAY`，但沙箱内进程仍然无法连接桌面图形会话
- 结果是 `wl-copy` / `wl-paste` 和 `xclip` 都不可用，TUI 无法读取图片剪贴板

修复方式：

- 将 `~/.codex/config.toml` 的默认 sandbox 改为 `danger-full-access`
- 将默认 approval policy 改为 `never`
- 完全退出当前 `codex` 会话后重新启动

这组配置在效果上基本等价于在 `codex` 里使用 `/permissions full`：

- 不再使用受限工作区沙箱
- 可以访问工作区外文件
- 可以联网
- 更容易访问当前桌面图形会话的剪贴板和相关 socket

这种长期把默认值改成 `danger-full-access` 虽然方便，也可能触发模型误操作，暂时先这么配置。

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

常见问题：

- `VS Code` 如果用 `snap` 版，`GNOME Wayland + Fcitx5` 下输入法兼容性比 `.deb` 版更容易出问题
- `fcitx5-diagnose` 显示当前桌面环境里仍然混有 `IBus/XIM` 痕迹，因此 Electron 应用里的输入法行为可能不稳定
- `Fcitx5` 的简繁转换会绑定 `Ctrl+Shift+F`，这和 `VS Code` 默认全局搜索快捷键冲突

当前处理：

- 已移除 `~/.config/fcitx5/conf/chttrans.conf` 里的 `Ctrl+Shift+F` 热键
- 已移除 `snap` 版 `VS Code`
- 已安装官方 `.deb` 版 `VS Code`
- 当前 `code` 命令路径为 `/usr/share/code/bin/code`

