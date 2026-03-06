# fix-conda-mirror

## Name

Fix Conda/Anaconda Mirror

## Description

Configures Conda and Anaconda to use China-based package mirrors for faster environment creation and package installation. Supports Tsinghua (TUNA) and USTC mirrors covering main, conda-forge, bioconda, and other popular channels.

## When to Use

Use this skill when:
- `conda install` is very slow
- `conda create` takes forever to resolve dependencies
- `conda update` times out
- Package downloads from repo.anaconda.com are slow

## Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| mirror | string | No | Mirror preference: tuna, ustc (default: tuna) |
| channels | string[] | No | Channels to configure (defaults, conda-forge, bioconda) |
| dry_run | boolean | No | Show what would change without applying (default: false) |

## Steps

### Step 1: Detect Conda Installation

Check for conda or mamba:
```bash
which conda
which mamba
```

Also check for Anaconda/Miniconda installation locations.

### Step 2: Backup Existing Configuration

Backup `~/.condarc` if it exists:
```bash
cp ~/.condarc ~/.condarc.backup.<date>
```

### Step 3: Generate .condarc

Create new `.condarc` with mirror configuration:

```yaml
channels:
  - defaults
show_channel_urls: true
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  bioconda: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  menpo: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
```

### Step 4: Clean Index Cache

Remove cached package indexes to force reload:
```bash
conda clean -i -y
```

### Step 5: Verify Configuration

Test the new configuration:
```bash
conda info  # Should show mirror URLs
conda search python  # Quick connectivity test
```

## Safety Notes

⚠️ **Channel Priority**: Mirror configuration preserves channel priority (defaults first)

⚠️ **Cloud Channels**: Also configures popular cloud channels (conda-forge, bioconda)

⚠️ **Mixed Sources**: Some packages may still come from official sources if not mirrored

## Verification

```bash
# Check current channels
conda config --show channels
conda config --show default_channels

# Check full config
conda config --show-sources

# Test package search
conda search numpy

# Check package source
conda list numpy  # Look for 'channel' column
```

## Available Mirrors

| Mirror | URL | Priority |
|--------|-----|----------|
| Tsinghua (TUNA) | https://mirrors.tuna.tsinghua.edu.cn/anaconda | 1 (default) |
| USTC | https://mirrors.ustc.edu.cn/anaconda | 2 |

## Configured Channels

The following channels are configured with mirror URLs:

- `defaults` (main, r, msys2)
- `conda-forge`
- `bioconda`
- `menpo`
- `pytorch`
- `pytorch-lts`
- `simpleitk`

## Examples

### Example 1: Quick Fix

```
"Make conda install faster"
"Fix slow conda package downloads"
```

### Example 2: Specific Mirror

```
"Use USTC mirror for conda"
```

### Example 3: With Specific Channels

```
"Configure conda with China mirror for pytorch"
```

## Troubleshooting

### Issue: conda still uses official channels

**Check**: Look for `.condarc` in multiple locations
```bash
conda config --show-sources
# Check project-level .condarc
cat .condarc 2>/dev/null || echo "No project .condarc"
```

**Fix**: Remove conflicting configs:
```bash
conda config --remove channels defaults
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
```

### Issue: Package not found on mirror

**Cause**: Some packages may not be synced to mirror

**Fix**: Temporarily use official:
```bash
conda install -c defaults <package>
```

### Issue: CondaHTTPError

**Cause**: SSL certificate or connectivity issues

**Fix**:
```bash
# Update certificates
conda install -c conda-forge certifi

# Or disable SSL verification (not recommended)
conda config --set ssl_verify false
```

### Issue: Slow environment solving

**Cause**: Dependency resolution is CPU-intensive, not network

**Fix**: Use mamba instead:
```bash
conda install -c conda-forge mamba
mamba install <package>  # Much faster solving
```

## Rollback

```bash
# Using restore script
./scripts/restore_config.sh --tool conda --latest

# Or manually
cp ~/.condarc.backup.* ~/.condarc

# Or remove custom config
rm ~/.condarc
conda clean -i -y
```

## Implementation

```bash
./scripts/setup_conda.sh --mirror <mirror>
```
