#!/bin/bash
#
# Setup curated GitHub mirrors for China network environment
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

DEFAULT_MIRROR="tuna"

get_release_mirror() {
    case "$1" in
        tuna)
            echo "https://mirrors.tuna.tsinghua.edu.cn/github-release/"
            ;;
        ustc)
            echo "https://mirrors.ustc.edu.cn/github-release/"
            ;;
        ghfast)
            echo "https://ghfast.top/"
            ;;
        *)
            return 1
            ;;
    esac
}

show_help() {
    cat << EOF
Setup curated GitHub mirrors for China network environment

Usage: $(basename "$0") [OPTIONS]

Options:
  -m, --mirror MIRROR      Choose mirror (tuna|ustc|ghfast)
      --release-url URL    Convert a GitHub release URL to a mirror URL
      --proxy-clone        Configure global git clone acceleration via prefix proxy
      --list               Show supported mirrors
  -d, --dry-run            Show what would be changed without applying
  -y, --yes                Skip confirmation prompts
  -h, --help               Show this help message

Notes:
  - TUNA/USTC release mirrors work for GitHub Releases assets only (path rewrite).
  - ghfast proxy works for releases, clone, archive, and raw files (URL prefix).
  - --proxy-clone configures git config url.insteadOf for global clone acceleration.

Examples:
  $(basename "$0") --release-url https://github.com/cli/cli/releases/download/v2.69.0/gh_2.69.0_checksums.txt
  $(basename "$0") --mirror ustc --release-url https://github.com/owner/repo/releases/download/v1.0.0/app.tar.gz
  $(basename "$0") --mirror ghfast --release-url https://github.com/owner/repo/releases/download/v1.0.0/app.tar.gz
  $(basename "$0") --proxy-clone --mirror ghfast
EOF
}

show_catalog() {
    echo "Release mirrors:"
    echo "  - tuna: $(get_release_mirror tuna)  (path rewrite, releases only)"
    echo "  - ustc: $(get_release_mirror ustc)  (path rewrite, releases only)"
    echo "  - ghfast: $(get_release_mirror ghfast)  (URL prefix proxy, releases/clone/archive/raw)"
    echo ""
    echo "Global clone acceleration (--proxy-clone):"
    echo "  - ghfast: git config --global url.\"https://ghfast.top/https://github.com/\".insteadOf \"https://github.com/\""
}

convert_release_url() {
    local release_url="$1"
    local mirror_name="$2"
    local mirror_prefix=""

    if ! mirror_prefix="$(get_release_mirror "$mirror_name")"; then
        log_error "Unknown mirror: $mirror_name"
        return 1
    fi

    # ghfast-style prefix proxy: prepend the full original URL
    if [[ "$mirror_name" == "ghfast" ]]; then
        if [[ "$release_url" =~ ^https://github\.com/ ]]; then
            echo "${mirror_prefix}${release_url}"
            return 0
        fi
        log_error "Unsupported URL for proxy: $release_url"
        log_info "Expected format: https://github.com/..."
        return 1
    fi

    # TUNA/USTC-style path rewrite: extract components and rebuild
    if [[ "$release_url" =~ ^https://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/(.+)$ ]]; then
        local owner="${BASH_REMATCH[1]}"
        local repo="${BASH_REMATCH[2]}"
        local tag="${BASH_REMATCH[3]}"
        local asset="${BASH_REMATCH[4]}"
        echo "${mirror_prefix}${owner}/${repo}/releases/download/${tag}/${asset}"
        return 0
    fi

    log_error "Unsupported release URL: $release_url"
    log_info "Expected format: https://github.com/<owner>/<repo>/releases/download/<tag>/<asset>"
    return 1
}

get_proxy_prefix() {
    case "$1" in
        ghfast)
            echo "https://ghfast.top/"
            ;;
        *)
            return 1
            ;;
    esac
}

configure_proxy_clone() {
    local mirror_name="$1"
    local dry_run="$2"
    local proxy_prefix=""

    if ! proxy_prefix="$(get_proxy_prefix "$mirror_name")"; then
        log_error "Mirror '$mirror_name' does not support proxy-clone"
        log_info "Supported: ghfast"
        return 1
    fi

    if ! command_exists git; then
        log_error "git is required to configure proxy-clone"
        return 1
    fi

    local insteadof_url="${proxy_prefix}https://github.com/"

    if [[ "$dry_run" == true ]]; then
        log_info "[DRY RUN] Would back up ~/.gitconfig if it exists"
        log_info "[DRY RUN] Would run:"
        echo "  git config --global url.\"${insteadof_url}\".insteadOf \"https://github.com/\""
        return 0
    fi

    if [[ -f "${HOME}/.gitconfig" ]]; then
        backup_file "${HOME}/.gitconfig" "github" >/dev/null
    fi

    local git_config_key="url.${insteadof_url}.insteadOf"
    git config --global --unset-all "${git_config_key}" >/dev/null 2>&1 || true
    git config --global "${git_config_key}" "https://github.com/"

    log_success "Configured global clone acceleration via ${mirror_name}"
    log_info "All https://github.com/ URLs will be rewritten to ${insteadof_url}"
    log_info "Verify with: git config --global --get-all \"${git_config_key}\""
    log_info "To remove: git config --global --unset-all \"${git_config_key}\""
}

main() {
    local mirror="$DEFAULT_MIRROR"
    local release_url=""
    local proxy_clone=false
    local dry_run=false
    local yes=false
    local list_only=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mirror)
                mirror="$2"
                shift 2
                ;;
            --release-url)
                release_url="$2"
                shift 2
                ;;
            --proxy-clone)
                proxy_clone=true
                shift
                ;;
            --list)
                list_only=true
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

    if [[ "$list_only" == true ]]; then
        show_catalog
        exit 0
    fi

    if [[ -z "$release_url" && "$proxy_clone" == false ]]; then
        log_error "You must provide --release-url or --proxy-clone"
        show_help
        exit 1
    fi

    warn_proxy_conflict || true

    if [[ -n "$release_url" ]]; then
        convert_release_url "$release_url" "$mirror"
        exit 0
    fi

    if [[ "$proxy_clone" == true ]]; then
        if [[ "$yes" == false && "$dry_run" == false ]]; then
            echo ""
            echo "This will configure global GitHub clone acceleration:"
            echo "  Proxy: $mirror"
            echo "  All https://github.com/ URLs will be rewritten via the proxy"
            echo ""
            if ! confirm "Continue?" "y"; then
                exit 0
            fi
        fi
        configure_proxy_clone "$mirror" "$dry_run"
        exit 0
    fi
}

main "$@"
