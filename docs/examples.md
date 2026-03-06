# Usage Examples

## Quick Start: Full Environment Setup

Set up all tools at once using the bootstrap skill, or run individual setup scripts:

```bash
# Clone the repository
git clone https://github.com/yourusername/china-mirror-skills.git
cd china-mirror-skills

# Individual tool setup
./scripts/setup_pip.sh
./scripts/setup_npm.sh
./scripts/setup_apt.sh
./scripts/setup_cargo.sh
./scripts/setup_go.sh
```

---

## Python (pip, uv, poetry)

### pip

```bash
# Interactive setup (recommended)
./scripts/setup_pip.sh

# Choose specific mirror
./scripts/setup_pip.sh --mirror tuna   # Tsinghua TUNA
./scripts/setup_pip.sh --mirror ustc   # USTC
./scripts/setup_pip.sh --mirror aliyun # Alibaba Cloud

# Non-interactive
./scripts/setup_pip.sh --mirror tuna --yes

# Dry run (preview changes)
./scripts/setup_pip.sh --dry-run
```

**Manual configuration:**
```bash
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn
```

**Per-install override:**
```bash
pip install requests -i https://pypi.tuna.tsinghua.edu.cn/simple
```

---

## Node.js (npm, pnpm, yarn)

### npm

```bash
./scripts/setup_npm.sh
./scripts/setup_npm.sh --mirror npmmirror
./scripts/setup_npm.sh --mirror tencent
```

**Manual:**
```bash
npm config set registry https://registry.npmmirror.com
```

### pnpm

```bash
pnpm config set registry https://registry.npmmirror.com
```

### yarn

```bash
yarn config set registry https://registry.npmmirror.com
# or for yarn v2+
yarn config set npmRegistryServer https://registry.npmmirror.com
```

---

## Ubuntu/Debian APT

```bash
# Auto-detect Ubuntu version and apply TUNA mirror
./scripts/setup_apt.sh

# Choose mirror
./scripts/setup_apt.sh --mirror tuna
./scripts/setup_apt.sh --mirror ustc
./scripts/setup_apt.sh --mirror aliyun

# Force overwrite existing sources.list
./scripts/setup_apt.sh --mirror tuna --force
```

After setup:
```bash
sudo apt update
sudo apt upgrade
```

---

## Docker CE Installation

> **Note:** This configures the Docker CE **package repository** for installing/updating Docker CE via apt/yum. It does NOT configure Docker Hub image mirrors.

```bash
# Setup Docker CE package mirror
./scripts/setup_docker.sh
./scripts/setup_docker.sh --mirror tuna
./scripts/setup_docker.sh --mirror ustc

# Then install Docker CE normally
sudo apt install docker-ce docker-ce-cli containerd.io
```

---

## Rust / Cargo

```bash
./scripts/setup_cargo.sh
./scripts/setup_cargo.sh --mirror ustc
./scripts/setup_cargo.sh --mirror tuna
```

This configures `~/.cargo/config.toml` with sparse index support (Rust 1.68+).

**Verify:**
```bash
cargo search serde --limit 5
```

---

## Homebrew (macOS)

```bash
./scripts/setup_homebrew.sh
./scripts/setup_homebrew.sh --mirror tuna
./scripts/setup_homebrew.sh --mirror ustc
```

**Verify:**
```bash
brew update
brew install wget
```

---

## Conda / Anaconda

```bash
./scripts/setup_conda.sh
./scripts/setup_conda.sh --mirror tuna
./scripts/setup_conda.sh --mirror ustc
```

**Verify:**
```bash
conda update conda
conda search numpy
```

---

## Go Modules

```bash
./scripts/setup_go.sh
./scripts/setup_go.sh --mirror goproxy-cn
./scripts/setup_go.sh --mirror ustc
```

**Manual:**
```bash
go env -w GOPROXY=https://goproxy.cn,direct
go env -w GONOSUMDB="*"
```

**Verify:**
```bash
go get github.com/gin-gonic/gin
```

---

## Flutter

```bash
./scripts/setup_flutter.sh
./scripts/setup_flutter.sh --mirror tuna
./scripts/setup_flutter.sh --mirror ustc
```

**Verify:**
```bash
flutter pub get
flutter doctor
```

---

## Backup and Restore

### Backup before making changes

```bash
# Backup all supported configs
./scripts/backup_config.sh --all

# Backup specific tool
./scripts/backup_config.sh --tool pip
./scripts/backup_config.sh --tool npm
./scripts/backup_config.sh --tool apt
```

Backups are stored in `~/.china-mirror-skills/backups/`.

### List available backups

```bash
./scripts/restore_config.sh --list
```

### Restore a backup

```bash
# Restore latest backup for a tool
./scripts/restore_config.sh --tool pip --latest

# Restore specific backup by ID
./scripts/restore_config.sh --tool pip --backup-id 20250306_120000
```

---

## Mirror Health Check

```bash
# Check all mirrors and print report
python scripts/check_mirrors.py

# Save report to file
python scripts/check_mirrors.py --output reports/report.json

# Check specific output path
python scripts/check_mirrors.py --output /tmp/mirror-check.json
```

---

## Generate README

After adding new mirrors to `data/mirrors.yml`:

```bash
# Generate README from template
python scripts/render_readme.py

# If reports/report.json exists, it will show live health status
```

---

## Using with Claude Code

### Bootstrap the entire environment

Prompt Claude Code:
```
Setup my development environment for China's network. I need pip, npm, and cargo configured.
```

### Fix a specific tool

```
My npm installs are timing out. Configure npm to use a China mirror.
```

```
Configure pip to use Tsinghua TUNA mirror.
```

```
Set up Go modules proxy for China.
```

### Diagnose network issues

```
Diagnose my network setup for development tools in China.
```
