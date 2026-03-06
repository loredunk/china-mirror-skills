#!/bin/bash
#
# Backup configuration script for china-mirror-skills
# Backs up configuration files before modification
#

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

# ==================== Configuration ====================

# Map of tools to their config files
# Format: tool_name:path1,path2,...
declare -A TOOL_CONFIGS=(
    ["pip"]="${HOME}/.config/pip/pip.conf,${HOME}/.pip/pip.conf"
    ["npm"]="${HOME}/.npmrc"
    ["docker"]="/etc/docker/daemon.json"
    ["apt"]="/etc/apt/sources.list,/etc/apt/sources.list.d/*"
    ["homebrew"]="${HOME}/.bash_profile,${HOME}/.zshrc,${HOME}/.config/fish/config.fish"
    ["conda"]="${HOME}/.condarc"
    ["cargo"]="${HOME}/.cargo/config.toml,${HOME}/.cargo/config"
    ["go"]="${HOME}/.bash_profile,${HOME}/.zshrc"
    ["flutter"]="${HOME}/.bash_profile,${HOME}/.zshrc"
    ["gem"]="${HOME}/.gemrc"
)

# ==================== Functions ====================

show_help() {
    cat << EOF
Backup configuration files for development tools

Usage: $(basename "$0") [OPTIONS]

Options:
  -a, --all           Backup all supported configurations
  -t, --tool TOOL     Backup specific tool configuration
  -l, --list          List available backups
  -h, --help          Show this help message

Tools: pip, npm, docker, apt, homebrew, conda, cargo, go, flutter, gem

Examples:
  $(basename "$0") --all
  $(basename "$0") --tool pip
  $(basename "$0") --list
EOF
}

list_backups() {
    log_info "Available backups:"
    echo ""

    local found=false
    for tool_dir in "${BACKUP_DIR}"/*/; do
        if [[ -d "$tool_dir" ]]; then
            local tool_name
            tool_name=$(basename "$tool_dir")
            found=true

            echo "📁 $tool_name:"
            find "$tool_dir" -name "metadata.json" | sort | while read -r meta; do
                local dir
                dir=$(dirname "$meta")
                local id
                id=$(basename "$dir")
                local time
                time=$(grep '"backup_time"' "$meta" | cut -d'"' -f4)
                local original
                original=$(grep '"original_path"' "$meta" | cut -d'"' -f4)
                echo "   └─ $id | $time"
                echo "      Original: $original"
            done
            echo ""
        fi
    done

    if [[ "$found" == false ]]; then
        log_info "No backups found"
    fi
}

backup_tool() {
    local tool="$1"
    local config_paths="${TOOL_CONFIGS[$tool]:-}"

    if [[ -z "$config_paths" ]]; then
        log_error "Unknown tool: $tool"
        log_info "Available tools: ${!TOOL_CONFIGS[*]}"
        return 1
    fi

    log_info "Backing up $tool configuration..."

    local backed_up=false
    IFS=',' read -ra paths <<< "$config_paths"

    for path in "${paths[@]}"; do
        # Handle wildcards
        if [[ "$path" == *"*"* ]]; then
            for file in $path; do
                if [[ -f "$file" ]]; then
                    backup_file "$file" "$tool"
                    backed_up=true
                fi
            done
        else
            if [[ -f "$path" ]]; then
                backup_file "$path" "$tool"
                backed_up=true
            fi
        fi
    done

    if [[ "$backed_up" == false ]]; then
        log_warn "No configuration files found for $tool"
        return 1
    fi

    log_success "$tool configuration backed up successfully"
}

backup_all() {
    log_info "Backing up all configurations..."

    local failed=()
    for tool in "${!TOOL_CONFIGS[@]}"; do
        if ! backup_tool "$tool" 2>/dev/null; then
            failed+=("$tool")
        fi
    done

    echo ""
    log_success "Backup complete"

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_warn "Some tools had no config to backup: ${failed[*]}"
    fi
}

# ==================== Main ====================

main() {
    local action=""
    local tool=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--all)
                action="all"
                shift
                ;;
            -t|--tool)
                action="tool"
                tool="$2"
                shift 2
                ;;
            -l|--list)
                action="list"
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

    # Execute action
    case $action in
        all)
            backup_all
            ;;
        tool)
            if [[ -z "$tool" ]]; then
                log_error "No tool specified. Use --tool TOOL"
                exit 1
            fi
            backup_tool "$tool"
            ;;
        list)
            list_backups
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

main "$@"
