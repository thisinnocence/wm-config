# vscode

```json
{
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

    "editor.rulers": [120],

    // clang-format
    "files.associations": {
        ".clang-format": "yaml"
    },

    // conflict with clangd
    "C_Cpp.intelliSenseEngine": "disabled",

    // common exclude files    
    "files.exclude": {
        "**/*.d": true,
        "**/*.o": true,
        "**/*.so": true,
        "**/*.out": true,
        "**/.cache": true,
        "**/__pycache__": true,
        "**/compile_commands.json": true,
    }
}
```
