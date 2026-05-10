# Node.js 环境

## fnm + pnpm 方案

Node.js 官方和社区提供了多种安装方式。本环境选择 `fnm + pnpm`，主要是为了让 Node.js runtime、全局 CLI 和项目依赖都尽量维护在用户目录下，不修改系统目录的 nodejs 环境。

- `fnm` 负责切换 Node.js 版本，相比 `nvm` 这类 script 工具，有更快的版本切换速度；
- `pnpm` 负责依赖和用户级全局 CLI，适合个人 Linux 开发机长期维护。

这不是唯一的最佳方案，如果目标是严格跟随官网最少变量，直接使用官方推荐的 `npm` 命令也可以，如果目标是团队一致性，应优先跟随项目里的 `.nvmrc`、`packageManager` 或团队规范。

`fnm` 安装在用户目录下。当前 binary 路径：

```text
~/.local/share/fnm/fnm
```

原则：

- 使用 `fnm` 管理 Node.js runtime
- Node.js 版本保留在用户目录下，不写入系统目录
- 项目依赖优先使用项目自己的 package manager workflow

常用命令：

```bash
# 查找可用的 Node.js 版本
fnm list

# 切换当前 shell 的 Node.js runtime，自动安装缺失的版本
# 后续在这个 shell 里运行的全局 CLI 安装和项目命令都会使用该版本
fnm use --install-if-missing 24
```

`fnm` 由 shell 配置初始化。打开新的 shell 后，应自动进入当前配置的 Node.js 版本。

`pnpm` 源的 registry 配置：

```bash
# pnpm 的配置文件是 ~/.npmrc
pnpm config set registry https://registry.npmmirror.com
```

## 用户级全局包维护

Linux 开发环境中的 Node.js 工具应优先安装在用户目录下，注意：

- 通过 `fnm` 管理 Node.js 版本时，用户级包会落在当前用户 Node.js 或包管理器目录中，不要使用 `sudo`
- 用户级安装管理公共CLI工具，如 `codex`、`pnpm`、`typescript`、`eslint` 这类需要在多个项目中调用的 CLI
- 项目级安装如运行时依赖、构建依赖和框架依赖应放在项目自己的 `package.json` 中，避免把全局环境变成隐式依赖
- 环境的用户级 CLI 统一由 `pnpm` 维护，不要在 `npm`、`pnpm` 和手工二进制安装之间来回切换
- 不要用 sudo 安装全局包，这会修改系统级目录，导致权限问题和环境污染

常用检查命令：

```bash
which pnpm
pnpm config get global-bin-dir # 查看全局包安装目录
pnpm list -g --depth 0         # 列出全局安装的包，确认版本和安装位置
pnpm outdated -g               # 检查全局包是否过期，及时更新
```

维护用户级全局包时，先确认当前 Node.js 版本，再更新指定工具:

```bash
node -v
pnpm install -g <package>@latest
<command> --version

# 例如更新 codex CLI
pnpm install -g @openai/codex@latest
```
