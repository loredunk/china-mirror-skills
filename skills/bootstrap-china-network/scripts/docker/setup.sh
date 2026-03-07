#!/bin/bash
#
# Setup Docker CE repository mirror for China network environment
# IMPORTANT: This sets up Docker CE INSTALLATION packages, NOT Docker Hub image pulls
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# ==================== Configuration ====================

# Docker CE install repo mirrors (NOT Docker Hub)
declare -A DOCKER_CE_MIRRORS=(
    ["tuna"]="https://mirrors.tuna.tsinghua.edu.cn/docker-ce"
    ["ustc"]="https://mirrors.ustc.edu.cn/docker-ce"
    ["aliyun"]="https://mirrors.aliyun.com/docker-ce"
)

DEFAULT_MIRROR="tuna"

# ==================== Functions ====================

show_help() {
    cat << EOF
Setup Docker CE repository mirror for China network environment

⚠️  IMPORTANT: This configures Docker CE INSTALLATION packages mirror
   NOT Docker Hub image registry mirror. These are different:

   - Docker CE mirror: Where to download Docker engine packages
   - Docker Hub mirror: Where to pull container images from

Usage: $(basename "$0") [OPTIONS]

Options:
  -m, --mirror MIRROR    Choose mirror (tuna|ustc|aliyun)
                         Default: tuna
  -d, --dry-run          Show what would be changed without applying
  -y, --yes              Skip confirmation prompts
  -h, --help             Show this help message

Supported distros: Ubuntu, Debian, CentOS, RHEL, Fedora

Examples:
  $(basename "$0")                    # Use Tsinghua mirror
  $(basename "$0") -m ustc            # Use USTC mirror

Docker Hub Note:
  Docker Hub mirrors in China are largely deprecated.
  Consider using alternative registries or proxy instead.
  See: docs/troubleshooting.md
EOF
}

get_distro_id() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

get_distro_codename() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "$VERSION_CODENAME"
    else
        echo "unknown"
    fi
}

setup_docker_apt() {
    local mirror_name="$1"
    local mirror_url="${DOCKER_CE_MIRRORS[$mirror_name]}"
    local distro_id
    distro_id=$(get_distro_id)
    local codename
    codename=$(get_distro_codename)

    log_info "Setting up Docker CE APT repository..."
    log_info "Mirror: $mirror_name ($mirror_url)"
    log_info "Distribution: $distro_id ($codename)"

    # Check if running as root or with sudo
    if ! is_root && ! check_sudo; then
        log_error "This script requires root or sudo privileges"
        exit 1
    fi

    # Backup existing sources
    if [[ -f /etc/apt/sources.list.d/docker.list ]]; then
        if is_root; then
            backup_file /etc/apt/sources.list.d/docker.list "docker"
        else
            sudo bash -c "source ${SCRIPT_DIR}/../common.sh && backup_file /etc/apt/sources.list.d/docker.list docker"
        fi
    fi

    # Remove old docker.list if exists
    if is_root; then
        rm -f /etc/apt/sources.list.d/docker.list
    else
        sudo rm -f /etc/apt/sources.list.d/docker.list
    fi

    # Install prerequisites
    log_info "Installing prerequisites..."
    local prereqs="ca-certificates curl gnupg"
    if is_root; then
        apt-get update -qq
        apt-get install -y -qq $prereqs
    else
        sudo apt-get update -qq
        sudo apt-get install -y -qq $prereqs
    fi

    # Add Docker's official GPG key
    log_info "Adding Docker GPG key..."
    local keyring_dir="/etc/apt/keyrings"
    if is_root; then
        install -m 0755 -d "$keyring_dir"
        curl -fsSL "${mirror_url}/linux/${distro_id}/gpg" -o "$keyring_dir/docker.asc"
        chmod a+r "$keyring_dir/docker.asc"
    else
        sudo install -m 0755 -d "$keyring_dir"
        curl -fsSL "${mirror_url}/linux/${distro_id}/gpg" | sudo tee "$keyring_dir/docker.asc" > /dev/null
        sudo chmod a+r "$keyring_dir/docker.asc"
    fi

    # Add repository
    log_info "Adding Docker CE repository..."
    local arch
    arch=$(dpkg --print-architecture)
    local repo_line="deb [arch=${arch} signed-by=${keyring_dir}/docker.asc] ${mirror_url}/linux/${distro_id} ${codename} stable"

    if is_root; then
        echo "$repo_line" > /etc/apt/sources.list.d/docker.list
    else
        echo "$repo_line" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi

    # Update package list
    log_info "Updating package list..."
    if is_root; then
        apt-get update -qq
    else
        sudo apt-get update -qq
    fi

    log_success "Docker CE repository configured successfully!"
    echo ""
    log_info "You can now install Docker CE with:"
    log_info "  sudo apt-get install docker-ce docker-ce-cli containerd.io"
}

setup_docker_yum() {
    local mirror_name="$1"
    local mirror_url="${DOCKER_CE_MIRRORS[$mirror_name]}"
    local distro_id
    distro_id=$(get_distro_id)

    log_info "Setting up Docker CE YUM repository..."
    log_info "Mirror: $mirror_name ($mirror_url)"
    log_info "Distribution: $distro_id"

    # Check if running as root or with sudo
    if ! is_root && ! check_sudo; then
        log_error "This script requires root or sudo privileges"
        exit 1
    fi

    # Determine repo file name based on distro
    local repo_file="/etc/yum.repos.d/docker-ce.repo"

    # Backup existing repo
    if [[ -f "$repo_file" ]]; then
        if is_root; then
            backup_file "$repo_file" "docker"
        else
            sudo bash -c "source ${SCRIPT_DIR}/../common.sh && backup_file $repo_file docker"
        fi
    fi

    # Install yum-utils for config-manager
    log_info "Installing prerequisites..."
    if is_root; then
        yum install -y -q yum-utils
    else
        sudo yum install -y -q yum-utils
    fi

    # Add repository using config-manager
    log_info "Adding Docker CE repository..."
    local repo_url="${mirror_url}/linux/${distro_id}/docker-ce.repo"

    if is_root; then
        yum-config-manager --add-repo "$repo_url"
    else
        sudo yum-config-manager --add-repo "$repo_url"
    fi

    # Update cache
    log_info "Updating package cache..."
    if is_root; then
        yum makecache -q
    else
        sudo yum makecache -q
    fi

    log_success "Docker CE repository configured successfully!"
    echo ""
    log_info "You can now install Docker CE with:"
    log_info "  sudo yum install docker-ce docker-ce-cli containerd.io"
}

print_docker_hub_warning() {
    echo ""
    log_warn "═══════════════════════════════════════════════════════════"
    log_warn "  Docker Hub Image Registry Mirrors in China"
    log_warn "═══════════════════════════════════════════════════════════"
    echo ""
    log_warn "Docker Hub image mirrors (for pulling images) are largely"
    log_warn "deprecated due to Docker policy changes. If you need to pull"
    log_warn "images from Docker Hub, consider:"
    echo ""
    log_info "  1. Use alternative registries (if available)"
    log_info "  2. Configure a proxy for Docker daemon"
    log_info "  3. Use docker.mirrors.sjtug.sjtu.edu.cn (may require auth)"
    echo ""
    log_info "See docs/troubleshooting.md for details"
    echo ""
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
    if [[ -z "${DOCKER_CE_MIRRORS[$mirror]:-}" ]]; then
        log_error "Unknown mirror: $mirror"
        log_info "Available mirrors: ${!DOCKER_CE_MIRRORS[*]}"
        exit 1
    fi

    # Detect OS
    local os
    os=$(detect_os)
    if [[ "$os" != "linux" ]]; then
        log_error "This script only supports Linux"
        exit 1
    fi

    local distro_family
    distro_family=$(get_distro_family)

    if [[ "$distro_family" == "unknown" ]]; then
        log_error "Unsupported distribution. Supported: Ubuntu, Debian, CentOS, RHEL, Fedora"
        exit 1
    fi

    # Print warning about Docker Hub vs Docker CE
    echo ""
    log_info "This will configure Docker CE INSTALLATION repository"
    log_info "Mirror: $mirror (${DOCKER_CE_MIRRORS[$mirror]})"
    echo ""

    # Confirm
    if [[ "$yes" == false && "$dry_run" == false ]]; then
        if ! confirm "Continue?" "y"; then
            exit 0
        fi
    fi

    # Execute
    if [[ "$dry_run" == true ]]; then
        log_info "[DRY RUN] Would configure Docker CE for $distro_family"
        exit 0
    fi

    case "$distro_family" in
        debian)
            setup_docker_apt "$mirror"
            ;;
        rhel)
            setup_docker_yum "$mirror"
            ;;
    esac

    print_docker_hub_warning
}

main "$@"
