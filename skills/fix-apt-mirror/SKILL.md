# fix-apt-mirror

## Name

Fix APT Package Mirror

## Description

Configures Ubuntu or Debian APT to use China-based package mirrors for faster system updates and package installations. Supports Tsinghua (TUNA), USTC, Alibaba Cloud, and Tencent Cloud mirrors.

## When to Use

Use this skill when:
- `apt update` is very slow
- `apt install` downloads packages slowly
- System updates time out
- You see "Failed to fetch" errors from archive.ubuntu.com

## Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| mirror | string | No | Mirror preference: tuna, ustc, aliyun, tencent (default: tuna) |
| codename | string | No | Ubuntu/Debian codename (auto-detected) |
| dry_run | boolean | No | Show what would change without applying (default: false) |

## Steps

### Step 1: Detect Distribution

Check Linux distribution:
```bash
source /etc/os-release
echo $ID      # ubuntu or debian
echo $VERSION_CODENAME  # jammy, focal, noble, etc.
```

### Step 2: Backup sources.list

Backup the original APT configuration:
```bash
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup.<date>
```

### Step 3: Generate New sources.list

**For Ubuntu:**
```
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
```

**For Debian:**
```
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security/ bookworm-security main contrib non-free
```

### Step 4: Apply and Update

1. Write new sources.list
2. Run `apt-get update` to refresh package lists

## Safety Notes

⚠️ **CRITICAL**: This modifies system package sources. Incorrect configuration can break package management.

⚠️ **Backup**: Original `/etc/apt/sources.list` is backed up automatically

⚠️ **Root Required**: Requires sudo privileges

⚠️ **Codename**: Wrong codename can cause 404 errors

## Verification

```bash
# Check current sources
cat /etc/apt/sources.list

# Verify update works
sudo apt-get update

# Check package source
apt-cache policy ubuntu-server  # Should show mirror URL
```

## Available Mirrors

| Mirror | URL | Priority |
|--------|-----|----------|
| Tsinghua (TUNA) | https://mirrors.tuna.tsinghua.edu.cn | 1 (default) |
| USTC | https://mirrors.ustc.edu.cn | 2 |
| Alibaba Cloud | https://mirrors.aliyun.com | 3 |
| Tencent Cloud | https://mirrors.cloud.tencent.com | 4 |

## Supported Codenames

**Ubuntu:**
- `noble` - 24.04 LTS
- `jammy` - 22.04 LTS
- `focal` - 20.04 LTS

**Debian:**
- `bookworm` - 12
- `bullseye` - 11

## Examples

### Example 1: Quick Fix

```
"Make apt update faster"
"Switch Ubuntu to Tsinghua mirror"
```

### Example 2: Specific Mirror

```
"Use USTC mirror for apt"
"Configure Ubuntu with Alibaba Cloud mirror"
```

## Troubleshooting

### Issue: 404 Not Found errors

**Cause**: Wrong codename or mirror doesn't have your release

**Fix**:
```bash
# Check your actual codename
lsb_release -cs

# Edit sources.list with correct codename
sudo nano /etc/apt/sources.list
```

### Issue: GPG errors

**Cause**: Outdated GPG keys

**Fix**:
```bash
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys <KEY_ID>
# or
sudo apt-get install --reinstall ca-certificates
```

### Issue: apt update still slow

**Check**: DNS resolution issues
```bash
# Test mirror connectivity
curl -I https://mirrors.tuna.tsinghua.edu.cn

# Check DNS
cat /etc/resolv.conf
```

## Rollback

```bash
# Using restore script
sudo ./scripts/restore_config.sh --tool apt --latest

# Or manually
sudo cp /etc/apt/sources.list.backup.* /etc/apt/sources.list
sudo apt-get update
```

## Implementation

```bash
sudo ./scripts/setup_apt.sh --mirror <mirror> --codename <codename>
```
