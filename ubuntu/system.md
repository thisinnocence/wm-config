# Ubuntu 系统配置

## Sudo timeout

`sudo` 配置为记住认证状态 120 分钟。这比直接设置免sudo密码更安全。

配置 `sudo vim /etc/sudoers.d/timeout`, 添加以下内容：

```text
Defaults timestamp_timeout=120
```

校验命令：

```bash
$ sudo visudo -cf /etc/sudoers.d/timeout
/etc/sudoers.d/timeout: parsed OK
```

## Apt sources

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
