#!/bin/bash
#
# Setup Flutter mirror for China network environment
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# ==================== Configuration ====================

declare -A FLUTTER_STORAGE_MIRRORS=(
    ["cfug"]="https://storage.flutter-io.cn"
)

declare -A PUB_HOSTED_MIRRORS=(
    ["cfug"]="https://pub.flutter-io.cn"
)

DEFAULT_MIRROR="cfug"

# ==================== Functions ====================

show_help() {
    cat << EOF
Setup Flutter mirror for China network environment

Usage: $(basename "$0") [OPTIONS]

Options:
  -m, --mirror MIRROR    Choose mirror (cfug)
                         Default: cfug
  -d, --dry-run          Show what would be changed without applying
  -y, --yes              Skip confirmation prompts
  -h, --help             Show this help message

This configures:
  - FLUTTER_STORAGE_BASE_URL (Flutter SDK downloads)
  - PUB_HOSTED_URL (Dart packages)

Examples:
  $(basename "$0")                    # Use Flutter 官方文档默认示例（CFUG）
  $(basename "$0") -m cfug

After setup, restart your shell or run:
  source ~/.bashrc (or ~/.zshrc)

For Flutter installation, use:
  https://docs.flutter.cn/community/china/
EOF
}

setup_flutter_mirror() {
    local mirror_name="$1"
    local storage_url="${FLUTTER_STORAGE_MIRRORS[$mirror_name]}"
    local pub_url="${PUB_HOSTED_MIRRORS[$mirror_name]}"

    log_info "Setting up Flutter mirror: $mirror_name"
    log_info "PUB_HOSTED_URL: $pub_url"
    log_info "FLUTTER_STORAGE_BASE_URL: $storage_url"

    # Check for proxy conflicts
    warn_proxy_conflict

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
    backup_file "$shell_profile" "flutter"

    # Remove old Flutter config if exists
    if grep -q "# Flutter mirror configuration" "$shell_profile" 2>/dev/null; then
        log_info "Removing old Flutter configuration..."
        local temp_file
        temp_file=$(mktemp)
        sed '/# Flutter mirror configuration/,/^export PUB_HOSTED_URL/d' "$shell_profile" > "$temp_file"
        mv "$temp_file" "$shell_profile"
    fi

    # Add Flutter configuration
    cat >> "$shell_profile" << EOF

# Flutter mirror configuration - added by china-mirror-skills
export FLUTTER_STORAGE_BASE_URL=${storage_url}
export PUB_HOSTED_URL=${pub_url}
EOF

    log_success "Flutter environment configured in: $shell_profile"
    log_info "Run 'source $shell_profile' or restart your shell to apply"

    # Also set for current session
    export FLUTTER_STORAGE_BASE_URL="$storage_url"
    export PUB_HOSTED_URL="$pub_url"

    # Check if Flutter is installed
    if command_exists flutter; then
        log_info ""
        log_info "Flutter found: $(flutter --version | head -1)"
        log_info "Run 'flutter doctor' to verify configuration"
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
    if [[ -z "${FLUTTER_STORAGE_MIRRORS[$mirror]:-}" ]]; then
        log_error "Unknown mirror: $mirror"
        log_info "Available mirrors: ${!FLUTTER_STORAGE_MIRRORS[*]}"
        exit 1
    fi

    # Confirm
    if [[ "$yes" == false && "$dry_run" == false ]]; then
        echo ""
        echo "This will configure Flutter to use:"
        echo "  Mirror: $mirror"
        echo "  PUB_HOSTED_URL=${PUB_HOSTED_MIRRORS[$mirror]}"
        echo "  FLUTTER_STORAGE_BASE_URL=${FLUTTER_STORAGE_MIRRORS[$mirror]}"
        echo ""
        if ! confirm "Continue?" "y"; then
            exit 0
        fi
    fi

    # Execute
    if [[ "$dry_run" == true ]]; then
        log_info "[DRY RUN] Would configure Flutter mirror to $mirror"
        exit 0
    fi

    setup_flutter_mirror "$mirror"

    echo ""
    log_success "Setup complete!"
    log_info "To install Flutter, follow the official guide:"
    log_info "  https://docs.flutter.cn/community/china/"
}

main "$@"
