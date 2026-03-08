#!/bin/bash
#
# Common utility functions for china-mirror-skills
# Source this file in other setup scripts
#

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find project root by walking up to .git or SKILL.md
_dir="$SCRIPT_DIR"
while [[ "$_dir" != "/" ]]; do
    if [[ -f "$_dir/SKILL.md" ]] || [[ -d "$_dir/.git" ]]; then break; fi
    _dir="$(dirname "$_dir")"
done
readonly PROJECT_ROOT="$_dir"

# Use home directory for backups (works both in-repo and as standalone skill)
readonly BACKUP_DIR="${HOME}/.china-mirror-backup"

# ==================== Logging Functions ====================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# ==================== System Detection ====================

detect_os() {
    local os="unknown"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os="linux"
        if [[ -f /etc/os-release ]]; then
            # shellcheck source=/dev/null
            source /etc/os-release
            log_info "Detected Linux distribution: $NAME $VERSION_ID"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os="macos"
        log_info "Detected macOS: $(sw_vers -productVersion)"
    else
        log_warn "Unknown operating system: $OSTYPE"
    fi
    echo "$os"
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

get_distro_family() {
    local distro
    distro=$(detect_distro)
    case "$distro" in
        ubuntu|debian)
            echo "debian"
            ;;
        centos|rhel|fedora|rocky|almalinux)
            echo "rhel"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# ==================== Backup Functions ====================

# Generate a unique backup identifier
backup_id() {
    date +%Y%m%d_%H%M%S
}

# Backup a file with metadata
backup_file() {
    local file="$1"
    local tool_name="${2:-unknown}"
    local backup_id_val
    backup_id_val=$(backup_id)

    if [[ ! -f "$file" ]]; then
        log_warn "File does not exist, nothing to backup: $file"
        return 1
    fi

    local backup_subdir="${BACKUP_DIR}/${tool_name}/${backup_id_val}"
    mkdir -p "$backup_subdir"

    local filename
    filename=$(basename "$file")
    local backup_path="${backup_subdir}/${filename}"

    # Copy file
    cp -p "$file" "$backup_path"

    # Create metadata
    cat > "${backup_subdir}/metadata.json" << EOF
{
    "original_path": "$file",
    "backup_time": "$(date -Iseconds)",
    "tool": "$tool_name",
    "backup_id": "$backup_id_val",
    "file_size": $(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0"),
    "checksum": "$(md5sum "$file" 2>/dev/null | cut -d' ' -f1 || md5 -q "$file" 2>/dev/null || echo "unknown")"
}
EOF

    log_info "Backed up: $file -> $backup_path"
    echo "$backup_subdir"
}

# Restore from backup
restore_file() {
    local tool_name="$1"
    local backup_id_val="$2"

    local backup_subdir="${BACKUP_DIR}/${tool_name}/${backup_id_val}"

    if [[ ! -d "$backup_subdir" ]]; then
        log_error "Backup not found: $backup_subdir"
        return 1
    fi

    if [[ ! -f "${backup_subdir}/metadata.json" ]]; then
        log_error "Backup metadata not found"
        return 1
    fi

    local original_path
    original_path=$(grep '"original_path"' "${backup_subdir}/metadata.json" | cut -d'"' -f4)

    local filename
    filename=$(basename "$original_path")
    local backup_file="${backup_subdir}/${filename}"

    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi

    # Restore
    cp -p "$backup_file" "$original_path"
    log_success "Restored: $backup_file -> $original_path"
}

# List available backups
list_backups() {
    local tool_name="${1:-}"

    if [[ -z "$tool_name" ]]; then
        find "$BACKUP_DIR" -name "metadata.json" 2>/dev/null | while read -r meta; do
            local dir
            dir=$(dirname "$meta")
            local tool
            tool=$(basename "$(dirname "$dir")")
            local id
            id=$(basename "$dir")
            local time
            time=$(grep '"backup_time"' "$meta" | cut -d'"' -f4)
            echo "$tool | $id | $time"
        done
    else
        local tool_dir="${BACKUP_DIR}/${tool_name}"
        if [[ -d "$tool_dir" ]]; then
            find "$tool_dir" -name "metadata.json" | while read -r meta; do
                local dir
                dir=$(dirname "$meta")
                local id
                id=$(basename "$dir")
                local time
                time=$(grep '"backup_time"' "$meta" | cut -d'"' -f4)
                echo "$id | $time"
            done
        fi
    fi
}

# ==================== Proxy Detection ====================

# Check if HTTP/HTTPS proxy is set
detect_proxy() {
    local proxy_vars=("http_proxy" "https_proxy" "HTTP_PROXY" "HTTPS_PROXY" "ALL_PROXY")
    local found_proxy=""

    for var in "${proxy_vars[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            found_proxy="${found_proxy}${var}=${!var}; "
        fi
    done

    echo "$found_proxy"
}

# Warn about proxy/mirror conflicts
warn_proxy_conflict() {
    local proxy_env
    proxy_env=$(detect_proxy)

    if [[ -n "$proxy_env" ]]; then
        log_warn "Proxy environment variables detected: $proxy_env"
        log_warn "Using both mirror and proxy may cause conflicts or slower downloads"
        log_warn "Consider unsetting proxy variables if you're in China"
        echo ""
        echo "To temporarily disable proxy, run:"
        echo "  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY"
        echo ""
        return 0
    fi
    return 1
}

# ==================== Safety Checks ====================

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if user has sudo access (without password prompt)
check_sudo() {
    if command_exists sudo; then
        sudo -n true 2>/dev/null
    else
        return 1
    fi
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Request confirmation
confirm() {
    local message="$1"
    local default="${2:-n}"

    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="Y/n"
    else
        prompt="y/N"
    fi

    read -rp "$message [$prompt] " response
    response=${response:-$default}

    [[ "$response" =~ ^[Yy]$ ]]
}

# ==================== Network Checks ====================

# Test HTTP connectivity to a URL
test_url() {
    local url="$1"
    local timeout="${2:-10}"

    if command_exists curl; then
        curl -sSf --max-time "$timeout" "$url" -o /dev/null 2>/dev/null
    elif command_exists wget; then
        wget --timeout="$timeout" -q "$url" -O /dev/null 2>/dev/null
    else
        log_warn "Neither curl nor wget available for URL testing"
        return 1
    fi
}

# Get public IP information (optional, for diagnostics)
get_ip_info() {
    if command_exists curl; then
        curl -s --max-time 5 https://ipinfo.io/json 2>/dev/null || echo "{}"
    else
        echo "{}"
    fi
}

# ==================== File Operations ====================

# Safely append to file (idempotent)
append_if_not_exists() {
    local file="$1"
    local content="$2"

    mkdir -p "$(dirname "$file")"

    if [[ -f "$file" ]] && grep -qF "$content" "$file" 2>/dev/null; then
        log_info "Content already exists in $file, skipping"
        return 0
    fi

    echo "$content" >> "$file"
    log_info "Appended to $file"
}

# Replace or add line in file
replace_or_add_line() {
    local file="$1"
    local pattern="$2"
    new_line="$3"

    if [[ ! -f "$file" ]]; then
        mkdir -p "$(dirname "$file")"
        echo "$new_line" > "$file"
        return 0
    fi

    if grep -q "$pattern" "$file"; then
        # Replace existing line
        local temp_file
        temp_file=$(mktemp)
        sed "s|.*$pattern.*|$new_line|" "$file" > "$temp_file"
        mv "$temp_file" "$file"
    else
        # Add new line
        echo "$new_line" >> "$file"
    fi
}

# ==================== Main (for testing) ====================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_info "Common utilities loaded"
    log_info "Project root: $PROJECT_ROOT"
    log_info "Backup directory: $BACKUP_DIR"

    echo ""
    log_info "System detection:"
    detect_os

    echo ""
    log_info "Proxy detection:"
    detect_proxy || log_info "No proxy detected"

    echo ""
    log_info "Available backups:"
    list_backups || log_info "No backups found"
fi
