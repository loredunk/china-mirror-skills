# diagnose-network-environment

## Name

Diagnose Network Environment

## Description

Comprehensive network environment diagnostics for developers in China. Analyzes current network configuration, detects proxy settings, measures connectivity to official and mirror sources, and provides recommendations.

## When to Use

Use this skill when:
- Unsure why downloads are slow
- Multiple tools are having network issues
- Want to understand current network configuration
- Need to troubleshoot before applying fixes
- Want to compare mirror speeds

## Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| detailed | boolean | No | Run detailed diagnostics (default: false) |
| speed_test | boolean | No | Include speed tests (default: true) |
| output_format | string | No | Output format: text, json (default: text) |

## Steps

### Step 1: System Information

Collect basic system info:
- Operating system and version
- Distribution (Linux)
- Shell in use
- Current user and home directory

### Step 2: Network Configuration

Check network settings:
- DNS configuration (`/etc/resolv.conf`)
- Default gateway
- Public IP and location (optional)
- IPv4/IPv6 connectivity

### Step 3: Proxy Detection

Check for proxy configurations:

**Environment Variables:**
- `http_proxy` / `HTTP_PROXY`
- `https_proxy` / `HTTPS_PROXY`
- `all_proxy` / `ALL_PROXY`
- `no_proxy` / `NO_PROXY`

**System Proxy (macOS):**
- `networksetup -getwebproxy Wi-Fi`
- System preferences proxy settings

**Git Proxy:**
- `git config --global http.proxy`
- `git config --global https.proxy`

### Step 4: Tool Detection

Check installed development tools:
- Python: pip, uv, poetry, conda
- Node.js: npm, yarn, pnpm
- Docker: docker, docker-compose
- Rust: cargo, rustup
- Go: go
- Flutter: flutter
- Homebrew: brew
- System: apt, yum

### Step 5: Current Mirror Configuration

Check if mirrors are already configured:

**pip:**
```bash
pip config get global.index-url
```

**npm:**
```bash
npm config get registry
```

**Docker:**
```bash
cat /etc/docker/daemon.json  # For registry mirrors
cat /etc/apt/sources.list.d/docker.list  # For CE repo
```

**apt:**
```bash
grep -E '^deb' /etc/apt/sources.list | head -5
```

**Cargo:**
```bash
cat ~/.cargo/config.toml 2>/dev/null || cat ~/.cargo/config 2>/dev/null
```

**Go:**
```bash
go env GOPROXY
```

**Conda:**
```bash
conda config --show channels
```

### Step 6: Connectivity Tests

Test connectivity to key endpoints:

| Endpoint | Purpose | Expected |
|----------|---------|----------|
| pypi.org | Official PyPI | Slow/timeout in China |
| registry.npmjs.org | Official npm | Slow/timeout in China |
| docker.io | Docker Hub | May require auth |
| github.com | GitHub | Varies |

### Step 7: Mirror Connectivity Tests

Test connectivity to mirror sources:

| Mirror | Test URL |
|--------|----------|
| TUNA PyPI | https://pypi.tuna.tsinghua.edu.cn/simple/pip/ |
| npmmirror | https://registry.npmmirror.com/npm |
| TUNA Docker CE | https://mirrors.tuna.tsinghua.edu.cn/docker-ce |
| TUNA APT | https://mirrors.tuna.tsinghua.edu.cn/ubuntu/dists/ |
| USTC Cargo | https://mirrors.ustc.edu.cn/crates.io-index/ |
| goproxy.cn | https://goproxy.cn/github.com/ |

### Step 8: Speed Tests (Optional)

If `speed_test=true`, measure download speeds:

1. Download small test file from official source
2. Download same file from mirror
3. Compare speeds
4. Calculate speedup ratio

### Step 9: Generate Recommendations

Based on findings, recommend:
- Which tools need mirror configuration
- Which mirror to use for each tool
- Whether proxy should be disabled
- Any conflicting configurations to fix

## Output Format

### Text Format (Default)

```
═══════════════════════════════════════════════════════════════
           NETWORK ENVIRONMENT DIAGNOSTICS
═══════════════════════════════════════════════════════════════

SYSTEM INFORMATION
──────────────────
OS: Ubuntu 22.04.3 LTS
Shell: /bin/bash
User: developer

NETWORK CONFIGURATION
─────────────────────
DNS: 223.5.5.5, 223.6.6.6 (Alibaba DNS)
Gateway: 192.168.1.1
Public IP: 203.0.113.x (Beijing, China)

PROXY DETECTION
───────────────
⚠️ WARNING: http_proxy=http://proxy.company.com:8080
⚠️ WARNING: https_proxy=http://proxy.company.com:8080
Recommendation: Proxy may conflict with mirrors. Consider unsetting.

INSTALLED TOOLS
───────────────
✓ pip 23.0.1
✓ npm 9.5.1
✓ docker 24.0.5
✓ cargo 1.72.0
✗ conda (not found)

CURRENT MIRROR CONFIGURATION
────────────────────────────
pip: ❌ Not configured (using default pypi.org)
npm: ❌ Not configured (using default registry.npmjs.org)
Docker: ⚠️ Using default (slow)
Cargo: ✓ Configured (USTC mirror)

CONNECTIVITY TESTS
──────────────────
pypi.org: ⚠️ 8.2s (slow)
registry.npmjs.org: ⚠️ 12.5s (slow)
TUNA PyPI: ✓ 0.3s (fast)
npmmirror: ✓ 0.4s (fast)

RECOMMENDATIONS
───────────────
1. HIGH PRIORITY: Configure pip to use TUNA mirror (27x faster)
2. HIGH PRIORITY: Configure npm to use npmmirror (31x faster)
3. MEDIUM PRIORITY: Configure Docker CE mirror
4. ACTION: Consider unsetting proxy environment variables

═══════════════════════════════════════════════════════════════
```

### JSON Format

```json
{
  "timestamp": "2025-03-06T10:30:00Z",
  "system": {
    "os": "linux",
    "distribution": "ubuntu",
    "version": "22.04"
  },
  "proxy": {
    "detected": true,
    "http_proxy": "http://proxy.company.com:8080",
    "https_proxy": "http://proxy.company.com:8080"
  },
  "tools": {
    "pip": { "installed": true, "version": "23.0.1" },
    "npm": { "installed": true, "version": "9.5.1" }
  },
  "mirrors_configured": {
    "pip": false,
    "npm": false,
    "cargo": true
  },
  "connectivity": {
    "pypi.org": { "status": "slow", "time_ms": 8200 },
    "tuna_pypi": { "status": "ok", "time_ms": 300 }
  },
  "recommendations": [
    {
      "priority": "high",
      "tool": "pip",
      "action": "configure_mirror",
      "mirror": "tuna"
    }
  ]
}
```

## Examples

### Example 1: Quick Diagnostics

```
"Diagnose my network setup"
"Why are my downloads so slow?"
```

### Example 2: Detailed Diagnostics

```
"Run detailed network diagnostics"
"Full network environment check"
```

### Example 3: Export Results

```
"Export network diagnostics as JSON"
"Save diagnostic report to file"
```

## Troubleshooting Based on Results

### Issue: Proxy detected but slow

**Diagnosis**: Company proxy interfering with mirrors

**Fix**: Unset proxy for development tools:
```bash
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
```

### Issue: DNS slow

**Diagnosis**: ISP DNS is slow

**Fix**: Use public DNS:
```bash
# Alibaba DNS
echo "nameserver 223.5.5.5" | sudo tee /etc/resolv.conf
# or Tencent DNS: 119.29.29.29
```

### Issue: Some mirrors unreachable

**Diagnosis**: Network blocks certain mirrors

**Fix**: Try alternative mirrors from the report

## Implementation

```bash
# Run diagnostics
./scripts/diagnose_network.sh [--detailed] [--speed-test]

# Or via Python
python scripts/diagnose.py --format text
```
