# tmux

## 个人配置

本机使用 `tmux` 管理长期终端会话、窗口和 pane。配置目标：

- 保留默认 prefix，降低和远程环境、服务器环境的差异
- 使用 vim 风格 copy mode
- 支持鼠标、true color、nvim focus event
- 新建 window 和 pane 时继承当前路径
- 提供快速 reload 和保存 pane history 的快捷键

## 安装和检查

```bash
sudo apt install tmux
tmux -V
```

当前本机版本：

```text
tmux 3.6
```

编辑配置：

```bash
vim ~/.tmux.conf
```

修改后可在 tmux 内执行：

```bash
tmux source-file ~/.tmux.conf
```

也可以使用本文配置里的 `prefix + r` 重新加载。

## `~/.tmux.conf`

```bash
# Use vim key bindings in copy mode, default is emacs
setw -g mode-keys vi

# Xshell select copy will not work when mouse is enabled
# Use Shift + select to copy from the terminal directly
set -g mouse on

# For zsh, vim, and nvim true color
set -g default-terminal "tmux-256color"
set -as terminal-features ',xterm-256color:RGB'

# For nvim
set -sg escape-time 10
set -g focus-events on

# Move around panes with Alt + arrow keys
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Open new windows and panes in current path
bind-key c new-window -c "#{pane_current_path}"
bind-key '"' split-window -c "#{pane_current_path}"
bind-key % split-window -h -c "#{pane_current_path}"

# Do not rename windows automatically
setw -g allow-rename off
setw -g automatic-rename off

# Reorder window index when closing a window
set -g renumber-windows on

# Keep prefix + q pane numbers visible for 5000ms
set -g display-panes-time 5000

# Keep more scrollback history in each pane
set -g history-limit 65536

# Reload config
bind-key r source-file ~/.tmux.conf \; display-message "Tmux config reloaded!"

# Save current pane history to a file, default file is ~/tmux.log
bind-key P command-prompt -p "save history to file:" -I "~/tmux.log" "capture-pane -S -65536; save-buffer %1; delete-buffer"
```

## 常用快捷键

这里的 `prefix` 是 tmux 默认的 `Ctrl+b`。

```text
Alt + Arrow   切换 pane
prefix + c    新建 window，继承当前路径
prefix + "    上下分割 pane，继承当前路径
prefix + %    左右分割 pane，继承当前路径
prefix + q    显示 pane 编号
prefix + r    重新加载 ~/.tmux.conf
prefix + P    保存当前 pane history 到文件
```

`prefix + P` 适合在排查问题、保存命令输出或记录远程会话现场时使用。默认文件是 `~/tmux.log`，执行时可以在提示里改成其他路径。

## true color 检查

外层终端的 `$TERM` 会影响 tmux 的 true color 判断。当前配置假设外层终端使用 `xterm-256color` 兼容能力。

在 tmux 外检查：

```bash
echo $TERM
infocmp tmux-256color
```

在 tmux 内检查：

```bash
echo $TERM
tmux info | grep RGB
```

如果外层终端不是 `xterm-256color`，需要按实际 `$TERM` 调整：

```bash
set -as terminal-features ',<TERM>:RGB'
```

例如 Ghostty、VS Code terminal 或其他终端里，如果 `$TERM` 不同，就把 `<TERM>` 换成 `echo $TERM` 的结果。
