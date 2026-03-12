#!/bin/bash
#
# Install Rust via rustup using China mirror
# Sets RUSTUP_DIST_SERVER and RUSTUP_UPDATE_ROOT before running the installer
#
# Prerequisites: curl or wget
#

set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# ==================== Configuration ====================

declare -A RUSTUP_DIST_MIRRORS=(
    ["tuna"]="https://mirrors.tuna.tsinghua.edu.cn/rustup"
    ["ustc"]="https://mirrors.ustc.edu.cn/rust-static"
)

declare -A RUSTUP_UPDATE_ROOTS=(
    ["tuna"]="https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup"
    ["ustc"]="https://mirrors.ustc.edu.cn/rust-static/rustup"
)

DEFAULT_MIRROR="tuna"
DEFAULT_TOOLCHAIN="stable"

# ==================== Functions ====================

show_help() {
    cat << EOF
Install Rust via rustup using China mirror

Usage: $(basename "$0") [OPTIONS]

Options:
  -m, --mirror MIRROR      Distribution mirror (tuna|ustc)
                           Default: tuna
  -c, --toolchain CHAIN    Toolchain to install (stable|nightly|beta|1.75.0)
                           Default: stable
  -d, --dry-run            Show what would be done without executing
  -y, --yes                Skip confirmation prompts
  -h, --help               Show this help message

Examples:
  $(basename "$0")                        # Install stable Rust via TUNA
  $(basename "$0") -m ustc                # Use USTC mirror
  $(basename "$0") -c nightly             # Install nightly toolchain
  $(basename "$0") -c 1.75.0             # Install specific version

Note: After installation, configure Cargo crates mirror with:
  bash scripts/rust/setup.sh
EOF
}

install_rustup() {
    local dist_server="$1"
    local update_root="$2"
    local toolchain="$3"
    local silent="$4"

    log_info "Installing Rust via rustup..."
    log_info "RUSTUP_DIST_SERVER: $dist_server"
    log_info "RUSTUP_UPDATE_ROOT: $update_root"

    local rustup_init_url="https://sh.rustup.rs"

    # Build rustup-init arguments
    local rustup_args=("--default-toolchain" "$toolchain")
    if [[ "$silent" == true ]]; then
        rustup_args+=("-y")
    fi

    export RUSTUP_DIST_SERVER="$dist_server"
    export RUSTUP_UPDATE_ROOT="$update_root"

    if command_exists curl; then
        curl --proto '=https' --tlsv1.2 -sSf "$rustup_init_url" \
            | sh -s -- "${rustup_args[@]}"
    elif command_exists wget; then
        wget -qO- "$rustup_init_url" \
            | sh -s -- "${rustup_args[@]}"
    else
        log_error "Neither curl nor wget found"
        exit 1
    fi
}

configure_rustup_mirror() {
    local dist_server="$1"
    local update_root="$2"

    local shell_profile="${HOME}/.bashrc"
    [[ -f "${HOME}/.zshrc" ]] && shell_profile="${HOME}/.zshrc"

    local rustup_mirror_config="
# rustup mirror - added by china-mirror-skills
export RUSTUP_DIST_SERVER=\"${dist_server}\"
export RUSTUP_UPDATE_ROOT=\"${update_root}\""

    if grep -q "RUSTUP_DIST_SERVER" "$shell_profile" 2>/dev/null; then
        log_info "RUSTUP_DIST_SERVER already configured in $shell_profile"
        return 0
    fi

    echo "$rustup_mirror_config" >> "$shell_profile"
    log_success "rustup mirror configured in $shell_profile"
    log_info "This ensures future 'rustup update' also uses the mirror"
}

# ==================== Main ====================

main() {
    local mirror="$DEFAULT_MIRROR"
    local toolchain="$DEFAULT_TOOLCHAIN"
    local dry_run=false
    local yes=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mirror)
                mirror="$2"
                shift 2
                ;;
            -c|--toolchain)
                toolchain="$2"
                shift 2
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            -y|--yes)
                yes=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    if [[ -z "${RUSTUP_DIST_MIRRORS[$mirror]:-}" ]]; then
        log_error "Unknown mirror: $mirror"
        log_info "Available mirrors: ${!RUSTUP_DIST_MIRRORS[*]}"
        exit 1
    fi

    # Check if already installed
    if command_exists rustup; then
        log_info "Rust already installed:"
        rustup show active-toolchain 2>/dev/null || true
        log_info "To update: RUSTUP_DIST_SERVER=${RUSTUP_DIST_MIRRORS[$mirror]} rustup update"
        log_info "To configure Cargo crates mirror: bash scripts/rust/setup.sh"
        exit 0
    fi

    local dist_server="${RUSTUP_DIST_MIRRORS[$mirror]}"
    local update_root="${RUSTUP_UPDATE_ROOTS[$mirror]}"

    if [[ "$dry_run" == true ]]; then
        log_info "[DRY RUN] Would set RUSTUP_DIST_SERVER=$dist_server"
        log_info "[DRY RUN] Would set RUSTUP_UPDATE_ROOT=$update_root"
        log_info "[DRY RUN] Would run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        exit 0
    fi

    if [[ "$yes" == false ]]; then
        echo ""
        echo "This will:"
        echo "  1. Install rustup + Rust $toolchain via $mirror mirror"
        echo "     RUSTUP_DIST_SERVER=$dist_server"
        echo "  2. Configure $mirror mirror for future rustup updates"
        echo ""
        if ! confirm "Continue?" "y"; then
            exit 0
        fi
    fi

    # Install rustup
    install_rustup "$dist_server" "$update_root" "$toolchain" "$yes"

    # Configure mirror in shell profile for future updates
    configure_rustup_mirror "$dist_server" "$update_root"

    echo ""
    log_success "Rust installed!"
    log_info "Verify: source ~/.cargo/env && rustc --version"
    log_info ""
    log_info "Next: configure Cargo crates mirror for faster package downloads:"
    log_info "  bash scripts/rust/setup.sh"
}

main "$@"
