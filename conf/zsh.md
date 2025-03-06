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
## v2RayN proxy

v2RayN is a good proxy client tool. See:

<https://github.com/2dust/v2rayN>

```bash
export host_ip=$(ip route | grep default | awk '{print $3}')

# check port on v2RayN status line 
export sock_port=10808
export http_port=10809

alias proxy='
    export HTTPS_PROXY="socks5://${host_ip}:${sock_port}";
    export HTTP_PROXY="socks5://${host_ip}:${sock_port}";
    echo "set proxy ok!"
    echo "  $HTTP_PROXY"
    echo "  $HTTPS_PROXY"
'
alias unproxy='
    unset HTTPS_PROXY;
    unset HTTP_PROXY;
    echo "unset proxy ok!"
'
```

If use WLS2 Ubuntu, you can also do:

<https://github.com/microsoft/WSL/issues/10753>

> 1. Open or create the wsl configuration file (located at %USERPROFILE%\.wslconfig), and enter the following content:

```ini
[experimental]
autoMemoryReclaim=gradual  # gradual  | dropcache | disabled
networkingMode=mirrored
dnsTunneling=true
firewall=true
autoProxy=true
```

> 2. Open the command prompt and execute `wsl --shutdown`

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

## Reference

- <https://blog.csdn.net/qq_36148847/article/details/79260745>
- <https://zhuanlan.zhihu.com/p/414627975>

