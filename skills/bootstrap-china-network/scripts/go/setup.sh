#!/bin/bash
#
# Setup Go module proxy for China network environment
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# ==================== Configuration ====================

declare -A GO_PROXIES=(
    ["goproxy"]="https://goproxy.cn"
    ["ustc"]="https://goproxy.ustc.edu.cn"
    ["aliyun"]="https://mirrors.aliyun.com/goproxy/"
)

DEFAULT_PROXY="goproxy"

# ==================== Functions ====================

show_help() {
    cat << EOF
Setup Go module proxy for China network environment

Usage: $(basename "$0") [OPTIONS]

Options:
  -m, --mirror MIRROR    Choose proxy (goproxy|ustc|aliyun)
                         Default: goproxy
  -d, --dry-run          Show what would be changed without applying
  -y, --yes              Skip confirmation prompts
  -h, --help             Show this help message

This configures the GOPROXY environment variable.
The change is applied to your shell profile.

Examples:
  $(basename "$0")                    # Use goproxy.cn
  $(basename "$0") -m ustc            # Use USTC proxy

After setup, restart your shell or run:
  source ~/.bashrc (or ~/.zshrc)
EOF
}

setup_go_proxy() {
    local proxy_name="$1"
    local proxy_url="${GO_PROXIES[$proxy_name]}"

    log_info "Setting up Go module proxy: $proxy_name"
    log_info "Proxy URL: $proxy_url"

    # Check for proxy conflicts
    warn_proxy_conflict

    # Check if Go is installed
    if ! command_exists go; then
        log_warn "Go not found in PATH"
        log_info "Please install Go first: https://golang.org/dl/"
        return 1
    fi

    log_info "Go version: $(go version)"

    # Detect current shell
    local shell_profile=""
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
        shell_profile="${HOME}/.zshrc"
    elif [[ -n "${BASH_VERSION:-}" ]] || [[ "$SHELL" == */bash ]]; then
        shell_profile="${HOME}/.bashrc"
        [[ ! -f "$shell_profile" ]] && shell_profile="${HOME}/.bash_profile"
    fi

    if [[ -z "$shell_profile" ]]; then
        log_error "Could not detect shell profile"
        return 1
    fi

    # Backup shell profile
    backup_file "$shell_profile" "go"

    # Check if GOPROXY is already set
    if grep -q "export GOPROXY=" "$shell_profile" 2>/dev/null; then
        log_warn "GOPROXY already configured in $shell_profile"
        log_info "Replacing with new configuration..."

        # Remove old GOPROXY config
        local temp_file
        temp_file=$(mktemp)
        sed '/^# Go module proxy configuration/,/^export GOPRIVATE=/d' "$shell_profile" > "$temp_file"
        mv "$temp_file" "$shell_profile"
    fi

    # Add GOPROXY configuration
    cat >> "$shell_profile" << EOF

# Go module proxy configuration - added by china-mirror-skills
export GOPROXY="${proxy_url},direct"
export GO111MODULE=on
export GOPRIVATE=""
EOF

    log_success "Go proxy configured in: $shell_profile"
    log_info "Run 'source $shell_profile' or restart your shell to apply"

    # Also set for current session
    export GOPROXY="${proxy_url},direct"
    export GO111MODULE=on

    # Verify
    log_info ""
    log_info "Current GOPROXY: $(go env GOPROXY)"
}

# ==================== Main ====================

main() {
    local mirror="$DEFAULT_PROXY"
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
    if [[ -z "${GO_PROXIES[$mirror]:-}" ]]; then
        log_error "Unknown proxy: $mirror"
        log_info "Available proxies: ${!GO_PROXIES[*]}"
        exit 1
    fi

    # Confirm
    if [[ "$yes" == false && "$dry_run" == false ]]; then
        echo ""
        echo "This will configure Go to use:"
        echo "  Proxy: $mirror (${GO_PROXIES[$mirror]})"
        echo ""
        if ! confirm "Continue?" "y"; then
            exit 0
        fi
    fi

    # Execute
    if [[ "$dry_run" == true ]]; then
        log_info "[DRY RUN] Would configure Go proxy to $mirror"
        exit 0
    fi

    setup_go_proxy "$mirror"

    echo ""
    log_success "Setup complete!"
    log_info "Test with: go env GOPROXY"
}

main "$@"
