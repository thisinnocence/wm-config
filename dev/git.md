# Git

## Git account

```bash
git config --global user.name "your_name"
git config --global user.email "your_email@example.com"

# 建议使用 ed25519 算法生成 SSH key，安全性更高，且生成速度更快，更短的密钥长度
ssh-keygen -t ed25519 -C "your_email@example.com"
```

## Git config

`vim ~/.gitconfig`

```ini
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
[difftool]
    prompt = false
[core]
    editor = vim
[pager]
    diff = false
    branch = false
    log = false
```

参考： <https://snyk.io/blog/10-git-aliases-for-faster-and-productive-git-workflow>

## Git delta

`git delta` 是一个更现代化的 Git diff pager，提供更好的可读性和导航功能，可选安装：

通过 cargo 安装 `git delta`：

```bash
cargo install git-delta
```

在 `~/.gitconfig` 中添加以下配置：

```ini
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    side-by-side = true
    line-numbers = true

[merge]
    conflictstyle = zdiff3

[diff]
    colorMoved = default
```

说明：

- `pager = delta` 将 Git diff 输出通过 delta 进行分页显示，提供更好的格式化和颜色支持
- `interactive.diffFilter` 配置允许在交互式命令中使用 delta 的颜色输出
- `navigate = true` 允许在 diff 输出中使用键盘导航
- `side-by-side = true` 以并排方式显示 diff，便于比较
- `line-numbers = true` 显示行号，帮助定位修改位置
- `conflictstyle = zdiff3` 在合并冲突时使用更清
