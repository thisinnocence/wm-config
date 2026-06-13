#!/usr/bin/env bash
set -euo pipefail

# 更新当前用户通过 fnm + pnpm 管理的 Node.js 开发环境
# - 仅更新用户目录中的 fnm、Node.js LTS、pnpm 和 pnpm 全局 CLI，不使用 sudo
# - 不修改 Ubuntu APT 安装的系统级 Node.js，也不更新任何项目的 package.json 或依赖
# - 在临时空目录中运行，避免用户主目录或项目中的 Node.js 配置影响版本解析
# - fnm 通过 GitHub 官方发布包更新并校验 SHA-256；Node.js 更新到最新 LTS 并设为默认
# - pnpm 通过 Corepack 更新到最新版，再更新 pnpm 管理的用户级全局软件包
# - 所有 fnm、Node.js、Corepack 和 pnpm 管理路径都必须位于 HOME 内，否则拒绝更新
# - 若检测到 nvm、Volta、系统 Node.js、独立 pnpm 等其他方案，将提示仅支持 fnm + pnpm 并退出
# - 任一步骤失败都会立即终止，最后显示更新后的版本、路径和 fnm 默认版本

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

require_command() {
  local name="$1"

  if ! command -v "$name" >/dev/null 2>&1; then
    echo "error: required command is missing: $name" >&2
    exit 1
  fi
}

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

validate_active_runtime() {
  local error_mode="$1"
  local validate_pnpm="$2"
  local corepack_path
  local node_path
  local pnpm_path
  local corepack_pnpm_version
  local pnpm_version

  if [[ "$error_mode" == "unsupported" ]]; then
    require_supported_command node
  else
    require_command node
  fi
  node_path="$(readlink -f "$(command -v node)")"
  if [[ "$node_path" != "$FNM_INSTALL_DIR"/node-versions/*/installation/bin/node ]]; then
    if [[ "$error_mode" == "unsupported" ]]; then
      unsupported_environment "node is not managed by the detected fnm installation: $node_path"
    fi
    echo "error: updated node is not managed by fnm: $node_path" >&2
    exit 1
  fi
  NODE_INSTALL_DIR="$(dirname "$(dirname "$node_path")")"

  if [[ "$error_mode" == "unsupported" ]]; then
    require_supported_command corepack
  else
    require_command corepack
  fi
  corepack_path="$(readlink -f "$(command -v corepack)")"
  if [[ "$corepack_path" != "$NODE_INSTALL_DIR"/lib/node_modules/corepack/* ]]; then
    if [[ "$error_mode" == "unsupported" ]]; then
      unsupported_environment "corepack is not provided by the active fnm Node.js installation: $corepack_path"
    fi
    echo "error: updated corepack is outside the active fnm Node.js installation: $corepack_path" >&2
    exit 1
  fi

  if [[ "$validate_pnpm" == "yes" ]]; then
    if [[ "$error_mode" == "unsupported" ]]; then
      require_supported_command pnpm
    else
      require_command pnpm
    fi
    pnpm_path="$(readlink -f "$(command -v pnpm)")"
    if [[ "$pnpm_path" != "$NODE_INSTALL_DIR"/lib/node_modules/corepack/* ]]; then
      if [[ "$error_mode" == "unsupported" ]]; then
        unsupported_environment "pnpm is outside the active fnm Node.js installation: $pnpm_path"
      fi
      echo "error: updated pnpm is outside the active fnm Node.js installation: $pnpm_path" >&2
      exit 1
    fi

    if [[ "$error_mode" != "unsupported" ]]; then
      pnpm_version="$(pnpm --version)"
      corepack_pnpm_version="$(corepack pnpm --version)"
    fi
    if [[ "$error_mode" != "unsupported" && "$pnpm_version" != "$corepack_pnpm_version" ]]; then
      echo "error: pnpm does not match the version selected by Corepack" >&2
      exit 1
    fi
  fi
}

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

  case "$(uname -m)" in
    x86_64 | amd64) asset_name="fnm-linux.zip" ;;
    aarch64 | arm64) asset_name="fnm-arm64.zip" ;;
    armv7l | armv6l) asset_name="fnm-arm32.zip" ;;
    *) echo "error: unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac

  # 使用 GitHub API 返回的官方 SHA-256 摘要校验发布包，再原子替换 fnm
  echo "Updating fnm..."
  curl -fsSL "$FNM_RELEASE_API" -o "$release_json"
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
  local current_version

  echo "Installing the latest Node.js LTS..."
  fnm install --lts --use
  current_version="$(fnm current)"

  if [[ -z "$current_version" || "$current_version" == "none" ]]; then
    echo "error: fnm did not activate the installed Node.js LTS version" >&2
    exit 1
  fi

  # 使用完整版本号设置默认版本，确保新 shell 与本次激活的 LTS 完全一致
  fnm default "$current_version"
  validate_active_runtime updated no
  require_user_command npm
}

update_pnpm() {
  require_user_path "COREPACK_HOME" "$COREPACK_HOME"
  require_user_path "PNPM_HOME" "$PNPM_HOME"

  echo "Updating the user-level pnpm managed by Corepack..."

  # 在 fnm 管理的当前 Node.js 安装中启用 shim，并设置用户默认 pnpm 版本
  corepack enable
  corepack install --global pnpm@latest
  hash -r
  validate_active_runtime updated yes
  validate_pnpm_storage updated

  echo "Updating pnpm user-global packages..."

  # --global 仅更新用户级 CLI，不读取或修改任何项目依赖
  pnpm update --global --latest
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

  printf 'fnm current: %s\n' "$(fnm current 2>/dev/null || echo unknown)"

  # fnm 没有稳定的纯版本输出选项，因此从带 default 标记的列表行提取版本号
  default_version="$(
    fnm list 2>/dev/null \
      | sed -nE 's/^[*[:space:]]*([^[:space:]]+).*[[:space:]]default$/\1/p' \
      | head -n1 \
      || true
  )"
  printf 'fnm default: %s\n' "${default_version:-unknown}"
  echo
  pnpm list --global --depth 0
}

main() {
  preflight
  update_fnm
  update_nodejs
  update_pnpm
  show_environment
}

main "$@"
