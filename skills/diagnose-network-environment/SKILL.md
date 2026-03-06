---
name: diagnose-network-environment
description: |
  Diagnose the development network environment to identify slow mirrors, proxy conflicts, and
  unconfigured package managers for developers in China. Tests connectivity to official and mirror
  sources, detects installed tools and their current mirror configuration, and generates actionable
  recommendations. Use this skill when the user is unsure why downloads are slow, wants to audit
  their development environment, needs to compare mirror speeds, or is troubleshooting network issues
  before applying mirror configurations. If the user says "为什么下载慢", "诊断网络", or similar, always use this skill.
---

# Diagnose Network Environment

Run a comprehensive network environment check to identify issues and recommend fixes.

## Steps

**1. Collect system info**
```bash
uname -a
source /etc/os-release 2>/dev/null && echo "$NAME $VERSION"
echo "Shell: $SHELL"
```

**2. Check for proxy conflicts**
```bash
echo "http_proxy=$http_proxy HTTP_PROXY=$HTTP_PROXY"
echo "https_proxy=$https_proxy HTTPS_PROXY=$HTTPS_PROXY"
# macOS
networksetup -getwebproxy Wi-Fi 2>/dev/null
# git proxy
git config --global http.proxy 2>/dev/null
```
⚠️ If proxy env vars are set in China, they often conflict with mirrors — recommend unsetting them.

**3. Detect installed development tools**
```bash
for tool in pip uv poetry npm yarn pnpm docker cargo go flutter brew conda; do
  which $tool 2>/dev/null && $tool --version 2>/dev/null | head -1 && echo "✓ $tool" || echo "✗ $tool"
done
```

**4. Check current mirror configuration for detected tools**
```bash
pip config get global.index-url 2>/dev/null || echo "pip: not configured"
npm config get registry 2>/dev/null || echo "npm: not configured"
go env GOPROXY 2>/dev/null || echo "go: not configured"
cat ~/.cargo/config.toml 2>/dev/null | grep -A1 "\[registries" || echo "cargo: not configured"
conda config --show default_channels 2>/dev/null | head -5 || echo "conda: not configured"
cat /etc/apt/sources.list 2>/dev/null | grep "^deb" | head -3 || echo "apt: N/A"
cat /etc/docker/daemon.json 2>/dev/null || echo "docker: not configured"
```

**5. Test connectivity (time each request)**
```bash
# Official sources (expected: slow in China)
curl -s -o /dev/null -w "pypi.org: %{time_total}s\n" --max-time 10 https://pypi.org/simple/pip/ || echo "pypi.org: timeout"
curl -s -o /dev/null -w "registry.npmjs.org: %{time_total}s\n" --max-time 10 https://registry.npmjs.org/npm || echo "registry.npmjs.org: timeout"

# China mirrors (expected: fast)
curl -s -o /dev/null -w "TUNA PyPI: %{time_total}s\n" --max-time 10 https://pypi.tuna.tsinghua.edu.cn/simple/pip/
curl -s -o /dev/null -w "npmmirror: %{time_total}s\n" --max-time 10 https://registry.npmmirror.com/npm
curl -s -o /dev/null -w "goproxy.cn: %{time_total}s\n" --max-time 10 https://goproxy.cn/github.com/
curl -s -o /dev/null -w "USTC Cargo: %{time_total}s\n" --max-time 10 https://mirrors.ustc.edu.cn/crates.io-index/
```

**6. Generate recommendations**

Based on findings:
- For each detected tool with no mirror configured → recommend the relevant fix-* skill
- If proxy vars are set → recommend unsetting
- If a mirror is unreachable → recommend alternative mirror

## Output Format

Present a clear summary with sections:
1. **System** — OS, shell
2. **Proxy** — detected proxy settings (warn if present)
3. **Installed Tools** — ✓/✗ for each tool
4. **Mirror Status** — configured / not configured per tool
5. **Connectivity** — response times for key endpoints
6. **Recommendations** — prioritized list of actions (HIGH/MEDIUM/LOW)

Example recommendation format:
```
🔴 HIGH: pip not configured — run fix-python-mirror (TUNA 0.3s vs pypi.org timeout)
🔴 HIGH: npm not configured — run fix-node-mirror (npmmirror 0.4s vs npmjs.org 12s)
🟡 MEDIUM: Proxy detected (HTTP_PROXY=...) — consider unsetting for mirror use
✅ OK: cargo already using USTC mirror
```
