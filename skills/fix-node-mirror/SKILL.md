---
name: fix-node-mirror
description: |
  Configure npm, yarn, and pnpm to use China-based registry mirrors (npmmirror/Taobao, Tencent Cloud,
  TUNA, USTC) for faster package installation. Use this skill whenever npm install, yarn install, or
  pnpm install is slow or timing out in China, when ETIMEDOUT or ECONNREFUSED errors appear from
  registry.npmjs.org, or when setting up a Node.js development environment in China. If the user says
  "npm 太慢", "yarn 超时", or similar, always use this skill.
---

# Configure Node.js Package Registry Mirror

Configure npm, yarn, and/or pnpm to use a China mirror for faster package installs.

## Steps

**1. Detect installed Node.js package managers**
```bash
which npm yarn pnpm 2>/dev/null
npm --version 2>/dev/null; yarn --version 2>/dev/null; pnpm --version 2>/dev/null
```

**2. Check for proxy conflicts**
```bash
echo "HTTP_PROXY=$HTTP_PROXY HTTPS_PROXY=$HTTPS_PROXY"
npm config get proxy; npm config get https-proxy
```
Warn if proxy is set — mirrors and proxies often conflict.

**3. Run the setup script**

Default mirror: **npmmirror** (official Taobao mirror, most reliable in China).

```bash
./scripts/setup_npm.sh --mirror <npmmirror|tencent|tuna|ustc>
```

The script configures the registry for all detected tools and also sets binary mirrors for native packages (electron, node-sass, etc.).

**4. Verify**
```bash
npm config get registry        # Should show mirror URL
npm view npm version           # Quick connectivity test
```

## Available Mirrors

| Mirror | URL | Priority |
|--------|-----|----------|
| npmmirror (Taobao) | https://registry.npmmirror.com | 1 (default) |
| Tencent Cloud | https://mirrors.cloud.tencent.com/npm/ | 2 |
| Tsinghua TUNA | https://mirrors.tuna.tsinghua.edu.cn/npm/ | 3 |
| USTC | https://mirrors.ustc.edu.cn/npm/ | 4 |

## Config Reference

**npm** (`~/.npmrc`):
```ini
registry=https://registry.npmmirror.com
fetch-retries=5
fetch-timeout=120000
disturl=https://npmmirror.com/mirrors/node
electron_mirror=https://npmmirror.com/mirrors/electron/
```

**yarn:**
```bash
yarn config set registry https://registry.npmmirror.com
yarn config set network-timeout 120000
```

**pnpm:**
```bash
pnpm config set registry https://registry.npmmirror.com
```

## Note on Scoped Packages

If a scoped package (`@org/package`) is not found on the mirror, configure it separately:
```ini
# Add to ~/.npmrc
@yourorg:registry=https://registry.npmjs.org
```

## Rollback

```bash
./scripts/restore_config.sh --tool npm --latest
```
