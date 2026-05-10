# tmux

`vim ~/.tmux.conf`

```bash
# Use vim keymap on copy mode, default emacs
setw -g mode-keys vi 

# Xshell select copy will not work when enable mouse
# you can use shift+select to copy
set -g mouse on

# For zsh and vim color  
set -g default-terminal "tmux-256color"
set -ga terminal-features 'xterm-256color:RGB'

# for nvim
set -sg escape-time 10
set -g focus-events on

# Move around panes with ALT + arrow keys
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Open current path when create new window
bind-key c new-window -c "#{pane_current_path}"
bind-key '"' split-window -c "#{pane_current_path}"
bind-key % split-window -h -c "#{pane_current_path}"

# Donot rename windows
setw -g allow-rename off
setw -g automatic-rename off

# Reorder window index when close a window
set -g renumber-windows on

# When switch panes, prefix+q prompt stay 5000ms
set -g display-panes-time 5000

set -g history-limit 65536

bind-key r source-file ~/.tmux.conf \; display-message "Tmux config reloaded!"
bind-key P command-prompt -p "save history to file:" -I "~/tmux.log" "capture-pane -S -65536; save-buffer %1; delete-buffer"
```
