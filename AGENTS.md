# wm-config

Personal Linux development-environment configuration and maintenance scripts.

## Scope

- `dev/` documents shared development tooling.
- `ubuntu/` documents bare-metal Ubuntu Desktop setup.
- `update/` contains user-invoked maintenance scripts.
- Keep documentation aligned with the scripts and verified machine behavior.
- When a change makes `README.md` inaccurate or incomplete, update it in the same change.

## Node.js Environment

- Use `fnm` to manage Node.js versions and Corepack to select pnpm.
- Use pnpm for all user-global Node.js CLIs. Do not introduce npm-managed global packages.
- Update Codex with `pnpm install -g @openai/codex@latest`, not `codex update`.
- Do not use `sudo` for user-level tools or package-manager globals.

## Shell Scripts

- Keep `update/*.sh` narrowly scoped and fail fast on errors.
- Prefer explicit status labels when a script reports both a manager version and a managed-runtime version.
- Preserve Bash compatibility and keep shell lines at or below 120 characters.
- Long URLs, paths, commands, hashes, and identifiers are allowed only when wrapping them would make them
  less readable or change their meaning.

## Validation

- After editing a shell script, run `bash -n` on every touched script.
- Run `git diff --check` for every change.
- After editing `update/*.sh`, run:

  ```bash
  awk 'length($0) > 120 { print FILENAME ":" FNR ":" length($0) }' update/*.sh
  ```
