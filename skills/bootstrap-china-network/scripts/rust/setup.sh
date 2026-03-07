#!/bin/bash
#
# Setup Rust/Cargo mirror for China network environment
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# ==================== Configuration ====================

declare -A CARGO_MIRRORS=(
    ["ustc"]="https://mirrors.ustc.edu.cn/crates.io-index"
    ["tuna"]="https://mirrors.tuna.tsinghua.edu.cn/crates.io-index"
    ["rsproxy"]="https://rsproxy.cn/crates.io-index"
)

# rustup mirrors (for installing Rust itself)
declare -A RUSTUP_MIRRORS=(
    ["ustc"]="https://mirrors.ustc.edu.cn/rust-static"
    ["rsproxy"]="https://rsproxy.cn"
)

DEFAULT_MIRROR="ustc"
CARGO_CONFIG_DIR="${HOME}/.cargo"
CARGO_CONFIG_FILE="${CARGO_CONFIG_DIR}/config.toml"
LEGACY_CARGO_CONFIG="${CARGO_CONFIG_DIR}/config"

# ==================== Functions ====================

show_help() {
    cat << EOF
Setup Rust/Cargo mirror for China network environment

Usage: $(basename "$0") [OPTIONS]

Options:
  -m, --mirror MIRROR    Choose mirror (ustc|tuna|rsproxy)
                         Default: ustc
  -d, --dry-run          Show what would be changed without applying
  -y, --yes              Skip confirmation prompts
  -h, --help             Show this help message

This configures:
  - Cargo crates.io mirror (sparse index)
  - rustup mirror (for Rust installation)

Examples:
  $(basename "$0")                    # Use USTC mirror
  $(basename "$0") -m tuna            # Use TUNA mirror
  $(basename "$0") -m rsproxy         # Use rsproxy mirror (includes rustup)

Note: This requires Cargo 1.68+ for sparse index support.
EOF
}

generate_cargo_config() {
    local mirror_name="$1"
    local mirror_url="${CARGO_MIRRORS[$mirror_name]}"

    cat << EOF
# Cargo mirror configuration - added by china-mirror-skills
# Mirror: $mirror_name
# Generated: $(date -Iseconds)

[registries.crates-io]
index = "sparse+${mirror_url}/"

[net]
git-fetch-with-cli = true

# Optional: Use sparse index for faster updates
[registries]
EOF
}

generate_cargo_config_legacy() {
    local mirror_name="$1"
    local mirror_url="${CARGO_MIRRORS[$mirror_name]}"

    cat << EOF
# Cargo mirror configuration - added by china-mirror-skills
# Mirror: $mirror_name
# Generated: $(date -Iseconds)
# NOTE: Using git-based index (slower than sparse)

[source.crates-io]
replace-with = '${mirror_name}'

[source.${mirror_name}]
registry = "${mirror_url}"

[net]
git-fetch-with-cli = true
EOF
}

setup_cargo_mirror() {
    local mirror_name="$1"
    local mirror_url="${CARGO_MIRRORS[$mirror_name]}"

    log_info "Setting up Cargo mirror: $mirror_name"
    log_info "Mirror URL: $mirror_url"

    # Check for proxy conflicts
    warn_proxy_conflict

    # Check if cargo is installed
    if ! command_exists cargo; then
        log_warn "Cargo not found in PATH"
        log_info "To install Rust with this mirror, set these environment variables first:"
        if [[ -n "${RUSTUP_MIRRORS[$mirror_name]:-}" ]]; then
            echo "  export RUSTUP_DIST_SERVER=${RUSTUP_MIRRORS[$mirror_name]}"
            echo "  export RUSTUP_UPDATE_ROOT=${RUSTUP_MIRRORS[$mirror_name]}/rustup"
        fi
        log_info "Then run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        return 1
    fi

    # Check Cargo version for sparse index support
    local cargo_version
    cargo_version=$(cargo --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
    local major_version
    major_version=$(echo "$cargo_version" | cut -d. -f1)
    local minor_version
    minor_version=$(echo "$cargo_version" | cut -d. -f2)

    local use_sparse=false
    if [[ "$major_version" -gt 1 ]] || [[ "$major_version" -eq 1 && "$minor_version" -ge 68 ]]; then
        use_sparse=true
        log_info "Cargo $cargo_version supports sparse index"
    else
        log_warn "Cargo $cargo_version does not support sparse index (requires 1.68+)"
        log_info "Falling back to git-based index"
    fi

    # Determine config file location
    local config_file="$CARGO_CONFIG_FILE"
    if [[ -f "$LEGACY_CARGO_CONFIG" && ! -f "$CARGO_CONFIG_FILE" ]]; then
        config_file="$LEGACY_CARGO_CONFIG"
    fi

    # Backup existing config
    if [[ -f "$config_file" ]]; then
        backup_file "$config_file" "cargo"
    fi

    # Create config directory
    mkdir -p "$CARGO_CONFIG_DIR"

    # Generate config
    if [[ "$use_sparse" == true ]]; then
        generate_cargo_config "$mirror_name" > "$config_file"
    else
        generate_cargo_config_legacy "$mirror_name" > "$config_file"
    fi

    log_success "Cargo config written to: $config_file"

    # Add rustup mirror to shell profile if applicable
    if [[ -n "${RUSTUP_MIRRORS[$mirror_name]:-}" ]]; then
        log_info ""
        log_info "To use mirror for rustup (Rust installation), add to your shell profile:"
        echo "  export RUSTUP_DIST_SERVER=${RUSTUP_MIRRORS[$mirror_name]}"
        echo "  export RUSTUP_UPDATE_ROOT=${RUSTUP_MIRRORS[$mirror_name]}/rustup"
    fi
}

verify_cargo() {
    if command_exists cargo; then
        log_info ""
        log_info "Cargo version: $(cargo --version)"
        log_info "To verify mirror is working, run: cargo search anyhow"
    fi
}

# ==================== Main ====================

main() {
    local mirror="$DEFAULT_MIRROR"
    local dry_run=false
    local yes=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mirror)
                mirror="$2"
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

    # Validate mirror
    if [[ -z "${CARGO_MIRRORS[$mirror]:-}" ]]; then
        log_error "Unknown mirror: $mirror"
        log_info "Available mirrors: ${!CARGO_MIRRORS[*]}"
        exit 1
    fi

    # Confirm
    if [[ "$yes" == false && "$dry_run" == false ]]; then
        echo ""
        echo "This will configure Cargo to use:"
        echo "  Mirror: $mirror (${CARGO_MIRRORS[$mirror]})"
        echo ""
        if ! confirm "Continue?" "y"; then
            exit 0
        fi
    fi

    # Execute
    if [[ "$dry_run" == true ]]; then
        log_info "[DRY RUN] Would configure Cargo for $mirror mirror"
        exit 0
    fi

    setup_cargo_mirror "$mirror"
    verify_cargo

    echo ""
    log_success "Setup complete!"
}

main "$@"
