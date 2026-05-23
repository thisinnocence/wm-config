# node.js 环境

## fnm + pnpm 方案

node.js 官方和社区提供了多种安装方式。本环境选择 `fnm + pnpm`，主要是为了让 node.js runtime、全局 CLI 和项目依赖都尽量维护在用户目录下，不修改系统目录的 nodejs 环境。

- `fnm` 负责切换 node.js 版本，相比 `nvm` 这类 script 工具，有更快的版本切换速度;
- `pnpm` 负责依赖和用户级全局 CLI，适合个人 Linux 开发机长期维护;
- `corepack` 负责管理 `pnpm`、`yarn` 这类包管理器的版本解析;

```bash
# node
fnm install --lts --use
fnm list
fnm current

# 指定大版本
fnm use --install-if-missing 24  # 当前 shell 使用 24；缺失时安装到当前用户目录
fnm default 24                   # 设置当前用户默认 node.js 版本

# corepack
corepack enable

# 在项目目录里固定 pnpm 版本，会写入 package.json 的 packageManager
corepack use pnpm@latest
```

这不是唯一的最佳方案，如果目标是严格跟随官网最少变量，直接使用官方推荐的 `npm` 命令也可以，如果目标是团队一致性，应优先跟随项目里的 `.nvmrc/packageManager` 或团队规范。

`pnpm` 源的 registry 配置：

```bash
# pnpm 的配置文件是 ~/.npmrc
pnpm config set registry https://registry.npmmirror.com
```

## 手动更新版本

node.js 环境建议手动更新，避免 runtime、全局 CLI 和项目依赖互相影响。

### 1. 确认当前是用户级环境

先离开项目目录，在用户目录下检查当前 node.js 和 `pnpm`：

```bash
cd ~
node -v
which node
which pnpm
pnpm -v
corepack pnpm -v          # 查看 Corepack 解析到的 pnpm 版本
pnpm list -g --depth 0    # 查看用户级全局包
```

如果 `which node` 指向 `fnm` 管理的用户目录，说明当前 node.js runtime 是用户级环境。

- `corepack` 是 node.js 自带的包管理器代理工具，用来管理 `pnpm`、`yarn` 这类包管理器的版本。
- `corepack prepare pnpm@latest --activate` 是把当前用户 `node.js` 环境的默认 `pnpm` 激活到最新版本。

不要在项目目录里判断用户默认 `pnpm` 版本。

### 2. 更新用户默认 `pnpm`

确认在用户目录后，更新 corepack 激活的默认 `pnpm`：

```bash
cd ~                                      # 离开项目目录，避免被项目 packageManager 配置影响
corepack prepare pnpm@latest --activate   # 更新当前用户 node.js 环境下 corepack 激活的默认 pnpm
pnpm -v                                   # 查看当前 shell 直接执行 pnpm 时的版本
corepack pnpm -v                          # 查看经过 corepack 解析后的 pnpm 版本
```

确认当前 `pnpm` 命令来自哪里：

```bash
which pnpm              # 查看当前 shell 里 pnpm 命令的实际路径
ls -l "$(which pnpm)"   # 查看 pnpm 是否是软链接；如果指向 .../corepack/dist/pnpm.js，就是 Corepack 管理
pnpm root -g            # 查看用户级全局包安装目录
pnpm list -g --depth 0 | grep pnpm  # 检查 pnpm 自己是否也作为用户级全局包安装
```

- 如果 `pnpm` 指向 `.../corepack/dist/pnpm.js`，用 `corepack prepare pnpm@latest --activate` 更新
- 如果 `pnpm list -g --depth 0 | grep pnpm` 能看到 `pnpm`，也可以用 `pnpm add -g pnpm@latest` 更新

### 3. 手动升级 node.js runtime

node.js runtime 不做自动更新，需要升级时手动安装和切换：

```bash
fnm install 24
fnm default 24
node -v
```

## 用户级全局包维护

Linux 开发环境中的 node.js 工具应优先安装在用户目录下，注意：

- 通过 `fnm` 管理 node.js 版本时，全局包会落在当前用户 node.js 或包管理器目录中，不要使用 `sudo`
- 用户级全局包用于安装公共 CLI，如 `codex`、`pnpm`、`typescript`、`eslint` 这类需要在多个项目中调用的工具
- `pnpm -g` 里的 `-g` 表示 `global`，这里指当前用户 node.js 环境的全局包，不是系统级包，也不是项目依赖
- 项目级安装如运行时依赖、构建依赖和框架依赖应放在项目自己的 `package.json` 中，避免把全局环境变成隐式依赖
- 环境的用户级 CLI 统一由 `pnpm` 维护，不要在 `npm/pnpm` 和手工二进制安装之间来回切换
- 不要用 sudo 安装全局包，这会修改系统级目录，导致权限问题和环境污染

常用检查命令：

```bash
which pnpm
pnpm config get global-bin-dir # 查看全局包安装目录
pnpm list -g --depth 0         # 列出全局安装的包，确认版本和安装位置
pnpm outdated -g               # 检查全局包是否过期，及时更新
```

先查看过期包，再更新：

```bash
pnpm outdated -g
pnpm update -g
pnpm list -g --depth 0
```

更新指定 CLI 时，直接安装 latest 版本：

```bash
pnpm install -g <package>@latest
<command> --version

# 例如更新 codex CLI
pnpm install -g @openai/codex@latest
codex --version
```
