#!/bin/bash
#
# Setup curated GitHub mirrors for China network environment
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

DEFAULT_MIRROR="tuna"

get_release_mirror() {
    case "$1" in
        tuna)
            echo "https://mirrors.tuna.tsinghua.edu.cn/github-release/"
            ;;
        ustc)
            echo "https://mirrors.ustc.edu.cn/github-release/"
            ;;
        *)
            return 1
            ;;
    esac
}

get_project_upstream() {
    case "$1" in
        flutter-sdk)
            echo "https://github.com/flutter/flutter.git"
            ;;
        *)
            return 1
            ;;
    esac
}

get_project_mirror() {
    case "$1:$2" in
        flutter-sdk:tuna)
            echo "https://mirrors.tuna.tsinghua.edu.cn/git/flutter-sdk.git"
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
  -m, --mirror MIRROR      Choose mirror (tuna|ustc)
  -p, --project PROJECT    Configure git rewrite for a curated mirrored project
      --release-url URL    Convert a GitHub release URL to a mirror URL
      --list               Show supported mirrors and curated projects
  -d, --dry-run            Show what would be changed without applying
  -y, --yes                Skip confirmation prompts
  -h, --help               Show this help message

Notes:
  - This script does NOT configure a universal GitHub mirror.
  - Release mirrors work for GitHub Releases assets only.
  - Project mirror rewrites are available only for curated official mirrors.

Examples:
  $(basename "$0") --release-url https://github.com/cli/cli/releases/download/v2.69.0/gh_2.69.0_checksums.txt
  $(basename "$0") --mirror ustc --release-url https://github.com/owner/repo/releases/download/v1.0.0/app.tar.gz
  $(basename "$0") --project flutter-sdk
EOF
}

show_catalog() {
    echo "Release mirrors:"
    echo "  - tuna: $(get_release_mirror tuna)"
    echo "  - ustc: $(get_release_mirror ustc)"
    echo ""
    echo "Curated project mirrors:"
    echo "  - flutter-sdk"
    echo "      upstream: $(get_project_upstream flutter-sdk)"
    echo "      tuna: $(get_project_mirror flutter-sdk tuna)"
}

convert_release_url() {
    local release_url="$1"
    local mirror_name="$2"
    local mirror_prefix=""

    if ! mirror_prefix="$(get_release_mirror "$mirror_name")"; then
        log_error "Unknown mirror: $mirror_name"
        return 1
    fi

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

configure_project_mirror() {
    local project="$1"
    local mirror_name="$2"
    local dry_run="$3"
    local git_config_key=""
    local upstream_url=""
    local mirror_url=""

    if ! upstream_url="$(get_project_upstream "$project")"; then
        log_error "Unknown project: $project"
        return 1
    fi

    if ! mirror_url="$(get_project_mirror "$project" "$mirror_name")"; then
        log_error "Mirror '$mirror_name' is not available for project '$project'"
        return 1
    fi

    if ! command_exists git; then
        log_error "git is required to configure project mirrors"
        return 1
    fi

    if [[ "$dry_run" == true ]]; then
        log_info "[DRY RUN] Would back up ~/.gitconfig if it exists"
        log_info "[DRY RUN] Would run:"
        echo "  git config --global url.${mirror_url}.insteadOf ${upstream_url}"
        echo "  git config --global --add url.${mirror_url}.insteadOf git@github.com:flutter/flutter.git"
        echo "  git config --global --add url.${mirror_url}.insteadOf ssh://git@github.com/flutter/flutter.git"
        return 0
    fi

    if [[ -f "${HOME}/.gitconfig" ]]; then
        backup_file "${HOME}/.gitconfig" "github" >/dev/null
    fi

    git_config_key="url.${mirror_url}.insteadOf"
    git config --global --unset-all "${git_config_key}" >/dev/null 2>&1 || true
    git config --global --add "${git_config_key}" "${upstream_url}"
    git config --global --add "${git_config_key}" "git@github.com:flutter/flutter.git"
    git config --global --add "${git_config_key}" "ssh://git@github.com/flutter/flutter.git"

    log_success "Configured git rewrite for ${project}"
    log_info "GitHub upstream: ${upstream_url}"
    log_info "Mirror target: ${mirror_url}"
    log_info "Verify with: git config --global --get-all ${git_config_key}"
}

main() {
    local mirror="$DEFAULT_MIRROR"
    local project=""
    local release_url=""
    local dry_run=false
    local yes=false
    local list_only=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mirror)
                mirror="$2"
                shift 2
                ;;
            -p|--project)
                project="$2"
                shift 2
                ;;
            --release-url)
                release_url="$2"
                shift 2
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

    if [[ -n "$release_url" && -n "$project" ]]; then
        log_error "Use either --release-url or --project, not both"
        exit 1
    fi

    if [[ -z "$release_url" && -z "$project" ]]; then
        log_error "You must provide --release-url or --project"
        show_help
        exit 1
    fi

    warn_proxy_conflict || true

    if [[ -n "$release_url" ]]; then
        convert_release_url "$release_url" "$mirror"
        exit 0
    fi

    if [[ "$yes" == false && "$dry_run" == false ]]; then
        echo ""
        echo "This will configure a curated GitHub project mirror:"
        echo "  Project: $project"
        echo "  Mirror:  $mirror"
        echo ""
        if ! confirm "Continue?" "y"; then
            exit 0
        fi
    fi

    configure_project_mirror "$project" "$mirror" "$dry_run"
}

main "$@"
