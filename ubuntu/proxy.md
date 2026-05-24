# Proxy 配置

这是可选配置。当前本机使用 Clash Verge Rev，监听 `127.0.0.1:7897`，支持 HTTP、HTTPS 和 SOCKS5。

## Shell proxy

部分终端 app 会自动继承 proxy variables；Ghostty 里需要时可以手动开启：

下面配置可以加入 `~/.zshrc`，需要代理时执行 `proxy`，不需要时执行 `unproxy`。

```bash
proxy() {
  export HTTP_PROXY="http://127.0.0.1:7897"
  export HTTPS_PROXY="http://127.0.0.1:7897"
  export ALL_PROXY="socks5://127.0.0.1:7897"
  export http_proxy="$HTTP_PROXY"
  export https_proxy="$HTTPS_PROXY"
  export all_proxy="$ALL_PROXY"
  export NO_PROXY="localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,::1"
  export no_proxy="$NO_PROXY"
  echo "Proxy enabled: 127.0.0.1:7897"
}

unproxy() {
  unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
  unset http_proxy https_proxy all_proxy
  unset NO_PROXY no_proxy
  echo "Proxy disabled"
}
```

说明：

- `curl`、Git HTTPS 等 CLI 会读取这些环境变量
- SSH 不会读取这些变量，GitHub SSH 需要单独配置
- apt 当前不配置 proxy，直接使用 mirror

## GitHub SSH proxy

安装 OpenBSD netcat：

```bash
# netcat-openbsd 提供 nc 命令，SSH ProxyCommand 用它连接 Clash Verge 的 SOCKS5 proxy
sudo apt install netcat-openbsd
```

编辑 `~/.ssh/config`：

```sshconfig
Host github.com
  HostName github.com
  User git
  Port 22
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
  ProxyCommand nc -x 127.0.0.1:7897 -X 5 %h %p
```

验证：

```bash
ssh -T git@github.com
```

成功时会看到：

```text
Hi thisinnocence! You've successfully authenticated, but GitHub does not provide shell access.
```

## apt source

旧的 installer CD-ROM source 已禁用：

```text
/etc/apt/sources.list.d/cdrom.sources.disabled
```

当前 Ubuntu source 使用 Aliyun mirror，security source 保持 Ubuntu 官方：

```text
URIs: https://mirrors.aliyun.com/ubuntu/
Suites: resolute resolute-updates resolute-backports

URIs: http://security.ubuntu.com/ubuntu/
Suites: resolute-security
```

检查 apt 没有 proxy：

```bash
apt-config dump | rg -i 'Acquire::.*Proxy|proxy'
```
