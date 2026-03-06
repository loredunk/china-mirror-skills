---
name: fix-apt-mirror
description: |
  Configure Ubuntu or Debian APT package sources to use China-based mirrors (TUNA, USTC, Alibaba Cloud,
  Tencent Cloud) for faster system updates and package installations. Use this skill whenever apt update
  is slow, apt install downloads packages slowly, system updates time out, or "Failed to fetch" errors
  appear from archive.ubuntu.com or deb.debian.org. Also use when setting up a new Linux server/container
  in China. If the user says "apt 太慢", "apt update 超时", or similar, always use this skill.
---

# Configure Ubuntu/Debian APT Mirror

Replace official APT sources with a China mirror for faster system package downloads.

## Steps

**1. Detect Linux distribution and codename**
```bash
source /etc/os-release
echo "ID=$ID VERSION_CODENAME=$VERSION_CODENAME"
# or: lsb_release -is && lsb_release -cs
```
This is critical — the wrong codename causes 404 errors. Auto-detect if not specified.

**2. Run the setup script**

Default mirror: **tuna**. Requires sudo.

```bash
sudo ./scripts/setup_apt.sh --mirror <tuna|ustc|aliyun|tencent>
```

The script backs up `/etc/apt/sources.list` before modification.

**3. Verify**
```bash
cat /etc/apt/sources.list        # Confirm mirror URLs
sudo apt-get update              # Should be fast now
apt-cache policy docker-ce       # Check which source packages come from
```

## Available Mirrors

| Mirror | Base URL | Priority |
|--------|----------|----------|
| Tsinghua TUNA | https://mirrors.tuna.tsinghua.edu.cn | 1 (default) |
| USTC | https://mirrors.ustc.edu.cn | 2 |
| Alibaba Cloud | https://mirrors.aliyun.com | 3 |
| Tencent Cloud | https://mirrors.cloud.tencent.com | 4 |

## Config Reference

**Ubuntu sources.list** (replace `jammy` with actual codename):
```
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
```

**Debian sources.list** (replace `bookworm` with actual codename):
```
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security/ bookworm-security main contrib non-free
```

## Supported Codenames

- Ubuntu: `noble` (24.04), `jammy` (22.04), `focal` (20.04)
- Debian: `bookworm` (12), `bullseye` (11)

## Rollback

```bash
sudo ./scripts/restore_config.sh --tool apt --latest
# Or: sudo cp /etc/apt/sources.list.backup.* /etc/apt/sources.list && sudo apt-get update
```
