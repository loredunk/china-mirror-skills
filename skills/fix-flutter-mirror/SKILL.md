# fix-flutter-mirror

## Name

Fix Flutter/Dart Mirror

## Description

Configures Flutter SDK and Dart Pub to use China-based mirrors for faster SDK downloads, dependency resolution, and package installation.

## When to Use

Use this skill when:
- Flutter SDK download is slow
- `flutter doctor` takes forever downloading components
- `flutter packages get` is slow
- `pub get` times out
- Dart package downloads from pub.dev are slow

## Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| mirror | string | No | Mirror preference: tuna, ustc (default: tuna) |
| dry_run | boolean | No | Show what would change without applying (default: false) |

## Steps

### Step 1: Detect Flutter Installation

Check for Flutter:
```bash
which flutter
flutter --version
```

If not installed, provide installation instructions with mirror.

### Step 2: Backup Shell Profile

Backup shell profile:
- `~/.zshrc` (zsh)
- `~/.bashrc` or `~/.bash_profile` (bash)

### Step 3: Configure Environment Variables

Add to shell profile:

```bash
# Flutter mirror configuration
export FLUTTER_STORAGE_BASE_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter
export PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter/dart-pub
```

### Step 4: Apply for Current Session

```bash
export FLUTTER_STORAGE_BASE_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter
export PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter/dart-pub
```

### Step 5: Update Flutter (if installed)

If Flutter is already installed:
```bash
flutter channel stable
flutter upgrade
```

### Step 6: Verify

Test the configuration:
```bash
echo $FLUTTER_STORAGE_BASE_URL
flutter doctor
flutter packages get  # In a Flutter project
```

## Safety Notes

⚠️ **SDK Downloads**: `FLUTTER_STORAGE_BASE_URL` affects Flutter SDK component downloads

⚠️ **Pub Packages**: `PUB_HOSTED_URL` affects Dart/Flutter package downloads

⚠️ **Git Repository**: Flutter itself is cloned from git; use mirror for initial clone

## Verification

```bash
# Check environment variables
echo $FLUTTER_STORAGE_BASE_URL
echo $PUB_HOSTED_URL

# Verify Flutter can connect
flutter doctor --android-licenses

# Test package download
cd your_flutter_project
rm -rf pubspec.lock .packages
flutter packages get -v  # -v for verbose output
```

## Available Mirrors

| Mirror | Storage URL | Pub URL | Priority |
|--------|-------------|---------|----------|
| Tsinghua (TUNA) | https://mirrors.tuna.tsinghua.edu.cn/flutter | https://mirrors.tuna.tsinghua.edu.cn/flutter/dart-pub | 1 (default) |
| USTC | https://mirrors.ustc.edu.cn/flutter | https://mirrors.ustc.edu.cn/flutter/dart-pub | 2 |

## Flutter Installation with Mirror

If Flutter is not yet installed:

```bash
# Clone from mirror instead of GitHub
git clone https://mirrors.tuna.tsinghua.edu.cn/git/flutter-sdk.git flutter
# or
git clone https://mirrors.ustc.edu.cn/flutter.git flutter

# Add to PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# Set mirror environment variables
export FLUTTER_STORAGE_BASE_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter
export PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter/dart-pub

# Initialize Flutter
flutter doctor
```

## Examples

### Example 1: Quick Fix

```
"Flutter downloads are too slow"
"Make flutter packages get faster"
```

### Example 2: Specific Mirror

```
"Use USTC mirror for Flutter"
```

### Example 3: New Flutter Setup

```
"Install Flutter with China mirror"
"Setup Flutter development in China"
```

## Troubleshooting

### Issue: flutter doctor still slow

**Check**: Environment variables are set
```bash
echo $FLUTTER_STORAGE_BASE_URL
```

**Fix**: Reload shell
```bash
source ~/.zshrc  # or ~/.bashrc
```

### Issue: Git clone of Flutter is slow

**Cause**: Initial Flutter SDK clone from GitHub

**Fix**: Clone from mirror:
```bash
git clone https://mirrors.tuna.tsinghua.edu.cn/git/flutter-sdk.git flutter
```

### Issue: Android SDK downloads are slow

**Cause**: Android SDK comes from Google servers

**Fix**: Configure Android SDK separately or use Android Studio's built-in SDK manager

### Issue: Some packages not found

**Cause**: Mirror sync delay

**Fix**: Use official pub.dev temporarily:
```bash
unset PUB_HOSTED_URL
flutter packages get
export PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter/dart-pub
```

### Issue: CocoaPods issues on macOS

**Cause**: CocoaPods is separate from Flutter/Dart mirrors

**Fix**: Configure CocoaPods separately:
```bash
# In Podfile, add source
source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'
```

## Rollback

```bash
# Using restore script
./scripts/restore_config.sh --tool flutter --latest

# Or manually edit shell profile
nano ~/.zshrc  # or ~/.bashrc
# Remove FLUTTER_STORAGE_BASE_URL and PUB_HOSTED_URL lines

# Unset for current session
unset FLUTTER_STORAGE_BASE_URL PUB_HOSTED_URL
```

## Implementation

```bash
./scripts/setup_flutter.sh --mirror <mirror>
```
