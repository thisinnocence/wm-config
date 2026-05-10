# Node.js 环境

## fnm + pnpm 方案

Node.js 官方和社区提供了多种安装方式。本环境选择 `fnm + pnpm`，主要是为了让 Node.js runtime、全局 CLI 和项目依赖都尽量维护在用户目录下，减少对系统目录的写入。`fnm` 负责切换 Node.js 版本，相比 `nvm` 这类 shell script 工具，通常有更轻的 shell 初始化成本和更快的版本切换速度；`pnpm` 负责依赖和用户级全局 CLI，适合个人 Linux 开发机长期维护。

这不是唯一的最佳方案。如果目标是严格跟随官网最少变量，直接使用官方推荐的 `npm` 命令也可以；如果目标是团队一致性，应优先跟随项目里的 `.nvmrc`、`packageManager` 或团队规范。

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
fnm list
fnm use --install-if-missing 24
node -v
npm -v
pnpm -v
```

`fnm` 由 shell 配置初始化。打开新的 shell 后，应自动进入当前配置的 Node.js 版本。

`pnpm` registry 配置：

```bash
pnpm config set registry https://registry.npmmirror.com
```

配置文件是 `~/.npmrc`。

## 用户级全局包维护

Linux 开发环境中的 Node.js 工具应优先安装在用户目录下。通过 `fnm` 管理 Node.js 版本时，全局包会落在当前用户的 Node.js 或包管理器目录中，不需要使用 `sudo`。

全局包适合放少量命令行工具，例如 `codex`、`pnpm`、`typescript`、`eslint` 这类需要在多个项目中直接调用的 CLI。项目运行时依赖、构建依赖和框架依赖应放在项目自己的 `package.json` 中，避免把全局环境变成隐式依赖。

本环境的用户级全局 CLI 统一由 `pnpm` 维护。`npm` 是 Node.js 官方自带工具，也是很多官网文档的默认示例；`pnpm` 更适合作为个人开发环境里的统一包管理器，因为它和项目依赖管理习惯一致，并且全局命令入口集中在用户目录下。关键原则是同一个 CLI 只由一个包管理器维护，不要在 `npm`、`pnpm` 和手工二进制安装之间来回切换。

常用检查命令：

```bash
which node
which pnpm
pnpm config get global-bin-dir
pnpm list -g --depth 0
pnpm outdated -g
```

维护全局包时，先确认当前 Node.js 版本，再更新指定工具：

```bash
node -v
pnpm install -g <package>@latest
<command> --version
```

不要使用下面这种方式维护用户级 Linux 环境：

```bash
sudo npm install -g <package>
sudo pnpm install -g <package>
```

使用 `sudo` 安装全局 Node.js 包容易把文件写入系统目录或 root 拥有的目录，后续会导致普通用户无法升级、删除或覆盖全局包。已经出现权限混乱时，应先确认 `which <command>`、`pnpm config get global-bin-dir` 和全局包目录归属，再修复目录权限或重建对应 Node.js 版本环境。

比如，在用户级安装 openai/codex 工具：

OpenAI Codex CLI 的官方 npm 包名是 `@openai/codex`。OpenAI 官方文档通常使用 `npm install -g @openai/codex` 作为 npm 示例；在本环境中，Codex CLI 按同一个包名使用 `pnpm` 维护：

```bash
pnpm install -g @openai/codex
```

安装完成后，`codex` 命令会在用户级全局目录中。
