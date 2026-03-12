# Mirror Selection Policy

## Principles

This project selects mirrors based on strict criteria to ensure reliability and trustworthiness for developers in China.

## Acceptance Criteria

A mirror must meet **all** of the following to be included:

### 1. Official Documentation Required

Every mirror entry must include an `official_help` URL pointing to the mirror operator's own documentation page. Blog posts, third-party guides, or unofficial wikis do not qualify.

**Acceptable sources:**
- `https://mirrors.tuna.tsinghua.edu.cn/help/*` — Tsinghua University TUNA
- `https://mirrors.ustc.edu.cn/help/*` — USTC LUG
- `https://developer.aliyun.com/mirror/*` — Alibaba Cloud
- `https://mirrors.cloud.tencent.com/help/*` — Tencent Cloud
- `https://npmmirror.com` — Official npm China mirror
- `https://goproxy.cn` — Qiniu Cloud official Go proxy
- Vendor's own mirror documentation

### 2. HTTPS Required

All mirror URLs must use HTTPS. HTTP-only mirrors are not accepted due to security concerns.

### 3. Active Maintenance

Mirrors should demonstrate active maintenance:
- Sync frequency documented
- Operator reachable (university IT or company)
- Not known to be abandoned

### 4. No Certificate Bypassing

We do not recommend or document any configuration that bypasses TLS certificate validation.

## Mirror Status Values

| Status | Meaning |
|--------|---------|
| `active` | Verified working, recommended for use |
| `testing` | Under evaluation, may be added after validation period |
| `deprecated` | Officially discontinued or policy-changed; kept for documentation only |
| `community` | Community-maintained, lower trust level, use with caution |

## Priority Ordering

Within a category, mirrors are ordered by priority (lower number = higher priority):

1. **Priority 1**: University mirrors (TUNA, USTC) — highest reliability, non-commercial
2. **Priority 2**: Official cloud provider mirrors (Alibaba, Tencent) — well-maintained
3. **Priority 3+**: Community or regional mirrors — may be less reliable

## Deprecated Mirrors Policy

When a mirror operator announces deprecation (e.g., Docker Hub mirrors):

1. Change `status` to `deprecated` in `mirrors.yml`
2. Add a `notes` field explaining the deprecation and linking to the announcement
3. Update the verification URL to expect the actual HTTP status (e.g., `403`)
4. Keep the entry for documentation purposes so users know to remove old configs
5. Do **not** recommend deprecated mirrors in setup scripts

## Adding a New Mirror

1. Verify the mirror meets all acceptance criteria above
2. Find and link the `official_help` URL
3. Test the verify URL returns the expected HTTP status
4. Add the entry to `data/mirrors.yml` with appropriate `priority`
5. Run `python scripts/check_mirrors.py` to verify the health check passes
6. Submit a PR with a link to the official help page in the PR description

## Removing a Mirror

Mirrors should be **deprecated, not removed** when they go offline. This documents the history and helps users who may still have old configurations. Only remove a mirror entry if:

- It was added by mistake
- It is a duplicate of another entry
- The operator explicitly asks for removal

## Known Deprecated Categories

### Docker Hub Mirrors

As of 2023-2024, most public Docker Hub mirrors in China have become unavailable or restricted due to Docker's policy changes. We document these as `deprecated` with warnings. Users should use alternative solutions (VPN, paid proxy, registry mirrors on private infrastructure).
