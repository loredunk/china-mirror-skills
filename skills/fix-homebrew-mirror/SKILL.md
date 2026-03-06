# fix-homebrew-mirror

## Name

Fix Homebrew Mirror

## Description

Configures Homebrew to use China-based git mirrors for faster formula/tap updates and bottle downloads. Supports Tsinghua (TUNA) and USTC mirrors.

## When to Use

Use this skill when:
- `brew update` is very slow
- `brew install` takes a long time to download bottles
- `brew tap` operations are slow
- Homebrew git operations timeout
- You're setting up Homebrew on a new macOS/Linux system in China

## Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| mirror | string | No | Mirror preference: tuna, ustc (default: tuna) |
| dry_run | boolean | No | Show what would change without applying (default: false) |

## Steps

### Step 1: Detect Homebrew Installation

Check if Homebrew is installed:
```bash
which brew
brew --prefix
```

If not installed, will provide installation instructions with mirror.

### Step 2: Backup Configuration

Backup shell profile that contains Homebrew environment variables:
- `~/.zshrc` (zsh)
- `~/.bash_profile` or `~/.bashrc` (bash)

### Step 3: Configure Environment Variables

Add to shell profile:

```bash
# Homebrew mirror configuration
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
```

### Step 4: Update Git Remotes (if Homebrew installed)

For existing installations, update git remotes:
```bash
cd "$(brew --prefix)"
git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git

cd "$(brew --prefix)/Library/Taps/homebrew/homebrew-core"
git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git
```

### Step 5: Run brew update

Execute `brew update` to test the new configuration.

## Safety Notes

⚠️ **Git Remotes**: Modifies git remote URLs for Homebrew repositories

⚠️ **Shell Profile**: Adds environment variables to shell profile

⚠️ **Bottle Domain**: Changes where precompiled binaries are downloaded from

## Verification

```bash
# Check environment variables
echo $HOMEBREW_BREW_GIT_REMOTE
echo $HOMEBREW_CORE_GIT_REMOTE

# Check git remotes
cd "$(brew --prefix)" && git remote -v

# Test update
brew update

# Time a package install
time brew install --dry-run wget
```

## Available Mirrors

| Mirror | Git URL | Priority |
|--------|---------|----------|
| Tsinghua (TUNA) | https://mirrors.tuna.tsinghua.edu.cn/git/homebrew | 1 (default) |
| USTC | https://mirrors.ustc.edu.cn/brew.git | 2 |

## Installation with Mirror

If Homebrew is not yet installed:

```bash
# Set mirror environment variables first
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"

# Run official installer
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Examples

### Example 1: Quick Fix

```
"Homebrew is so slow, fix it"
"Make brew update faster in China"
```

### Example 2: Specific Mirror

```
"Use USTC mirror for Homebrew"
```

### Example 3: New Installation

```
"Install Homebrew with China mirror"
"Setup Homebrew on my new Mac in China"
```

## Troubleshooting

### Issue: brew update still slow

**Check**: Verify environment variables are set
```bash
echo $HOMEBREW_BREW_GIT_REMOTE
```

If empty, reload shell profile:
```bash
source ~/.zshrc  # or ~/.bash_profile
```

### Issue: Git authentication errors

**Cause**: Git credential manager conflicts

**Fix**:
```bash
# Use GitHub CLI token or SSH instead of HTTPS
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

### Issue: Some bottles not found

**Cause**: Mirror might not have all bottles

**Fix**: Homebrew will fall back to building from source. To force mirror only:
```bash
export HOMEBREW_NO_AUTO_UPDATE=1
```

### Issue: M1/M2 Mac-specific problems

**Cause**: ARM64 bottles might have different paths

**Fix**: Ensure you're using ARM64-native Homebrew:
```bash
which brew  # Should be /opt/homebrew/bin/brew, not /usr/local/bin/brew
```

## Rollback

```bash
# Using restore script
./scripts/restore_config.sh --tool homebrew --latest

# Or manually edit shell profile
nano ~/.zshrc  # or ~/.bash_profile
# Remove Homebrew mirror lines

# Reset git remotes to official
cd "$(brew --prefix)"
git remote set-url origin https://github.com/Homebrew/brew.git
```

## Implementation

```bash
./scripts/setup_homebrew.sh --mirror <mirror>
```
