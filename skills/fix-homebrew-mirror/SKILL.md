---
name: fix-homebrew-mirror
description: |
  Configure Homebrew to use China-based git mirrors (TUNA, USTC) for faster formula/tap updates
  and bottle downloads. Use this skill whenever brew update is slow, brew install takes too long,
  tap operations time out, or Homebrew git operations hang in China. Also use when setting up
  Homebrew on a new Mac or Linux machine in China. If the user says "brew 太慢", "Homebrew 好慢",
  or similar, always use this skill.
---

# Configure Homebrew Mirror

Configure Homebrew git remotes and environment variables to use a China mirror.

## Steps

**1. Check if Homebrew is installed**
```bash
which brew && brew --version
```
If not installed, provide installation instructions via mirror (see below).

**2. Run the setup script**

Default mirror: **tuna**.

```bash
./scripts/setup_homebrew.sh --mirror <tuna|ustc>
```

The script sets environment variables in the shell profile AND updates git remote URLs for existing installations.

**3. Verify**
```bash
echo $HOMEBREW_BREW_GIT_REMOTE   # Should show mirror URL
brew update                       # Should be fast
```

## Available Mirrors

| Mirror | Git Base URL | Priority |
|--------|-------------|----------|
| Tsinghua TUNA | https://mirrors.tuna.tsinghua.edu.cn/git/homebrew | 1 (default) |
| USTC | https://mirrors.ustc.edu.cn/brew.git | 2 |

## Config Reference

Add to shell profile (`~/.zshrc` or `~/.bash_profile`):

**Tsinghua TUNA:**
```bash
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
```

Also update git remotes for existing installations:
```bash
cd "$(brew --prefix)" && git remote set-url origin "$HOMEBREW_BREW_GIT_REMOTE"
cd "$(brew --prefix)/Library/Taps/homebrew/homebrew-core" && git remote set-url origin "$HOMEBREW_CORE_GIT_REMOTE"
```

## Installing Homebrew via Mirror (if not yet installed)

```bash
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Rollback

```bash
./scripts/restore_config.sh --tool homebrew --latest
# Reset git remotes: cd "$(brew --prefix)" && git remote set-url origin https://github.com/Homebrew/brew.git
```
