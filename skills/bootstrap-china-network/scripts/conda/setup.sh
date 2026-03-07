#!/bin/bash
#
# Setup Conda/Anaconda mirror for China network environment
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# ==================== Configuration ====================

declare -A CONDA_MIRRORS=(
    ["tuna"]="https://mirrors.tuna.tsinghua.edu.cn/anaconda"
    ["ustc"]="https://mirrors.ustc.edu.cn/anaconda"
)

DEFAULT_MIRROR="tuna"
CONDARC_FILE="${HOME}/.condarc"

# Default channels to configure
CONDA_CHANNELS=("defaults" "conda-forge")

# ==================== Functions ====================

show_help() {
    cat << EOF
Setup Conda/Anaconda mirror for China network environment

Usage: $(basename "$0") [OPTIONS]

Options:
  -m, --mirror MIRROR    Choose mirror (tuna|ustc)
                         Default: tuna
  -d, --dry-run          Show what would be changed without applying
  -y, --yes              Skip confirmation prompts
  -h, --help             Show this help message

This configures:
  - Anaconda main repository
  - Conda-forge repository
  - Free repository (if available)

Examples:
  $(basename "$0")                    # Use Tsinghua mirror
  $(basename "$0") -m ustc            # Use USTC mirror
EOF
}

generate_condarc() {
    local mirror_name="$1"
    local mirror_url="${CONDA_MIRRORS[$mirror_name]}"

    cat << EOF
# Conda mirror configuration - added by china-mirror-skills
# Mirror: $mirror_name
# Generated: $(date -Iseconds)

channels:
  - defaults
show_channel_urls: true
default_channels:
  - ${mirror_url}/pkgs/main
  - ${mirror_url}/pkgs/r
  - ${mirror_url}/pkgs/msys2
custom_channels:
  conda-forge: ${mirror_url}/cloud
  bioconda: ${mirror_url}/cloud
  menpo: ${mirror_url}/cloud
  pytorch: ${mirror_url}/cloud
  pytorch-lts: ${mirror_url}/cloud
  simpleitk: ${mirror_url}/cloud
EOF
}

setup_conda_mirror() {
    local mirror_name="$1"
    local mirror_url="${CONDA_MIRRORS[$mirror_name]}"

    log_info "Setting up Conda mirror: $mirror_name"
    log_info "Mirror URL: $mirror_url"

    # Check for proxy conflicts
    warn_proxy_conflict

    # Check if conda is installed
    local conda_cmd=""
    if command_exists conda; then
        conda_cmd="conda"
    elif command_exists mamba; then
        conda_cmd="mamba"
        log_info "Using mamba instead of conda"
    fi

    if [[ -z "$conda_cmd" ]]; then
        log_warn "Neither conda nor mamba found in PATH"
        log_info "Please install Anaconda or Miniconda first"
        return 1
    fi

    # Backup existing .condarc
    if [[ -f "$CONDARC_FILE" ]]; then
        backup_file "$CONDARC_FILE" "conda"
    fi

    # Generate new .condarc
    log_info "Generating .condarc..."
    generate_conda_mirror "$mirror_name" > "$CONDARC_FILE"

    log_success "Conda configuration written to: $CONDARC_FILE"

    # Clean conda cache to use new mirrors
    log_info "Cleaning conda cache..."
    $conda_cmd clean -i -y || true

    # Test configuration
    log_info "Testing conda configuration..."
    if $conda_cmd info | grep -q "$mirror_url"; then
        log_success "Conda is using the mirror!"
    else
        log_warn "Could not verify conda configuration"
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
    if [[ -z "${CONDA_MIRRORS[$mirror]:-}" ]]; then
        log_error "Unknown mirror: $mirror"
        log_info "Available mirrors: ${!CONDA_MIRRORS[*]}"
        exit 1
    fi

    # Confirm
    if [[ "$yes" == false && "$dry_run" == false ]]; then
        echo ""
        echo "This will configure Conda to use:"
        echo "  Mirror: $mirror (${CONDA_MIRRORS[$mirror]})"
        echo "  Config file: $CONDARC_FILE"
        echo ""
        if ! confirm "Continue?" "y"; then
            exit 0
        fi
    fi

    # Execute
    if [[ "$dry_run" == true ]]; then
        log_info "[DRY RUN] Would configure Conda for $mirror mirror"
        log_info "[DRY RUN] Generated .condarc would be:"
        generate_condarc "$mirror"
        exit 0
    fi

    setup_conda_mirror "$mirror"

    echo ""
    log_success "Setup complete!"
    log_info "You can verify with: conda config --show channels"
    log_info "Or: conda info"
}

main "$@"
