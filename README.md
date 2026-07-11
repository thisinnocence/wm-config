# wm-config

My personal Linux development environment configuration, setup notes, and maintenance scripts.

## Repository layout

- `dev/`: shared development-tool configuration and setup notes
- `ubuntu/`: bare-metal Ubuntu Desktop hardware, system, boot, and network notes
- `update/`: scripts for updating the system and user-level development environments
- [`AGENTS.md`](AGENTS.md): repository-specific guidance for coding agents

## Development configuration

| Tool    | Configuration                                  |
| ------- | ---------------------------------------------- |
| Vim     | <https://github.com/thisinnocence/vim>         |
| Git     | [dev/git.md](dev/git.md)                       |
| tmux    | [dev/tmux.md](dev/tmux.md)                     |
| Zsh     | [dev/zsh.md](dev/zsh.md)                       |
| VS Code | [dev/vscode.md](dev/vscode.md)                 |
| Node.js | [dev/nodejs.md](dev/nodejs.md)                 |
| Python  | [dev/python.md](dev/python.md)                 |

Because Vim configuration is somewhat complex, I maintain the Vim configuration in a separate code repository.

## Update scripts

Run update scripts individually according to the environment being maintained:

| Script | Purpose |
| --- | --- |
| [`update_all.sh`](update/update_all.sh) | Update Ubuntu packages and clean obsolete dependencies |
| [`update_chrome.sh`](update/update_chrome.sh) | Install or update Google Chrome Stable |
| [`update_clash_verge.sh`](update/update_clash_verge.sh) | Install or update the matching Clash Verge DEB package |
| [`update_nodejs_env.sh`](update/update_nodejs_env.sh) | Update the user-level `fnm + Corepack/pnpm` environment |
| [`update_python_env.sh`](update/update_python_env.sh) | Update the user-level `uv` Python environment |
| [`update_rust.sh`](update/update_rust.sh) | Update the user-level Rust toolchain and installed tools |

The scripts fail fast when their expected environment is not available. Read each script's header before running it.
System package scripts use `sudo`; user-level language environment scripts reject root execution and keep changes under
the current user's home directory.

`update_all.sh` runs `apt-get full-upgrade -y` and `apt-get autoremove -y`. Review the pending APT changes before using
it on a machine where automatic package removal is not acceptable.
