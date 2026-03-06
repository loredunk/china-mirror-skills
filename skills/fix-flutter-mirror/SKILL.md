---
name: fix-flutter-mirror
description: |
  Configure Flutter SDK and Dart Pub to use China-based mirrors (TUNA, USTC) via
  FLUTTER_STORAGE_BASE_URL and PUB_HOSTED_URL environment variables for faster SDK downloads
  and package fetching. Use this skill whenever Flutter SDK downloads are slow, flutter doctor
  hangs downloading components, flutter packages get or pub get times out, or Dart packages
  from pub.dev are slow in China. Also use when setting up Flutter development in China.
  If the user says "Flutter 太慢", "pub get 超时", or similar, always use this skill.
---

# Configure Flutter/Dart Mirror

Set Flutter storage and Pub mirror environment variables for China.

## Steps

**1. Check Flutter installation**
```bash
which flutter 2>/dev/null && flutter --version
```
If not installed, provide installation-via-mirror instructions (see below).

**2. Run the setup script**

Default mirror: **tuna**.

```bash
./scripts/setup_flutter.sh --mirror <tuna|ustc>
```

The script adds `FLUTTER_STORAGE_BASE_URL` and `PUB_HOSTED_URL` to the shell profile.

**3. Apply to current session and verify**
```bash
source ~/.zshrc    # or ~/.bashrc
echo $FLUTTER_STORAGE_BASE_URL
flutter doctor     # Should download components faster
```

## Available Mirrors

| Mirror | FLUTTER_STORAGE_BASE_URL | PUB_HOSTED_URL | Priority |
|--------|--------------------------|----------------|----------|
| Tsinghua TUNA | https://mirrors.tuna.tsinghua.edu.cn/flutter | https://mirrors.tuna.tsinghua.edu.cn/flutter/dart-pub | 1 |
| USTC | https://mirrors.ustc.edu.cn/flutter | https://mirrors.ustc.edu.cn/flutter/dart-pub | 2 |

## Config Reference

Add to shell profile (`~/.zshrc` or `~/.bash_profile`):
```bash
export FLUTTER_STORAGE_BASE_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter
export PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter/dart-pub
```

## Installing Flutter via Mirror (if not yet installed)

```bash
# Clone Flutter SDK from mirror
git clone https://mirrors.tuna.tsinghua.edu.cn/git/flutter-sdk.git flutter

# Add to PATH and set mirror env vars
export PATH="$PATH:$(pwd)/flutter/bin"
export FLUTTER_STORAGE_BASE_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter
export PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter/dart-pub

flutter doctor
```

## Notes

- Android SDK downloads from Google servers are not covered by these mirrors — configure separately if needed
- CocoaPods on macOS: add `source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'` to Podfile

## Rollback

```bash
./scripts/restore_config.sh --tool flutter --latest
# Or: edit shell profile, remove the two export lines; then: unset FLUTTER_STORAGE_BASE_URL PUB_HOSTED_URL
```
