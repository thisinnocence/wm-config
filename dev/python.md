# Python 环境

## uv 方案

Python 官方和社区有多种环境管理方式，如系统包管理器、`venv + pip`、`pyenv`、`pipx`、`poetry`、`conda` 等。
本环境选择 `uv`，主要是为了用一个用户级工具管理 Python runtime、项目 `.venv`、依赖锁定和用户级 CLI。

原则：

- 使用 `uv` 管理 Python runtime 和项目级虚拟环境
- 保持 System Python 不被直接污染，不使用 `sudo pip install`
- 项目环境保留在项目目录内，如 `.venv`
- 新项目优先使用 `pyproject.toml + uv.lock`，旧项目再使用 `requirements.txt`
- 跨项目通用 CLI 用 `uv tool install`，项目专用开发工具放到项目 dev dependencies

为什么选用 `uv` 呢？

- `uv` 用 Rust 开发，依赖解析、安装和虚拟环境创建速度快，适合频繁创建和切换项目环境的个人开发机
- `uv` 可以替代 `pip`、`venv`、`pip-tools`、`pipx` 和部分 `pyenv` 工作流，减少 Python 工具链碎片化
- `uv` 可以自动下载和管理 Python runtime，让项目不依赖系统 Python 版本
- `uv` 默认使用项目 `.venv`，可以把项目依赖和用户级 CLI 分开维护
- `uv.lock` 适合新项目固定依赖解析结果，比只维护宽松的 `requirements.txt` 更可复现

## 安装和更新 `uv`

安装 `uv`：

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

安装后确认 `uv` 在当前用户 PATH 中：

```bash
which uv
uv --version
```

如果 `uv` 不在 PATH 中，重新打开 shell，或执行：

```bash
source ~/.zshrc
```

更新 `uv`：

```bash
uv self update
```

## Python 版本管理

截至 2026-05，Python 3.14 和 3.13 处于 bugfix/stable 维护阶段，Python 3.12 已进入 security 维护阶段。
新项目优先使用当前 bugfix/stable 分支，如 `3.14` 或 `3.13`；旧项目按项目要求使用对应版本。

常用命令：

```bash
uv python find                      # 查找当前 uv 会使用的 Python
uv python list                      # 列出可用 Python；默认包含已安装版本和可下载版本
uv python list --only-installed     # 只列出已安装的 Python 版本
uv python install 3.14              # 安装指定 Python version 到用户目录
uv python pin 3.14                  # 把当前项目的 Python version 写到 .python-version
uv python pin --global 3.14         # 把用户级默认 Python version 写到 ~/.config/uv/.python-version
```

如果希望直接在 shell 中执行 `python` 时使用 uv 管理的 Python，可更新 shell PATH：

```bash
uv python update-shell
```

修改 shell 配置后重新打开 shell，或执行 `source ~/.zshrc`。

注意：

- `uv` 会优先读取 `UV_PYTHON`、项目级 `.python-version`、用户级 `.python-version`
- 在项目目录或子目录执行时，`uv` 会向上查找项目级 `.python-version`
- 不在项目目录下执行时，通常只会命中用户级 `.python-version` 或默认最新版本
- 如果不指定 Python 版本，`uv` 可能会自动下载满足请求的 Python

## 新项目工作流

新项目优先使用 `uv init`、`uv add` 和 `uv sync`，让依赖进入 `pyproject.toml` 并由 `uv.lock` 锁定。

```bash
mkdir my-project
cd my-project
uv init --python 3.14
uv add requests
uv add --dev ruff pytest
uv sync
uv run python main.py
```

常用项目命令：

```bash
uv run pytest        # 在项目 .venv 中运行测试
uv run ruff check .  # 在项目 .venv 中运行 lint
uv lock              # 更新 uv.lock
uv sync              # 按 pyproject.toml 和 uv.lock 同步 .venv
```

如果不想每次都加 `uv run`，可以手动激活项目里的 `.venv`：

```bash
source .venv/bin/activate
python main.py
deactivate
```

激活后，当前 shell 会优先使用 `.venv` 里的 `python` 和命令行工具。离开项目或切换项目时，建议执行 `deactivate`，
避免把一个项目的环境带到另一个项目里。

## 旧项目和 requirements.txt

已有 `requirements.txt` 的项目，不需要强行迁移；先按项目原有方式建立 `.venv`：

```bash
cd /path/to/project
uv venv --python 3.12              # 老项目按项目要求指定 Python version
uv pip install -r requirements.txt # 在当前项目 .venv 里安装依赖
uv run python main.py              # 在当前项目 .venv 里运行 Python 脚本
```

项目下的 `requirements.txt` 是项目依赖清单，应安装到项目 `.venv`，不要安装到用户级环境或 System Python。

## 用户级 CLI 工具

跨项目通用的 Python CLI 用 `uv tool` 安装到用户级目录，例如 `ruff`、`black`、`sphinx`、`mkdocs` 等。
项目专用工具优先用 `uv add --dev` 加到项目中，避免全局工具版本变成隐式依赖。

`uv tool` 会把工具的隔离环境放在 `~/.local/share/uv/tools`，并把可执行命令入口放到 `~/.local/bin`。
例如安装 `ruff` 后，工具环境通常在 `~/.local/share/uv/tools/ruff`，命令入口通常是 `~/.local/bin/ruff`。

```bash
uv tool install ruff
uv tool list
uv tool dir           # 查看 uv tool 的隔离环境目录
which ruff            # 查看 ruff 命令入口是否在 PATH 中
uv tool upgrade --all
uv tool update-shell  # 确保用户级 CLI 可执行程序目录在 PATH 中
```

## 参考

- uv 安装: <https://docs.astral.sh/uv/getting-started/installation/>
- uv Python 管理: <https://docs.astral.sh/uv/guides/install-python/>
- uv CLI reference: <https://docs.astral.sh/uv/reference/cli/>
- Python 版本状态: <https://devguide.python.org/versions/>
