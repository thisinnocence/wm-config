# Dev

## Python With uv

`uv` is installed in user scope.  Binary location:

```text
~/.local/bin/uv
```

Notice:

- Use `uv` for Python runtime management and project virtual environments
- Keep system Python untouched
- Keep project envs local to project directories (for example `.venv`)

e.g.:

```bash
uv python list
uv python install 3.12
uv venv --python 3.12
uv pip install -r requirements.txt
uv run python main.py
```

Notes:

- `uv` uses user-space caches and tools
- Prefer running Python work through `uv` in each project instead of system-wide `pip`

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
```

Verification result:

```text
Hi thisinnocence! You've successfully authenticated, but GitHub does not provide shell access.
```

Meaning:

- SSH GitHub clone and push traffic uses Clash Verge through SOCKS5
- GitHub authentication works with the generated SSH key

## Proxy Behavior

Clash Verge Rev is running locally and exposes a proxy listener on:

```text
127.0.0.1:7897
```

The current shell environment has proxy variables set automatically:

```text
HTTP_PROXY=http://127.0.0.1:7897
HTTPS_PROXY=http://127.0.0.1:7897
ALL_PROXY=socks://127.0.0.1:7897
http_proxy=http://127.0.0.1:7897
https_proxy=http://127.0.0.1:7897
all_proxy=socks://127.0.0.1:7897
NO_PROXY=localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,::1
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

## Apt Sources

The stale Ubuntu installer CD-ROM apt source was disabled because it caused `apt-get update` to fail.

Disabled file:

```text
/etc/apt/sources.list.d/cdrom.sources.disabled
```

Original source:

```text
/etc/apt/sources.list.d/cdrom.sources
```

Reason: The file:/cdrom repository no longer existed after installation.

Verification command: `bash sudo apt-get update`

## Sudo Timeout

Sudo was configured to remember authentication for 120 minutes.

Config file:

```text
/etc/sudoers.d/timeout
```

Content:

```text
Defaults timestamp_timeout=120
```

Validation command:

```bash
sudo visudo -cf /etc/sudoers.d/timeout
```

Validation result:

```text
/etc/sudoers.d/timeout: parsed OK
```

Meaning:

- After entering the sudo password once, sudo should not ask again for 120 minutes in that sudo timestamp context
- This is safer than full passwordless sudo

## Useful Verification Commands

```bash
zsh -ic 'echo plugins=$plugins'
ssh -T git@github.com
ssh -G github.com | rg -i 'proxycommand|identityfile|identitiesonly'
apt-config dump | rg -i 'Acquire::.*Proxy|proxy'
sudo apt-get update
sudo visudo -cf /etc/sudoers.d/timeout
```
