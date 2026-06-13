#!/usr/bin/env bash
set -euo pipefail

# 更新 Rust 开发环境：
# - 将 rustup 默认工具链设为 stable，并更新 rustc、cargo 和标准库；
# - 安装 rustfmt、clippy、rust-src 组件，并显示当前工具链和版本信息；
# - 安装 cargo-update（如尚未安装），再更新所有通过 cargo install 安装的工具。
# - 仅支持当前用户目录中的 rustup/Cargo 环境，禁止使用 sudo/root 运行；
# - 在临时空目录中执行，并显式指定 stable，避免项目 rust-toolchain 配置干扰。

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
  # 更新并固定默认 stable 工具链；显式指定工具链，避免目录级 override 生效。
  rustup update stable
  rustup default stable
  rustup component add --toolchain stable rustfmt clippy rust-src

  rustup show
  rustc +stable --version
  cargo +stable --version
}

update_cargo_tools() {
  # cargo-update 本身也安装到当前用户的 CARGO_HOME。
  if ! command -v cargo-install-update >/dev/null 2>&1; then
    cargo +stable install cargo-update
  fi
  require_user_command cargo-install-update

  cargo +stable install-update --all --cargo-dir "$CARGO_HOME"
  cargo +stable install --list --root "$CARGO_HOME"
}

main() {
  preflight
  update_rust
  update_cargo_tools
}

main "$@"
