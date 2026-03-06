#!/bin/bash
#
# Setup Ubuntu/Debian APT mirror for China network environment
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

# ==================== Configuration ====================

declare -A APT_MIRRORS=(
    ["tuna"]="https://mirrors.tuna.tsinghua.edu.cn"
    ["ustc"]="https://mirrors.ustc.edu.cn"
    ["aliyun"]="https://mirrors.aliyun.com"
    ["tencent"]="https://mirrors.cloud.tencent.com"
)

DEFAULT_MIRROR="tuna"
SOURCES_LIST="/etc/apt/sources.list"

# ==================== Functions ====================

show_help() {
    cat << EOF
Setup Ubuntu/Debian APT mirror for China network environment

Usage: $(basename "$0") [OPTIONS]

Options:
  -m, --mirror MIRROR    Choose mirror (tuna|ustc|aliyun|tencent)
                         Default: tuna
  -c, --codename CODE    Ubuntu/Debian codename (auto-detected by default)
                         e.g., jammy, focal, noble
  -d, --dry-run          Show what would be changed without applying
  -y, --yes              Skip confirmation prompts
  -r, --restore          Restore from backup
  -h, --help             Show this help message

Examples:
  $(basename "$0")                    # Use Tsinghua mirror (auto-detect)
  $(basename "$0") -m ustc            # Use USTC mirror
  $(basename "$0") -c jammy           # Specify Ubuntu 22.04 codename
EOF
}

get_ubuntu_codename() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "$VERSION_CODENAME"
    else
        echo "unknown"
    fi
}

generate_sources_list() {
    local mirror_url="$1"
    local codename="$2"
    local distro_id="$3"

    # Determine if Ubuntu or Debian based on ID
    case "$distro_id" in
        ubuntu)
            cat << EOF
# Ubuntu APT sources configured by china-mirror-skills
# Mirror: $mirror_url
# Codename: $codename
# Generated: $(date -Iseconds)

deb ${mirror_url}/ubuntu/ ${codename} main restricted universe multiverse
deb ${mirror_url}/ubuntu/ ${codename}-updates main restricted universe multiverse
deb ${mirror_url}/ubuntu/ ${codename}-backports main restricted universe multiverse
deb ${mirror_url}/ubuntu/ ${codename}-security main restricted universe multiverse

# deb-src ${mirror_url}/ubuntu/ ${codename} main restricted universe multiverse
# deb-src ${mirror_url}/ubuntu/ ${codename}-updates main restricted universe multiverse
# deb-src ${mirror_url}/ubuntu/ ${codename}-backports main restricted universe multiverse
# deb-src ${mirror_url}/ubuntu/ ${codename}-security main restricted universe multiverse
EOF
            ;;
        debian)
            cat << EOF
# Debian APT sources configured by china-mirror-skills
# Mirror: $mirror_url
# Codename: $codename
# Generated: $(date -Iseconds)

deb ${mirror_url}/debian/ ${codename} main contrib non-free
deb ${mirror_url}/debian/ ${codename}-updates main contrib non-free
deb ${mirror_url}/debian-security/ ${codename}-security main contrib non-free

# deb-src ${mirror_url}/debian/ ${codename} main contrib non-free
# deb-src ${mirror_url}/debian/ ${codename}-updates main contrib non-free
# deb-src ${mirror_url}/debian-security/ ${codename}-security main contrib non-free
EOF
            ;;
        *)
            log_error "Unsupported distribution: $distro_id"
            return 1
            ;;
    esac
}

setup_apt_mirror() {
    local mirror_name="$1"
    local mirror_url="${APT_MIRRORS[$mirror_name]}"
    local codename="$2"

    log_info "Setting up APT mirror: $mirror_name"
    log_info "Mirror URL: $mirror_url"
    log_info "Codename: $codename"

    # Detect distribution
    local distro_id
    distro_id=$(detect_distro)
    log_info "Distribution: $distro_id"

    if [[ "$distro_id" != "ubuntu" && "$distro_id" != "debian" ]]; then
        log_error "This script only supports Ubuntu and Debian"
        exit 1
    fi

    # Check if running as root or with sudo
    if ! is_root && ! check_sudo; then
        log_error "This script requires root or sudo privileges"
        exit 1
    fi

    # Check for proxy conflicts
    warn_proxy_conflict

    # Backup existing sources.list
    if [[ -f "$SOURCES_LIST" ]]; then
        if is_root; then
            backup_file "$SOURCES_LIST" "apt"
        else
            sudo bash -c "source ${SCRIPT_DIR}/common.sh && backup_file $SOURCES_LIST apt"
        fi
    fi

    # Generate new sources.list
    log_info "Generating new sources.list..."
    local new_sources
    new_sources=$(generate_sources_list "$mirror_url" "$codename" "$distro_id")

    # Write sources.list
    if is_root; then
        echo "$new_sources" > "$SOURCES_LIST"
    else
        echo "$new_sources" | sudo tee "$SOURCES_LIST" > /dev/null
    fi

    # Update package list
    log_info "Updating package list..."
    if is_root; then
        apt-get update -qq
    else
        sudo apt-get update -qq
    fi

    log_success "APT mirror configured successfully!"
}

# ==================== Main ====================

main() {
    local mirror="$DEFAULT_MIRROR"
    local codename=""
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
            -c|--codename)
                codename="$2"
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

    # Auto-detect codename if not provided
    if [[ -z "$codename" ]]; then
        codename=$(get_ubuntu_codename)
        if [[ "$codename" == "unknown" ]]; then
            log_error "Could not detect distribution codename. Use --codename"
            exit 1
        fi
        log_info "Auto-detected codename: $codename"
    fi

    # Validate mirror
    if [[ -z "${APT_MIRRORS[$mirror]:-}" ]]; then
        log_error "Unknown mirror: $mirror"
        log_info "Available mirrors: ${!APT_MIRRORS[*]}"
        exit 1
    fi

    # Detect OS
    local os
    os=$(detect_os)
    if [[ "$os" != "linux" ]]; then
        log_error "This script only supports Linux"
        exit 1
    fi

    # Confirm
    if [[ "$yes" == false && "$dry_run" == false ]]; then
        echo ""
        echo "This will configure APT to use:"
        echo "  Mirror: $mirror (${APT_MIRRORS[$mirror]})"
        echo "  Codename: $codename"
        echo "  File: $SOURCES_LIST"
        echo ""
        echo "⚠️  This will modify your system package sources!"
        echo ""
        if ! confirm "Continue?" "n"; then
            exit 0
        fi
    fi

    # Execute
    if [[ "$dry_run" == true ]]; then
        log_info "[DRY RUN] Would configure APT for $codename with $mirror mirror"
        log_info "[DRY RUN] Generated sources would be:"
        local distro_id
        distro_id=$(detect_distro)
        generate_sources_list "${APT_MIRRORS[$mirror]}" "$codename" "$distro_id"
        exit 0
    fi

    setup_apt_mirror "$mirror" "$codename"

    echo ""
    log_success "Setup complete!"
    log_info "Your package manager now uses the China mirror."
    log_info "You can restore the original with:"
    log_info "  sudo ./scripts/restore_config.sh --tool apt --latest"
}

main "$@"
