---
name: fix-python-mirror
description: |
  Configure pip, uv, and Poetry to use verified China-based PyPI mirrors (TUNA, USTC, Alibaba Cloud)
  for dramatically faster Python package downloads. Use this skill whenever pip install, uv pip install,
  or poetry install is slow, times out, or fails in a China network environment. Also use when the user
  mentions slow pypi.org, connection timeouts for Python packages, or is setting up a Python development
  environment in China. If the user says "pip 太慢" or similar, always use this skill.
---

# Configure Python Package Mirror

Configure pip, uv, and/or Poetry to use a China mirror for faster downloads.

## Steps

**1. Detect installed Python tools**
```bash
which pip pip3 uv poetry 2>/dev/null
pip --version 2>/dev/null; uv --version 2>/dev/null; poetry --version 2>/dev/null
```

**2. Check for proxy conflicts**
```bash
echo "HTTP_PROXY=$HTTP_PROXY HTTPS_PROXY=$HTTPS_PROXY"
```
Warn if proxy environment variables are set — they may conflict with mirrors and should be unset.

**3. Run the setup script**

Ask the user which mirror to use if not specified. Default: **tuna** (Tsinghua TUNA, priority 1).

```bash
./scripts/setup_pip.sh --mirror <tuna|ustc|aliyun|douban|tencent>
```

The script handles backup, idempotent configuration, and applies to all detected tools (pip, uv, Poetry).

**4. Verify**
```bash
pip config get global.index-url   # Should show mirror URL
uv pip install --no-cache pip     # Quick test (if uv installed)
```

## Available Mirrors

| Mirror | URL | Priority |
|--------|-----|----------|
| Tsinghua TUNA | https://pypi.tuna.tsinghua.edu.cn/simple | 1 (default) |
| USTC | https://pypi.mirrors.ustc.edu.cn/simple | 2 |
| Alibaba Cloud | https://mirrors.aliyun.com/pypi/simple | 3 |
| Douban | https://pypi.doubanio.com/simple | 4 |
| Tencent Cloud | https://mirrors.cloud.tencent.com/pypi/simple | 5 |

## Config Reference

**pip** (`~/.config/pip/pip.conf`):
```ini
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
timeout = 120
retries = 5
```

**uv** (`~/.config/uv/uv.toml`):
```toml
[pip]
index-url = "https://pypi.tuna.tsinghua.edu.cn/simple"
trusted-host = ["pypi.tuna.tsinghua.edu.cn"]
```

## Rollback

```bash
./scripts/restore_config.sh --tool pip --latest
```
