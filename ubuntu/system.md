# Ubuntu System

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
