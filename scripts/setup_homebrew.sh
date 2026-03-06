#!/bin/bash
#
# Setup Homebrew mirror for China network environment
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

# ==================== Configuration ====================

declare -A BREW_MIRRORS=(
    ["tuna"]="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew"
    ["ustc"]="https://mirrors.ustc.edu.cn/brew.git"
)

DEFAULT_MIRROR="tuna"

# Homebrew repositories
BREW_REPOS=("brew" "core" "cask" "services")

# ==================== Functions ====================

show_help() {
    cat << EOF
Setup Homebrew mirror for China network environment

Usage: $(basename "$0") [OPTIONS]

Options:
  -m, --mirror MIRROR    Choose mirror (tuna|ustc)
                         Default: tuna
  -d, --dry-run          Show what would be changed without applying
  -y, --yes              Skip confirmation prompts
  -h, --help             Show this help message

Note: Homebrew mirrors are git repositories. This configures:
  - Homebrew/brew (main repository)
  - Homebrew/homebrew-core
  - Homebrew/homebrew-cask
  - Homebrew/homebrew-services

Examples:
  $(basename "$0")                    # Use Tsinghua mirror
  $(basename "$0") -m ustc            # Use USTC mirror

After setup, run: brew update
EOF
}

setup_homebrew_mirror() {
    local mirror_name="$1"
    local mirror_url="${BREW_MIRRORS[$mirror_name]}"

    log_info "Setting up Homebrew mirror: $mirror_name"
    log_info "Mirror URL: $mirror_url"

    # Check for proxy conflicts
    warn_proxy_conflict

    # Check if Homebrew is installed
    if ! command_exists brew; then
        log_warn "Homebrew not found. Installing with mirror..."
        install_homebrew_with_mirror "$mirror_name"
        return
    fi

    # Backup current configuration
    local brew_prefix
    brew_prefix=$(brew --prefix)

    # Get current shell profile
    local shell_profile=""
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
        shell_profile="${HOME}/.zshrc"
    elif [[ -n "${BASH_VERSION:-}" ]] || [[ "$SHELL" == */bash ]]; then
        shell_profile="${HOME}/.bash_profile"
        [[ ! -f "$shell_profile" ]] && shell_profile="${HOME}/.bashrc"
    fi

    if [[ -n "$shell_profile" && -f "$shell_profile" ]]; then
        backup_file "$shell_profile" "homebrew"
    fi

    # Configure Homebrew environment variables
    log_info "Configuring Homebrew environment..."

    # Set HOMEBREW_BREW_GIT_REMOTE and others
    local config_lines="
# Homebrew mirror configuration - added by china-mirror-skills
export HOMEBREW_BREW_GIT_REMOTE=\"${mirror_url}/brew.git\"
export HOMEBREW_CORE_GIT_REMOTE=\"${mirror_url}/homebrew-core.git\"
export HOMEBREW_BOTTLE_DOMAIN=\"${mirror_url}/homebrew-bottles\"
"

    # Add to shell profile
    if [[ -n "$shell_profile" ]]; then
        # Remove old config if exists
        if grep -q "# Homebrew mirror configuration - added by china-mirror-skills" "$shell_profile"; then
            log_info "Removing old Homebrew configuration..."
            local temp_file
            temp_file=$(mktemp)
            sed '/# Homebrew mirror configuration - added by china-mirror-skills/,/^$/d' "$shell_profile" > "$temp_file"
            mv "$temp_file" "$shell_profile"
        fi

        echo "$config_lines" >> "$shell_profile"
        log_success "Homebrew configuration added to $shell_profile"
    fi

    # Update existing Homebrew installation
    log_info "Updating Homebrew with new mirror..."
    export HOMEBREW_BREW_GIT_REMOTE="${mirror_url}/brew.git"
    export HOMEBREW_CORE_GIT_REMOTE="${mirror_url}/homebrew-core.git"
    export HOMEBREW_BOTTLE_DOMAIN="${mirror_url}/homebrew-bottles"

    # Change remote URLs for existing repos
    if [[ -d "$brew_prefix/.git" ]]; then
        log_info "Updating Homebrew/brew remote..."
        git -C "$brew_prefix" remote set-url origin "${mirror_url}/brew.git" || true
    fi

    if [[ -d "$brew_prefix/Library/Taps/homebrew/homebrew-core/.git" ]]; then
        log_info "Updating homebrew-core remote..."
        git -C "$brew_prefix/Library/Taps/homebrew/homebrew-core" remote set-url origin "${mirror_url}/homebrew-core.git" || true
    fi

    if [[ -d "$brew_prefix/Library/Taps/homebrew/homebrew-cask/.git" ]]; then
        log_info "Updating homebrew-cask remote..."
        git -C "$brew_prefix/Library/Taps/homebrew/homebrew-cask" remote set-url origin "${mirror_url}/homebrew-cask.git" || true
    fi

    log_success "Homebrew mirror configured!"
    log_info "Run 'source $shell_profile' or restart your shell to apply changes."
    log_info "Then run: brew update"
}

install_homebrew_with_mirror() {
    local mirror_name="$1"
    local mirror_url="${BREW_MIRRORS[$mirror_name]}"

    log_info "Installing Homebrew with $mirror_name mirror..."

    # Set environment variables for install script
    export HOMEBREW_BREW_GIT_REMOTE="${mirror_url}/brew.git"
    export HOMEBREW_CORE_GIT_REMOTE="${mirror_url}/homebrew-core.git"

    # Run official installer
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Configure bottle domain after install
    local shell_profile=""
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
        shell_profile="${HOME}/.zshrc"
    else
        shell_profile="${HOME}/.bash_profile"
    fi

    echo "export HOMEBREW_BOTTLE_DOMAIN=\"${mirror_url}/homebrew-bottles\"" >> "$shell_profile"

    log_success "Homebrew installed with $mirror_name mirror!"
    log_info "Run 'source $shell_profile' or restart your shell."
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
    if [[ -z "${BREW_MIRRORS[$mirror]:-}" ]]; then
        log_error "Unknown mirror: $mirror"
        log_info "Available mirrors: ${!BREW_MIRRORS[*]}"
        exit 1
    fi

    # Detect OS
    local os
    os=$(detect_os)
    if [[ "$os" != "macos" ]]; then
        log_warn "Homebrew is primarily for macOS. Linux (Homebrew on Linux) is supported but not recommended."
    fi

    # Confirm
    if [[ "$yes" == false && "$dry_run" == false ]]; then
        echo ""
        echo "This will configure Homebrew to use:"
        echo "  Mirror: $mirror (${BREW_MIRRORS[$mirror]})"
        echo ""
        if ! confirm "Continue?" "y"; then
            exit 0
        fi
    fi

    # Execute
    if [[ "$dry_run" == true ]]; then
        log_info "[DRY RUN] Would configure Homebrew for $mirror mirror"
        exit 0
    fi

    setup_homebrew_mirror "$mirror"
}

main "$@"
