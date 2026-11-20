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

`update_nodejs_env.sh` checks fnm's latest GitHub release, the latest Node.js LTS, and registry `latest`
versions for Corepack, pnpm, existing global CLI packages, and dsh. Matching versions skip installation;
only differing versions are updated. Node.js stays on the LTS channel. Missing pnpm shims are still repaired,
and the fnm default is aligned with the selected LTS when needed. Release checks require network access.
The script then runs `codex --version`.
It stops if the Codex command is missing, resolves outside the user's home directory, or fails to start.
It also checks the separately managed Codex daemon. If its installed or running version differs, the script
copies and pins the current CLI package with `codex app-server daemon update --from-cli --yes`, then verifies
the versions match. Daemon sync runs after the other updates and can interrupt active Codex sessions.
If the daemon hosts the updater, sync runs in a separate process session and writes the result to the
printed log path so it can finish across the restart.
An absent daemon is left uninstalled. Matching versions do not trigger a daemon update.

The script also resolves the latest `@deepseek-ai/dsh`, prepares its isolated `pnpm dlx` cache, and
creates a `dsh` launcher in `pnpm bin -g`. The launcher uses the version selected by the last update; no shell
configuration or manually maintained version is needed. dsh is excluded from the global package list, though
upstream dependency warnings can still appear when its cache is installed or refreshed. When migrating an existing
global installation, first run `pnpm remove -g @deepseek-ai/dsh`; pnpm removes its whole installation group,
including any packages installed together with dsh.

Chrome and Clash Verge already compare installed versions with their APT candidate or latest GitHub release
before downloading/installing. The Python updater reuses uv's self-update dry-run and skips an up-to-date uv.
Python runtimes and uv tools use uv's native version/dependency checks without forced reinstalls.
The Rust updater checks stable and rustup releases first and adds only missing components. Cargo tools use
cargo-update's native registry/Git checks without forced rebuilds. Release-check failures stop the scripts.

`update_all.sh` runs `apt-get full-upgrade -y` and `apt-get autoremove -y`. Review the pending APT changes before using
it on a machine where automatic package removal is not acceptable.
