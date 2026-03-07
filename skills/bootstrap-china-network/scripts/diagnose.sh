#!/bin/bash
#
# Network environment diagnostic script for China developers
# Detects installed tools, checks mirror configurations, tests connectivity,
# and generates actionable recommendations.
#
# Usage: bash diagnose.sh
#

# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# ==================== Tool Detection ====================

# List of tools to check
TOOLS=(pip uv poetry npm yarn pnpm docker cargo go conda flutter brew)

detect_tools() {
    local found=()
    for tool in "${TOOLS[@]}"; do
        if command_exists "$tool"; then
            local version
            version=$("$tool" --version 2>/dev/null | head -1) || version="unknown"
            echo -e "  ${GREEN}✓${NC} $tool — $version"
            found+=("$tool")
        else
            echo -e "  ${RED}✗${NC} $tool"
        fi
    done
    # Return found tools via global variable
    DETECTED_TOOLS=("${found[@]}")
}

# ==================== Mirror Config Check ====================

check_mirror_config() {
    local tool="$1"
    case "$tool" in
        pip)
            pip config get global.index-url 2>/dev/null || echo "未配置"
            ;;
        uv)
            if [[ -f "$HOME/.config/uv/uv.toml" ]]; then
                grep -i 'index-url' "$HOME/.config/uv/uv.toml" 2>/dev/null || echo "未配置"
            else
                echo "未配置"
            fi
            ;;
        npm)
            npm config get registry 2>/dev/null || echo "未配置"
            ;;
        yarn)
            yarn config get registry 2>/dev/null || echo "未配置"
            ;;
        pnpm)
            pnpm config get registry 2>/dev/null || echo "未配置"
            ;;
        docker)
            if [[ -f /etc/docker/daemon.json ]]; then
                grep -o '"registry-mirrors"[^]]*]' /etc/docker/daemon.json 2>/dev/null || echo "未配置"
            else
                echo "未配置"
            fi
            ;;
        cargo)
            if [[ -f "$HOME/.cargo/config.toml" ]]; then
                grep -A1 '\[source' "$HOME/.cargo/config.toml" 2>/dev/null || echo "未配置"
            elif [[ -f "$HOME/.cargo/config" ]]; then
                grep -A1 '\[source' "$HOME/.cargo/config" 2>/dev/null || echo "未配置"
            else
                echo "未配置"
            fi
            ;;
        go)
            go env GOPROXY 2>/dev/null || echo "未配置"
            ;;
        conda)
            conda config --show default_channels 2>/dev/null | head -5 || echo "未配置"
            ;;
        flutter)
            echo "FLUTTER_STORAGE_BASE_URL=${FLUTTER_STORAGE_BASE_URL:-未配置}"
            echo "PUB_HOSTED_URL=${PUB_HOSTED_URL:-未配置}"
            ;;
        brew)
            echo "HOMEBREW_API_DOMAIN=${HOMEBREW_API_DOMAIN:-未配置}"
            echo "HOMEBREW_BREW_GIT_REMOTE=${HOMEBREW_BREW_GIT_REMOTE:-未配置}"
            ;;
        *)
            echo "N/A"
            ;;
    esac
}

# ==================== Connectivity Test ====================

test_connectivity() {
    local label="$1"
    local url="$2"
    local timeout="${3:-10}"

    if ! command_exists curl; then
        echo "$label: curl 不可用"
        return 1
    fi

    local result
    result=$(curl -s -o /dev/null -w "%{http_code} %{time_total}" --max-time "$timeout" "$url" 2>/dev/null)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        echo "$label: 超时或失败"
        return 1
    fi

    local http_code time_total
    http_code=$(echo "$result" | awk '{print $1}')
    time_total=$(echo "$result" | awk '{print $2}')

    echo "$label: ${time_total}s (HTTP $http_code)"
    return 0
}

# ==================== Recommendations ====================

generate_recommendations() {
    local recommendations=()

    # Check proxy conflicts
    local proxy_env
    proxy_env=$(detect_proxy)
    if [[ -n "$proxy_env" ]]; then
        recommendations+=("🟡 MEDIUM: 检测到代理环境变量 ($proxy_env) — 使用镜像时建议取消代理设置")
    fi

    # Check each detected tool's mirror config
    for tool in "${DETECTED_TOOLS[@]}"; do
        local config
        config=$(check_mirror_config "$tool" 2>/dev/null)

        # Determine if mirror is configured (heuristic: check for Chinese mirror domains)
        local has_mirror=false
        if echo "$config" | grep -qiE 'tuna|ustc|aliyun|npmmirror|goproxy\.cn|huaweicloud|tencent'; then
            has_mirror=true
        fi

        if [[ "$has_mirror" == false && "$config" != "N/A" ]]; then
            recommendations+=("🔴 HIGH: $tool 未配置国内镜像 — 运行 bootstrap-china-network 的对应脚本配置")
        else
            recommendations+=("✅ OK: $tool 已配置镜像")
        fi
    done

    # Print recommendations
    echo ""
    for rec in "${recommendations[@]}"; do
        echo "  $rec"
    done
}

# ==================== Main ====================

main() {
    echo "========================================"
    echo "  网络环境诊断"
    echo "========================================"
    echo ""

    # 1. System info
    log_info "1. 系统信息"
    echo "  OS: $(uname -s) $(uname -r)"
    local os
    os=$(detect_os 2>/dev/null)
    echo "  平台: $os"
    echo "  Shell: ${SHELL:-unknown}"
    echo ""

    # 2. Proxy check
    log_info "2. 代理检测"
    local proxy_env
    proxy_env=$(detect_proxy)
    if [[ -n "$proxy_env" ]]; then
        echo -e "  ${YELLOW}⚠️  检测到代理:${NC} $proxy_env"
        echo "  提示: 在中国使用镜像时，代理可能导致冲突，建议取消代理设置"
        echo "  运行: unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY"
    else
        echo -e "  ${GREEN}✓${NC} 未检测到代理环境变量"
    fi
    # macOS system proxy
    if [[ "$(uname -s)" == "Darwin" ]]; then
        networksetup -getwebproxy Wi-Fi 2>/dev/null | head -3 || true
    fi
    # git proxy
    local git_proxy
    git_proxy=$(git config --global http.proxy 2>/dev/null || true)
    if [[ -n "$git_proxy" ]]; then
        echo -e "  ${YELLOW}⚠️  Git 代理:${NC} $git_proxy"
    fi
    echo ""

    # 3. Installed tools
    log_info "3. 已安装的开发工具"
    DETECTED_TOOLS=()
    detect_tools
    echo ""

    # 4. Mirror configuration
    log_info "4. 镜像配置状态"
    for tool in "${DETECTED_TOOLS[@]}"; do
        echo -e "  ${BLUE}[$tool]${NC}"
        local config
        config=$(check_mirror_config "$tool" 2>/dev/null)
        echo "    $config" | head -5
    done
    echo ""

    # 5. Connectivity test
    log_info "5. 连通性测试"
    echo "  --- 官方源（中国通常较慢）---"
    test_connectivity "  pypi.org" "https://pypi.org/simple/pip/" 10 || true
    test_connectivity "  registry.npmjs.org" "https://registry.npmjs.org/npm" 10 || true
    echo ""
    echo "  --- 国内镜像（应该较快）---"
    test_connectivity "  TUNA PyPI" "https://pypi.tuna.tsinghua.edu.cn/simple/pip/" 10 || true
    test_connectivity "  npmmirror" "https://registry.npmmirror.com/npm" 10 || true
    test_connectivity "  goproxy.cn" "https://goproxy.cn/" 10 || true
    test_connectivity "  USTC" "https://mirrors.ustc.edu.cn/" 10 || true
    echo ""

    # 6. Recommendations
    log_info "6. 建议"
    generate_recommendations

    echo ""
    echo "========================================"
    echo "  诊断完成"
    echo "========================================"
}

main "$@"
