#!/bin/bash
#
# Install Miniconda/Anaconda from China mirror
# Downloads the installer .sh from TUNA/USTC mirrors
#
# Prerequisites: wget or curl, bash
#

set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# ==================== Configuration ====================

declare -A CONDA_INSTALL_MIRRORS=(
    ["tuna"]="https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda"
    ["ustc"]="https://mirrors.ustc.edu.cn/anaconda/miniconda"
)

DEFAULT_MIRROR="tuna"
DEFAULT_TYPE="Miniconda3"   # Miniconda3 or Anaconda3
INSTALL_DIR="${HOME}/miniconda3"

# ==================== Functions ====================

show_help() {
    cat << EOF
Install Miniconda/Anaconda from China mirror

Usage: $(basename "$0") [OPTIONS]

Options:
  -m, --mirror MIRROR    Download mirror (tuna|ustc)
                         Default: tuna
  -t, --type TYPE        Installer type (Miniconda3|Anaconda3)
                         Default: Miniconda3
  -p, --prefix PATH      Install directory (default: $INSTALL_DIR)
  -d, --dry-run          Show what would be done without executing
  -y, --yes              Skip confirmation and run installer silently
  -h, --help             Show this help message

Examples:
  $(basename "$0")                        # Install Miniconda3 from TUNA
  $(basename "$0") -m ustc                # Use USTC mirror
  $(basename "$0") -t Anaconda3           # Install full Anaconda3
  $(basename "$0") -p /opt/conda -y       # Install to /opt/conda silently
EOF
}

detect_platform() {
    local os arch
    case "$OSTYPE" in
        linux*)
            os="Linux"
            arch=$(uname -m)
            ;;
        darwin*)
            os="MacOSX"
            arch=$(uname -m)
            # Normalize Apple Silicon
            [[ "$arch" == "arm64" ]] && arch="arm64"
            ;;
        *)
            log_error "Unsupported OS: $OSTYPE"
            exit 1
            ;;
    esac

    # Normalize arch names
    case "$arch" in
        x86_64)  arch="x86_64" ;;
        aarch64) arch="aarch64" ;;
        arm64)   arch="arm64" ;;
        *)
            log_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac

    echo "${os}-${arch}"
}

get_installer_filename() {
    local type="$1"
    local platform="$2"
    echo "${type}-latest-${platform}.sh"
}

download_installer() {
    local mirror_url="$1"
    local filename="$2"
    local dest="/tmp/${filename}"

    if [[ -f "$dest" ]]; then
        log_info "Installer already downloaded: $dest"
        echo "$dest"
        return 0
    fi

    local url="${mirror_url}/${filename}"
    log_info "Downloading from: $url"

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

install_conda() {
    local installer="$1"
    local prefix="$2"
    local silent="$3"

    log_info "Installing Conda to: $prefix"

    chmod +x "$installer"

    if [[ "$silent" == true ]]; then
        bash "$installer" -b -p "$prefix"
    else
        bash "$installer" -p "$prefix"
    fi

    log_success "Conda installed to: $prefix"
}

configure_conda_shell() {
    local prefix="$1"
    local conda_bin="${prefix}/bin/conda"

    if [[ ! -f "$conda_bin" ]]; then
        log_warn "conda binary not found at $conda_bin"
        return 1
    fi

    log_info "Initializing conda for current shell..."
    "$conda_bin" init 2>/dev/null || true

    log_success "Conda shell initialization complete"
    log_info "Run: source ~/.bashrc (or ~/.zshrc) to activate"
}

# ==================== Main ====================

main() {
    local mirror="$DEFAULT_MIRROR"
    local type="$DEFAULT_TYPE"
    local prefix="$INSTALL_DIR"
    local dry_run=false
    local yes=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mirror)
                mirror="$2"
                shift 2
                ;;
            -t|--type)
                type="$2"
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

    if [[ -z "${CONDA_INSTALL_MIRRORS[$mirror]:-}" ]]; then
        log_error "Unknown mirror: $mirror"
        log_info "Available mirrors: ${!CONDA_INSTALL_MIRRORS[*]}"
        exit 1
    fi

    # Check if already installed
    if [[ -d "$prefix/bin" ]] && command_exists "${prefix}/bin/conda"; then
        log_info "Conda already installed at $prefix"
        "${prefix}/bin/conda" --version
        log_info "To reconfigure mirrors, use: scripts/conda/setup.sh"
        exit 0
    fi

    local mirror_url="${CONDA_INSTALL_MIRRORS[$mirror]}"
    local platform
    platform=$(detect_platform)
    local filename
    filename=$(get_installer_filename "$type" "$platform")

    if [[ "$dry_run" == true ]]; then
        log_info "[DRY RUN] Would download: ${mirror_url}/${filename}"
        log_info "[DRY RUN] Would install to: $prefix"
        exit 0
    fi

    if [[ "$yes" == false ]]; then
        echo ""
        echo "This will:"
        echo "  1. Download $filename from $mirror mirror"
        echo "  2. Install $type to: $prefix"
        echo "  3. Initialize conda for current shell"
        echo ""
        if ! confirm "Continue?" "y"; then
            exit 0
        fi
    fi

    # Download installer
    local installer
    installer=$(download_installer "$mirror_url" "$filename")

    # Install
    install_conda "$installer" "$prefix" "$yes"

    # Configure shell
    configure_conda_shell "$prefix"

    echo ""
    log_success "Done! Conda installed at: $prefix"
    log_info "Next steps:"
    log_info "  1. source ~/.bashrc (or ~/.zshrc)"
    log_info "  2. Configure conda channels: bash scripts/conda/setup.sh"
    log_info "  3. Verify: conda --version"
}

main "$@"
