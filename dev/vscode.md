# vscode

## WSL: `code .` 报 `Exec format error`

现象：

```bash
code .
# /mnt/c/Users/.../Microsoft VS Code/bin/code: .../Code.exe: Exec format error
```

这个错误通常不是 VS Code 配置坏了，而是当前 WSL 实例里的 Windows interop
运行态丢了。WSL 从 Linux 启动 `cmd.exe`、`Code.exe` 依赖
`/proc/sys/fs/binfmt_misc/WSLInterop` 这条注册规则；如果这条规则缺失，Linux
会把 Windows `.exe` 当成本机二进制执行，于是报 `Exec format error`。

先检查：

```bash
cmd.exe /c ver
ls -l /proc/sys/fs/binfmt_misc
cat /proc/sys/fs/binfmt_misc/WSLInterop
```

如果 `cmd.exe /c ver` 也报 `exec format error`，并且
`/proc/sys/fs/binfmt_misc/WSLInterop` 不存在，可以手动重新注册：

```bash
sudo sh -c "printf ':WSLInterop:M::MZ::/init:PF\n' > /proc/sys/fs/binfmt_misc/register"
```

验证：

```bash
cmd.exe /c ver
code --version
code .
```

如果重启 WSL 后复发，在 Windows PowerShell 里完整关闭 WSL 后再重新打开：

```powershell
wsl --shutdown
```

```jsonc
{
    // common
    "window.title": "${dirty}${activeEditorMedium}${separator}${rootName}${separator}${profileName}${separator}${appName}",
    "editor.rulers": [100, 120],
    "workbench.colorCustomizations": {
        "editorRuler.foreground": "#ffffff14"
    },
    "files.exclude": {
        "**/*.d": true,
        "**/*.o": true,
        "**/*.so": true,
        "**/*.out": true,
        "**/.cache": true,
        "**/__pycache__": true,
        "**/node_modules": true,
        "**/compile_commands.json": true,
    },

    // vim 
    "vim.handleKeys": {
        "<C-a>": false,
        "<C-b>": false,
        "<C-c>": false,
        "<C-f>": false,
        "<C-h>": false,
        "<C-i>": false,
        "<C-p>": false,
        "<C-s>": false,
        "<C-v>": false,
        "<C-w>": false,
        "<C-x>": false,
        "<C-z>": false,
    },
    "vim.leader": ",",
    "vim.easymotion": true,
    "vim.useSystemClipboard": false, // not use system clipboard
    "vim.incsearch": true,
    "vim.hlsearch": true,

    // font
    "editor.fontFamily": "'JetBrains Mono', 'Noto Sans Mono CJK SC', 'Microsoft YaHei', monospace",
    "editor.fontSize": 15,
    "editor.lineHeight": 21,
    "editor.fontLigatures": false,
    "terminal.integrated.fontFamily": "'JetBrains Mono', 'Noto Sans Mono CJK SC', monospace",
    "terminal.integrated.fontSize": 14,

    // clang-format
    "files.associations": {
        ".clang-format": "yaml"
    },

    // conflict with clangd
    "C_Cpp.intelliSenseEngine": "disabled",

    // ----------------- specific language settings -----------------
    // html
    "[html]": {
        "editor.tabSize": 2,
        "editor.insertSpaces": true,
        "editor.detectIndentation": false // 禁止自动检测缩进
    },
    // markdown
    "[markdown]": {
        "editor.wordWrap": "bounded",
        "editor.wordWrapColumn": 200,
        "editor.defaultFormatter": "DavidAnson.vscode-markdownlint"
    },
    "markdownlint.config": {
        "MD024": false, // https://github.com/DavidAnson/markdownlint/blob/v0.37.4/doc/md024.md
        "MD037": false,
        "MD046": false,
        "no-hard-tabs": false
    }
}
```
