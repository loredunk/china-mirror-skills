# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

China Mirror Skills 是专为中国网络环境优化的 Claude Code Plugin，包含自包含的 Skill 和配置脚本。目标用户是中国国内开发者，帮助他们将 pip、npm、Docker、apt 等工具切换到国内镜像源。

本项目同时是一个 **Plugin Marketplace**，用户可通过 `/plugin marketplace add` 添加并安装。

## Common Commands

```bash
# 检查所有镜像源健康状态（并发检测，生成 reports/report.json）
# 需要 Python 依赖：pip install pyyaml requests
python scripts/check_mirrors.py

# 指定报告输出路径
python scripts/check_mirrors.py --output /tmp/report.json

# 重新生成 README.md（从 data/mirrors.yml 和模板渲染）
python scripts/render_readme.py

# 配置各工具镜像（所有脚本支持 -m/--mirror, -f/--force, -d/--dry-run, -y/--yes）
bash china-mirror/scripts/python/setup.sh
bash china-mirror/scripts/node/setup.sh
sudo bash china-mirror/scripts/apt/setup.sh --mirror tuna
sudo bash china-mirror/scripts/docker/setup.sh

# 备份和还原配置
bash china-mirror/scripts/backup_config.sh --all
bash china-mirror/scripts/backup_config.sh --tool pip
bash china-mirror/scripts/restore_config.sh --tool pip --latest
bash china-mirror/scripts/restore_config.sh --list
```

## Architecture

### Plugin 结构

本 repo 根目录既是一个 Plugin 也是一个 Marketplace：

- `.claude-plugin/marketplace.json` — Marketplace 清单，列出本 repo 提供的 plugin
- `china-mirror/` — Plugin 包含的唯一 Skill

用户安装方式：
```bash
/plugin marketplace add https://github.com/loredunk/china-mirror-skills
/plugin install china-mirror-skills@china-mirror-market
```

### 核心数据源

`data/mirrors.yml` 是所有镜像信息的唯一真实来源，包含：
- 每个镜像的 `id`、`name`、`category`、`url`、`status`（active/testing/deprecated）、`priority`
- `verify` 字段定义健康检查 URL 和期望 HTTP 状态码
- `categories` 元数据和 `health_check` 全局配置

**修改镜像数据只需编辑此文件**，README 会由 `render_readme.py` 自动重新生成。

### Skill（`china-mirror/`）

自包含的主 Skill，包含 `SKILL.md`（YAML frontmatter + Markdown 工作流说明）和所有配置脚本：

```
china-mirror/
  SKILL.md                    # 主入口：检测环境 → 调用对应脚本
  scripts/
    common.sh                 # 共享工具库（日志、OS 检测、备份等）
    diagnose.sh               # 网络环境诊断（纯检测，不修改配置）
    backup_config.sh          # 跨工具备份
    restore_config.sh         # 跨工具还原
    python/setup.sh           # pip/uv/poetry
    node/setup.sh             # npm/yarn/pnpm
    docker/setup.sh           # Docker CE + Hub
    apt/setup.sh              # Ubuntu/Debian APT
    homebrew/setup.sh         # Homebrew
    conda/setup.sh            # Conda/Anaconda
    rust/setup.sh             # Cargo/rustup
    go/setup.sh               # Go modules
    flutter/setup.sh          # Flutter/Dart
    github/setup.sh           # GitHub Releases
```

本项目只有一个 Skill（`china-mirror`），包含所有配置和诊断功能。

### Scripts 层（`scripts/`）— 仅 CI 维护脚本

- `check_mirrors.py` — 读取 `mirrors.yml`，并发 HTTP 检测（ThreadPoolExecutor），输出 JSON 报告
- `render_readme.py` — 读取 `mirrors.yml` + 内嵌 Jinja2 模板，生成 README.md
- `watch_deprecation.py` — 监控镜像源弃用状态
- `weekly_curation.py` — 每周镜像源整理

### CI/CD（`.github/workflows/`）

- `mirror-health.yml` — 每天北京时间 08:00 运行 `check_mirrors.py`，输出 `reports/report.json`
- `readme-refresh.yml` — 当 `data/mirrors.yml` 或 `scripts/` 变更时，自动运行 `render_readme.py` 并提交更新的 README

## Key Conventions

- **镜像优先级**：清华 TUNA（priority: 1）> 中科大 USTC（priority: 2）> 阿里云等商业镜像（priority: 3）
- **Docker 区分**：`docker-ce` 类别是安装源（APT repo），`docker-hub` 类别是镜像加速（daemon.json `registry-mirrors`），两者用途不同，不能混淆
- **幂等性**：所有 setup 脚本可重复安全执行，不会产生重复配置
- **配置备份**：备份存放在 `~/.china-mirror-backup/` 下（由 `common.sh` 中 `BACKUP_DIR` 定义）
- **README 生成**：`README.md` 是自动生成文件，不要直接手动编辑其镜像表格部分，修改 `data/mirrors.yml` 后运行 `render_readme.py`
