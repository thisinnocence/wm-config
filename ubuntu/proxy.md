# Proxy 配置

## Proxy 行为

*Clash Verge Rev* 在本机运行，默认提供监听 `127.0.0.1:7897`, 支持 HTTP、HTTPS 和 SOCKS5 代理协议。

默认中断 app 环境会自动设置 proxy variables，但使用 Ghostty terminal app 时，需要手动设置：

```bash
proxy() {
  export HTTP_PROXY="http://127.0.0.1:7897"
  export HTTPS_PROXY="http://127.0.0.1:7897"
  export ALL_PROXY="socks://127.0.0.1:7897"
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

默认行为：

- 很多CLI工具，如 curl、git(https) 会读取这些这些环境变量，自动走 Clash Verge 代理
- SSH 不会自动读取这些环境变量，所以 GitHub SSH 需要在 `~/.ssh/config` 里单独配置
- Apt 没有 apt-specific proxy config，所以 Ubuntu package 下载应直接走配置好的 mirror

## 针对 Github 的 SSH 代理

Github 的 SSH 已配置为使用本机 Clash Verge SOCKS5 proxy。SSH config 文件：

`vim ~/.ssh/config`

```yaml
Host github.com
  HostName github.com
  User git
  Port 22
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
  ProxyCommand nc -x 127.0.0.1:7897 -X 5 %h %p
```

验证命令：

```bash
ssh -T git@github.com
Hi thisinnocence! You've successfully authenticated, but GitHub does not provide shell access.
```

## Apt 源配置

旧的 Ubuntu installer CD-ROM apt source 已禁用，因为它会导致 `apt-get update` 失败。

已禁用文件：`/etc/apt/sources.list.d/cdrom.sources.disabled`

主软件源使用 Aliyun mirror，`resolute-security` 仍使用 Ubuntu 官方 security source：

```yaml
URIs: https://mirrors.aliyun.com/ubuntu/
Suites: resolute resolute-updates resolute-backports

URIs: http://security.ubuntu.com/ubuntu/
Suites: resolute-security
```

`apt` 有国内阿里的 mirror 后，不要再配置 proxy, 检查命令：

```bash
apt-config dump | rg -i 'Acquire::.*Proxy|proxy'
```
