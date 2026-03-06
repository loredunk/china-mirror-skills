---
name: bootstrap-china-network
description: |
  Main entry point for configuring all development tools to work efficiently in China's network
  environment. Detects installed tools (pip/uv/poetry, npm/yarn/pnpm, docker, apt, cargo, go,
  conda, flutter, homebrew), checks for proxy conflicts, and applies appropriate mirror
  configurations for each. Use this skill when the user wants to configure everything at once,
  is setting up a new development machine in China, or doesn't know which specific tool is slow.
  Also use when the user says "配置国内镜像", "网络太慢全部配一下", or describes a general
  "slow downloads in China" problem without specifying which tool.
---

# Bootstrap China Network Environment

One-stop configuration for all development tools in China. Diagnose first, then apply fixes.

## Steps

**1. Quick environment scan**

Run the `diagnose-network-environment` skill OR do a quick scan inline:
```bash
# Detect installed tools
for tool in pip uv npm yarn pnpm docker cargo go conda flutter brew; do
  which $tool 2>/dev/null && echo "✓ $tool" || true
done

# Check proxy conflicts
[[ -n "$HTTP_PROXY$HTTPS_PROXY$http_proxy$https_proxy" ]] && echo "⚠️ Proxy detected"
```

**2. Check for proxy conflicts**

If `HTTP_PROXY` or `HTTPS_PROXY` is set, warn the user:
> Proxy environment variables are set. In China, using a VPN/proxy alongside mirrors can cause conflicts. Consider: `unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY`

**3. Apply mirror configurations**

For each detected tool, run the corresponding skill/script. Ask the user for preferences or use sensible defaults:

| Tool | Script | Default Mirror |
|------|--------|---------------|
| pip / uv / poetry | `./scripts/setup_pip.sh` | tuna |
| npm / yarn / pnpm | `./scripts/setup_npm.sh` | npmmirror |
| Ubuntu/Debian APT | `sudo ./scripts/setup_apt.sh` | tuna |
| Docker CE repo | `sudo ./scripts/setup_docker.sh` | tuna |
| Homebrew | `./scripts/setup_homebrew.sh` | tuna |
| Conda/Anaconda | `./scripts/setup_conda.sh` | tuna |
| Cargo/Rust | `./scripts/setup_cargo.sh` | ustc |
| Go modules | `./scripts/setup_go.sh` | goproxy |
| Flutter/Dart | `./scripts/setup_flutter.sh` | tuna |

Run scripts for detected tools. Each script is idempotent — safe to run multiple times.

**4. Verify configurations**

After applying, run a quick verification for each configured tool:
```bash
pip config get global.index-url 2>/dev/null
npm config get registry 2>/dev/null
go env GOPROXY 2>/dev/null
cat ~/.cargo/config.toml 2>/dev/null | grep index
```

**5. Provide summary**

Report:
- ✅ What was configured (tool → mirror URL)
- ⚠️ Any warnings (proxy conflicts, permission issues, tool not found)
- 📋 How to restore: `./scripts/restore_config.sh --tool <name> --latest`

## Dry Run

If the user wants to preview changes first, add `--dry-run` to each script:
```bash
./scripts/setup_pip.sh --dry-run
./scripts/setup_npm.sh --dry-run
```

## Related Skills

For individual tool configuration, use the specific skill instead:
- `fix-python-mirror` — pip/uv/poetry only
- `fix-node-mirror` — npm/yarn/pnpm only
- `fix-docker-mirror` — Docker CE + Docker Hub
- `fix-apt-mirror` — Ubuntu/Debian APT
- `fix-homebrew-mirror` — Homebrew
- `fix-conda-mirror` — Conda/Anaconda
- `fix-rust-mirror` — Cargo/rustup
- `fix-go-proxy` — Go modules
- `fix-flutter-mirror` — Flutter/Dart
- `diagnose-network-environment` — diagnosis only, no changes
