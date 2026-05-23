# Ubuntu 桌面配置

OS: Ubuntu 26.04 LTS

## Power 配置

### 电源配置

功耗模式用 `Settings -> Power -> Power Mode` 调成 `Balanced`，否则风扇容易太吵。

### 锁屏唤醒

如果 `Win + L` 锁屏后无法唤醒，先关闭 Mutter experimental features，注销重登后再测试：

```bash
gsettings set org.gnome.mutter experimental-features "[]"
gsettings get org.gnome.mutter experimental-features
```

这类问题通常是 `GNOME Wayland + NVIDIA + mutter` 的图形会话不稳定；如果仍复现，再排查 GNOME Extensions。

## 显示配置

### 分辨率和刷新率

分辨率、刷新率和显示缩放直接用 `Settings -> Displays` 调整：

- 显示器：`DP-3 PHL 27M2N5810`
- 分辨率：`3840x2160 @ 160Hz`
- 显示缩放：`125%`

### 字体配置

安装 CJK(Chinese/Japanese/Korean) 中文字体和 JetBrains Mono：

```bash
# install fonts
sudo apt install fonts-noto-cjk fonts-noto-cjk-extra
sudo apt install fonts-jetbrains-mono
fc-cache -fv

# check fonts
fc-match "Noto Sans CJK SC"
fc-match "Noto Serif CJK SC"
fc-match "JetBrains Mono"
```

- 系统中文 sans fallback：`Noto Sans CJK SC`
- 系统中文 serif fallback：`Noto Serif CJK SC`

字体渲染和缩放等直接用 `GNOME Tweaks -> Fonts` 调整：

- UI 字体：`Ubuntu Sans 11`
- 文档字体：`Sans 11`
- 等宽字体：`JetBrains Mono 11`
- Scaling Factor：`1.20`
- Hinting(字体微调/清晰度)：`Slight`，适合高 DPI 屏幕，字形更自然，不会被强行像素对齐得太硬
- Antialiasing(抗锯齿)：`rgba`，适合普通 LCD / LED 背光 LCD 显示器

```bash
# check fonts cfg
gsettings get org.gnome.desktop.interface font-name
gsettings get org.gnome.desktop.interface document-font-name
gsettings get org.gnome.desktop.interface monospace-font-name
gsettings get org.gnome.desktop.interface text-scaling-factor
gsettings get org.gnome.desktop.interface font-hinting
gsettings get org.gnome.desktop.interface font-antialiasing
```

## 中文输入法

当前桌面中文输入法使用 Fcitx5 + Pinyin：

sudo apt install -y fcitx5 fcitx5-chinese-addons fcitx5-config-qt fcitx5-frontend-all
im-config -n fcitx5

注销重登后打开 Fcitx 5 Configuration，添加 Pinyin。
如果列表中看不到 Pinyin，取消 Only Show Current Language 后再搜索。

GNOME Wayland 下，如果候选框位置异常或不跟随光标，可安装并启用 Kimpanel / Input Method Panel 类 GNOME 扩展。

当前候选框字体由 Kimpanel 单独控制，不完全跟随 GNOME Tweaks 的系统 UI 字体。
当前实际字体值：Noto Sans CJK SC 12。

如果候选框字体改大后只看到汉字、看不到拼音预编辑串，可在：
Fcitx 5 Configuration -> Global Options
中关闭 Client Preedit。

修改输入法配置后如果没有立即生效，可注销重登，或执行：
fcitx5 -r

常见问题：

- VS Code 建议使用 Microsoft 官方 .deb / apt 源版本，不建议使用 snap 版。
- Fcitx5 简繁转换快捷键可能占用 Ctrl+Shift+F，与 VS Code 全局搜索冲突，可在 Fcitx5 GUI 配置中修改或禁用。

## Ubuntu Dock

这里列出必须通过命令或配置方式处理的项。像 dock 位置、是否自动隐藏、是否 panel mode 这类常见选项，可以直接在 Ubuntu Desktop 的 GUI 设置里调整。

控制点击 dock 上应用图标时的行为。这个值不在 Ubuntu Desktop 的常规 GUI 设置里，需要命令配置：

```bash
# 配置 `minimize-or-previews` 含义：
#    - 如果应用当前只有一个活动窗口，点击后可以最小化
#    - 如果应用有多个窗口，点击后可以显示窗口预览
#    - 这种行为比 Ubuntu 默认设置更接近 macOS Dock
gsettings set org.gnome.shell.extensions.dash-to-dock click-action minimize-or-previews

# 检查当前的 `click-action`
gsettings get org.gnome.shell.extensions.dash-to-dock click-action

# 恢复 `click-action` 默认方法
gsettings reset org.gnome.shell.extensions.dash-to-dock click-action
```

## Flameshot 截图

使用 Flameshot 截图，在 `Settings -> Keyboard -> View and Customize Shortcuts -> Custom Shortcuts` 添加快捷键：

- 快捷键：`F1`
- 命令：`flameshot gui`

PS: `Flameshot` 的 `--pin` 在当前 `GNOME Wayland` 还不能很好的兼容。

## Ghostty 终端

选择 Ghostty 有如下原因：

- 原生 GUI 终端模拟器，Linux 下支持 `Wayland`
- 默认配置就能正常使用，不需要像传统终端那样额外调很多参数
- 适合替代 `gnome-terminal` 作为日常主终端
- 在 TUI 里可以贴图，方便使用 codex 等软件

配置文件 `~/.config/ghostty/config.ghostty` ，推荐配置：

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
