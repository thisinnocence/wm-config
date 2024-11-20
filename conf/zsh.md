# zsh

## xterm-256

```bash
export TERM=xterm-256color
```

## Enable * wildcard

When using `grep key --include=*.c` in zsh, you may encounter zsh:
no matches found error. By default, zsh always automatically expands `*.`
To resolve this, add the following configuration to `~/.zshrc`:

`vim ~/.zshrc`

```bash
# pass * to cmd
setopt no_nomatch
```
## v2RayN proxy

v2RayN is a good proxy client tool. See:

<https://github.com/2dust/v2rayN>

`vim ~/.zshrc`

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

https://github.com/microsoft/WSL/issues/10753

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

## Reference

- <https://blog.csdn.net/qq_36148847/article/details/79260745>
- <https://zhuanlan.zhihu.com/p/414627975>
