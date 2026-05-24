# node.js 环境

## fnm + pnpm 方案

node.js 官方和社区提供了多种安装方式。本环境选择 `fnm + pnpm`，主要是为了让 node.js runtime、全局 CLI 和
项目依赖都尽量维护在用户目录下，不修改系统目录的 nodejs 环境。

- `fnm` 管理 `node.js` runtime 版本，安装和切换都在用户目录内完成;
- `corepack` 管理 `pnpm` 版本选择，可跟随项目的 `packageManager` 声明;
- `pnpm` 管理项目依赖和用户级全局 CLI，避免污染系统目录;

```bash
# fnm
fnm install --lts --use
fnm list
fnm current
fnm use --install-if-missing 24  # 当前 shell 使用 24；缺失时安装到当前用户目录
fnm default 24                   # 设置当前用户默认 node.js 版本

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
which node                               # 指向 `fnm` 管理的用户目录说明是 node.js 是用户级环境
node -v                                  # 看 node.js 的版本
corepack -v                              # node.js 自带的包管理器代理工具，用来管理 pnpm 等包管理器
corepack pnpm -v                         # 查看 corepack 解析到的 pnpm 版本
pnpm -v                                  # 注意不要再项目目录里查看，要在 ~ 这个 user 目录看
pnpm list -g --depth 0                   # 查看用户级全局包；--depth 0 表示只列出直接安装的包
```

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
pnpm bin -g             # 查看用户级全局 CLI 可执行程序安装目录, 必须在 PATH 中
pnpm root -g            # 查看用户级全局包安装目录
pnpm list -g --depth 0 | grep pnpm  # 检查 pnpm 自己是否也作为用户级全局包安装；--depth 0 只列直接安装的包
```

- 如果 `pnpm` 指向 `.../corepack/dist/pnpm.js`，用 `corepack prepare pnpm@latest --activate` 更新
- 如果 `pnpm list -g --depth 0 | grep pnpm` 能看到 `pnpm`，也可以用 `pnpm add -g pnpm@latest` 更新

如果 `pnpm bin -g` 或 `pnpm root -g` 提示 `global bin directory ... is not in PATH`，
检查 `~/.zshrc` 的 pnpm 段落：

```bash
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
- 环境的用户级 CLI 统一由 `pnpm` 维护，不要在 `npm/pnpm` 和手工二进制安装之间来回切换

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
codex --version
```
