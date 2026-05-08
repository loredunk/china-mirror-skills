#!/bin/bash
#
# Install Go language from China mirror
# Downloads Go binary tarball from TUNA/Aliyun mirrors
#
# Prerequisites: wget or curl, sudo (for system-wide install)
#

set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# ==================== Configuration ====================

declare -A GO_INSTALL_MIRRORS=(
    # 2026-05：TUNA 已下线 Go 二进制镜像，现改用阿里云为默认
    ["aliyun"]="https://mirrors.aliyun.com/golang"
)

DEFAULT_MIRROR="aliyun"
DEFAULT_VERSION="1.22.4"
DEFAULT_INSTALL_DIR="/usr/local"    # Go installs to /usr/local/go

# ==================== Functions ====================

show_help() {
    cat << EOF
Install Go language from China mirror

Usage: $(basename "$0") [OPTIONS]

Options:
  -v, --version VERSION  Go version to install (default: $DEFAULT_VERSION)
                         Use "list" to show recent stable versions
  -m, --mirror MIRROR    Download mirror (aliyun)
                         Default: aliyun
  -p, --prefix PATH      Install prefix (default: $DEFAULT_INSTALL_DIR)
                         Go will be installed to <prefix>/go
  -d, --dry-run          Show what would be done without executing
  -y, --yes              Skip confirmation prompts
  -h, --help             Show this help message

Examples:
  $(basename "$0")                        # Install Go $DEFAULT_VERSION via Aliyun
  $(basename "$0") -v 1.21.8             # Install Go 1.21.8
  $(basename "$0") -m aliyun             # Use Aliyun mirror
  $(basename "$0") -p ~/local -y         # Install to ~/local/go (no sudo needed)
  $(basename "$0") -v list               # Show recent stable versions

Note: After installation, configure GOPROXY with:
  bash scripts/go/setup.sh
EOF
}

detect_go_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        arm64)   echo "arm64" ;;
        armv6l)  echo "armv6l" ;;
        i686)    echo "386" ;;
        *)
            log_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
}

detect_go_os() {
    case "$OSTYPE" in
        linux*)  echo "linux" ;;
        darwin*) echo "darwin" ;;
        *)
            log_error "Unsupported OS: $OSTYPE"
            exit 1
            ;;
    esac
}

list_recent_versions() {
    local mirror_url="$1"
    log_info "Fetching Go version list from mirror..."

    # Most mirrors list directories; show recent ones
    if command_exists curl; then
        curl -s "${mirror_url}/" | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?\.linux-amd64\.tar\.gz' \
            | sed 's/\.linux-amd64\.tar\.gz//' \
            | sort -V | tail -20 || true
    fi
    log_info "Visit: ${mirror_url}/ for full list"
}

download_go() {
    local mirror_url="$1"
    local version="$2"
    local os="$3"
    local arch="$4"

    local filename="go${version}.${os}-${arch}.tar.gz"
    local url="${mirror_url}/${filename}"
    local dest="/tmp/${filename}"

    if [[ -f "$dest" ]]; then
        log_info "Already downloaded: $dest"
        echo "$dest"
        return 0
    fi

    log_info "Downloading: $url"

    if command_exists wget; then
        wget -q --show-progress -O "$dest" "$url"
    elif command_exists curl; then
        curl -L --progress-bar -o "$dest" "$url"
    else
        log_error "Neither wget nor curl found"
        exit 1
    fi

    log_success "Downloaded to: $dest"
    echo "$dest"
}

install_go() {
    local tarball="$1"
    local prefix="$2"
    local go_dir="${prefix}/go"

    # Remove old installation
    if [[ -d "$go_dir" ]]; then
        log_info "Removing existing Go installation at $go_dir..."
        if [[ "$prefix" == "/usr/local" ]]; then
            sudo rm -rf "$go_dir"
        else
            rm -rf "$go_dir"
        fi
    fi

    log_info "Extracting Go to $prefix ..."

    if [[ "$prefix" == "/usr/local" ]]; then
        sudo tar -C "$prefix" -xzf "$tarball"
    else
        mkdir -p "$prefix"
        tar -C "$prefix" -xzf "$tarball"
    fi

    log_success "Go extracted to $go_dir"
}

configure_go_path() {
    local go_dir="$1"

    local shell_profile="${HOME}/.bashrc"
    [[ -f "${HOME}/.zshrc" ]] && shell_profile="${HOME}/.zshrc"

    local go_path_config="
# Go environment - added by china-mirror-skills
export PATH=\"${go_dir}/bin:\$PATH\"
export GOPATH=\"\$HOME/go\"
export PATH=\"\$GOPATH/bin:\$PATH\""

    if grep -q "GOPATH" "$shell_profile" 2>/dev/null; then
        log_info "Go PATH already configured in $shell_profile"
        return 0
    fi

    echo "$go_path_config" >> "$shell_profile"
    log_success "Go PATH configured in $shell_profile"
    log_info "Run: source $shell_profile"
}

# ==================== Main ====================

main() {
    local version="$DEFAULT_VERSION"
    local mirror="$DEFAULT_MIRROR"
    local prefix="$DEFAULT_INSTALL_DIR"
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
            -p|--prefix)
                prefix="$2"
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

    if [[ -z "${GO_INSTALL_MIRRORS[$mirror]:-}" ]]; then
        log_error "Unknown mirror: $mirror"
        log_info "Available mirrors: ${!GO_INSTALL_MIRRORS[*]}"
        exit 1
    fi

    local mirror_url="${GO_INSTALL_MIRRORS[$mirror]}"

    if [[ "$version" == "list" ]]; then
        list_recent_versions "$mirror_url"
        exit 0
    fi

    # Check if already installed
    local go_bin="${prefix}/go/bin/go"
    if [[ -f "$go_bin" ]]; then
        local current_version
        current_version=$("$go_bin" version | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
        if [[ "$current_version" == "go${version}" ]]; then
            log_info "Go $version already installed at ${prefix}/go"
            "$go_bin" version
            exit 0
        else
            log_info "Current: $current_version → Installing: go$version"
        fi
    fi

    local os arch
    os=$(detect_go_os)
    arch=$(detect_go_arch)

    if [[ "$dry_run" == true ]]; then
        log_info "[DRY RUN] Would download: ${mirror_url}/go${version}.${os}-${arch}.tar.gz"
        log_info "[DRY RUN] Would install to: ${prefix}/go"
        exit 0
    fi

    if [[ "$yes" == false ]]; then
        echo ""
        echo "This will:"
        echo "  1. Download go${version}.${os}-${arch}.tar.gz from $mirror mirror"
        echo "  2. Install Go to: ${prefix}/go"
        if [[ "$prefix" == "/usr/local" ]]; then
            echo "  (requires sudo for /usr/local)"
        fi
        echo ""
        if ! confirm "Continue?" "y"; then
            exit 0
        fi
    fi

    # Download
    local tarball
    tarball=$(download_go "$mirror_url" "$version" "$os" "$arch")

    # Install
    install_go "$tarball" "$prefix"

    # Configure PATH
    configure_go_path "${prefix}/go"

    echo ""
    log_success "Go $version installed at ${prefix}/go"
    log_info "Verify: source ~/.bashrc && go version"
    log_info ""
    log_info "Next: configure GOPROXY for faster module downloads:"
    log_info "  bash scripts/go/setup.sh"
}

main "$@"
