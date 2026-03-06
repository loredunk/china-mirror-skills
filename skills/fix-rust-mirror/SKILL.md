---
name: fix-rust-mirror
description: |
  Configure Cargo and rustup to use China-based crates.io mirrors (USTC, TUNA, rsproxy) with
  sparse index support for dramatically faster Rust dependency downloads. Use this skill whenever
  cargo build is slow downloading crates, cargo update hangs, rustup install or update is slow,
  or crates.io index cloning is slow in China. Also use when setting up a Rust development
  environment from scratch in China. If the user says "cargo 太慢", "rust 下载好慢", or similar,
  always use this skill.
---

# Configure Rust/Cargo Mirror

Configure Cargo mirrors and optionally rustup mirrors for China.

## Steps

**1. Check Cargo version** (determines which config format to use)
```bash
cargo --version   # Need 1.68+ for sparse index (much faster)
```

**2. Run the setup script**

Default mirror: **ustc** (also provides rustup mirror).

```bash
./scripts/setup_cargo.sh --mirror <ustc|tuna|rsproxy>
```

The script detects Cargo version, uses sparse index when available, and backs up existing `~/.cargo/config.toml`.

**3. Verify**
```bash
cat ~/.cargo/config.toml
cargo search tokio --limit 3   # Quick test (no download)
```

## Available Mirrors

| Mirror | Crates URL | Rustup URL | Priority |
|--------|-----------|-----------|----------|
| USTC | https://mirrors.ustc.edu.cn/crates.io-index/ | https://mirrors.ustc.edu.cn/rust-static | 1 (default) |
| Tsinghua TUNA | https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/ | N/A | 2 |
| rsproxy | https://rsproxy.cn/crates.io-index/ | https://rsproxy.cn | 3 |

## Config Reference (`~/.cargo/config.toml`)

**Cargo 1.68+ (sparse index — recommended):**
```toml
[registries.crates-io]
index = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"

[net]
git-fetch-with-cli = true
```

**Cargo < 1.68 (git-based index):**
```toml
[source.crates-io]
replace-with = 'ustc'

[source.ustc]
registry = "https://mirrors.ustc.edu.cn/crates.io-index"

[net]
git-fetch-with-cli = true
```

## Rustup Mirror (for toolchain downloads)

Add to shell profile:
```bash
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
```

## Installing Rust via Mirror (if not yet installed)

```bash
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Rollback

```bash
./scripts/restore_config.sh --tool cargo --latest
# Or: rm ~/.cargo/config.toml
```
