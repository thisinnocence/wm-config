#!/usr/bin/env bash
set -euo pipefail

# 更新 Rust 开发环境
# - 将 rustup 默认工具链设为 stable，并更新 rustc、cargo 和标准库
# - 安装 rustfmt、clippy、rust-src 组件，并显示当前工具链和版本信息
# - 安装 cargo-update（如尚未安装），再更新所有通过 cargo install 安装的工具
# - 仅支持当前用户目录中的 rustup/Cargo 环境，禁止使用 sudo/root 运行
# - 在临时空目录中执行，并显式指定 stable，避免项目 rust-toolchain 配置干扰

HOME_REAL=""
WORK_DIR=""

require_user_command() {
  local name="$1"
  local command_path

  if ! command -v "$name" >/dev/null 2>&1; then
    echo "error: required command is missing: $name" >&2
    exit 1
  fi

  command_path="$(readlink -f "$(command -v "$name")")"
  if [[ "$command_path" != "$HOME_REAL/"* ]]; then
    echo "error: $name is outside the current user's home directory: $command_path" >&2
    exit 1
  fi
}

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
  require_user_command rustup
  require_user_command cargo

  export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
  export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
  if [[ "$(readlink -m "$CARGO_HOME")" != "$HOME_REAL/"* ]]; then
    echo "error: CARGO_HOME is outside the current user's home directory: $CARGO_HOME" >&2
    exit 1
  fi
  if [[ "$(readlink -m "$RUSTUP_HOME")" != "$HOME_REAL/"* ]]; then
    echo "error: RUSTUP_HOME is outside the current user's home directory: $RUSTUP_HOME" >&2
    exit 1
  fi

  WORK_DIR="$(mktemp -d "$HOME/.rust-env-update.XXXXXX")"
  trap 'rm -rf "$WORK_DIR"' EXIT
  cd "$WORK_DIR"
}

update_rust() {
  local check_output
  local check_status=0
  local stable_toolchain
  local default_toolchain
  local installed_components
  local component
  local -a missing_components=()

  # rustup check 返回 100 表示有更新，其他非零值表示检查失败，不能当成无需更新
  check_output="$(RUSTUP_TERM_COLOR=never rustup check)" || check_status=$?
  if (( check_status != 0 && check_status != 100 )); then
    echo "error: rustup update check failed" >&2
    return "$check_status"
  fi
  printf '%s\n' "$check_output"
  stable_toolchain="$(rustup toolchain list | awk '$1 ~ /^stable-/ { print $1; exit }')"
  if [[ -n "$stable_toolchain" ]] \
    && grep -Eq "^${stable_toolchain} - up to date:" <<<"$check_output"; then
    echo "Rust stable matches the latest release; skipping toolchain update."
  else
    rustup update stable --no-self-update
  fi

  if grep -Eq '^rustup - up to date[[:space:]]*:' <<<"$check_output"; then
    echo "rustup matches the latest release; skipping self-update."
  elif grep -Eq '^rustup - update available[[:space:]]*:' <<<"$check_output"; then
    rustup self update
  else
    echo "error: unrecognized rustup self-update check response" >&2
    return 1
  fi

  # 显式指定 stable，避免项目目录的 toolchain override；默认值一致时不重复写入
  stable_toolchain="$(rustup toolchain list | awk '$1 ~ /^stable-/ { print $1; exit }')"
  default_toolchain="$(rustup toolchain list | awk '/\(default\)/ { print $1; exit }')"
  if [[ "$default_toolchain" != "$stable_toolchain" ]]; then
    rustup default stable
  fi

  installed_components="$(rustup component list --toolchain stable --installed)"
  for component in rustfmt clippy rust-src; do
    if ! grep -Eq "^${component}(-[^[:space:]]+)?$" <<<"$installed_components"; then
      missing_components+=("$component")
    fi
  done
  if (( ${#missing_components[@]} > 0 )); then
    rustup component add --toolchain stable "${missing_components[@]}"
  else
    echo "Rust components rustfmt, clippy and rust-src are installed; skipping component installation."
  fi

  rustup show
  rustc +stable --version
  cargo +stable --version
}

update_cargo_tools() {
  # cargo-update 本身也安装到当前用户的 CARGO_HOME
  if ! command -v cargo-install-update >/dev/null 2>&1; then
    cargo +stable install cargo-update
  fi
  require_user_command cargo-install-update

  # cargo-update 原生比较 registry 版本和 Git revision；不使用 --force，匹配时不编译安装
  # 使用已验证并导出的 CARGO_HOME，同时更新 registry 和 Git 来源的工具
  cargo +stable install-update --all --git
  cargo +stable install --list --root "$CARGO_HOME"
}

main() {
  preflight
  update_rust
  update_cargo_tools
}

main "$@"
