---
name: fix-github-mirror
description: |
  Diagnose and mitigate GitHub access problems in China. Use this skill when GitHub Releases
  downloads are slow, `curl` or browser downloads from github.com time out, or a curated
  mirrored repository such as flutter/flutter needs a faster git clone path. This skill should
  be used for GitHub-specific cases only. It does not assume a universal GitHub mirror exists;
  instead it prefers official GitHub Release mirrors and curated project-level git mirrors.
---

# Diagnose GitHub Mirror Options

Handle GitHub access issues by separating release downloads from repository clones.

## Steps

**1. Identify the failing GitHub path**
```bash
git remote -v 2>/dev/null
env | grep -i proxy
```

Classify the issue:
- `https://github.com/<owner>/<repo>/releases/download/...` => GitHub Releases asset
- `git clone https://github.com/...` => repository clone/fetch
- `raw.githubusercontent.com` or API traffic => not covered by this script

**2. For GitHub Releases, convert the download URL**

Default mirror: **tuna**.

```bash
./scripts/setup_github.sh --mirror <tuna|ustc> --release-url <github-release-url>
```

Example:
```bash
./scripts/setup_github.sh --release-url \
  https://github.com/cli/cli/releases/download/v2.69.0/gh_2.69.0_checksums.txt
```

This prints a mirrored download URL using the official GitHub Release mirror path.

**3. For curated mirrored repositories, configure git rewrite**

Currently supported project: **flutter-sdk** (`flutter/flutter`).

```bash
./scripts/setup_github.sh --project flutter-sdk --mirror tuna
```

This writes `git config --global url.<mirror>.insteadOf ...` rules to `~/.gitconfig`.

**4. Verify**
```bash
git config --global --get-regexp '^url\..*insteadOf$'
```

For release assets, test the printed mirror URL with:
```bash
curl -I '<mirrored-url>'
```

## Available Mirrors

### GitHub Releases

| Mirror | Base URL | Priority |
|--------|----------|----------|
| Tsinghua TUNA | https://mirrors.tuna.tsinghua.edu.cn/github-release/ | 1 (default) |
| USTC | https://mirrors.ustc.edu.cn/github-release/ | 2 |

### Curated Git Mirrors

| Project | Upstream | Mirror | Priority |
|---------|----------|--------|----------|
| flutter-sdk | https://github.com/flutter/flutter.git | https://mirrors.tuna.tsinghua.edu.cn/git/flutter-sdk.git | 1 |

## Notes

- Do not present GitHub Release mirrors as a universal GitHub proxy
- Do not rewrite arbitrary `github.com/*` remotes globally; only configure curated project mirrors with official help pages
- If the user needs `raw.githubusercontent.com`, GitHub API, or private repository access, recommend a normal proxy/VPN instead of mirror rewrites

## Rollback

```bash
./scripts/restore_config.sh --tool github --latest
```
