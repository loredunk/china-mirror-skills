# fix-node-mirror

## Name

Fix Node.js Package Mirror

## Description

Configures npm, yarn, and pnpm to use China-based npm registry mirrors for faster package installation. Supports npmmirror (formerly Taobao), Tencent Cloud, and university mirrors.

## When to Use

Use this skill when:
- `npm install` is very slow or times out
- `yarn install` hangs or is slow
- `pnpm install` takes a long time
- npm packages fail to download from registry.npmjs.org
- You see ETIMEDOUT or ECONNREFUSED errors

## Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| tool | string | No | Target tool: npm, yarn, pnpm, all (default: all) |
| mirror | string | No | Mirror preference: npmmirror, tencent, tuna, ustc (default: npmmirror) |
| dry_run | boolean | No | Show what would change without applying (default: false) |

## Steps

### Step 1: Detect Node.js Tools

Check which package managers are installed:
- npm (always present with Node.js)
- yarn (`yarn --version`)
- pnpm (`pnpm --version`)

### Step 2: Backup Existing Configuration

Backup existing configuration:
- `~/.npmrc`
- Shell profile (for yarn/pnpm global config)

### Step 3: Configure Mirror

**For npm:**
```ini
registry=https://registry.npmmirror.com
fetch-retries=5
fetch-timeout=120000

# Binary mirrors for native packages
disturl=https://npmmirror.com/mirrors/node
electron_mirror=https://npmmirror.com/mirrors/electron/
```

**For yarn:**
```bash
yarn config set registry https://registry.npmmirror.com
yarn config set network-timeout 120000
```

**For pnpm:**
```bash
pnpm config set registry https://registry.npmmirror.com
```

### Step 4: Verify Configuration

Test the configuration:
- `npm config get registry`
- `npm view npm version` (quick connectivity test)

## Safety Notes

⚠️ **Backup**: Original `.npmrc` is backed up to `.backup/npm/<timestamp>/`

⚠️ **Binary Mirrors**: Also configures mirrors for native package binaries (node-sass, electron, etc.)

⚠️ **Proxy Warning**: Warns if HTTP_PROXY is set (may conflict with mirrors)

## Verification

```bash
# Check current registry
npm config get registry

# Test connectivity
npm view npm version

# Test with actual install
time npm install --no-save lodash
```

## Available Mirrors

| Mirror | URL | Priority |
|--------|-----|----------|
| npmmirror | https://registry.npmmirror.com | 1 (default) |
| Tencent Cloud | https://mirrors.cloud.tencent.com/npm/ | 2 |
| Tsinghua (TUNA) | https://mirrors.tuna.tsinghua.edu.cn/npm/ | 3 |
| USTC | https://mirrors.ustc.edu.cn/npm/ | 4 |

**Recommendation**: Use **npmmirror** - it's the official npm mirror maintained by Taobao and is the most reliable in China.

## Examples

### Example 1: Quick Fix

```
"npm install is taking forever, fix it"
"Make npm faster in China"
```

### Example 2: Specific Tool

```
"Configure yarn to use China mirror"
"Setup pnpm with npmmirror"
```

### Example 3: Specific Mirror

```
"Use Tencent Cloud mirror for npm"
```

## Troubleshooting

### Issue: npm still uses official registry

**Check**: Look for project-level `.npmrc`
```bash
# Check project config
cat .npmrc 2>/dev/null || echo "No project .npmrc"

# Check global config
cat ~/.npmrc
```

### Issue: Native module compilation fails

**Cause**: Binary download might still be from slow source

**Fix**: This skill also configures binary mirrors. Verify:
```bash
npm config get disturl
npm config get electron_mirror
```

### Issue: Scoped packages (@org/package) not found

**Cause**: Some scoped packages might not be synced

**Fix**: Add to `~/.npmrc`:
```ini
@yourorg:registry=https://registry.npmjs.org
```

## Rollback

```bash
# Using the restore script
./scripts/restore_config.sh --tool npm --latest

# Or manually restore .npmrc
cp ~/.backup/npm/<timestamp>/.npmrc ~/
```

## Implementation

```bash
./scripts/setup_npm.sh --tool <tool> --mirror <mirror>
```
