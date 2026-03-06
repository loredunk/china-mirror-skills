# fix-go-proxy

## Name

Fix Go Module Proxy

## Description

Configures Go to use China-based module proxies for faster dependency downloads. Supports goproxy.cn (official China proxy), USTC, and Alibaba Cloud proxies.

## When to Use

Use this skill when:
- `go mod download` is very slow
- `go get` times out
- `go build` takes forever downloading modules
- Module downloads from proxy.golang.org fail

## Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| mirror | string | No | Proxy preference: goproxy, ustc, aliyun (default: goproxy) |
| dry_run | boolean | No | Show what would change without applying (default: false) |

## Steps

### Step 1: Detect Go Installation

Check for Go:
```bash
which go
go version
```

### Step 2: Check Current GOPROXY

Check if GOPROXY is already set:
```bash
go env GOPROXY
echo $GOPROXY
```

### Step 3: Backup Shell Profile

Backup shell profile before modification:
- `~/.zshrc` (zsh)
- `~/.bashrc` or `~/.bash_profile` (bash)

### Step 4: Configure GOPROXY

Add to shell profile:

```bash
# Go module proxy configuration
export GOPROXY="https://goproxy.cn,direct"
export GO111MODULE=on
export GOPRIVATE=""
```

The `,direct` fallback means if the proxy doesn't have a module, Go will try the original source.

### Step 5: Apply Configuration

Source the profile or set for current session:
```bash
export GOPROXY="https://goproxy.cn,direct"
export GO111MODULE=on
```

### Step 6: Verify

Test the configuration:
```bash
go env GOPROXY
go list -m -versions github.com/gin-gonic/gin
```

## Safety Notes

⚠️ **Shell Profile**: Modifies shell startup file to persist the setting

⚠️ **Module Mode**: Sets `GO111MODULE=on` which is default in Go 1.16+

⚠️ **Private Modules**: `GOPRIVATE` is left empty; configure if you have private modules

## Verification

```bash
# Check current proxy
go env GOPROXY

# Test with module lookup
go list -m -versions github.com/sirupsen/logrus

# Test with actual download
go clean -modcache
time go mod download

# Check module source in go.mod
cat go.mod
```

## Available Proxies

| Proxy | URL | Priority |
|-------|-----|----------|
| goproxy.cn | https://goproxy.cn | 1 (default) |
| USTC | https://goproxy.ustc.edu.cn | 2 |
| Alibaba Cloud | https://mirrors.aliyun.com/goproxy/ | 3 |

**Recommendation**: Use **goproxy.cn** - it's the official Go module proxy for China, maintained by Qiniu Cloud, and is highly reliable.

## How Go Module Proxy Works

1. When you run `go get` or `go build`, Go requests modules from `GOPROXY`
2. If the proxy has the module cached, it returns immediately
3. If not, the proxy fetches from the original source and caches it
4. The `,direct` fallback tells Go to try original source if proxy fails

## Examples

### Example 1: Quick Fix

```
"Go mod download is too slow"
"Make go get faster in China"
```

### Example 2: Specific Proxy

```
"Use USTC Go module proxy"
```

### Example 3: With Private Modules

```
"Configure Go proxy but keep my company's private modules direct"
```

(Will set GOPRIVATE for company domain)

## Private Modules

If you have private GitHub/GitLab repositories:

```bash
# Add to shell profile
export GOPRIVATE="github.com/mycompany/*,gitlab.com/mycompany/*"

# Or configure per-module
export GOPRIVATE="github.com/mycompany/secret-project"
```

Private modules bypass the proxy and download directly.

## Troubleshooting

### Issue: GOPROXY not persistent

**Check**: Shell profile was properly modified
```bash
grep GOPROXY ~/.zshrc ~/.bashrc ~/.bash_profile 2>/dev/null
```

**Fix**: Reload shell or source profile
```bash
source ~/.zshrc  # or ~/.bashrc
```

### Issue: Private module fails

**Symptom**: `go get` fails for company private repo

**Fix**: Add to GOPRIVATE
```bash
export GOPRIVATE="github.com/yourcompany/*"
```

### Issue: Checksum mismatch errors

**Cause**: Proxy has different version than expected

**Fix**: Clean module cache
```bash
go clean -modcache
go mod download
```

### Issue: Some modules not found

**Cause**: Module might not be cached by proxy yet

**Fix**: Wait a few minutes or use direct:
```bash
GOPROXY=direct go get <module>
```

## Rollback

```bash
# Using restore script
./scripts/restore_config.sh --tool go --latest

# Or manually edit shell profile
nano ~/.zshrc  # or ~/.bashrc
# Remove GOPROXY lines

# Unset for current session
unset GOPROXY
```

## Implementation

```bash
./scripts/setup_go.sh --mirror <mirror>
```
