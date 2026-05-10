# Node.js With fnm

`fnm` is installed in user scope. Binary location:

```text
~/.local/share/fnm/fnm
```

Notice:

- Use `fnm` for Node.js runtime management
- Keep Node.js versions managed in user space
- Use the project-local package manager workflow when possible

e.g.:

```bash
fnm list
fnm use --install-if-missing 24
node -v
npm -v
pnpm -v
```

Notes: `fnm` is initialized from the shell config, so a new shell should pick up the active Node.js version automatically

The pnpm mirror set:

```bash
pnpm config set registry https://registry.npmmirror.com
```

the cfg file is `~/.npmrc`
