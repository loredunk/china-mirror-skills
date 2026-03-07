#!/bin/bash
#
# Setup npm/yarn/pnpm mirror for China network environment
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# ==================== Configuration ====================

declare -A NPM_MIRRORS=(
    ["npmmirror"]="https://registry.npmmirror.com"
    ["tencent"]="https://mirrors.cloud.tencent.com/npm/"
    ["tuna"]="https://mirrors.tuna.tsinghua.edu.cn/npm/"
    ["ustc"]="https://mirrors.ustc.edu.cn/npm/"
)

declare -A BINARY_MIRRORS=(
    ["npmmirror"]="https://npmmirror.com/mirrors"
    ["tencent"]="https://mirrors.cloud.tencent.com"
)

DEFAULT_MIRROR="npmmirror"
NPMRC_FILE="${HOME}/.npmrc"

# ==================== Functions ====================

show_help() {
    cat << EOF
Setup npm/yarn/pnpm mirror for China network environment

Usage: $(basename "$0") [OPTIONS]

Options:
  -m, --mirror MIRROR    Choose mirror (npmmirror|tencent|tuna|ustc)
                         Default: npmmirror
  -t, --tool TOOL        Target tool (npm|yarn|pnpm|all)
                         Default: npm
  -f, --force            Force overwrite existing config
  -d, --dry-run          Show what would be changed without applying
  -y, --yes              Skip confirmation prompts
  -h, --help             Show this help message

Examples:
  $(basename "$0")                    # Use npmmirror
  $(basename "$0") -m tencent         # Use Tencent mirror
  $(basename "$0") -t all             # Configure all Node tools
EOF
}

setup_npm_config() {
    local mirror_name="$1"
    local registry_url="${NPM_MIRRORS[$mirror_name]}"
    local binary_url="${BINARY_MIRRORS[$mirror_name]:-}"

    log_info "Setting up npm to use $mirror_name mirror..."
    log_info "Registry URL: $registry_url"

    # Check for proxy conflicts
    warn_proxy_conflict

    # Backup existing .npmrc
    if [[ -f "$NPMRC_FILE" ]]; then
        backup_file "$NPMRC_FILE" "npm"
    fi

    # Create new .npmrc
    cat > "$NPMRC_FILE" << EOF
# Configured by china-mirror-skills
# Mirror: $mirror_name
registry=${registry_url}

# Increase timeouts for slow connections
fetch-retries=5
fetch-timeout=120000
EOF

    # Add binary mirrors if available
    if [[ -n "$binary_url" ]]; then
        cat >> "$NPMRC_FILE" << EOF

# Binary mirrors for native packages
disturl=${binary_url}/node
electron_mirror=${binary_url}/electron/
chromedriver_cdnurl=${binary_url}/chromedriver
operadriver_cdnurl=${binary_url}/operadriver
phantomjs_cdnurl=${binary_url}/phantomjs
sass_binary_site=${binary_url}/node-sass
EOF
    fi

    log_success "npm config written to: $NPMRC_FILE"
}

setup_yarn_config() {
    local mirror_name="$1"
    local registry_url="${NPM_MIRRORS[$mirror_name]}"

    log_info "Setting up yarn to use $mirror_name mirror..."

    if ! command_exists yarn; then
        log_warn "Yarn not found in PATH"
        return 1
    fi

    # Backup is trickier with yarn as it stores config in various places
    # We'll use yarn config commands

    yarn config set registry "$registry_url"

    # Set timeouts
    yarn config set network-timeout 120000

    log_success "Yarn registry configured: $registry_url"
}

setup_pnpm_config() {
    local mirror_name="$1"
    local registry_url="${NPM_MIRRORS[$mirror_name]}"

    log_info "Setting up pnpm to use $mirror_name mirror..."

    if ! command_exists pnpm; then
        log_warn "pnpm not found in PATH"
        return 1
    fi

    # pnpm uses .npmrc, so npm config should cover it
    # But we can also set it explicitly
    pnpm config set registry "$registry_url"

    log_success "pnpm registry configured: $registry_url"
}

verify_npm() {
    if command_exists npm; then
        log_info "Verifying npm configuration..."
        local current_registry
        current_registry=$(npm config get registry)
        log_info "Current npm registry: $current_registry"

        # Test with a simple package info request
        log_info "Testing npm connectivity..."
        if npm view npm version >/dev/null 2>&1; then
            log_success "npm connectivity test passed"
        else
            log_warn "npm connectivity test failed - check network"
        fi
    fi
}

# ==================== Main ====================

main() {
    local mirror="$DEFAULT_MIRROR"
    local tool="npm"
    local force=false
    local dry_run=false
    local yes=false

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
    if [[ -z "${NPM_MIRRORS[$mirror]:-}" ]]; then
        log_error "Unknown mirror: $mirror"
        log_info "Available mirrors: ${!NPM_MIRRORS[*]}"
        exit 1
    fi

    # Confirm
    if [[ "$yes" == false && "$dry_run" == false ]]; then
        echo ""
        echo "This will configure Node.js package managers to use:"
        echo "  Mirror: $mirror (${NPM_MIRRORS[$mirror]})"
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
        npm)
            setup_npm_config "$mirror"
            verify_npm
            ;;
        yarn)
            setup_yarn_config "$mirror"
            ;;
        pnpm)
            setup_pnpm_config "$mirror"
            ;;
        all)
            setup_npm_config "$mirror"
            setup_yarn_config "$mirror"
            setup_pnpm_config "$mirror"
            verify_npm
            ;;
        *)
            log_error "Unknown tool: $tool"
            exit 1
            ;;
    esac

    echo ""
    log_success "Setup complete!"
    log_info "You can verify with: npm config get registry"
}

main "$@"
