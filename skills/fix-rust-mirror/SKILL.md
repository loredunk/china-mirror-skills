# fix-rust-mirror

## Name

Fix Rust/Cargo Mirror

## Description

Configures Cargo (Rust's package manager) to use China-based crates.io mirrors with sparse index support for faster dependency resolution and downloads. Also configures rustup mirror for Rust toolchain installation.

## When to Use

Use this skill when:
- `cargo build` is very slow to download dependencies
- `cargo update` takes a long time
- `rustup install` or `rustup update` is slow
- Crates.io index cloning is slow
- You're setting up Rust in China

## Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| mirror | string | No | Mirror preference: ustc, tuna, rsproxy (default: ustc) |
| use_sparse | boolean | No | Use sparse index (requires Cargo 1.68+) (default: true) |
| dry_run | boolean | No | Show what would change without applying (default: false) |

## Steps

### Step 1: Detect Cargo Installation

Check for Cargo:
```bash
which cargo
cargo --version
```

Check version for sparse index support:
- Cargo 1.68+ supports sparse index (much faster)
- Older versions use git-based index

### Step 2: Backup Existing Configuration

Backup existing Cargo config:
```bash
# Check for existing config
ls -la ~/.cargo/config.toml ~/.cargo/config 2>/dev/null

# Backup if exists
cp ~/.cargo/config.toml ~/.cargo/config.toml.backup.<date>
```

### Step 3: Generate Cargo Config

**For Cargo 1.68+ (sparse index):**

```toml
[registries.crates-io]
index = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"

[net]
git-fetch-with-cli = true
```

**For older Cargo (git-based index):**

```toml
[source.crates-io]
replace-with = 'ustc'

[source.ustc]
registry = "https://mirrors.ustc.edu.cn/crates.io-index"

[net]
git-fetch-with-cli = true
```

### Step 4: Configure Rustup Mirror (Optional)

For rustup (Rust toolchain installer), add to shell profile:

```bash
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
```

Or for rsproxy:
```bash
export RUSTUP_DIST_SERVER=https://rsproxy.cn
export RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup
```

### Step 5: Verify Configuration

Test the configuration:
```bash
cargo search anyhow  # Quick test
```

## Safety Notes

⚠️ **Sparse Index**: Requires Cargo 1.68+. Automatically detected and used when available.

⚠️ **Rustup**: Toolchain installation mirror requires environment variables.

⚠️ **Git CLI**: `git-fetch-with-cli = true` helps with authentication and proxy handling.

## Verification

```bash
# Check Cargo version
cargo --version

# Check current config
cat ~/.cargo/config.toml

# Test with a search (quick, no download)
cargo search tokio --limit 5

# Test with actual build
cargo new test_mirror --bin
cd test_mirror
time cargo build  # Should be much faster
```

## Available Mirrors

| Mirror | Crates URL | Rustup URL | Priority |
|--------|------------|------------|----------|
| USTC | https://mirrors.ustc.edu.cn/crates.io-index | https://mirrors.ustc.edu.cn/rust-static | 1 (default) |
| Tsinghua (TUNA) | https://mirrors.tuna.tsinghua.edu.cn/crates.io-index | N/A | 2 |
| rsproxy | https://rsproxy.cn/crates.io-index | https://rsproxy.cn | 3 |

## Sparse Index vs Git Index

**Sparse Index (Cargo 1.68+):**
- ✅ Much faster initial setup
- ✅ Incremental updates
- ✅ Lower bandwidth usage
- ❌ Requires newer Cargo

**Git Index (older Cargo):**
- ✅ Works with any Cargo version
- ❌ Slow initial clone (hundreds of MB)
- ❌ Slower updates

## Examples

### Example 1: Quick Fix

```
"Cargo build is too slow"
"Make Rust package downloads faster"
```

### Example 2: Specific Mirror

```
"Use rsproxy for Rust"
"Configure Cargo with TUNA mirror"
```

### Example 3: New Rust Installation

```
"Install Rust with China mirror"
"Setup Rust development environment in China"
```

## Installation with Mirror

If Rust is not yet installed:

```bash
# Set rustup mirror
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup

# Run official installer
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# After installation, configure Cargo mirror
# (run this skill or setup_cargo.sh)
```

## Troubleshooting

### Issue: Sparse index not working

**Check**: Cargo version
```bash
cargo --version  # Need 1.68+
```

**Fix**: Update Rust or use git-based config
```bash
rustup update
```

### Issue: Index sync still slow

**Check**: Git configuration
```bash
git config --global http.postBuffer 524288000
```

### Issue: Authentication errors with private crates

**Cause**: Mirror doesn't have your private registry credentials

**Fix**: Configure private registry separately:
```toml
[registries.my-private]
index = "https://github.com/myorg/crate-index"
```

### Issue: Some crates not found

**Cause**: Mirror sync delay

**Fix**: Mirror syncs every few minutes. Wait or use:
```bash
CARGO_NET_OFFLINE=false cargo build
```

## Rollback

```bash
# Using restore script
./scripts/restore_config.sh --tool cargo --latest

# Or manually
rm ~/.cargo/config.toml
# Restore from backup if needed
cp ~/.cargo/config.toml.backup.* ~/.cargo/config.toml
```

## Implementation

```bash
./scripts/setup_cargo.sh --mirror <mirror>
```
