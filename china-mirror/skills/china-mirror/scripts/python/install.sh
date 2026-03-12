#!/bin/bash
#
# Install Python via pyenv using China mirror
# Uses PYTHON_BUILD_MIRROR_URL to download Python releases from Chinese mirrors
#
# Prerequisites: git, curl/wget, build dependencies
#

set -euo pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# ==================== Configuration ====================

declare -A PYTHON_BUILD_MIRRORS=(
    ["huawei"]="https://mirrors.huaweicloud.com/python/"
    ["tuna"]="https://mirrors.tuna.tsinghua.edu.cn/python-release/"
)

declare -A PYENV_INSTALL_MIRRORS=(
    ["tuna"]="https://mirrors.tuna.tsinghua.edu.cn/git/pyenv.git"
    ["ghfast"]="https://ghfast.top/https://github.com/pyenv/pyenv.git"
)

DEFAULT_MIRROR="huawei"
DEFAULT_VERSION="3.12.0"
PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"

# ==================== Functions ====================

show_help() {
    cat << EOF
Install Python via pyenv using China mirror

Usage: $(basename "$0") [OPTIONS]

Options:
  -v, --version VERSION  Python version to install (default: $DEFAULT_VERSION)
                         Use "list" to show available versions
  -m, --mirror MIRROR    Build mirror (huawei|tuna)
                         Default: huawei
  -d, --dry-run          Show what would be done without executing
  -y, --yes              Skip confirmation prompts
  -h, --help             Show this help message

Examples:
  $(basename "$0")                       # Install Python $DEFAULT_VERSION via Huawei mirror
  $(basename "$0") -v 3.11.8             # Install Python 3.11.8
  $(basename "$0") -m tuna               # Use TUNA mirror
  $(basename "$0") -v list               # List installable versions
EOF
}

install_pyenv_deps_ubuntu() {
    log_info "Installing pyenv build dependencies (Ubuntu/Debian)..."
    sudo apt-get update -qq
    sudo apt-get install -y \
        make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
        libffi-dev liblzma-dev
}

install_pyenv_deps_macos() {
    log_info "Installing pyenv build dependencies (macOS)..."
    if command_exists brew; then
        brew install openssl readline sqlite3 xz zlib tcl-tk
    else
        log_warn "Homebrew not found. Install it first or ensure Xcode Command Line Tools are installed."
    fi
}

install_pyenv() {
    if [[ -d "$PYENV_ROOT/.git" ]] || [[ -d "$PYENV_ROOT/bin" ]]; then
        log_info "pyenv already installed at $PYENV_ROOT"
        return 0
    fi

    log_info "Installing pyenv to $PYENV_ROOT..."
    log_info "Using TUNA git mirror for pyenv..."

    git clone "${PYENV_INSTALL_MIRRORS[tuna]}" "$PYENV_ROOT"

    # Install pyenv-update plugin
    if [[ -d "$PYENV_ROOT/plugins" ]]; then
        local update_dir="$PYENV_ROOT/plugins/pyenv-update"
        if [[ ! -d "$update_dir" ]]; then
            git clone "https://ghfast.top/https://github.com/pyenv/pyenv-update.git" \
                "$update_dir" 2>/dev/null || true
        fi
    fi

    log_success "pyenv installed to $PYENV_ROOT"
}

configure_pyenv_shell() {
    local shell_profile=""
    if [[ -n "${BASH_VERSION:-}" ]]; then
        shell_profile="${HOME}/.bashrc"
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_profile="${HOME}/.zshrc"
    else
        shell_profile="${HOME}/.profile"
    fi

    local pyenv_init='
# pyenv configuration - added by china-mirror-skills
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"'

    if grep -q "PYENV_ROOT" "$shell_profile" 2>/dev/null; then
        log_info "pyenv already configured in $shell_profile"
        return 0
    fi

    echo "$pyenv_init" >> "$shell_profile"
    log_success "pyenv configured in $shell_profile"
    log_info "Run: source $shell_profile  (or open a new terminal)"
}

install_python_version() {
    local version="$1"
    local mirror_url="$2"

    # Ensure pyenv is in PATH for this script
    export PATH="$PYENV_ROOT/bin:$PATH"
    if command_exists pyenv; then
        eval "$(pyenv init -)" 2>/dev/null || true
    else
        log_error "pyenv not found after installation. Please run: source ~/.bashrc"
        exit 1
    fi

    if [[ "$version" == "list" ]]; then
        log_info "Available Python versions:"
        pyenv install --list | grep -E '^\s+[0-9]+\.[0-9]+\.[0-9]+$' | tail -30
        return 0
    fi

    if pyenv versions | grep -q "$version" 2>/dev/null; then
        log_info "Python $version already installed"
        pyenv versions
        return 0
    fi

    log_info "Installing Python $version via $mirror_url ..."
    log_info "This may take several minutes..."

    # Set mirror for Python source download
    PYTHON_BUILD_MIRROR_URL="$mirror_url" \
    PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1 \
        pyenv install "$version"

    log_success "Python $version installed!"
    log_info "To use: pyenv global $version"
    pyenv versions
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

    if [[ -z "${PYTHON_BUILD_MIRRORS[$mirror]:-}" ]]; then
        log_error "Unknown mirror: $mirror"
        log_info "Available mirrors: ${!PYTHON_BUILD_MIRRORS[*]}"
        exit 1
    fi

    local mirror_url="${PYTHON_BUILD_MIRRORS[$mirror]}"

    if [[ "$dry_run" == true ]]; then
        log_info "[DRY RUN] Would install Python $version via $mirror mirror"
        log_info "[DRY RUN] PYTHON_BUILD_MIRROR_URL=$mirror_url"
        log_info "[DRY RUN] pyenv install $version"
        exit 0
    fi

    if [[ "$yes" == false && "$version" != "list" ]]; then
        echo ""
        echo "This will:"
        echo "  1. Install pyenv (if not present) from TUNA mirror"
        echo "  2. Install Python $version via $mirror mirror ($mirror_url)"
        echo ""
        if ! confirm "Continue?" "y"; then
            exit 0
        fi
    fi

    local os
    os=$(detect_os)

    # Install build dependencies
    if [[ "$os" == "linux" ]]; then
        local distro_family
        distro_family=$(get_distro_family)
        if [[ "$distro_family" == "debian" ]]; then
            install_pyenv_deps_ubuntu
        fi
    elif [[ "$os" == "macos" ]]; then
        install_pyenv_deps_macos
    fi

    # Install pyenv
    install_pyenv

    # Configure shell
    configure_pyenv_shell

    # Install Python version
    install_python_version "$version" "$mirror_url"

    echo ""
    log_success "Done!"
    if [[ "$version" != "list" ]]; then
        log_info "Set as global default: pyenv global $version"
        log_info "Verify: python --version"
    fi
}

main "$@"
