# bootstrap-china-network

## Name

Bootstrap China Network Environment

## Description

Main entry point for configuring development tools to work efficiently in China's network environment. This skill diagnoses the current environment and automatically applies appropriate mirror configurations for all detected tools.

## When to Use

Use this skill when:
- Setting up a new development machine in China
- Downloads from official sources are slow or failing
- Multiple package managers need configuration
- You're unsure which specific tools need mirror configuration
- You want a comprehensive network environment setup

## Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| tools | string[] | No | Specific tools to configure (auto-detect if not specified) |
| mirror_preference | string | No | Preferred mirror source (tuna, ustc, aliyun, etc.) |
| dry_run | boolean | No | Show what would be changed without applying (default: false) |

## Steps

### Step 1: Environment Diagnosis

First, diagnose the current environment:

1. Detect operating system (Linux/macOS)
2. Detect installed package managers
3. Check for existing proxy configurations
4. Check for existing mirror configurations
5. Test connectivity to official sources

### Step 2: Conflict Detection

Check for potential conflicts:

1. **Proxy Environment Variables**: Check if `http_proxy`, `https_proxy`, `HTTP_PROXY`, `HTTPS_PROXY` are set
   - Warn if both proxy and mirrors are requested (may cause conflicts)
   - Suggest unsetting proxy if in China

2. **Existing Configurations**: Check if mirrors are already configured
   - Offer to backup existing configurations
   - Skip if already properly configured

### Step 3: Select Tools to Configure

Based on user input or auto-detection:

| Tool | Detection Method | Priority |
|------|------------------|----------|
| pip/uv/poetry | `which pip` / `which uv` | High |
| npm/yarn/pnpm | `which npm` | High |
| Docker CE | `which docker` | High |
| apt | `/etc/apt/sources.list` | High (Linux) |
| Homebrew | `which brew` | High (macOS) |
| Conda | `which conda` | Medium |
| Cargo | `which cargo` | Medium |
| Go | `which go` | Medium |
| Flutter | `which flutter` | Low |

### Step 4: Apply Configurations

For each selected tool:

1. **Backup** existing configuration
2. **Apply** mirror configuration using appropriate script
3. **Verify** configuration is working
4. **Log** results

### Step 5: Summary and Next Steps

Provide a summary of:
- What was configured
- How to verify each configuration
- How to restore original settings
- Any warnings or recommendations

## Safety Notes

⚠️ **Backup First**: This skill always backs up existing configurations before modification.

⚠️ **Proxy Conflicts**: If HTTP/HTTPS proxy environment variables are detected, the skill will warn about potential conflicts with mirrors.

⚠️ **Idempotent**: Running this skill multiple times is safe - it will update existing configurations rather than duplicate them.

⚠️ **Reversible**: All changes can be reverted using the restore script or by invoking the appropriate skill.

## Verification

After running this skill, verify configurations:

```bash
# Python
pip config get global.index-url

# Node.js
npm config get registry

# Docker
apt-cache policy docker-ce  # Check source

# apt
cat /etc/apt/sources.list

# Homebrew
echo $HOMEBREW_BREW_GIT_REMOTE

# Conda
conda config --show channels

# Cargo
cat ~/.cargo/config.toml

# Go
go env GOPROXY

# Flutter
echo $FLUTTER_STORAGE_BASE_URL
```

## Examples

### Example 1: Full Environment Setup

```
"Setup my development environment for China's network"
"Configure all my package managers to use China mirrors"
```

### Example 2: Specific Tools

```
"Configure pip and npm to use China mirrors"
"Setup Python and Node.js mirrors for China"
```

### Example 3: With Preferences

```
"Use Tsinghua mirror for everything"
"Configure development tools with USTC mirror"
```

### Example 4: Dry Run

```
"Show me what would change without actually doing it"
"Preview the mirror configuration changes"
```

## Troubleshooting

### Issue: Proxy warnings

**Symptom**: Skill warns about proxy environment variables

**Resolution**:
```bash
# Temporarily disable proxy
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY

# Or configure mirrors without proxy
```

### Issue: Permission denied

**Symptom**: Cannot modify system files (apt, Docker CE)

**Resolution**: Run with sudo or ensure user has passwordless sudo configured.

### Issue: Tool not detected

**Symptom**: A tool is installed but not detected

**Resolution**: Ensure the tool is in PATH, or explicitly specify the tool.

## Related Skills

- `diagnose-network-environment` - Deep network diagnostics
- `fix-python-mirror` - Python-specific configuration
- `fix-node-mirror` - Node.js-specific configuration
- `fix-docker-mirror` - Docker-specific configuration
- `fix-apt-mirror` - APT-specific configuration
- `fix-homebrew-mirror` - Homebrew-specific configuration
- `fix-conda-mirror` - Conda-specific configuration
- `fix-rust-mirror` - Rust/Cargo-specific configuration
- `fix-go-proxy` - Go-specific configuration
- `fix-flutter-mirror` - Flutter-specific configuration

## Implementation

This skill delegates to the following scripts:

```
scripts/bootstrap.sh --detect --apply
scripts/setup_<tool>.sh --mirror <mirror>
scripts/backup_config.sh --all
```
