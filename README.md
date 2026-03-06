# 🇨🇳 China Mirror Skills

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

| 🐍 Python (pip) | pip, uv, poetry | ✅ Active | Package Index |

| 📦 Node.js (npm) | npm, pnpm, yarn | ✅ Active | Package Index |

| 🐧 Ubuntu (apt) | ubuntu | ✅ Active | APT Repository |

| 🐳 Docker CE | Docker CE install | ✅ Active | Install Repo |

| 🐳 Docker Hub | Docker Hub (docs only) | ⚠️ Deprecated | Registry Mirror |

| 🦀 Rust (Cargo) | Cargo | ✅ Active | Package Index |

| 🍺 Homebrew | Homebrew | ✅ Active | Git Repository |

| 🐍 Conda/Anaconda | Conda/Anaconda | ✅ Active | Package Index |

| 🐹 Go | Go modules | ✅ Active | Module Proxy |

| 📱 Flutter | Flutter SDK | ✅ Active | SDK Mirror |

| ☸️ Kubernetes | K8s registry | ✅ Active | Notes |

| 🏔️ Alpine Linux | alpine | ✅ Active | APT Repository |


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

_Mirror data last updated: 2025-03-06_


_Health check data not yet available. See [GitHub Actions](../../actions) for latest results._



#### 🐍 Python (pip)

| Mirror | URL | Status | Priority |
|--------|-----|--------|----------|

| Tsinghua TUNA PyPI Mirror | [https://pypi.tuna.tsinghua.edu.cn/simple](https://pypi.tuna.tsinghua.edu.cn/simple) | ✅ Active | 1 |

| USTC PyPI Mirror | [https://pypi.mirrors.ustc.edu.cn/simple](https://pypi.mirrors.ustc.edu.cn/simple) | ✅ Active | 2 |

| Alibaba Cloud PyPI Mirror | [https://mirrors.aliyun.com/pypi/simple](https://mirrors.aliyun.com/pypi/simple) | ✅ Active | 3 |



#### 📦 Node.js (npm)

| Mirror | URL | Status | Priority |
|--------|-----|--------|----------|

| npmmirror (Taobao) | [https://registry.npmmirror.com](https://registry.npmmirror.com) | ✅ Active | 1 |

| Tencent Cloud NPM Mirror | [https://mirrors.cloud.tencent.com/npm/](https://mirrors.cloud.tencent.com/npm/) | ✅ Active | 2 |



#### 🐧 Ubuntu (apt)

| Mirror | URL | Status | Priority |
|--------|-----|--------|----------|

| Tsinghua TUNA Ubuntu Mirror | [https://mirrors.tuna.tsinghua.edu.cn/ubuntu/](https://mirrors.tuna.tsinghua.edu.cn/ubuntu/) | ✅ Active | 1 |

| USTC Ubuntu Mirror | [https://mirrors.ustc.edu.cn/ubuntu/](https://mirrors.ustc.edu.cn/ubuntu/) | ✅ Active | 2 |



#### 🐳 Docker CE

| Mirror | URL | Status | Priority |
|--------|-----|--------|----------|

| Tsinghua TUNA Docker CE Mirror | [https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/](https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/) | ✅ Active | 1 |

| USTC Docker CE Mirror | [https://mirrors.ustc.edu.cn/docker-ce/linux/](https://mirrors.ustc.edu.cn/docker-ce/linux/) | ✅ Active | 2 |



#### 🐳 Docker Hub

| Mirror | URL | Status | Priority |
|--------|-----|--------|----------|

| Tsinghua TUNA Docker Hub Mirror | [https://docker.mirrors.tuna.tsinghua.edu.cn](https://docker.mirrors.tuna.tsinghua.edu.cn) | ⚠️ Deprecated | 0 |



#### 🦀 Rust (Cargo)

| Mirror | URL | Status | Priority |
|--------|-----|--------|----------|

| USTC Rust Crates Mirror | [https://mirrors.ustc.edu.cn/crates.io-index/](https://mirrors.ustc.edu.cn/crates.io-index/) | ✅ Active | 1 |

| Tsinghua TUNA Rust Crates Mirror | [https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/](https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/) | ✅ Active | 2 |

| Rust China Community Mirror | [https://rsproxy.cn/crates.io-index/](https://rsproxy.cn/crates.io-index/) | 🧪 Testing | 3 |



#### 🍺 Homebrew

| Mirror | URL | Status | Priority |
|--------|-----|--------|----------|

| Tsinghua TUNA Homebrew Mirror | [https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/](https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/) | ✅ Active | 1 |

| USTC Homebrew Mirror | [https://mirrors.ustc.edu.cn/brew.git](https://mirrors.ustc.edu.cn/brew.git) | ✅ Active | 2 |



#### 🐍 Conda/Anaconda

| Mirror | URL | Status | Priority |
|--------|-----|--------|----------|

| Tsinghua TUNA Anaconda Mirror | [https://mirrors.tuna.tsinghua.edu.cn/anaconda/](https://mirrors.tuna.tsinghua.edu.cn/anaconda/) | ✅ Active | 1 |

| USTC Anaconda Mirror | [https://mirrors.ustc.edu.cn/anaconda/](https://mirrors.ustc.edu.cn/anaconda/) | ✅ Active | 2 |



#### 🐹 Go

| Mirror | URL | Status | Priority |
|--------|-----|--------|----------|

| China Go Module Proxy | [https://goproxy.cn](https://goproxy.cn) | ✅ Active | 1 |

| USTC Go Module Proxy | [https://goproxy.ustc.edu.cn](https://goproxy.ustc.edu.cn) | ✅ Active | 2 |

| Alibaba Cloud Go Module Proxy | [https://mirrors.aliyun.com/goproxy/](https://mirrors.aliyun.com/goproxy/) | ✅ Active | 3 |



#### 📱 Flutter

| Mirror | URL | Status | Priority |
|--------|-----|--------|----------|

| Tsinghua TUNA Flutter Mirror | [https://mirrors.tuna.tsinghua.edu.cn/flutter/](https://mirrors.tuna.tsinghua.edu.cn/flutter/) | ✅ Active | 1 |

| USTC Flutter Mirror | [https://mirrors.ustc.edu.cn/flutter/](https://mirrors.ustc.edu.cn/flutter/) | ✅ Active | 2 |



#### ☸️ Kubernetes

| Mirror | URL | Status | Priority |
|--------|-----|--------|----------|

| Official Kubernetes Registry | [https://registry.k8s.io](https://registry.k8s.io) | ✅ Active | 1 |



#### 🏔️ Alpine Linux

| Mirror | URL | Status | Priority |
|--------|-----|--------|----------|

| Tsinghua TUNA Alpine Mirror | [https://mirrors.tuna.tsinghua.edu.cn/alpine/](https://mirrors.tuna.tsinghua.edu.cn/alpine/) | ✅ Active | 1 |

| USTC Alpine Mirror | [https://mirrors.ustc.edu.cn/alpine/](https://mirrors.ustc.edu.cn/alpine/) | ✅ Active | 2 |




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
