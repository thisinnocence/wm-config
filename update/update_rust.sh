#!/usr/bin/env bash
set -e

# 更新 Rust 开发环境：
# - 将 rustup 默认工具链设为 stable，并更新 rustc、cargo 和标准库；
# - 安装 rustfmt、clippy、rust-src 组件，并显示当前工具链和版本信息；
# - 安装 cargo-update（如尚未安装），再更新所有通过 cargo install 安装的工具。

# 只使用 stable 工具链
rustup default stable

# 更新 stable 工具链，包括 rustc、cargo、rustfmt、clippy、标准库等
rustup update stable

# 安装常用组件，如果已经安装会自动跳过
rustup component add rustfmt clippy rust-src

# 显示当前 Rust 环境信息
rustup show
rustc --version
cargo --version

# 确保 cargo-update 已安装，用于更新 cargo install 安装的二进制工具
if ! command -v cargo-install-update >/dev/null 2>&1; then
    cargo install cargo-update
fi

# 更新所有通过 cargo install 安装的命令行工具
cargo install-update -a

# 显示已安装的 cargo 二进制工具
cargo install --list
