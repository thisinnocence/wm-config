# zsh

vim `~/.zshrc`

## xterm-256

```bash
export TERM=xterm-256color
```

Or just put tmux in plugin(). Use `echo $TERM` to check.

## Enable * wildcard

When using `grep key --include=*.c` in zsh, you may encounter zsh:
no matches found error. By default, zsh always automatically expands `*.`
To resolve this, add the following configuration to `~/.zshrc`:

```bash
# pass * to cmd
setopt no_nomatch
```

## Plugins

```bash
plugins=(
    git
    tmux

    # https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#oh-my-zsh
    zsh-autosuggestions

    # sudo apt install fzf first
    fzf

    # https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md#with-a-plugin-manager
    # Note: zsh-syntax-highlighting must be the last plugin sourced.
    zsh-syntax-highlighting
)

# https://github.com/zsh-users/zsh-completions
# Additional completions, add nextline before `source source $ZSH/oh-my-zsh.sh`
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

source $ZSH/oh-my-zsh.sh

```
