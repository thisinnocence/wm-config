# vscode

```js
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
    }

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
