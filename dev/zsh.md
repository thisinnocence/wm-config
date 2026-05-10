# zsh

## Theme and plugins

Use Powerlevel10k  as the `Oh My Zsh` theme.

Plugin functions, add the following lines to `~/.zshrc`, the plugins section:

```bash
# Oh My Zsh plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)
```

- `git`: Oh My Zsh Git aliases and Git completion helpers
- `zsh-autosuggestions`: shows gray command suggestions while typing, based on history and completions
- `zsh-syntax-highlighting`: highlights valid and invalid shell syntax while typing

Reload shell after changes: `exec zsh`

## xterm

For tmux to support 256 colors, add the following line to `~/.zshrc`:

```bash
# echo $TERM to check, should be xterm-256color
export TERM=xterm-256color
```

## Enable * wildcard

When using `grep key --include=*.c` in zsh, you may encounter zsh:
no matches found error. By default, zsh always automatically expands `*.`
To resolve this, add the following configuration to `~/.zshrc`:

```bash
# pass * to cmd
setopt no_nomatch
```
