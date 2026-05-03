# Dev

## Zsh


Powerlevel10k is used as the `Oh My Zsh` theme.

Plugin functions:

- `git`: Oh My Zsh Git aliases and Git completion helpers
- `zsh-autosuggestions`: shows gray command suggestions while typing, based on history and completions
- `zsh-syntax-highlighting`: highlights valid and invalid shell syntax while typing

Reload shell after changes: `exec zsh`

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

## Apt Sources

The stale Ubuntu installer CD-ROM apt source was disabled because it caused `apt-get update` to fail.

Disabled file: `/etc/apt/sources.list.d/cdrom.sources.disabled`

Use the Aliyun mirror for the main package repositories, while `resolute-security` still uses the official Ubuntu security source:

```text
URIs: https://mirrors.aliyun.com/ubuntu/
Suites: resolute resolute-updates resolute-backports

URIs: http://security.ubuntu.com/ubuntu/
Suites: resolute-security
```

No need use proxy for apt, check command:

```bash
apt-config dump | rg -i 'Acquire::.*Proxy|proxy'
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

## Git delta

`git delta` is configured as the global Git pager.

Current global config:

```ini
[core]
    pager = delta
[pager]
    diff = false
    log = false
[delta]
    navigate = true
    side-by-side = true
```

Meaning:

- `core.pager = delta`: use `delta` as the default pager for Git output
- `pager.diff = false`: do not force `git diff` through pager config, avoid double-pager conflicts
- `pager.log = false`: do not force `git log` through pager config, let `core.pager` handle normal cases
- `delta.navigate = true`: allow easier navigation in long diff output
- `delta.side-by-side = true`: show side-by-side diff when terminal width is enough

Check command:

```bash
git config --global --get-regexp '^delta\\.|^interactive\\.diffFilter$|^pager\\.(diff|log|reflog|show)$|^core\\.pager$'
```

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

## Node.js With fnm

`fnm` is installed in user scope. Binary location:

```text
~/.local/share/fnm/fnm
```

Notice:

- Use `fnm` for Node.js runtime management
- Keep Node.js versions managed in user space
- Use the project-local package manager workflow when possible

e.g.:

```bash
fnm list
fnm use --install-if-missing 24
node -v
npm -v
pnpm -v
```

Notes: `fnm` is initialized from the shell config, so a new shell should pick up the active Node.js version automatically

The pnpm mirror set:

```bash
pnpm config set registry https://registry.npmmirror.com
```

the cfg file is `~/.npmrc`
