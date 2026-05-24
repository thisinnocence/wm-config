# zsh

## 安装

安装 zsh：

```bash
sudo apt install zsh
zsh --version
```

设置 zsh 为当前用户默认 shell：

```bash
chsh -s "$(which zsh)"
```

修改默认 shell 后，需要注销重登，或重新打开登录 shell。

## Oh My Zsh

安装 `Oh My Zsh`：

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

本机 `Oh My Zsh` theme 使用 Powerlevel10k。安装 Powerlevel10k：

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
```

在 `~/.zshrc` 中配置 theme：

```bash
ZSH_THEME="powerlevel10k/powerlevel10k"
```

首次进入 zsh 时，Powerlevel10k 会启动交互式配置。后续需要重新配置时执行：

```bash
p10k configure
```

## Plugins

安装常用 plugins：

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
```

在 `~/.zshrc` 的 plugins 段落加入：

```bash
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)
```

- `git`: 提供 `Oh My Zsh` Git aliases 和 Git completion helpers
- `zsh-autosuggestions`: 根据 history 和 completions，在输入时显示灰色命令建议
- `zsh-syntax-highlighting`: 输入时高亮有效和无效的 shell syntax，建议放在 plugins 列表最后

修改后重新加载 shell：

```bash
exec zsh
```

## Shell 行为

在 zsh 中执行 `grep key --include=*.c` 这类命令时，可能遇到 `zsh: no matches found`。
这是因为 zsh 默认会尝试展开 `*` wildcard，如果当前目录下没有匹配项，就会直接报错。

如果希望把 `*` 原样传给命令处理，在 `~/.zshrc` 中加入：

```bash
# 把没有匹配到的 wildcard 原样传给命令
setopt no_nomatch
```

## TERM 和 tmux

不要在 `~/.zshrc` 里无条件设置 `TERM`。`TERM` 应由外层 terminal 或 tmux 设置，强行覆盖可能导致颜色、按键和 terminal capability 判断异常。

检查当前 terminal 类型：

```bash
echo $TERM
```

tmux true color 配置放在 [tmux.md](tmux.md) 中维护。

## 参考

- Oh My Zsh: <https://ohmyz.sh/>
- Powerlevel10k: <https://github.com/romkatv/powerlevel10k>
- zsh-autosuggestions: <https://github.com/zsh-users/zsh-autosuggestions>
- zsh-syntax-highlighting: <https://github.com/zsh-users/zsh-syntax-highlighting>
- zsh options: <https://zsh.sourceforge.io/Doc/Release/Options.html>
