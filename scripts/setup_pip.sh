#!/bin/bash
#
# Setup pip mirror for China network environment
# Supports: pip, pip3, uv, poetry
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

# ==================== Configuration ====================

# Mirror URLs
declare -A PIP_MIRRORS=(
    ["tuna"]="https://pypi.tuna.tsinghua.edu.cn/simple"
    ["ustc"]="https://pypi.mirrors.ustc.edu.cn/simple"
    ["aliyun"]="https://mirrors.aliyun.com/pypi/simple"
    ["douban"]="https://pypi.doubanio.com/simple"
    ["tencent"]="https://mirrors.cloud.tencent.com/pypi/simple"
)

# Default mirror
DEFAULT_MIRROR="tuna"

# Config file locations
PIP_CONFIG_DIR="${HOME}/.config/pip"
PIP_CONFIG_FILE="${PIP_CONFIG_DIR}/pip.conf"
LEGACY_PIP_CONFIG="${HOME}/.pip/pip.conf"

# ==================== Functions ====================

show_help() {
    cat << EOF
Setup pip mirror for China network environment

Usage: $(basename "$0") [OPTIONS]

Options:
  -m, --mirror MIRROR    Choose mirror (tuna|ustc|aliyun|douban|tencent)
                         Default: tuna
  -t, --tool TOOL        Target tool (pip|uv|poetry|all)
                         Default: pip
  -f, --force            Force overwrite existing config
  -d, --dry-run          Show what would be changed without applying
  -y, --yes              Skip confirmation prompts
  -r, --restore          Restore from backup
  -h, --help             Show this help message

Examples:
  $(basename "$0")                    # Use default Tsinghua mirror
  $(basename "$0") -m ustc            # Use USTC mirror
  $(basename "$0") -t all             # Configure all Python tools
  $(basename "$0") -d                 # Dry run
EOF
}

detect_python_tools() {
    local tools=()
    command_exists pip && tools+=("pip")
    command_exists pip3 && tools+=("pip3")
    command_exists uv && tools+=("uv")
    command_exists poetry && tools+=("poetry")
    echo "${tools[*]}"
}

setup_pip_config() {
    local mirror_name="$1"
    local mirror_url="${PIP_MIRRORS[$mirror_name]}"

    log_info "Setting up pip to use $mirror_name mirror..."
    log_info "Mirror URL: $mirror_url"

    # Check for proxy conflicts
    warn_proxy_conflict

    # Determine config file location
    local config_file="$PIP_CONFIG_FILE"
    if [[ -f "$LEGACY_PIP_CONFIG" && ! -f "$PIP_CONFIG_FILE" ]]; then
        config_file="$LEGACY_PIP_CONFIG"
    fi

    # Backup existing config
    if [[ -f "$config_file" ]]; then
        backup_file "$config_file" "pip"
    fi

    # Create config directory
    mkdir -p "$(dirname "$config_file")"

    # Generate pip config
    cat > "$config_file" << EOF
[global]
index-url = ${mirror_url}
trusted-host = $(echo "$mirror_url" | sed -E 's|https?://||' | cut -d'/' -f1)
timeout = 120
retries = 5

[install]
use-pep517 = true
EOF

    log_success "pip config written to: $config_file"
}

setup_uv_config() {
    local mirror_name="$1"
    local mirror_url="${PIP_MIRRORS[$mirror_name]}"

    log_info "Setting up uv to use $mirror_name mirror..."

    local uv_config_dir="${HOME}/.config/uv"
    local uv_config_file="${uv_config_dir}/uv.toml"

    # Backup existing config
    if [[ -f "$uv_config_file" ]]; then
        backup_file "$uv_config_file" "uv"
    fi

    mkdir -p "$uv_config_dir"

    cat > "$uv_config_file" << EOF
[pip]
index-url = "${mirror_url}"
trusted-host = ["$(echo "$mirror_url" | sed -E 's|https?://||' | cut -d'/' -f1)"]
EOF

    # Also set environment variable for immediate effect
    echo ""
    log_info "Add this to your shell profile for persistent configuration:"
    echo "  export UV_DEFAULT_INDEX=${mirror_url}"

    log_success "uv config written to: $uv_config_file"
}

setup_poetry_config() {
    local mirror_name="$1"
    local mirror_url="${PIP_MIRRORS[$mirror_name]}"

    log_info "Setting up Poetry to use $mirror_name mirror..."

    if ! command_exists poetry; then
        log_warn "Poetry not found in PATH"
        return 1
    fi

    # Poetry uses pip config for package installation
    # We just need to ensure Poetry doesn't override it

    log_info "Poetry uses pip's configuration. Ensure pip config is set."

    # Check poetry config
    local current_source
    current_source=$(poetry config repositories.pypi-url 2>/dev/null || echo "")

    if [[ -n "$current_source" && "$current_source" != "$mirror_url" ]]; then
        log_warn "Poetry has custom pypi-url: $current_source"
        log_info "Run: poetry config repositories.pypi-url ${mirror_url}"
    fi

    log_success "Poetry configuration complete"
}

verify_pip() {
    if command_exists pip; then
        log_info "Testing pip configuration..."
        local output
        output=$(pip config get global.index-url 2>/dev/null || echo "")
        if [[ -n "$output" ]]; then
            log_success "pip index-url: $output"
        else
            log_warn "Could not verify pip configuration"
        fi
    fi
}

# ==================== Main ====================

main() {
    local mirror="$DEFAULT_MIRROR"
    local tool="pip"
    local force=false
    local dry_run=false
    local yes=false
    local restore=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mirror)
                mirror="$2"
                shift 2
                ;;
            -t|--tool)
                tool="$2"
                shift 2
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            -y|--yes)
                yes=true
                shift
                ;;
            -r|--restore)
                restore=true
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
    if [[ -z "${PIP_MIRRORS[$mirror]:-}" ]]; then
        log_error "Unknown mirror: $mirror"
        log_info "Available mirrors: ${!PIP_MIRRORS[*]}"
        exit 1
    fi

    # Show detected tools
    log_info "Detected Python tools: $(detect_python_tools)"

    # Confirm
    if [[ "$yes" == false && "$dry_run" == false ]]; then
        echo ""
        echo "This will configure Python package managers to use:"
        echo "  Mirror: $mirror (${PIP_MIRRORS[$mirror]})"
        echo "  Tools: $tool"
        echo ""
        if ! confirm "Continue?" "y"; then
            exit 0
        fi
    fi

    # Execute
    if [[ "$dry_run" == true ]]; then
        log_info "[DRY RUN] Would configure $tool to use $mirror mirror"
        exit 0
    fi

    case "$tool" in
        pip)
            setup_pip_config "$mirror"
            verify_pip
            ;;
        uv)
            setup_uv_config "$mirror"
            ;;
        poetry)
            setup_poetry_config "$mirror"
            ;;
        all)
            setup_pip_config "$mirror"
            setup_uv_config "$mirror"
            setup_poetry_config "$mirror"
            verify_pip
            ;;
        *)
            log_error "Unknown tool: $tool"
            exit 1
            ;;
    esac

    echo ""
    log_success "Setup complete!"
    log_info "You can restore original configuration with:"
    log_info "  ./scripts/restore_config.sh --tool pip --latest"
}

main "$@"
