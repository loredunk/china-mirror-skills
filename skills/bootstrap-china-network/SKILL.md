---
name: bootstrap-china-network
description: |
  Main entry point for configuring and diagnosing all development tools in China's network
  environment. Detects installed tools (pip/uv/poetry, npm/yarn/pnpm, docker, apt, cargo, go,
  conda, flutter, homebrew), checks for proxy conflicts, and applies appropriate mirror
  configurations for each. Also provides comprehensive network diagnostics — tests connectivity
  to official and mirror sources, detects current mirror configuration status, and generates
  actionable recommendations. This is a self-contained skill — all setup and diagnostic scripts
  are bundled in the scripts/ subdirectory.
  Use this skill when the user wants to configure everything at once, is setting up a new
  development machine in China, or doesn't know which specific tool is slow.
  Also use when the user says "配置国内镜像", "网络太慢全部配一下", "为什么下载慢", "诊断网络",
  "diagnose network", or describes a general "slow downloads in China" problem.
  Use for diagnostics when the user wants to audit their environment, compare mirror speeds,
  or troubleshoot network issues before applying mirror configurations.
  For individual tool fixes, still use this skill and run only the relevant script.
---

# Bootstrap China Network Environment

One-stop configuration and diagnostics for all development tools in China. Diagnose first, then apply fixes.

All setup scripts are bundled under this skill's `scripts/` directory as resources — they are not loaded into context but invoked via bash.

## Steps

**1. Determine SKILL_DIR**

All script paths are relative to this skill's directory:
```bash
SKILL_DIR="<absolute path to skills/bootstrap-china-network>"
```
Use the directory where this SKILL.md resides.

**2. Diagnose (if user wants diagnostics or troubleshooting)**

If the user wants to diagnose their environment, check what's configured, or understand why things are slow:
```bash
bash "$SKILL_DIR/scripts/diagnose.sh"
```
This will:
- Collect system info and detect proxy conflicts
- Scan installed development tools and their mirror configurations
- Test connectivity to official sources and Chinese mirrors (with timing)
- Output structured recommendations (HIGH/MEDIUM/LOW priority)

After diagnostics, review the recommendations and offer to apply fixes for unconfigured tools.

**3. Quick environment scan (for direct configuration)**

```bash
# Detect installed tools
for tool in pip uv npm yarn pnpm docker cargo go conda flutter brew; do
  which $tool 2>/dev/null && echo "✓ $tool" || true
done

# Check proxy conflicts
[[ -n "$HTTP_PROXY$HTTPS_PROXY$http_proxy$https_proxy" ]] && echo "⚠️ Proxy detected"
```

**4. Check for proxy conflicts**

If `HTTP_PROXY` or `HTTPS_PROXY` is set, warn the user:
> Proxy environment variables are set. In China, using a VPN/proxy alongside mirrors can cause conflicts. Consider: `unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY`

**5. Apply mirror configurations**

For each detected tool, run the corresponding script. Ask the user for preferences or use sensible defaults:

| Tool | Script (relative to SKILL_DIR) | Default Mirror |
|------|------|----------|
| pip/uv/poetry | `scripts/python/setup.sh` | tuna |
| npm/yarn/pnpm | `scripts/node/setup.sh` | npmmirror |
| APT (Ubuntu/Debian) | `sudo scripts/apt/setup.sh` | tuna |
| Docker CE + Hub | `sudo scripts/docker/setup.sh` | tuna |
| Homebrew | `scripts/homebrew/setup.sh` | tuna |
| Conda/Anaconda | `scripts/conda/setup.sh` | tuna |
| Cargo/Rust | `scripts/rust/setup.sh` | ustc |
| Go modules | `scripts/go/setup.sh` | goproxy |
| Flutter/Dart | `scripts/flutter/setup.sh` | tuna |
| GitHub Releases/Clone | `scripts/github/setup.sh` | tuna (支持 `--proxy-clone` 全局加速 clone) |

All scripts support these flags:
- `-m / --mirror <name>` — choose mirror source
- `-f / --force` — force overwrite
- `-d / --dry-run` — preview changes without applying
- `-y / --yes` — skip confirmation prompts

Run scripts for detected tools. Each script is idempotent — safe to run multiple times.

Example:
```bash
bash "$SKILL_DIR/scripts/python/setup.sh" --mirror tuna
bash "$SKILL_DIR/scripts/node/setup.sh" --mirror npmmirror
sudo bash "$SKILL_DIR/scripts/apt/setup.sh" --mirror tuna
```

**6. Verify configurations**

After applying, run a quick verification for each configured tool:
```bash
pip config get global.index-url 2>/dev/null
npm config get registry 2>/dev/null
go env GOPROXY 2>/dev/null
cat ~/.cargo/config.toml 2>/dev/null | grep index
```

**7. Provide summary**

Report:
- What was configured (tool -> mirror URL)
- Any warnings (proxy conflicts, permission issues, tool not found)
- How to restore: `bash "$SKILL_DIR/scripts/restore_config.sh" --tool <name> --latest`

## Dry Run

If the user wants to preview changes first, add `--dry-run` to each script:
```bash
bash "$SKILL_DIR/scripts/python/setup.sh" --dry-run
bash "$SKILL_DIR/scripts/node/setup.sh" --dry-run
```

## Backup & Restore

Backups are stored in `~/.china-mirror-backup/`.

```bash
# Backup all tool configs
bash "$SKILL_DIR/scripts/backup_config.sh" --all

# Backup specific tool
bash "$SKILL_DIR/scripts/backup_config.sh" --tool pip

# Restore latest backup for a tool
bash "$SKILL_DIR/scripts/restore_config.sh" --tool pip --latest

# List all backups
bash "$SKILL_DIR/scripts/restore_config.sh" --list
```
