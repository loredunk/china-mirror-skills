#!/bin/bash
#
# Install Node.js via nvm using China mirror
# Uses NVM_NODEJS_ORG_MIRROR to download Node.js from Chinese mirrors
#
# Prerequisites: curl or wget
#

set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# ==================== Configuration ====================

declare -A NODE_BINARY_MIRRORS=(
    ["npmmirror"]="https://npmmirror.com/mirrors/node/"
    ["tuna"]="https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/"
)

declare -A NVM_INSTALL_MIRRORS=(
    ["tuna"]="https://mirrors.tuna.tsinghua.edu.cn/git/nvm.git"
    ["ghfast"]="https://ghfast.top/https://github.com/nvm-sh/nvm.git"
)

DEFAULT_MIRROR="npmmirror"
DEFAULT_VERSION="20"    # LTS
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
NVM_VERSION="v0.40.1"

# ==================== Functions ====================

show_help() {
    cat << EOF
Install Node.js via nvm using China mirror

Usage: $(basename "$0") [OPTIONS]

Options:
  -v, --version VERSION  Node.js version to install (default: $DEFAULT_VERSION)
                         Supports: 20, 22, 18, lts, latest, list
  -m, --mirror MIRROR    Binary mirror (npmmirror|tuna)
                         Default: npmmirror
  -d, --dry-run          Show what would be done without executing
  -y, --yes              Skip confirmation prompts
  -h, --help             Show this help message

Examples:
  $(basename "$0")                       # Install Node.js LTS ($DEFAULT_VERSION) via npmmirror
  $(basename "$0") -v 22                 # Install Node.js 22
  $(basename "$0") -v lts                # Install latest LTS
  $(basename "$0") -v list               # List available versions
  $(basename "$0") -m tuna               # Use TUNA mirror
EOF
}

install_nvm() {
    if [[ -d "$NVM_DIR" ]] && [[ -s "$NVM_DIR/nvm.sh" ]]; then
        log_info "nvm already installed at $NVM_DIR"
        return 0
    fi

    log_info "Installing nvm $NVM_VERSION..."
    log_info "Trying TUNA git mirror for nvm..."

    local install_ok=false

    # Try TUNA git mirror first
    if git clone --branch "$NVM_VERSION" \
        "${NVM_INSTALL_MIRRORS[tuna]}" "$NVM_DIR" 2>/dev/null; then
        install_ok=true
        log_success "nvm installed from TUNA mirror"
    else
        log_warn "TUNA mirror failed, trying ghfast proxy..."
        if git clone --branch "$NVM_VERSION" \
            "${NVM_INSTALL_MIRRORS[ghfast]}" "$NVM_DIR" 2>/dev/null; then
            install_ok=true
            log_success "nvm installed from ghfast proxy"
        fi
    fi

    if [[ "$install_ok" == false ]]; then
        log_error "Failed to install nvm. Please check your network or install manually."
        exit 1
    fi
}

configure_nvm_shell() {
    local shell_profile=""
    if [[ -f "${HOME}/.zshrc" ]]; then
        shell_profile="${HOME}/.zshrc"
    elif [[ -f "${HOME}/.bashrc" ]]; then
        shell_profile="${HOME}/.bashrc"
    else
        shell_profile="${HOME}/.profile"
    fi

    local nvm_init='
# nvm configuration - added by china-mirror-skills
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'

    local nvm_mirror_config="# nvm Node.js mirror - added by china-mirror-skills
export NVM_NODEJS_ORG_MIRROR=\"MIRROR_URL_PLACEHOLDER\""

    if grep -q "NVM_DIR" "$shell_profile" 2>/dev/null; then
        log_info "nvm already configured in $shell_profile"
    else
        echo "$nvm_init" >> "$shell_profile"
        log_success "nvm shell init added to $shell_profile"
    fi

    # Configure mirror
    if grep -q "NVM_NODEJS_ORG_MIRROR" "$shell_profile" 2>/dev/null; then
        log_info "NVM_NODEJS_ORG_MIRROR already set in $shell_profile"
    else
        echo "" >> "$shell_profile"
        echo "$nvm_mirror_config" >> "$shell_profile"
        log_success "NVM_NODEJS_ORG_MIRROR configured in $shell_profile"
    fi

    log_info "Run: source $shell_profile  (or open a new terminal)"
}

install_node_version() {
    local version="$1"
    local mirror_url="$2"

    # Load nvm in current shell
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

    if ! command_exists nvm 2>/dev/null && ! type nvm &>/dev/null; then
        log_error "nvm command not available. Try: source ~/.bashrc or source ~/.zshrc"
        exit 1
    fi

    if [[ "$version" == "list" ]]; then
        log_info "Available Node.js LTS versions:"
        NVM_NODEJS_ORG_MIRROR="$mirror_url" nvm ls-remote --lts | tail -20
        return 0
    fi

    # Map friendly names
    case "$version" in
        lts)   version="--lts" ;;
        latest) version="node" ;;
    esac

    log_info "Installing Node.js $version via $mirror_url ..."
    NVM_NODEJS_ORG_MIRROR="$mirror_url" nvm install "$version"

    # Set as default
    if [[ "$version" != "--lts" && "$version" != "node" ]]; then
        nvm alias default "$version" 2>/dev/null || true
    else
        nvm alias default "$(nvm current)" 2>/dev/null || true
    fi

    log_success "Node.js $(node --version) installed!"
    log_info "npm version: $(npm --version)"
}

# ==================== Main ====================

main() {
    local version="$DEFAULT_VERSION"
    local mirror="$DEFAULT_MIRROR"
    local dry_run=false
    local yes=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--version)
                version="$2"
                shift 2
                ;;
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

    if [[ -z "${NODE_BINARY_MIRRORS[$mirror]:-}" ]]; then
        log_error "Unknown mirror: $mirror"
        log_info "Available mirrors: ${!NODE_BINARY_MIRRORS[*]}"
        exit 1
    fi

    local mirror_url="${NODE_BINARY_MIRRORS[$mirror]}"

    if [[ "$dry_run" == true ]]; then
        log_info "[DRY RUN] Would install Node.js $version via $mirror mirror"
        log_info "[DRY RUN] NVM_NODEJS_ORG_MIRROR=$mirror_url"
        log_info "[DRY RUN] nvm install $version"
        exit 0
    fi

    if [[ "$yes" == false && "$version" != "list" ]]; then
        echo ""
        echo "This will:"
        echo "  1. Install nvm (if not present) from TUNA git mirror"
        echo "  2. Install Node.js $version via $mirror mirror ($mirror_url)"
        echo ""
        if ! confirm "Continue?" "y"; then
            exit 0
        fi
    fi

    # Install nvm
    install_nvm

    # Configure shell profile
    configure_nvm_shell

    # Replace mirror placeholder in shell profile
    local shell_profile="${HOME}/.zshrc"
    [[ ! -f "$shell_profile" ]] && shell_profile="${HOME}/.bashrc"
    if grep -q "MIRROR_URL_PLACEHOLDER" "$shell_profile" 2>/dev/null; then
        sed -i.bak "s|MIRROR_URL_PLACEHOLDER|$mirror_url|g" "$shell_profile"
        rm -f "${shell_profile}.bak"
    fi

    # Install Node.js version
    install_node_version "$version" "$mirror_url"

    echo ""
    log_success "Done!"
    if [[ "$version" != "list" ]]; then
        log_info "Verify: node --version && npm --version"
        log_info "Future nvm installs will use: NVM_NODEJS_ORG_MIRROR=$mirror_url"
    fi
}

main "$@"
