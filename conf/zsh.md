# zsh

## Enable * wildcard

When using `grep key --include=*.c` in zsh, you may encounter zsh:
no matches found error. By default, zsh always automatically expands `*.`
To resolve this, add the following configuration to `~/.zshrc`:

`vim ~/.zshrc`

```bash
# pass * to cmd
setopt no_nomatch
```

## Reference

- [Solve "zsh: no matches found"](https://blog.csdn.net/qq_36148847/article/details/79260745)
