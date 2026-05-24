# zsh

## Theme 和 plugins

`Oh My Zsh` theme 使用 Powerlevel10k。

在 `~/.zshrc` 的 plugins 段落加入：

```bash
# Oh My Zsh plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)
```

- `git`: 提供 `Oh My Zsh` Git aliases 和 Git completion helpers
- `zsh-autosuggestions`: 根据 history 和 completions，在输入时显示灰色命令建议
- `zsh-syntax-highlighting`: 输入时高亮有效和无效的 shell syntax

修改后重新加载 shell：

```bash
exec zsh
```

## xterm

为了让 tmux 支持 256 colors，在 `~/.zshrc` 中加入：

```bash
# echo $TERM 检查，期望值是 xterm-256color
export TERM=xterm-256color
```

## 启用 `*` wildcard

在 zsh 中执行 `grep key --include=*.c` 这类命令时，可能遇到 `zsh: no matches found`。
这是因为 zsh 默认会尝试展开 `*` wildcard，如果当前目录下没有匹配项，就会直接报错。

如果希望把 `*` 原样传给命令处理，在 `~/.zshrc` 中加入：

```bash
# 把没有匹配到的 wildcard 原样传给命令
setopt no_nomatch
```
