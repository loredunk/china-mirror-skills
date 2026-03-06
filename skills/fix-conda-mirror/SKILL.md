---
name: fix-conda-mirror
description: |
  Configure Conda/Anaconda to use China-based package channel mirrors (TUNA, USTC) for faster
  conda install, conda create, and package downloads. Use this skill whenever conda install is slow,
  conda create takes forever, conda update times out, or downloads from repo.anaconda.com are failing
  in China. Also use when setting up a data science or ML Python environment in China. If the user
  says "conda 太慢", "anaconda 下载好慢", or similar, always use this skill.
---

# Configure Conda/Anaconda Mirror

Configure Conda to use China mirrors via `~/.condarc`.

## Steps

**1. Check for conda/mamba**
```bash
which conda mamba 2>/dev/null && conda --version
```

**2. Run the setup script**

Default mirror: **tuna**.

```bash
./scripts/setup_conda.sh --mirror <tuna|ustc>
```

The script backs up `~/.condarc` and writes new mirror configuration.

**3. Clear index cache to force reload**
```bash
conda clean -i -y
```

**4. Verify**
```bash
conda config --show default_channels   # Should show mirror URLs
conda search python                    # Quick connectivity test
```

## Available Mirrors

| Mirror | Base URL | Priority |
|--------|----------|----------|
| Tsinghua TUNA | https://mirrors.tuna.tsinghua.edu.cn/anaconda | 1 (default) |
| USTC | https://mirrors.ustc.edu.cn/anaconda | 2 |

## Config Reference (`~/.condarc`)

**Tsinghua TUNA:**
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
  pytorch-lts: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  simpleitk: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
```

## Note

Slow environment solving (conda create, conda install) is often a CPU-bound dependency resolution
problem, not a network issue. If still slow after configuring mirrors, suggest using **mamba**:
```bash
conda install -c conda-forge mamba
mamba install <package>
```

## Rollback

```bash
./scripts/restore_config.sh --tool conda --latest
# Or: rm ~/.condarc && conda clean -i -y
```
