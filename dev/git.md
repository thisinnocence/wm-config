# Git

## 安装

安装 Git 和 SSH client：

```bash
sudo apt install git openssh-client
git --version
ssh -V
```

## 账号和 SSH

配置全局提交身份：

```bash
git config --global user.name "your_name"
git config --global user.email "your_email@example.com"
```

建议使用 `ed25519` 生成 SSH key，密钥更短，速度快，安全性好：

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

如果 SSH private key 设置了 passphrase，且桌面环境没有自动管理 SSH key，可以手动把 key 加到当前 shell 的
`ssh-agent`。这样输入一次 passphrase 后，本次登录会话里的 `git pull` / `git push` 不需要反复输入：

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

如果 SSH key 没有设置 passphrase，或系统已经通过桌面 keyring 自动管理 SSH key，可以跳过这一步。

复制 public key，并添加到 GitHub / Git server：

```bash
cat ~/.ssh/id_ed25519.pub
```

测试 GitHub SSH 连接：

```bash
ssh -T git@github.com
```

如果使用 Clash Verge 等本地代理，Git HTTPS 通常会读取 shell proxy variables；GitHub SSH 需要单独配置
`~/.ssh/config`，见 [ubuntu/proxy.md](../ubuntu/proxy.md)。

## 全局配置

`vim ~/.gitconfig`

基础配置：

```ini
[user]
    name = your_name
    email = your_email@example.com

[init]
    defaultBranch = master

[pull]
    rebase = true

[core]
    editor = vim

[alias]
    b = branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate
    d = diff
    f = fetch
    l = log --pretty=format:"%C(yellow)%h\\ %ad%Cred%d\\ %Creset%s%Cblue\\ [%an]" --decorate --date=short -12
    s = status
    br = branch -vv
    co = checkout
    cm = commit
    cane = commit --amend --no-edit

[diff]
    tool = vimdiff
    colorMoved = default

[difftool]
    prompt = false

[merge]
    conflictstyle = zdiff3

[pager]
    branch = false
    log = false
```

说明：

- `init.defaultBranch = master` 让新仓库默认分支名为 `master`
- `pull.rebase = true` 明确使用 rebase 方式处理 `git pull` 的分叉历史，避免 Git 每次提示选择策略
- `conflictstyle = zdiff3` 在冲突块中显示更多上下文，包括 base 版本，方便判断冲突来源
- `pager.branch = false` 和 `pager.log = false` 让短输出直接显示在 terminal 中
- 不设置 `pager.diff = false`，这样后续安装 delta 后，`git diff` 可以走 `core.pager = delta`

查看当前配置来源：

```bash
git config --global --list --show-origin
```

## delta diff pager

`delta` 是一个现代化的 Git diff pager，提供更好的可读性和导航功能。

通过 cargo 安装 `delta`：

```bash
cargo install git-delta
delta --version
```

在 `~/.gitconfig` 中添加：

```ini
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    side-by-side = true
    line-numbers = true
```

说明：

- `core.pager = delta` 将 Git diff 输出交给 delta 分页显示
- `interactive.diffFilter` 让交互式命令中的 diff 也保留颜色
- `navigate = true` 支持在 diff 输出中按文件跳转
- `side-by-side = true` 用并排方式显示 diff，适合宽屏 terminal
- `line-numbers = true` 显示行号，方便定位修改

如果没有安装 delta，又希望 `git diff` 不进入 pager，可以临时加：

```ini
[pager]
    diff = false
```

安装 delta 后建议移除 `pager.diff = false`。

## 常用 alias

```bash
git s       # git status
git b       # 按最近提交时间列出 branch
git br      # git branch -vv
git f       # git fetch
git d       # git diff
git l       # 最近 12 条简洁 log
git co      # git checkout
git cm      # git commit
git cane    # git commit --amend --no-edit
```

## 参考

- Git documentation: <https://git-scm.com/doc>
- Git config: <https://git-scm.com/docs/git-config>
- GitHub SSH keys: <https://docs.github.com/en/authentication/connecting-to-github-with-ssh>
- delta: <https://github.com/dandavison/delta>
