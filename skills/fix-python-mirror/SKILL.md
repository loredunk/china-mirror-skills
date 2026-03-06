# fix-python-mirror

## Name

Fix Python Package Mirror

## Description

Configures pip, uv, and Poetry to use China-based PyPI mirrors for faster package downloads. Supports Tsinghua (TUNA), USTC, Alibaba Cloud, and other verified mirrors.

## When to Use

Use this skill when:
- `pip install` is very slow or times out
- `uv pip install` downloads are slow
- `poetry install` takes a long time
- Python packages fail to download
- You see "connection timeout" errors from pypi.org

## Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| tool | string | No | Target tool: pip, uv, poetry, all (default: all) |
| mirror | string | No | Mirror preference: tuna, ustc, aliyun, douban, tencent (default: tuna) |
| dry_run | boolean | No | Show what would change without applying (default: false) |

## Steps

### Step 1: Detect Python Tools

Check which Python package managers are installed:
- pip / pip3
- uv (Astral's fast Python package installer)
- Poetry

### Step 2: Backup Existing Configuration

For each detected tool, backup existing configuration:
- `~/.config/pip/pip.conf`
- `~/.pip/pip.conf` (legacy)
- `~/.config/uv/uv.toml`
- Poetry uses pip configuration

### Step 3: Configure Mirror

Generate and apply configuration files:

**For pip:**
```ini
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
timeout = 120
retries = 5
```

**For uv:**
```toml
[pip]
index-url = "https://pypi.tuna.tsinghua.edu.cn/simple"
trusted-host = ["pypi.tuna.tsinghua.edu.cn"]
```

### Step 4: Verify Configuration

Test the configuration:
- `pip config get global.index-url`
- Check that the mirror URL is returned

## Safety Notes

⚠️ **Backup**: Original `pip.conf` or `uv.toml` is backed up to `.backup/pip/<timestamp>/`

⚠️ **Idempotent**: Running this skill multiple times updates the configuration rather than duplicating it

⚠️ **Proxy Warning**: Warns if HTTP_PROXY or HTTPS_PROXY is set (may conflict with mirrors)

## Verification

```bash
# Check pip configuration
pip config get global.index-url
pip config get global.trusted-host

# Test download speed
pip install --no-cache-dir pip --upgrade

# For uv
uv pip install --no-cache pip
```

## Available Mirrors

| Mirror | URL | Priority |
|--------|-----|----------|
| Tsinghua (TUNA) | https://pypi.tuna.tsinghua.edu.cn/simple | 1 (default) |
| USTC | https://pypi.mirrors.ustc.edu.cn/simple | 2 |
| Alibaba Cloud | https://mirrors.aliyun.com/pypi/simple | 3 |
| Douban | https://pypi.doubanio.com/simple | 4 |
| Tencent Cloud | https://mirrors.cloud.tencent.com/pypi/simple | 5 |

## Examples

### Example 1: Quick Fix

```
"Fix my pip downloads, they're too slow"
"Make pip install faster in China"
```

### Example 2: Specific Tool

```
"Configure uv to use China mirror"
"Setup Poetry with Tsinghua mirror"
```

### Example 3: Specific Mirror

```
"Use Alibaba Cloud mirror for pip"
"Configure pip with USTC mirror"
```

## Troubleshooting

### Issue: pip still slow after configuration

**Check**: Verify configuration is applied
```bash
pip config get global.index-url
```

**Check**: Look for competing configurations
```bash
pip config list -v
```

### Issue: SSL certificate errors

**Cause**: Some mirrors may have certificate issues

**Fix**: Use a different mirror or update certificates:
```bash
# Update CA certificates (Ubuntu/Debian)
sudo apt-get update && sudo apt-get install ca-certificates

# Or use http instead of https temporarily
```

### Issue: Package not found on mirror

**Cause**: Some packages may not be synced yet

**Fix**: The configuration includes both the mirror and direct fallback. If a package is not found, pip will try the original PyPI.

## Rollback

To restore original configuration:

```bash
# Using the restore script
./scripts/restore_config.sh --tool pip --latest

# Or manually
cp ~/.backup/pip/<timestamp>/pip.conf ~/.config/pip/pip.conf
```

## Implementation

```bash
./scripts/setup_pip.sh --tool <tool> --mirror <mirror>
```
