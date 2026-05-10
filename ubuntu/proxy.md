# Proxy

## Proxy Behavior

*Clash Verge Rev* is running locally and exposes a proxy listener on:

```text
127.0.0.1:7897
```

The current shell environment has proxy variables set automatically, but when use Ghostty term app, should set mannually:

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

Expected behavior:

- `curl`, Git HTTPS, and many CLI tools can use these proxy environment variables
- SSH does not automatically use these variables, so GitHub SSH is configured separately in `~/.ssh/config`
- Apt has no apt-specific proxy config, so Ubuntu package downloads should go directly to the configured mirror

Checked apt proxy config, just use Aliyun mirror:

```text
No Acquire::http::Proxy
No Acquire::https::Proxy
```

Current intended routing:

```text
GitHub SSH: through Clash Verge SOCKS5
General shell tools: can use Clash Verge from proxy env
Apt Ubuntu packages: direct to Aliyun mirror
```

## SSH And GitHub

GitHub SSH was configured to use the local Clash Verge SOCKS5 proxy. SSH config file:

```text
~/.ssh/config
```

Config:

```sshconfig
Host github.com
  HostName github.com
  User git
  Port 22
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
  ProxyCommand nc -x 127.0.0.1:7897 -X 5 %h %p
```

Verification command:

```bash
ssh -T git@github.com
Hi thisinnocence! You've successfully authenticated, but GitHub does not provide shell access.
```
