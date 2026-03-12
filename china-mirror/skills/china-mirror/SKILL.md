---
name: china-mirror
description: |
  One-stop skill for setting up China-friendly development tools:
  configuring package manager mirrors AND installing tools themselves via Chinese sources.

  TWO DISTINCT OPERATIONS — always identify which one the user needs:

  1. INSTALL TOOL（安装工具本体）
     User intent: "我没有 Python / 我要安装 Rust / 帮我装 Go / install Node.js"
     → Downloads and installs the tool itself using Chinese mirrors
     → Scripts: scripts/<tool>/install.sh

  2. CONFIGURE MIRROR（配置包管理器镜像源）
     User intent: "pip 下载太慢 / 配置 npm 镜像 / 加速 cargo / 换 conda 源"
     → Configures the already-installed tool to use a Chinese package registry
     → Scripts: scripts/<tool>/setup.sh

  Supported tools:
    Install: Python (pyenv), Node.js (nvm), Conda/Miniconda, Rust (rustup), Go
    Configure mirrors: pip/uv/poetry, npm/yarn/pnpm, Docker CE+Hub, APT, Homebrew,
                       Conda channels, Cargo, GOPROXY, Flutter, GitHub, Hugging Face

  Trigger phrases for INSTALL:
    "安装 Python/Node/Go/Rust/Conda", "下载安装 X", "install X", "没有 X 怎么装"
    "setup new machine", "初始化开发环境", "从零搭建"

  Trigger phrases for CONFIGURE:
    "X 太慢", "配置 X 镜像", "X 换源", "pip install 超时", "npm 下载慢",
    "cargo build 失败", "go mod 慢", "china mirror", "国内源"
---

# China Mirror

One-stop configuration and installation for all development tools in China.

All scripts are bundled under this skill's `scripts/` directory — invoked via bash, not loaded into context.

## Steps

**1. Determine SKILL_DIR**

```bash
SKILL_DIR="<absolute path to china-mirror skill directory>"
```
Use the directory where this SKILL.md resides.

---

**2. Identify intent: INSTALL vs CONFIGURE**

Ask the user (or infer from context) which operation they need:

| Intent | Signal | Action |
|--------|--------|--------|
| Install tool | "安装", "没有", "install", "从零" | Run `install.sh` |
| Configure mirror | "太慢", "换源", "配置镜像", "timeout" | Run `setup.sh` |
| Both | New machine setup | Run `install.sh` then `setup.sh` |

---

**3a. INSTALL TOOL — download and install via Chinese mirrors**

For users who don't have the tool yet or want to install a specific version:

| Tool | Script | Default Mirror | Notes |
|------|--------|----------------|-------|
| Python | `scripts/python/install.sh` | huawei (pyenv) | Installs pyenv + Python version |
| Node.js | `scripts/node/install.sh` | npmmirror (nvm) | Installs nvm + Node.js version |
| Conda/Miniconda | `scripts/conda/install.sh` | tuna | Downloads Miniconda installer |
| Rust | `scripts/rust/install.sh` | tuna (rustup) | Sets RUSTUP_DIST_SERVER |
| Go | `scripts/go/install.sh` | tuna | Downloads Go tarball |
| Docker CE | `sudo scripts/docker/setup.sh` | tuna | Uses docker-ce apt repo mirror |

Examples:
```bash
# Install Python 3.12 via Huawei Cloud pyenv mirror
bash "$SKILL_DIR/scripts/python/install.sh" -v 3.12.0

# Install Node.js LTS via npmmirror
bash "$SKILL_DIR/scripts/node/install.sh" -v lts

# Install Miniconda from TUNA
bash "$SKILL_DIR/scripts/conda/install.sh" -y

# Install Rust (stable) via TUNA rustup mirror
bash "$SKILL_DIR/scripts/rust/install.sh" -y

# Install Go 1.22.4 from TUNA
bash "$SKILL_DIR/scripts/go/install.sh" -v 1.22.4

# List available Python versions
bash "$SKILL_DIR/scripts/python/install.sh" -v list

# Dry run
bash "$SKILL_DIR/scripts/go/install.sh" -d
```

All install scripts support: `-v/--version`, `-m/--mirror`, `-d/--dry-run`, `-y/--yes`

---

**3b. CONFIGURE MIRROR — point package managers to Chinese sources**

For users who have tools but want to speed up package downloads:

| Tool | Script | Default Mirror |
|------|--------|----------------|
| pip/uv/poetry | `scripts/python/setup.sh` | tuna |
| npm/yarn/pnpm | `scripts/node/setup.sh` | npmmirror |
| APT (Ubuntu/Debian) | `sudo scripts/apt/setup.sh` | tuna |
| Docker CE (install repo) | `sudo scripts/docker/setup.sh` | tuna |
| Docker Hub (image pull) | `sudo scripts/docker/setup.sh` | tuna |
| Homebrew | `scripts/homebrew/setup.sh` | tuna |
| Conda channels (.condarc) | `scripts/conda/setup.sh` | tuna |
| Cargo (crates.io) | `scripts/rust/setup.sh` | ustc |
| Go modules (GOPROXY) | `scripts/go/setup.sh` | goproxy |
| Flutter/Dart | `scripts/flutter/setup.sh` | cfug |
| GitHub Releases/Clone | `scripts/github/setup.sh` | tuna |
| Hugging Face downloads | `scripts/huggingface/download.sh` | hf-mirror |

Examples:
```bash
bash "$SKILL_DIR/scripts/python/setup.sh" --mirror tuna
bash "$SKILL_DIR/scripts/node/setup.sh" --mirror npmmirror
sudo bash "$SKILL_DIR/scripts/apt/setup.sh" --mirror tuna
bash "$SKILL_DIR/scripts/rust/setup.sh" --mirror ustc
bash "$SKILL_DIR/scripts/go/setup.sh"
```

All setup scripts support: `-m/--mirror`, `-f/--force`, `-d/--dry-run`, `-y/--yes`

---

**4. Diagnose (when user wants to troubleshoot or audit)**

```bash
bash "$SKILL_DIR/scripts/diagnose.sh"
```
Tests connectivity, shows current mirror status, and generates prioritized recommendations.

---

**5. Quick environment scan (before configuring)**

```bash
# Detect installed tools
for tool in pip uv npm yarn pnpm docker cargo go conda flutter brew; do
  which $tool 2>/dev/null && echo "✓ $tool found" || echo "✗ $tool not found"
done

# Check proxy conflicts
[[ -n "$HTTP_PROXY$HTTPS_PROXY$http_proxy$https_proxy" ]] && echo "⚠️ Proxy detected"
```

If a tool is not found and the user wants to use it → suggest running the appropriate `install.sh` first, then `setup.sh`.

---

**6. Proxy conflict warning**

If `HTTP_PROXY` or `HTTPS_PROXY` is set:
> Proxy environment variables are set. In China, using a VPN/proxy alongside mirrors can cause conflicts. Consider: `unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY`

---

**7. Hugging Face downloads**

```bash
bash "$SKILL_DIR/scripts/huggingface/download.sh" gpt2 --tool hfd
bash "$SKILL_DIR/scripts/huggingface/download.sh" wget2 --dataset --tool cli --local-dir ./wget2
```
Injects `HF_ENDPOINT=https://hf-mirror.com` only for that command.

---

**8. Verify configurations**

```bash
pip config get global.index-url 2>/dev/null
npm config get registry 2>/dev/null
go env GOPROXY 2>/dev/null
cat ~/.cargo/config.toml 2>/dev/null | grep index
cat ~/.condarc 2>/dev/null | head -5
rustup show active-toolchain 2>/dev/null
go version 2>/dev/null
```

---

**9. Summary to user**

Report:
- **Tool installs**: which tools were installed, their version, install path
- **Mirror configs**: tool → mirror URL mapping
- **Warnings**: proxy conflicts, permission issues, tool not found
- **Restore**: `bash "$SKILL_DIR/scripts/restore_config.sh" --tool <name> --latest`

---

## Backup & Restore

```bash
bash "$SKILL_DIR/scripts/backup_config.sh" --all
bash "$SKILL_DIR/scripts/backup_config.sh" --tool pip
bash "$SKILL_DIR/scripts/restore_config.sh" --tool pip --latest
bash "$SKILL_DIR/scripts/restore_config.sh" --list
```

## Dry Run

Add `--dry-run` to any script to preview changes:
```bash
bash "$SKILL_DIR/scripts/python/install.sh" --dry-run
bash "$SKILL_DIR/scripts/python/setup.sh" --dry-run
```
