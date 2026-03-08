#!/bin/bash
#
# Restore configuration script for china-mirror-skills
# Restores configuration files from backup
#

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

# ==================== Functions ====================

show_help() {
    cat << EOF
Restore configuration files from backup

Usage: $(basename "$0") [OPTIONS]

Options:
  -t, --tool TOOL       Tool to restore (required)
  -b, --backup-id ID    Specific backup ID to restore
  -l, --latest          Restore latest backup for the tool
  -L, --list            List available backups
  -h, --help            Show this help message

Tools: pip, npm, docker, apt, homebrew, conda, cargo, go, flutter, github, gem

Examples:
  $(basename "$0") --list
  $(basename "$0") --tool pip --list
  $(basename "$0") --tool pip --latest
  $(basename "$0") --tool pip --backup-id 20250306_120000
EOF
}

list_tool_backups() {
    local tool="${1:-}"

    if [[ -z "$tool" ]]; then
        # List all tools with backups
        log_info "Tools with backups:"
        for tool_dir in "${BACKUP_DIR}"/*/; do
            if [[ -d "$tool_dir" ]]; then
                local tool_name
                tool_name=$(basename "$tool_dir")
                local count
                count=$(find "$tool_dir" -name "metadata.json" | wc -l)
                echo "  - $tool_name ($count backup(s))"
            fi
        done
        return 0
    fi

    local tool_dir="${BACKUP_DIR}/${tool}"
    if [[ ! -d "$tool_dir" ]]; then
        log_error "No backups found for tool: $tool"
        return 1
    fi

    log_info "Available backups for $tool:"
    echo ""

    find "$tool_dir" -name "metadata.json" | sort -r | while read -r meta; do
        local dir
        dir=$(dirname "$meta")
        local id
        id=$(basename "$dir")
        local time
        time=$(grep '"backup_time"' "$meta" | cut -d'"' -f4)
        local original
        original=$(grep '"original_path"' "$meta" | cut -d'"' -f4)
        echo "  Backup ID: $id"
        echo "    Time: $time"
        echo "    Original: $original"
        echo ""
    done
}

get_latest_backup() {
    local tool="$1"
    local tool_dir="${BACKUP_DIR}/${tool}"

    if [[ ! -d "$tool_dir" ]]; then
        return 1
    fi

    find "$tool_dir" -name "metadata.json" | sort -r | head -1 | xargs dirname | xargs basename
}

restore_tool_backup() {
    local tool="$1"
    local backup_id="$2"

    local backup_subdir="${BACKUP_DIR}/${tool}/${backup_id}"

    if [[ ! -d "$backup_subdir" ]]; then
        log_error "Backup not found: $backup_subdir"
        return 1
    fi

    if [[ ! -f "${backup_subdir}/metadata.json" ]]; then
        log_error "Backup metadata not found"
        return 1
    fi

    # Read metadata
    local original_path
    original_path=$(grep '"original_path"' "${backup_subdir}/metadata.json" | cut -d'"' -f4)
    local backup_time
    backup_time=$(grep '"backup_time"' "${backup_subdir}/metadata.json" | cut -d'"' -f4)

    local filename
    filename=$(basename "$original_path")
    local backup_file="${backup_subdir}/${filename}"

    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi

    # Confirm restore
    echo ""
    log_warn "You are about to restore:"
    echo "  Tool: $tool"
    echo "  Backup ID: $backup_id"
    echo "  Backup Time: $backup_time"
    echo "  Target: $original_path"
    echo ""

    if ! confirm "Do you want to proceed?" "n"; then
        log_info "Restore cancelled"
        return 0
    fi

    # Ensure target directory exists
    mkdir -p "$(dirname "$original_path")"

    # Restore file
    cp -p "$backup_file" "$original_path"
    log_success "Restored: $backup_file -> $original_path"
}

# ==================== Main ====================

main() {
    local action=""
    local tool=""
    local backup_id=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--tool)
                tool="$2"
                shift 2
                ;;
            -b|--backup-id)
                backup_id="$2"
                action="restore"
                shift 2
                ;;
            -l|--latest)
                action="latest"
                shift
                ;;
            -L|--list)
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
        list)
            list_tool_backups "$tool"
            ;;
        restore)
            if [[ -z "$tool" ]]; then
                log_error "No tool specified. Use --tool TOOL"
                exit 1
            fi
            if [[ -z "$backup_id" ]]; then
                log_error "No backup ID specified. Use --backup-id ID"
                exit 1
            fi
            restore_tool_backup "$tool" "$backup_id"
            ;;
        latest)
            if [[ -z "$tool" ]]; then
                log_error "No tool specified. Use --tool TOOL"
                exit 1
            fi
            backup_id=$(get_latest_backup "$tool")
            if [[ -z "$backup_id" ]]; then
                log_error "No backups found for $tool"
                exit 1
            fi
            log_info "Using latest backup: $backup_id"
            restore_tool_backup "$tool" "$backup_id"
            ;;
        *)
            if [[ -n "$tool" ]]; then
                # Tool specified but no action - default to list
                list_tool_backups "$tool"
            else
                show_help
            fi
            ;;
    esac
}

main "$@"
