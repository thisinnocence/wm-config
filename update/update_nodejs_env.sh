#!/usr/bin/env bash
set -euo pipefail

# 方案与适用范围
# - Node.js 官网可分别选择版本管理器和包管理器，本脚本仅针对 fnm + pnpm 组合
# - 首次安装 fnm、配置 shell 环境和启用 Corepack 需要手动完成，本脚本只更新已有环境
# - fnm 可在用户目录中管理多个 Node.js 版本并按项目切换，无需 sudo 且不影响系统 Node.js
# - pnpm 通过内容寻址存储复用依赖，通常可减少磁盘占用并加快依赖安装

# 更新行为与安全边界
# - 更新 fnm、Node.js LTS、Corepack/pnpm 和 pnpm 全局 CLI，并校验 fnm 发布包的 SHA-256
# - dsh 单独通过 pnpm dlx 更新缓存并生成启动命令，不加入全局依赖，不修改 shell 配置
# - 仅操作 HOME 内的用户级环境，不修改系统 Node.js、项目配置或项目依赖
# - 在临时空目录中运行，检测到其他 Node.js 管理方案或异常路径时拒绝更新
# - 任一步骤失败都会立即终止，完成后显示版本、路径和 fnm 默认版本

readonly FNM_RELEASE_API="https://api.github.com/repos/Schniz/fnm/releases/latest"
FNM_INSTALL_DIR=""
HOME_REAL=""
NODE_INSTALL_DIR=""
WORK_DIR=""

unsupported_environment() {
  local reason="$1"

  echo "error: unsupported Node.js environment: $reason" >&2
  echo "tip: this updater only supports a user-level fnm + Corepack/pnpm environment; nothing was changed." >&2
  exit 1
}

# 检查脚本自身运行所必需的通用命令
require_command() {
  local name="$1"

  if ! command -v "$name" >/dev/null 2>&1; then
    echo "error: required command is missing: $name" >&2
    exit 1
  fi
}

# 检查受支持的 fnm + Corepack/pnpm 环境必须提供的命令
require_supported_command() {
  local name="$1"

  if ! command -v "$name" >/dev/null 2>&1; then
    unsupported_environment "required command is missing: $name"
  fi
}

require_user_path() {
  local label="$1"
  local path="$2"
  local resolved_path

  resolved_path="$(readlink -m "$path")"
  if [[ "$resolved_path" != "$HOME_REAL/"* ]]; then
    echo "error: $label is outside the current user's home directory: $resolved_path" >&2
    exit 1
  fi
}

require_supported_user_path() {
  local label="$1"
  local path="$2"
  local resolved_path

  resolved_path="$(readlink -m "$path")"
  if [[ "$resolved_path" != "$HOME_REAL/"* ]]; then
    unsupported_environment "$label is outside the current user's home directory: $resolved_path"
  fi
}

require_user_command() {
  local name="$1"
  local command_path

  require_command "$name"
  command_path="$(readlink -f "$(command -v "$name")")"
  require_user_path "$name" "$command_path"
}

# 校验当前 node、corepack 和可选的 pnpm 是否属于 fnm 管理的同一套 Node.js 环境
# error_mode 控制环境检查与更新后检查的报错方式，validate_pnpm 决定是否校验 pnpm
validate_active_runtime() {
  local error_mode="$1"
  local validate_pnpm="$2"
  local require_runtime_command="require_command"
  local corepack_path
  local node_path
  local pnpm_path

  if [[ "$error_mode" == "unsupported" ]]; then
    require_runtime_command="require_supported_command"
  fi

  "$require_runtime_command" node
  node_path="$(readlink -f "$(command -v node)")"
  if [[ "$node_path" != "$FNM_INSTALL_DIR"/node-versions/*/installation/bin/node ]]; then
    [[ "$error_mode" == "unsupported" ]] \
      && unsupported_environment "node is not managed by the detected fnm installation: $node_path"
    echo "error: updated node is not managed by fnm: $node_path" >&2
    exit 1
  fi
  NODE_INSTALL_DIR="$(dirname "$(dirname "$node_path")")"

  "$require_runtime_command" corepack
  corepack_path="$(readlink -f "$(command -v corepack)")"
  if [[ "$corepack_path" != "$NODE_INSTALL_DIR"/lib/node_modules/corepack/* ]]; then
    [[ "$error_mode" == "unsupported" ]] \
      && unsupported_environment "corepack is not provided by the active fnm Node.js installation: $corepack_path"
    echo "error: updated corepack is outside the active fnm Node.js installation: $corepack_path" >&2
    exit 1
  fi

  [[ "$validate_pnpm" == "yes" ]] || return 0

  "$require_runtime_command" pnpm
  pnpm_path="$(readlink -f "$(command -v pnpm)")"
  if [[ "$pnpm_path" != "$NODE_INSTALL_DIR"/lib/node_modules/corepack/* ]]; then
    [[ "$error_mode" == "unsupported" ]] \
      && unsupported_environment "pnpm is outside the active fnm Node.js installation: $pnpm_path"
    echo "error: updated pnpm is outside the active fnm Node.js installation: $pnpm_path" >&2
    exit 1
  fi

  if [[ "$error_mode" != "unsupported" \
    && "$(pnpm --version)" != "$(corepack pnpm --version)" ]]; then
    echo "error: pnpm does not match the version selected by Corepack" >&2
    exit 1
  fi
}

# 校验 fnm、Corepack 和 pnpm 使用的配置目录、全局安装目录、可执行文件目录及 store 均位于 HOME 内
# 函数先设置用户级默认路径，再通过 pnpm 命令解析其实际使用的全局目录和内容寻址存储目录
# error_mode 为 unsupported 时表示更新前检查，发现异常会提示当前环境不受支持且不会进行更新
# 其他模式用于更新后检查，发现路径越界或目录无法解析时按更新结果异常直接退出
validate_pnpm_storage() {
  local error_mode="$1"
  local pnpm_bin_dir
  local pnpm_global_dir
  local pnpm_store_dir

  export FNM_DIR="$FNM_INSTALL_DIR"
  export COREPACK_HOME="${COREPACK_HOME:-$HOME/.cache/node/corepack}"
  export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
  if [[ "$error_mode" == "unsupported" ]]; then
    require_supported_user_path "FNM_DIR" "$FNM_DIR"
    require_supported_user_path "COREPACK_HOME" "$COREPACK_HOME"
    require_supported_user_path "PNPM_HOME" "$PNPM_HOME"
  else
    require_user_path "FNM_DIR" "$FNM_DIR"
    require_user_path "COREPACK_HOME" "$COREPACK_HOME"
    require_user_path "PNPM_HOME" "$PNPM_HOME"
  fi

  pnpm_global_dir="$(pnpm root --global)" \
    || {
      [[ "$error_mode" == "unsupported" ]] \
        && unsupported_environment "unable to resolve the pnpm global package directory"
      echo "error: unable to resolve the pnpm global package directory" >&2
      exit 1
    }
  pnpm_bin_dir="$(pnpm bin --global)" \
    || {
      [[ "$error_mode" == "unsupported" ]] \
        && unsupported_environment "unable to resolve the pnpm global executable directory"
      echo "error: unable to resolve the pnpm global executable directory" >&2
      exit 1
    }
  pnpm_store_dir="$(pnpm store path)" \
    || {
      [[ "$error_mode" == "unsupported" ]] \
        && unsupported_environment "unable to resolve the pnpm store directory"
      echo "error: unable to resolve the pnpm store directory" >&2
      exit 1
    }
  if [[ "$error_mode" == "unsupported" ]]; then
    require_supported_user_path "pnpm global directory" "$pnpm_global_dir"
    require_supported_user_path "pnpm global bin directory" "$pnpm_bin_dir"
    require_supported_user_path "pnpm store directory" "$pnpm_store_dir"
  else
    require_user_path "pnpm global directory" "$pnpm_global_dir"
    require_user_path "pnpm global bin directory" "$pnpm_bin_dir"
    require_user_path "pnpm store directory" "$pnpm_store_dir"
  fi
}

validate_supported_environment() {
  local fnm_path

  require_supported_command fnm
  fnm_path="$(readlink -f "$(command -v fnm)")"
  require_supported_user_path "fnm" "$fnm_path"
  FNM_INSTALL_DIR="$(dirname "$fnm_path")"

  validate_active_runtime unsupported yes
  validate_pnpm_storage unsupported
}

# 更新前安全检查（preflight）：确认权限、用户目录和 Node.js 环境类型符合要求
preflight() {
  if (( EUID == 0 )); then
    echo "error: do not run this user-level updater with sudo or as root" >&2
    exit 1
  fi

  if [[ -z "${HOME:-}" || ! -d "$HOME" ]]; then
    echo "error: HOME is not set to a valid directory" >&2
    exit 1
  fi

  HOME_REAL="$(readlink -f "$HOME")"
  require_command curl
  require_command jq
  require_command sha256sum
  require_command unzip

  # 使用空的临时目录隔离 package.json、.nvmrc、.node-version 等项目配置
  WORK_DIR="$(mktemp -d "$HOME/.node-env-update.XXXXXX")"
  trap 'rm -rf "$WORK_DIR"' EXIT
  cd "$WORK_DIR"

  # 在任何下载或更新之前确认环境完整属于当前用户，并且确实由 fnm + Corepack/pnpm 管理
  validate_supported_environment
}

update_fnm() {
  local archive="${WORK_DIR}/fnm.zip"
  local asset_name
  local asset_url
  local candidate="${WORK_DIR}/fnm-extract/fnm"
  local digest
  local release_json="${WORK_DIR}/fnm-release.json"
  local replacement="${FNM_INSTALL_DIR}/.fnm.new.$$"
  local current_version
  local latest_version

  case "$(uname -m)" in
    x86_64 | amd64) asset_name="fnm-linux.zip" ;;
    aarch64 | arm64) asset_name="fnm-arm64.zip" ;;
    armv7l | armv6l) asset_name="fnm-arm32.zip" ;;
    *) echo "error: unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac

  # 使用 GitHub API 返回的官方 SHA-256 摘要校验发布包，再原子替换 fnm
  curl -fsSL "$FNM_RELEASE_API" -o "$release_json"
  latest_version="$(jq -er '.tag_name | select(type == "string" and length > 0)' "$release_json")"
  latest_version="${latest_version#v}"
  current_version="$(fnm --version)"
  current_version="${current_version#fnm }"
  if [[ "$current_version" == "$latest_version" ]]; then
    echo "fnm: $current_version matches latest release; skipping update."
    return 0
  fi
  echo "Updating fnm: $current_version -> $latest_version..."
  asset_url="$(
    jq -er --arg name "$asset_name" \
      '.assets[] | select(.name == $name) | .browser_download_url' "$release_json"
  )"
  digest="$(
    jq -er --arg name "$asset_name" \
      '.assets[] | select(.name == $name) | .digest | select(startswith("sha256:")) | sub("^sha256:"; "")' \
      "$release_json"
  )"
  curl -fL "$asset_url" -o "$archive"
  printf '%s  %s\n' "$digest" "$archive" | sha256sum --check --status
  mkdir -p "$(dirname "$candidate")"
  unzip -q "$archive" -d "$(dirname "$candidate")"
  [[ -f "$candidate" ]] || {
    echo "error: fnm release archive does not contain the expected binary" >&2
    exit 1
  }
  chmod 0755 "$candidate"
  "$candidate" --version >/dev/null
  install -m 0755 "$candidate" "$replacement"
  mv -f "$replacement" "${FNM_INSTALL_DIR}/fnm"

  hash -r
  require_user_command fnm

  # 重新载入 fnm 环境，使后续命令立即使用更新后的 fnm 和 Node.js 路径
  local fnm_environment
  fnm_environment="$(fnm env --fnm-dir "$FNM_INSTALL_DIR" --shell bash)"
  eval "$fnm_environment"
  require_user_path "FNM_DIR" "$FNM_DIR"
}

update_nodejs() {
  local corepack_path
  local current_version
  local node_path
  local npm_path
  local npm_prefix
  local latest_version
  local corepack_version="missing"
  local latest_corepack

  latest_version="$(fnm list-remote --lts --latest)"
  latest_version="${latest_version%% *}"
  if [[ ! "$latest_version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "error: invalid latest Node.js LTS version: $latest_version" >&2
    exit 1
  fi
  if [[ "$(node --version)" == "$latest_version" ]]; then
    echo "Node.js LTS: $latest_version matches latest release; skipping installation."
  else
    echo "Installing Node.js LTS: $latest_version..."
    fnm install "$latest_version" --use
  fi
  current_version="$(fnm current)"

  if [[ -z "$current_version" || "$current_version" == "none" ]]; then
    echo "error: fnm did not activate the installed Node.js LTS version" >&2
    exit 1
  fi

  # 使用完整版本号设置默认版本，确保新 shell 与本次激活的 LTS 完全一致
  if [[ "$(fnm default)" != "$current_version" ]]; then
    fnm default "$current_version"
  fi

  require_user_command node
  node_path="$(readlink -f "$(command -v node)")"
  if [[ "$node_path" != "$FNM_INSTALL_DIR"/node-versions/*/installation/bin/node ]]; then
    echo "error: updated node is not managed by fnm: $node_path" >&2
    exit 1
  fi
  NODE_INSTALL_DIR="$(dirname "$(dirname "$node_path")")"

  require_user_command npm
  npm_path="$(readlink -f "$(command -v npm)")"
  if [[ "$npm_path" != "$NODE_INSTALL_DIR"/lib/node_modules/npm/* ]]; then
    echo "error: updated npm is outside the active fnm Node.js installation: $npm_path" >&2
    exit 1
  fi
  npm_prefix="$(readlink -m "$(npm prefix --global)")"
  if [[ "$npm_prefix" != "$NODE_INSTALL_DIR" ]]; then
    echo "error: npm global prefix is outside the active fnm Node.js installation: $npm_prefix" >&2
    exit 1
  fi

  # Node.js 25 及后续版本不再内置 Corepack，缺失时通过当前 Node.js 的 npm 补装
  corepack_path="$(command -v corepack 2>/dev/null || true)"
  if [[ -n "$corepack_path" ]]; then
    corepack_path="$(readlink -f "$corepack_path")"
  fi
  latest_corepack="$(registry_version corepack)"
  if [[ "$corepack_path" == "$NODE_INSTALL_DIR"/lib/node_modules/corepack/* ]]; then
    corepack_version="$(corepack --version)"
  fi
  if [[ "$corepack_version" == "$latest_corepack" ]]; then
    echo "Corepack: $corepack_version matches latest release; skipping update."
  else
    echo "Updating Corepack: $corepack_version -> $latest_corepack..."
    npm install --global "corepack@$latest_corepack"
    hash -r
  fi

  validate_active_runtime updated no
}

# 使用 registry 的 latest dist-tag，解析失败时直接终止，避免误判为无需更新
registry_version() {
  npm view "$1@latest" version --json | jq -er 'select(type == "string" and length > 0)'
}

update_global_packages() {
  local packages_json
  local packages
  local name
  local current_version
  local latest_version

  packages_json="$(pnpm list --global --depth 0 --json)"
  packages="$(jq -r '[.[] | (.dependencies // {}) | to_entries[]] | .[] | [.key, .value.version] | @tsv' \
    <<<"$packages_json")"
  while IFS=$'\t' read -r name current_version; do
    [[ -n "$name" ]] || continue
    latest_version="$(registry_version "$name")"
    if [[ "$current_version" == "$latest_version" ]]; then
      echo "$name: $current_version matches latest release; skipping update."
    else
      echo "Updating $name: $current_version -> $latest_version..."
      pnpm install --global "$name@$latest_version"
    fi
  done <<<"$packages"
}

update_pnpm() {
  require_user_path "COREPACK_HOME" "$COREPACK_HOME"
  require_user_path "PNPM_HOME" "$PNPM_HOME"

  local current_version
  local latest_version
  local pnpm_path

  latest_version="$(registry_version pnpm)"
  pnpm_path="$(command -v pnpm 2>/dev/null || true)"
  if [[ -z "$pnpm_path" || "$(readlink -f "$pnpm_path")" != \
    "$NODE_INSTALL_DIR"/lib/node_modules/corepack/* ]]; then
    corepack enable pnpm
    hash -r
  fi
  current_version="$(pnpm --version)"
  if [[ "$current_version" == "$latest_version" ]]; then
    echo "pnpm: $current_version matches latest release; skipping update."
  else
    echo "Updating pnpm: $current_version -> $latest_version..."
    corepack install --global "pnpm@$latest_version"
    hash -r
  fi
  validate_active_runtime updated yes
  validate_pnpm_storage updated
  update_global_packages

  # 严格检查 Codex 是否能启动；失败时立即退出，不将包安装成功视为 CLI 可用
  echo "Verifying Codex CLI..."
  hash -r
  require_user_command codex
  codex --version
  sync_codex_daemon
}

# daemon 使用独立安装包；仅在版本不一致时从当前 CLI 同步，避免每次更新都中断会话
sync_codex_daemon() {
  local versions
  local attempt
  local was_running

  versions="$(codex app-server daemon version)"
  jq -e '
    (.cliVersion | type == "string" and length > 0) and (.status | type == "string")
  ' <<<"$versions" >/dev/null || {
    echo "error: invalid Codex daemon version response: $versions" >&2
    return 1
  }
  was_running="$(jq -r '.status == "running"' <<<"$versions")"
  if jq -e '
    (.cliVersion | type == "string" and length > 0) and
    .managedCodexVersion == .cliVersion and
    (.status != "running" or .appServerVersion == .cliVersion)
  ' <<<"$versions" >/dev/null; then
    echo "Codex daemon package and running server match the CLI."
    return 0
  fi

  # 未安装 daemon 时无需创建后台服务
  if jq -e '.status != "running" and .managedCodexVersion == null' <<<"$versions" >/dev/null; then
    echo "Codex daemon is not installed; skipping daemon update."
    return 0
  fi

  echo "Syncing Codex daemon from the CLI (may interrupt active Codex sessions)..."
  codex app-server daemon update --from-cli --yes

  # 等待后台服务重启完成；禁止在 daemon 仍运行旧版本时报告更新成功
  for ((attempt = 0; attempt < 30; attempt++)); do
    versions="$(codex app-server daemon version)"
    if jq -e --argjson was_running "$was_running" '
      (.cliVersion | type == "string" and length > 0) and
      .managedCodexVersion == .cliVersion and
      ($was_running == false or .status == "running") and
      (.status != "running" or .appServerVersion == .cliVersion)
    ' <<<"$versions" >/dev/null; then
      printf 'Codex daemon versions: %s\n' "$versions"
      return 0
    fi
    sleep 1
  done

  echo "error: Codex daemon still does not match the CLI: $versions" >&2
  return 1
}

# 从 registry 解析最新版本，提前准备 dlx 缓存；启动命令使用本次解析的版本，直到下次统一更新
update_dsh() {
  local bin_dir
  local launcher
  local version
  local candidate="$WORK_DIR/dsh"
  local marker="# Managed by wm-config: dsh dlx launcher"
  local installed_version
  # 与现有 dsh 安装使用的构建依赖一致；缓存刷新时启动命令也需要相同授权
  local -a dlx_args=(
    dlx
    --allow-build=@deepseek-ai/dsh-subprocess-local
    --allow-build=@google/genai
    --allow-build=koffi
    --allow-build=node-pty
    --allow-build=protobufjs
  )

  bin_dir="$(pnpm bin --global)"
  require_user_path "dsh launcher directory" "$bin_dir"
  launcher="$bin_dir/dsh"
  if [[ -e "$launcher" || -L "$launcher" ]]; then
    if [[ -L "$launcher" ]] || ! grep -Fxq "$marker" "$launcher"; then
      echo "error: remove the old dsh installation with 'pnpm remove -g @deepseek-ai/dsh' first" >&2
      exit 1
    fi
  fi

  echo "Updating dsh in the isolated pnpm dlx cache..."
  version="$(pnpm view @deepseek-ai/dsh@latest version --json | jq -er 'select(type == "string")')"
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][a-zA-Z0-9.+-]+)?$ ]]; then
    echo "error: invalid dsh version returned by the registry: $version" >&2
    exit 1
  fi

  if [[ -f "$launcher" ]]; then
    installed_version="$(sed -nE 's/.* @deepseek-ai\/dsh@([^ ]+) "\$@"$/\1/p' "$launcher")"
    if [[ "$installed_version" == "$version" ]]; then
      echo "dsh: $version matches latest release; skipping cache and launcher update."
      return 0
    fi
  fi

  # 实际运行 --help，确认依赖安装和 CLI 启动成功后再替换入口；安装日志及 warning 保持可见
  pnpm "${dlx_args[@]}" "@deepseek-ai/dsh@$version" --help >"$WORK_DIR/dsh-help.txt"
  {
    printf '%s\n' '#!/usr/bin/env bash' "$marker"
    printf 'exec '
    printf '%q ' pnpm "${dlx_args[@]}" "@deepseek-ai/dsh@$version"
    printf '"$@"\n'
  } >"$candidate"
  mkdir -p "$bin_dir"
  install -m 0755 "$candidate" "$launcher"
  printf 'dsh dlx version: %s (%s)\n' "$version" "$launcher"
}

show_tool() {
  local name="$1"

  if command -v "$name" >/dev/null 2>&1; then
    local path
    path="$(command -v "$name")"
    local version
    version="$("$name" --version 2>/dev/null || true)"
    printf '%-6s %-12s %s\n' "$name" "${version:-unknown}" "$path"
  else
    printf '%-6s %-12s %s\n' "$name" "missing" "-"
  fi
}

show_environment() {
  local default_version

  echo
  echo "Updated Node.js user environment"
  echo "--------------------------------"
  show_tool fnm
  show_tool node
  show_tool npm
  show_tool corepack
  show_tool pnpm

  printf 'fnm node current: %s\n' "$(fnm current 2>/dev/null || echo unknown)"

  # fnm 没有稳定的纯版本输出选项，因此从带 default 标记的列表行提取版本号
  default_version="$(
    fnm list 2>/dev/null \
      | sed -nE 's/^[*[:space:]]*([^[:space:]]+).*[[:space:]]default$/\1/p' \
      | head -n1 \
      || true
  )"
  printf 'fnm node default: %s\n' "${default_version:-unknown}"
  echo
  pnpm list --global --depth 0
}

main() {
  preflight
  update_fnm
  update_nodejs
  update_pnpm
  update_dsh
  show_environment
}

main "$@"
