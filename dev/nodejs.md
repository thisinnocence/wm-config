# node.js 环境

## fnm + pnpm 方案

node.js 官方和社区提供了多种安装方式。本环境选择 `fnm + pnpm`，主要是为了让 node.js runtime、全局 CLI 和
项目依赖都尽量维护在用户目录下，不修改系统目录的 nodejs 环境。

- `fnm` 管理 `node.js` runtime 版本，安装和切换都在用户目录内完成;
- `corepack` 管理 `pnpm` 版本选择，可跟随项目的 `packageManager` 声明;
- `pnpm` 管理项目依赖和用户级全局 CLI，避免污染系统目录;

为什么选用 `fnm + pnpm` 呢？原因如下：

- `fnm` 用 Rust 开发，启动和切换速度快，比传统 shell 脚本型 node.js 版本管理器更适合需要频繁切换项目的个人环境
- `fnm` 支持 `.node-version` 和 `.nvmrc`，遇到已有项目时不需要强行改变团队约定
- `pnpm` 相比 `npm` 更节省磁盘空间，安装速度更快，依赖通过内容寻址 store 复用，不会在每个项目里重复保存同一份包
- `pnpm` 默认依赖结构更严格，不容易因为幽灵依赖把项目跑通但实际缺少声明
- `pnpm` 在前端和 monorepo 社区使用越来越多，很多新项目会直接通过 `packageManager` 指定 `pnpm`
- `corepack` 可以按项目的 `packageManager` 声明选择 `pnpm` 版本，让个人默认版本和项目固定版本分开

先安装并初始化 `fnm`：

```bash
# 安装 fnm；也可以改用系统包管理器或发行版推荐方式安装
curl -fsSL https://fnm.vercel.app/install | bash

# 将下面一行加入 ~/.zshrc，让新 shell 自动加载 fnm 管理的 node.js
eval "$(fnm env --use-on-cd --shell zsh)"
```

修改 `~/.zshrc` 后重新打开 shell，或执行 `source ~/.zshrc`。

```bash
# fnm
fnm install --lts --use
fnm list
fnm current
fnm use --install-if-missing 24  # 当前 shell 使用当前 LTS major；缺失时安装到当前用户目录
fnm default 24                   # 设置当前用户默认 node.js 版本；24 是 2026-05 的 LTS major

# corepack
corepack enable
```

这不是唯一方案，如果目标是严格跟随官网最少变量，直接使用官方推荐的 `npm` 命令也可，如果目标是团队一致性，
应优先跟随项目里的 `.nvmrc/packageManager` 或团队规范。

项目里需要固定 `pnpm` 版本时，在项目目录执行：

```bash
# 会写入 package.json 的 packageManager
corepack use pnpm@latest
```

`pnpm` 源的 registry 配置：

```bash
# pnpm 的配置文件是 ~/.npmrc
pnpm config set registry https://registry.npmmirror.com
```

如果不需要 npm 镜像源，可以跳过这一步。

## 手动更新版本

node.js 环境建议手动更新，避免 runtime、全局 CLI 和项目依赖互相影响。

### 1. 确认当前是用户级环境

先离开项目目录，在用户目录下检查当前 node.js 和 `pnpm`：

```bash
cd ~
which node               # 指向 `fnm` 管理的用户目录说明是 node.js 是用户级环境
node -v                  # 看 node.js 的版本
corepack -v              # node.js 自带的包管理器代理工具，用来管理 pnpm 等包管理器
corepack pnpm -v         # 查看 corepack 解析到的 pnpm 版本
pnpm -v                  # 注意不要在项目目录里查看，要在 ~ 这个 user 目录看
pnpm list -g --depth 0   # 查看用户级全局包；--depth 0 表示只列出直接安装的包
```

### 2. 更新用户默认 `pnpm`

确认在用户目录后，更新 corepack 激活的默认 `pnpm`：

```bash
cd ~                                      # 离开项目目录，避免被项目 packageManager 配置影响
corepack prepare pnpm@latest --activate   # 更新当前用户 node.js 环境下 corepack 激活的默认 pnpm
corepack pnpm -v                          # 查看经过 corepack 解析后的 pnpm 版本
pnpm -v                                   # 查看当前 shell 直接执行 pnpm 时的版本
```

确认当前 `pnpm` 命令来自哪里：

```bash
which pnpm              # 查看当前 shell 里 pnpm 命令的实际路径
ls -l "$(which pnpm)"   # 查看 pnpm 是否是软链接; 如果指向 .../corepack/dist/pnpm.js, 就是 corepack 管理
pnpm bin -g             # 查看用户级全局 CLI 可执行程序安装目录, 必须在 PATH 中
pnpm root -g            # 查看用户级全局包安装目录
pnpm list -g --depth 0 | grep pnpm  # 检查 pnpm 自己是否也作为用户级全局包安装
```

- 如果 `pnpm` 指向 `.../corepack/dist/pnpm.js`，用 `corepack prepare pnpm@latest --activate` 更新
- 如果 `pnpm list -g --depth 0 | grep pnpm` 能看到 `pnpm`，也可以用 `pnpm install -g pnpm@latest` 更新

如果 `pnpm bin -g` 或 `pnpm root -g` 提示 `global bin directory ... is not in PATH`，
检查 `~/.zshrc` 的 pnpm 段落：

```bash
# pnpm v11 的全局 CLI 可执行程序在 $PNPM_HOME/bin；如果 pnpm setup 生成了不同配置，以实际生成为准
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
```

修改后重新打开 shell，或执行 `source ~/.zshrc`

### 3. 手动升级 node.js runtime

node.js runtime 不做自动更新，需要升级时手动安装和切换：

```bash
# 24 是 2026-05 的 LTS major；以后升级时换成当前 Node.js LTS major
fnm install 24
fnm default 24
node -v
```

## 用户级全局包维护

Linux 开发环境中的 node.js 工具应优先安装在用户目录下，注意：

- 不要用 sudo 安装全局包，这会修改系统级目录，导致权限问题和环境污染
- 通过 `fnm` 管理 node.js 版本时，全局包会落在当前用户 node.js 或包管理器目录中
- 用户级全局包用于安装公共 CLI，如 `codex`、`pnpm`、`typescript`、`eslint` 这类需要在多个项目中调用的工具
- 项目级安装如运行时依赖、构建依赖和框架依赖应放在项目自己的 `package.json` 中，避免把全局环境变成隐式依赖
- 环境的用户级 CLI 统一由 `pnpm` 维护，不要在 `npm -g`、`pnpm -g` 和手工二进制安装之间来回切换

先查看过期包，再更新：

```bash
# 下面命令要在用户目录执行，避免被项目 packageManager 配置影响
# -g 表示操作用户级的全局包，不是当前项目依赖
pnpm outdated -g
pnpm update -g
pnpm list -g --depth 0  # --depth 0 表示只列出直接安装的包，不展开依赖树
```

更新指定 CLI 时，直接安装 latest 版本：

```bash
pnpm install -g <package>@latest

# 例如更新 codex CLI
pnpm install -g @openai/codex@latest
type -a codex          # 应只看到 pnpm 的 codex 路径，避免 npm/fnm 里还有另一个 codex
codex --version
```

如果 `type -a codex` 同时看到 `~/.local/share/pnpm/bin/codex` 和 `fnm` 当前 node.js 目录下的 `codex`，
说明同一个 CLI 被 `pnpm` 和 `npm` 各装了一份。这个环境只保留 `pnpm` 版本：

```bash
npm uninstall -g @openai/codex
pnpm install -g @openai/codex@latest
type -a codex
codex --version
```

## 参考

- fnm 安装说明: <https://www.fnmnode.com/guide/install.html>
- Node.js release 状态: <https://nodejs.org/en/about/previous-releases>
- pnpm setup: <https://pnpm.io/cli/setup>
