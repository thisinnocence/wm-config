# Python With uv

`uv` is installed in user scope.  Binary location:

```text
~/.local/bin/uv
```

Notice:

- Use `uv` for Python runtime management and project virtual environments
- Keep system Python untouched
- Keep project envs local to project directories (for example `.venv`)

e.g.:

```bash
uv python list
uv python install 3.12
uv venv --python 3.12
uv pip install -r requirements.txt
uv run python main.py
```

Notes:

- `uv` uses user-space caches and tools
- Prefer running Python work through `uv` in each project instead of system-wide `pip`
