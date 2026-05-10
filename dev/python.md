# Python 环境

## 使用 uv 包管理

`uv` 安装在用户目录下。当前 binary 路径：

```text
~/.local/bin/uv
```

原则：

- 使用 `uv` 管理 Python runtime 和项目级 venv 环境
- 保持 System Python 不被直接污染
- 项目环境保留在项目目录内，如 `.venv`

常用命令：

```bash
uv python find                     # 查找可用的 Python 版本
uv python list                     # 列出已安装的 Python 版本
uv python install 3.12             # 安装指定 Python version 到用户目录

# 用户级和项目级的 Python version 配置
uv python pin 3.12                 # 把当前项目的 Python version 写到 .python-version
uv python pin --global 3.12        # 把用户级默认 Python version 写到 ~/.config/uv/.python-version

# 项目级 venv 环境管理
uv venv --python 3.12              # 在当前目录创建一个 venv，默认目录是 .venv
uv pip install -r requirements.txt # 在当前 venv 环境里安装依赖
uv run python main.py              # 在当前 venv 环境里运行 Python 脚本

# Note: 如果不指定 Python 版本
#   uv 会按默认请求安装 Python
#   执行目录会影响项目级 .python-version 的查找
#   在项目目录或其子目录执行时，uv 会向上查找项目级 .python-version
#   不在项目目录下执行时，通常只会命中用户级 .python-version 或默认最新版本
#   默认请求会优先看 UV_PYTHON、项目级 .python-version、用户级 .python-version
#   如果都没有，则安装最新可用的 Python version
uv python install
```

说明：

- `uv` 使用用户目录下的 cache 和 tools，会加速 Python 版本的安装和管理
- 后续在每个项目内优先通过 `uv` 执行 Python 工作流，而不是依赖 system-wide `pip`
- 项目下的 `requirements.txt` 是项目依赖清单，应安装到项目 `.venv`，不要安装到用户级环境或 System Python

## 项目级配置

比如一个典型的 Sphinx 项目：

```bash
cd /path/to/sphinx-project
uv venv --python 3.12   # 可省略 --python，省略时按当前目录解析默认 Python
uv pip install -r requirements.txt
uv run python main.py
```

如果不想每次都加 `uv run`，可以手动激活项目里的 `.venv`：

```bash
source .venv/bin/activate
python main.py
deactivate
```

激活后，当前 shell 会优先使用 `.venv` 里的 `python` 和命令行工具。离开项目或切换项目时，建议执行 `deactivate`，避免把一个项目的环境带到另一个项目里。
