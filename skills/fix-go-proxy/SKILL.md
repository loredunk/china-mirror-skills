---
name: fix-go-proxy
description: |
  Configure Go to use China-based module proxies (goproxy.cn, USTC, Alibaba Cloud) for fast
  module downloads. Use this skill whenever go mod download is slow, go get times out, go build
  hangs downloading modules, or downloads from proxy.golang.org fail in China. Also use when
  setting up a Go development environment in China. If the user says "go mod 太慢", "go get 超时",
  or similar, always use this skill.
---

# Configure Go Module Proxy

Set GOPROXY to a China-based proxy for fast module downloads.

## Steps

**1. Check Go installation**
```bash
which go && go version
go env GOPROXY   # Check current setting
```

**2. Run the setup script**

Default proxy: **goproxy.cn** (official China Go proxy by Qiniu Cloud, most reliable).

```bash
./scripts/setup_go.sh --mirror <goproxy|ustc|aliyun>
```

The script adds `GOPROXY` and `GO111MODULE` to the shell profile and activates them for the current session.

**3. Verify**
```bash
go env GOPROXY
go list -m -versions github.com/gin-gonic/gin   # Quick connectivity test
```

## Available Proxies

| Proxy | URL | Priority |
|-------|-----|----------|
| goproxy.cn | https://goproxy.cn | 1 (default) |
| USTC | https://goproxy.ustc.edu.cn | 2 |
| Alibaba Cloud | https://mirrors.aliyun.com/goproxy/ | 3 |

## Config Reference

Add to shell profile (`~/.zshrc` or `~/.bashrc`):
```bash
export GOPROXY="https://goproxy.cn,direct"
export GO111MODULE=on
```

The `,direct` fallback means Go tries the original source if the proxy doesn't have the module.

## Private Modules

If you have private GitHub/GitLab repos that should bypass the proxy:
```bash
export GOPRIVATE="github.com/yourcompany/*,gitlab.com/yourcompany/*"
```

## Rollback

```bash
./scripts/restore_config.sh --tool go --latest
# Or: edit shell profile and remove GOPROXY lines; then: unset GOPROXY
```
