# Architecture

## Overview

China Mirror Skills is a collection of automation tools and Claude Code skills for configuring development tool mirrors in China's network environment.

```
china-mirror-skills/
├── data/
│   ├── mirrors.yml           # Single source of truth for all mirror definitions
│   └── page_fingerprints.json  # Saved fingerprints for deprecation detection
├── scripts/
│   ├── common.sh             # Shared bash utilities (logging, prompts, backup)
│   ├── check_mirrors.py      # HTTP health checker for all mirrors
│   ├── render_readme.py      # Jinja2-based README generator
│   ├── watch_deprecation.py  # Detects official page changes via fingerprinting
│   ├── weekly_curation.py    # Weekly report issue creator
│   ├── backup_config.sh      # Config backup utility
│   ├── restore_config.sh     # Config restore utility
│   └── setup_*.sh            # Per-tool setup scripts
├── skills/                   # Claude Code skill definitions
│   └── */                    # One directory per skill
├── docs/                     # Documentation
└── .github/workflows/        # GitHub Actions automation
```

## Data Layer: `data/mirrors.yml`

All mirror definitions live in a single YAML file. This is the single source of truth consumed by:

- `scripts/check_mirrors.py` — reads `mirrors[]` to know what URLs to test
- `scripts/render_readme.py` — reads `mirrors[]` and `categories{}` to generate README tables
- `scripts/setup_*.sh` — embed mirror URLs directly (kept in sync manually)

### Mirror Entry Schema

```yaml
- id: pip-tuna                  # Unique identifier
  name: "Tsinghua TUNA PyPI"    # Human-readable name
  category: pip                 # Groups mirrors by tool
  url: "https://..."            # Primary mirror URL used in configs
  homepage: "https://..."       # Mirror's own homepage
  status: active                # active | testing | deprecated | community
  priority: 1                   # Lower = higher priority
  official_help: "https://..."  # Required: link to official help page
  verify:
    type: http
    url: "https://..."          # URL used for health check (may differ from url)
    expect_status: 200          # Expected HTTP status code
  notes: "..."                  # Human notes shown in README
```

## Script Layer

### `common.sh`

Provides shared bash utilities sourced by all `setup_*.sh` scripts:

- **Logging**: `log_info`, `log_success`, `log_warn`, `log_error` with color output
- **Prompts**: `confirm_action` for interactive yes/no
- **Backup**: `backup_file` to `~/.china-mirror-skills/backups/`
- **Detection**: `check_proxy_conflict` to warn about conflicting proxy env vars

### `check_mirrors.py`

Concurrently tests all mirrors using `ThreadPoolExecutor`. Produces a structured JSON report:

```
reports/report.json
├── metadata: { generated_at, version, mirror_data_updated }
├── summary: { total_mirrors, healthy, unhealthy, health_rate, category_stats }
├── results: [ { id, name, category, url, status, http_status, response_time_ms, error_message } ]
└── recommendations: [ { category, severity, message, action } ]
```

Run with `--output PATH` to write the report to a custom location.

### `render_readme.py`

Uses Jinja2 to render `README.md` from the inline `README_TEMPLATE`. Template variables:

- `categories` — dict from `mirrors.yml`
- `mirrors_by_category` — mirrors grouped and sorted by priority
- `updated_at` — from `mirrors.yml`
- `has_report`, `health_checked_at`, `report_summary` — from `reports/report.json` if present

### `watch_deprecation.py`

Fetches a fixed list of official mirror help pages and computes SHA-256 fingerprints of their content. Fingerprints are persisted in `data/page_fingerprints.json`. If a page changes, a GitHub issue is created via the REST API.

### `weekly_curation.py`

Reads `reports/report.json` and creates a weekly GitHub issue with:
- Summary table of mirror health
- Checklist of failed/degraded mirrors
- Category health breakdown
- Standard action items

## Skills Layer

Each skill is a directory under `skills/` containing a `prompt.md` and optional `metadata.json`. Skills are loaded by Claude Code from the repository root.

Skills call the bash scripts in `scripts/` rather than duplicating logic.

## CI/CD Layer

| Workflow | Schedule | Trigger | Purpose |
|----------|----------|---------|---------|
| `mirror-health.yml` | Daily 08:00 UTC | `workflow_dispatch` | Health check + commit report |
| `readme-refresh.yml` | On push to `data/`, `docs/` | After mirror-health | Regenerate README |
| `deprecation-watch.yml` | Monday 09:00 UTC | `workflow_dispatch` | Page fingerprint diff |
| `weekly-curation.yml` | Monday 08:00 UTC | `workflow_dispatch` | Weekly issue |

## Design Principles

1. **Single source of truth**: `data/mirrors.yml` is the authoritative mirror list
2. **Official sources only**: All mirrors must have an `official_help` URL
3. **Backup before modify**: All setup scripts call `backup_file` before changing configs
4. **Idempotent**: Scripts detect existing correct config and skip redundant changes
5. **No sudo escalation without warning**: Scripts warn before requiring elevated privileges
