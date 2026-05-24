# Ubuntu 桌面配置

OS: Ubuntu 26.04 LTS

## Power

功耗模式用 `Settings -> Power -> Power Mode` 调成 `Balanced`，避免风扇过于频繁拉高。

如果 `Win + L` 锁屏后无法唤醒，先关闭 Mutter experimental features，注销重登后测试：

```bash
gsettings set org.gnome.mutter experimental-features "[]"
gsettings get org.gnome.mutter experimental-features
```

## Display 和字体

显示设置用 `Settings -> Displays` 调整：

```text
Monitor: DP-3 PHL 27M2N5810
Resolution: 3840x2160 @ 160Hz
Scale: 125%
```

安装字体：

```bash
# CJK = Chinese / Japanese / Korean，用于中文、日文、韩文字体 fallback
# Noto 是 Google 的开源字体家族，Noto CJK 覆盖中日韩字符
sudo apt install fonts-noto-cjk fonts-noto-cjk-extra fonts-jetbrains-mono
fc-cache -fv
```

当前字体设置通过 `GNOME Tweaks -> Fonts` 调整：

```text
UI font: Ubuntu Sans 11
Document font: Sans 11
Monospace font: JetBrains Mono 11
Scaling Factor: 1.20
Hinting: Slight
Antialiasing: rgba
```

检查：

```bash
fc-match "Noto Sans CJK SC"
fc-match "JetBrains Mono"
gsettings get org.gnome.desktop.interface text-scaling-factor
```

## 中文输入法

安装 Fcitx5 + Pinyin：

```bash
sudo apt install -y fcitx5 fcitx5-chinese-addons fcitx5-config-qt fcitx5-frontend-all
im-config -n fcitx5
```

注销重登后打开 `Fcitx 5 Configuration`，添加 `Pinyin`。如果列表中看不到 Pinyin，取消 `Only Show Current Language` 后再搜索。

常见处理：

- GNOME Wayland 下候选框位置异常，可安装并启用 Kimpanel / Input Method Panel 类 GNOME extension
- 候选框字体由 Kimpanel 单独控制，当前使用 `Noto Sans CJK SC 12`
- 如果只看到汉字、看不到拼音预编辑串，在 `Fcitx 5 Configuration -> Global Options` 关闭 `Client Preedit`
- VS Code 全局搜索 `Ctrl+Shift+F` 如果被 Fcitx5 简繁转换占用，就在 Fcitx5 GUI 里修改或禁用该快捷键

重启 Fcitx5：

```bash
fcitx5 -r
```

## Ubuntu Dock

让点击 Dock 图标的行为更接近 macOS：单窗口时最小化，多窗口时显示预览。

```bash
gsettings set org.gnome.shell.extensions.dash-to-dock click-action minimize-or-previews
gsettings get org.gnome.shell.extensions.dash-to-dock click-action
```

恢复默认值：

```bash
gsettings reset org.gnome.shell.extensions.dash-to-dock click-action
```

## Flameshot

安装：

```bash
sudo apt install flameshot
```

在 `Settings -> Keyboard -> View and Customize Shortcuts -> Custom Shortcuts` 添加：

```text
Shortcut: F1
Command: flameshot gui
```

`Flameshot --pin` 在当前 GNOME Wayland 下兼容不好，不作为默认流程。

## Ghostty

配置文件：

```text
~/.config/ghostty/config.ghostty
```

当前配置：

```bash
# 窗口初始大小，单位是终端网格，不是像素
window-width = 180
window-height = 56

# Ubuntu 风格主题
theme = Ubuntu

# 光标用方块
cursor-style = block
cursor-style-blink = false
```

## VS Code

VS Code 建议使用 Microsoft 官方 `.deb` / apt 源版本，不建议使用 snap 版。
