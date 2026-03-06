#!/usr/bin/env python3
"""
README.md generator for china-mirror-skills

Generates a comprehensive README based on mirrors.yml data and templates.
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime

import yaml


# Jinja2-style template for README
README_TEMPLATE = '''# 🇨🇳 China Mirror Skills

<p align="center">
  <strong>Claude Code skills for optimizing development tools in China's network environment</strong>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#supported-tools">Supported Tools</a> •
  <a href="#how-to-use">How to Use</a> •
  <a href="#mirror-sources">Mirror Sources</a> •
  <a href="#contributing">Contributing</a>
</p>

---

## 📋 Table of Contents

- [Why This Project?](#why-this-project)
- [Supported Tools & Scenarios](#supported-tools--scenarios)
- [Repository Structure](#repository-structure)
- [Quick Start](#quick-start)
- [Using with Claude Code](#using-with-claude-code)
- [Standalone Scripts](#standalone-scripts)
- [GitHub Actions](#github-actions)
- [Mirror Sources Policy](#mirror-sources-policy)
- [Security & Risks](#security--risks)
- [Roadmap](#roadmap)
- [Contributing](#contributing)

---

## 🤔 Why This Project?

Developers in China often face slow or unreliable access to official package registries and development tools:

- **PyPI** downloads timeout or crawl at 10KB/s
- **npm** packages take forever to install
- **Docker Hub** pulls fail or are extremely slow
- **Rust crates** download at snail's pace
- **GitHub Releases** downloads frequently stall

This repository provides:

1. **Verified mirror configurations** from official university mirrors (TUNA, USTC)
2. **Automated setup scripts** with backup and rollback support
3. **Claude Code skills** for AI-assisted configuration
4. **Daily health checks** to ensure mirror availability
5. **Idempotent operations** - safe to run multiple times

> ⚠️ **Important Distinctions**
> - Docker **CE installation** repo ≠ Docker **Hub** image mirror
> - Kubernetes **k8s.gcr.io** has been **deprecated** (migrated to registry.k8s.io)
> - We prioritize **official help pages** over third-party blog posts

---

## 🛠️ Supported Tools & Scenarios

| Category | Tool | Status | Mirror Type |
|----------|------|--------|-------------|
{% for cat_id, cat_info in categories.items() %}
| {{ cat_info.icon }} {{ cat_info.name }} | {% if cat_id == 'pip' %}pip, uv, poetry{% elif cat_id == 'npm' %}npm, pnpm, yarn{% elif cat_id == 'docker-ce' %}Docker CE install{% elif cat_id == 'docker-hub' %}Docker Hub (docs only){% elif cat_id == 'cargo' %}Cargo{% elif cat_id == 'homebrew' %}Homebrew{% elif cat_id == 'conda' %}Conda/Anaconda{% elif cat_id == 'go' %}Go modules{% elif cat_id == 'flutter' %}Flutter SDK{% elif cat_id == 'kubernetes-notes' %}K8s registry{% else %}{{ cat_id }}{% endif %} | {% if cat_id == 'docker-hub' %}⚠️ Deprecated{% else %}✅ Active{% endif %} | {% if cat_id == 'docker-hub' %}Registry Mirror{% elif cat_id in ['pip', 'npm', 'cargo', 'conda'] %}Package Index{% elif cat_id in ['ubuntu', 'alpine'] %}APT Repository{% elif cat_id == 'docker-ce' %}Install Repo{% elif cat_id == 'homebrew' %}Git Repository{% elif cat_id == 'go' %}Module Proxy{% elif cat_id == 'flutter' %}SDK Mirror{% else %}Notes{% endif %} |
{% endfor %}

### Key Features

- ✅ **Backup & Rollback** - Always backup before modification
- ✅ **Proxy Conflict Detection** - Warns if proxy env vars are set
- ✅ **Idempotent** - Safe to run multiple times
- ✅ **Multi-platform** - Linux primary, macOS compatible where applicable
- ✅ **Official Sources** - Prioritizes TUNA, USTC, and vendor mirrors

---

## 📁 Repository Structure

```
china-mirror-skills/
├── README.md              # This file (auto-generated)
├── LICENSE                # MIT License
├── data/
│   └── mirrors.yml        # Mirror source definitions
├── scripts/               # Setup and utility scripts
│   ├── common.sh          # Shared functions
│   ├── check_mirrors.py   # Mirror health checker
│   ├── render_readme.py   # README generator
│   ├── backup_config.sh   # Backup utility
│   ├── restore_config.sh  # Restore utility
│   └── setup_*.sh         # Tool-specific setup scripts
├── skills/                # Claude Code skills
│   ├── bootstrap-china-network/   # Main entry point
│   ├── fix-python-mirror/         # Python tools
│   ├── fix-node-mirror/           # Node.js tools
│   ├── fix-docker-mirror/         # Docker
│   ├── fix-apt-mirror/            # Ubuntu/Debian
│   ├── fix-homebrew-mirror/       # Homebrew
│   ├── fix-conda-mirror/          # Conda
│   ├── fix-rust-mirror/           # Rust/Cargo
│   ├── fix-go-proxy/              # Go
│   ├── fix-flutter-mirror/        # Flutter
│   └── diagnose-network-environment/  # Network diagnostics
├── docs/                  # Documentation
│   ├── architecture.md    # Technical architecture
│   ├── mirrors-policy.md  # Mirror selection criteria
│   ├── troubleshooting.md # Common issues & fixes
│   └── examples.md        # Usage examples
└── .github/workflows/     # CI/CD automation
    ├── mirror-health.yml  # Daily health checks
    └── readme-refresh.yml # Auto-update README
```

---

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- Bash 4.0+
- Linux (primary) or macOS (limited support)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/china-mirror-skills.git
cd china-mirror-skills

# Install Python dependencies
pip install -r requirements.txt

# Or use uv
uv pip install -r requirements.txt
```

### Quick Health Check

```bash
# Check all mirror sources
python scripts/check_mirrors.py
```

### Quick Setup (Individual Tools)

```bash
# Setup Python pip mirror
./scripts/setup_pip.sh

# Setup npm mirror
./scripts/setup_npm.sh

# Setup Ubuntu APT mirror
./scripts/setup_apt.sh --mirror tuna

# Setup Docker CE (NOT Docker Hub)
./scripts/setup_docker.sh
```

---

## 🤖 Using with Claude Code

### Loading Skills

Add this repository to your Claude Code skills:

```bash
# In Claude Code settings or CLAUDE.md
# Add the skills directory to your skills path
```

### Available Skills

#### 1. bootstrap-china-network

Main entry point - diagnoses environment and applies appropriate fixes.

```
"Setup my development environment for China's network"
"Configure pip, npm, and Docker to use China mirrors"
```

#### 2. fix-python-mirror

Configures pip, uv, poetry to use China mirrors.

```
"Fix my Python package downloads - they're too slow"
"Configure pip to use Tsinghua mirror"
```

#### 3. fix-node-mirror

Configures npm, pnpm, yarn to use China mirrors.

```
"npm install is taking forever, help"
"Setup npm to use npmmirror"
```

#### 4. fix-docker-mirror

Configures Docker CE installation source.

```
"Install Docker CE from China mirror"
```

> ⚠️ **Note**: This configures Docker CE **installation packages**, NOT Docker Hub image pulls.

#### 5. fix-apt-mirror

Configures Ubuntu/Debian APT sources.

```
"Make apt update faster"
"Switch to TUNA Ubuntu mirror"
```

#### 6. fix-homebrew-mirror

Configures Homebrew taps and bottles.

```
"Homebrew is so slow, fix it"
```

#### 7. fix-conda-mirror

Configures Conda/Anaconda channels.

```
"Configure conda to use China mirror"
```

#### 8. fix-rust-mirror

Configures Cargo to use China crates mirrors.

```
"Cargo build is downloading too slowly"
```

#### 9. fix-go-proxy

Configures Go module proxy.

```
"Go mod download is slow from China"
```

#### 10. fix-flutter-mirror

Configures Flutter SDK and dependency mirrors.

```
"Setup Flutter in China"
```

#### 11. diagnose-network-environment

Analyzes network environment and detects issues.

```
"Diagnose my network setup for development"
"Why are my downloads so slow?"
```

---

## 🔧 Standalone Scripts

### Backup Your Configuration

```bash
# Backup all supported configurations
./scripts/backup_config.sh --all

# Backup specific tool
./scripts/backup_config.sh --tool pip
```

### Restore Configuration

```bash
# List available backups
./scripts/restore_config.sh --list

# Restore from specific backup
./scripts/restore_config.sh --tool pip --backup-id 20250306_120000

# Restore latest backup for a tool
./scripts/restore_config.sh --tool pip --latest
```

### Setup Scripts

All setup scripts support these options:

```bash
./scripts/setup_<tool>.sh [OPTIONS]

Options:
  -m, --mirror MIRROR    Choose specific mirror (tuna|ustc|aliyun|...)
  -f, --force            Force overwrite existing config
  -d, --dry-run          Show what would be changed without applying
  -y, --yes              Skip confirmation prompts
  -h, --help             Show help
```

---

## ⚙️ GitHub Actions

### Mirror Health Check

**Workflow**: `.github/workflows/mirror-health.yml`

- **Schedule**: Daily at 08:00 UTC
- **Manual trigger**: `workflow_dispatch`
- **Function**: Tests HTTP connectivity to all mirrors in `data/mirrors.yml`
- **Output**: `reports/report.json`

To view latest results:

```bash
# Check the Actions tab in GitHub
# Or download the latest artifact
```

### README Auto-Refresh

**Workflow**: `.github/workflows/readme-refresh.yml`

- **Trigger**: Push to main affecting `data/mirrors.yml` or `scripts/`
- **Function**: Regenerates README.md from template
- **Commit**: Automatically commits changes if README differs

---

## 🪞 Mirror Sources

### Current Mirror Status

_Mirror data last updated: {{ updated_at }}_
{% if has_report %}
_Health check run: {{ health_checked_at }}_

**Summary**: {{ report_summary.healthy }}/{{ report_summary.total_mirrors }} mirrors healthy ({{ report_summary.health_rate }}%)
{% else %}

_Health check data not yet available. See [GitHub Actions](../../actions) for latest results._
{% endif %}

{% for cat_id, cat_info in categories.items() %}
#### {{ cat_info.icon }} {{ cat_info.name }}

| Mirror | URL | Status | Priority |
|--------|-----|--------|----------|
{% for mirror in mirrors_by_category[cat_id] %}
| {{ mirror.name }} | [{{ mirror.url }}]({{ mirror.url }}) | {% if mirror.live_status == 'ok' %}✅ OK{% elif mirror.live_status == 'timeout' %}⏱️ Timeout{% elif mirror.live_status is not none %}❌ {{ mirror.live_status }}{% elif mirror.status == 'active' %}✅ Active{% elif mirror.status == 'deprecated' %}⚠️ Deprecated{% else %}🧪 Testing{% endif %}{% if mirror.response_time_ms is not none %} ({{ mirror.response_time_ms }}ms){% endif %} | {{ mirror.priority }} |
{% endfor %}

{% endfor %}

### Mirror Selection Criteria

We prioritize mirrors based on:

1. **Official Status** - University mirrors (TUNA, USTC) with official documentation
2. **Reliability** - Uptime history and maintenance commitment
3. **Sync Frequency** - How often they sync with upstream
4. **Help Documentation** - Quality of official help pages

See [docs/mirrors-policy.md](docs/mirrors-policy.md) for detailed policy.

---

## ⚠️ Security & Risks

### Understanding the Risks

Using third-party mirrors involves trust:

1. **Package Integrity** - Mirrors should not modify packages
2. **TLS Interception** - Some networks may intercept HTTPS
3. **Outdated Packages** - Mirrors may lag behind upstream

### Mitigations in This Project

- ✅ **HTTPS Only** - All mirrors use TLS encryption
- ✅ **Checksum Verification** - Scripts preserve original package signatures
- ✅ **Official Sources** - Prioritize mirrors with official backing
- ✅ **Health Monitoring** - Daily automated checks
- ✅ **Backup & Rollback** - Always can revert to original

### What We Don't Do

- ❌ Bypass security certificates
- ❌ Use unverified third-party binaries
- ❌ Recommend deprecated or known-bad mirrors
- ❌ Modify package contents

---

## 🗺️ Roadmap

### v0.1.0 (Current)
- ✅ Basic mirror configurations for 10+ tools
- ✅ Health checking infrastructure
- ✅ Claude Code skills framework
- ✅ Backup and rollback system

### v0.2.0 (Planned)
- Maven/Gradle support
- Ruby Gems support
- Alpine Linux APK support
- Windows WSL support improvements

### v0.3.0 (Planned)
- TUI/GUI configuration wizard
- Mirror speed testing and auto-selection
- Per-project configuration profiles

### v0.4.0 (Planned)
- Codex skill format support
- Cursor editor integration
- OpenCode compatibility

### v0.5.0 (Planned)
- Community mirror submission workflow
- Mirror quality scoring
- Regional mirror recommendations

### v1.0.0 (Planned)
- Stable API
- Comprehensive test coverage
- Multi-language documentation

---

## 🤝 Contributing

We welcome contributions! Please see our [contributing guidelines](CONTRIBUTING.md).

### Quick Contribution Guide

1. **Report Issues** - Mirror failures, documentation errors
2. **Suggest Mirrors** - Must meet our [mirror policy](docs/mirrors-policy.md)
3. **Improve Scripts** - Bug fixes, new platform support
4. **Add Skills** - New tool support

### Development Setup

```bash
# Fork and clone
git clone https://github.com/yourusername/china-mirror-skills.git
cd china-mirror-skills

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dev dependencies
pip install -r requirements.txt

# Run health check locally
python scripts/check_mirrors.py

# Generate README
python scripts/render_readme.py
```

### Adding a New Mirror

1. Add entry to `data/mirrors.yml`
2. Include `official_help` URL
3. Add `verify` configuration
4. Run health check to verify
5. Submit PR with rationale

---

## 📚 Documentation

- [Architecture](docs/architecture.md) - Technical design
- [Mirror Policy](docs/mirrors-policy.md) - Selection criteria
- [Troubleshooting](docs/troubleshooting.md) - Common issues
- [Examples](docs/examples.md) - Usage examples

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

---

## 🙏 Acknowledgments

- [Tsinghua TUNA](https://mirrors.tuna.tsinghua.edu.cn/) - Primary mirror source
- [USTC LUG](https://mirrors.ustc.edu.cn/) - Secondary mirror source
- [npmmirror](https://npmmirror.com/) - Official npm mirror
- All contributors and maintainers of open-source mirrors

---

<p align="center">
  <sub>Built with ❤️ for developers in China</sub>
</p>
'''


def load_mirrors(yaml_path: Path) -> dict:
    """Load mirror configuration from YAML file"""
    with open(yaml_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def group_mirrors_by_category(mirrors: list) -> dict:
    """Group mirrors by category"""
    groups = {}
    for mirror in mirrors:
        cat = mirror['category']
        if cat not in groups:
            groups[cat] = []
        groups[cat].append(mirror)

    # Sort by priority within each group
    for cat in groups:
        groups[cat].sort(key=lambda x: x.get('priority', 99))

    return groups


def load_report(report_path: Path) -> dict:
    """Load optional mirror health report"""
    if report_path.exists():
        with open(report_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}


def generate_readme(mirrors_data: dict, report: dict = None) -> str:
    """Generate README content using Jinja2 template"""
    from jinja2 import Environment

    mirrors = mirrors_data.get('mirrors', [])
    categories = mirrors_data.get('categories', {})
    mirrors_by_category = group_mirrors_by_category(mirrors)

    # Build per-mirror health status from report
    mirror_health = {}
    if report:
        for result in report.get('results', []):
            mirror_health[result['id']] = result

    # Enrich mirrors_by_category with live health data
    for cat_id, cat_mirrors in mirrors_by_category.items():
        for mirror in cat_mirrors:
            health = mirror_health.get(mirror['id'])
            if health:
                mirror['live_status'] = health['status']
                mirror['response_time_ms'] = health.get('response_time_ms')
            else:
                mirror['live_status'] = None
                mirror['response_time_ms'] = None

    report_meta = report.get('metadata', {}) if report else {}
    report_summary = report.get('summary', {}) if report else {}

    updated_at = mirrors_data.get('updated_at', 'unknown')
    health_checked_at = report_meta.get('generated_at', None)

    env = Environment(keep_trailing_newline=True)
    template = env.from_string(README_TEMPLATE)

    return template.render(
        categories=categories,
        mirrors_by_category=mirrors_by_category,
        updated_at=updated_at,
        health_checked_at=health_checked_at,
        report_summary=report_summary,
        has_report=bool(report),
    )


def main():
    """Main entry point"""
    # Determine paths
    script_dir = Path(__file__).parent.absolute()
    project_root = script_dir.parent
    mirrors_path = project_root / 'data' / 'mirrors.yml'
    report_path = project_root / 'reports' / 'report.json'
    readme_path = project_root / 'README.md'

    print("China Mirror Skills - README Generator")
    print("=" * 40)
    print(f"Mirrors file: {mirrors_path}")
    print(f"Output: {readme_path}")

    if not mirrors_path.exists():
        print(f"Error: Mirrors file not found: {mirrors_path}", file=sys.stderr)
        sys.exit(1)

    # Load mirrors configuration
    print("Loading mirrors configuration...")
    mirrors_data = load_mirrors(mirrors_path)

    # Load optional health report
    report = load_report(report_path)
    if report:
        print(f"Loaded health report from: {report_path}")
    else:
        print("No health report found, skipping live status")

    # Generate README
    print("Generating README...")
    readme_content = generate_readme(mirrors_data, report)

    # Write README
    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write(readme_content)

    print(f"✅ README generated: {readme_path}")


if __name__ == '__main__':
    main()
