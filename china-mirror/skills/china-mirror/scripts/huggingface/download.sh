#!/bin/bash
#
# Temporary Hugging Face mirror download helper.
# Uses a one-shot HF_ENDPOINT override so the mirror is not persisted.
#

set -euo pipefail

HUGGINGFACE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

readonly HF_MIRROR_ENDPOINT="https://hf-mirror.com"
readonly HFD_SCRIPT="${HUGGINGFACE_SCRIPT_DIR}/hfd.sh"

show_help() {
    cat << EOF
Download Hugging Face models or datasets with a temporary mirror.

Usage: $(basename "$0") <repo_id> [OPTIONS] [-- extra args]

Options:
  --tool TOOL        Choose downloader (auto|hfd|cli). Default: auto
  --mirror MIRROR    Choose source (auto|hf-mirror|official). Default: auto
  --dataset          Download a dataset repo
  --dry-run          Print the command without executing it
  -h, --help         Show this help message

Examples:
  $(basename "$0") gpt2
  $(basename "$0") meta-llama/Llama-2-7b --tool hfd --hf_username user --hf_token token
  $(basename "$0") wget2 --dataset --tool cli --local-dir ./wget2
  $(basename "$0") gpt2 --mirror official --tool cli
EOF
}

print_command() {
    local -a cmd=("$@")
    local rendered=""
    local part
    for part in "${cmd[@]}"; do
        rendered+=" $(printf '%q' "$part")"
    done
    echo "${rendered# }"
}

choose_cli_command() {
    if command_exists huggingface-cli; then
        echo "huggingface-cli"
        return 0
    fi
    if command_exists hf; then
        echo "hf"
        return 0
    fi
    return 1
}

choose_tool() {
    local preferred="$1"
    if [[ "$preferred" != "auto" ]]; then
        echo "$preferred"
        return 0
    fi

    if command_exists curl && { command_exists aria2c || command_exists wget; }; then
        echo "hfd"
        return 0
    fi

    if choose_cli_command >/dev/null; then
        echo "cli"
        return 0
    fi

    log_error "No supported downloader found. Install aria2c/wget+hfd or huggingface-cli/hf."
    exit 1
}

main() {
    local repo_id=""
    local tool="auto"
    local mirror="auto"
    local dataset=false
    local dry_run=false
    local -a passthrough=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tool)
                tool="$2"
                shift 2
                ;;
            --mirror)
                mirror="$2"
                shift 2
                ;;
            --dataset)
                dataset=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --)
                shift
                passthrough+=("$@")
                break
                ;;
            -*)
                passthrough+=("$1")
                shift
                ;;
            *)
                if [[ -z "$repo_id" ]]; then
                    repo_id="$1"
                else
                    passthrough+=("$1")
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$repo_id" ]]; then
        show_help
        exit 1
    fi

    case "$mirror" in
        auto|hf-mirror|official) ;;
        *)
            log_error "Unknown mirror: $mirror"
            exit 1
            ;;
    esac

    case "$tool" in
        auto|hfd|cli) ;;
        *)
            log_error "Unknown tool: $tool"
            exit 1
            ;;
    esac

    local resolved_tool
    resolved_tool="$(choose_tool "$tool")"

    local -a env_args=()
    if [[ "$mirror" == "auto" || "$mirror" == "hf-mirror" ]]; then
        env_args=("HF_ENDPOINT=${HF_MIRROR_ENDPOINT}")
    fi

    local -a cmd=()
    if [[ "$resolved_tool" == "hfd" ]]; then
        cmd=("bash" "$HFD_SCRIPT" "$repo_id")
        if [[ "$dataset" == true ]]; then
            cmd+=("--dataset")
        fi
        if [[ ${#passthrough[@]} -gt 0 ]]; then
            cmd+=("${passthrough[@]}")
        fi
    else
        local cli_binary
        cli_binary="$(choose_cli_command)" || {
            log_error "huggingface-cli or hf is required for --tool cli"
            exit 1
        }
        if [[ "$cli_binary" == "huggingface-cli" ]]; then
            cmd=("huggingface-cli" "download")
        else
            cmd=("hf" "download")
        fi
        if [[ "$dataset" == true ]]; then
            cmd+=("--repo-type" "dataset")
        fi
        cmd+=("$repo_id")
        if [[ ${#passthrough[@]} -gt 0 ]]; then
            cmd+=("${passthrough[@]}")
        fi
    fi

    echo ""
    log_info "Repo: $repo_id"
    log_info "Tool: $resolved_tool"
    if [[ ${#env_args[@]} -gt 0 ]]; then
        log_info "Mirror: hf-mirror (temporary HF_ENDPOINT only for this command)"
    else
        log_info "Mirror: official"
    fi

    if [[ "$dry_run" == true ]]; then
        echo ""
        log_info "[DRY RUN] Command:"
        if [[ ${#env_args[@]} -gt 0 ]]; then
            echo "  $(print_command env "${env_args[@]}" "${cmd[@]}")"
        else
            echo "  $(print_command "${cmd[@]}")"
        fi
        exit 0
    fi

    echo ""
    if [[ ${#env_args[@]} -gt 0 ]]; then
        env "${env_args[@]}" "${cmd[@]}"
    else
        "${cmd[@]}"
    fi
}

main "$@"
