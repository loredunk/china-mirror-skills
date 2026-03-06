# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

China Mirror Skills 是专为中国网络环境优化的 Claude Code Skills 集合，同时提供独立的 Bash/Python 配置脚本。目标用户是中国国内开发者，帮助他们将 pip、npm、Docker、apt 等工具切换到国内镜像源。

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
./scripts/setup_pip.sh
./scripts/setup_npm.sh
./scripts/setup_apt.sh --mirror tuna
./scripts/setup_docker.sh

# 备份和还原配置
./scripts/backup_config.sh --all
./scripts/backup_config.sh --tool pip
./scripts/restore_config.sh --tool pip --latest
./scripts/restore_config.sh --list
```

## Architecture

### 核心数据源

`data/mirrors.yml` 是所有镜像信息的唯一真实来源，包含：
- 每个镜像的 `id`、`name`、`category`、`url`、`status`（active/testing/deprecated）、`priority`
- `verify` 字段定义健康检查 URL 和期望 HTTP 状态码
- `categories` 元数据和 `health_check` 全局配置

**修改镜像数据只需编辑此文件**，README 会由 `render_readme.py` 自动重新生成。

### Scripts 层（`scripts/`）

- `common.sh` — 所有 `setup_*.sh` 脚本共同 source 的工具库，提供日志函数、OS/发行版检测、代理冲突检测、备份工具等
- `setup_*.sh` — 各工具的幂等配置脚本，修改前自动备份，使用 `common.sh` 中的公共函数
- `check_mirrors.py` — 读取 `mirrors.yml`，并发 HTTP 检测（ThreadPoolExecutor），输出 JSON 报告
- `render_readme.py` — 读取 `mirrors.yml` + 内嵌 Jinja2 模板，生成 README.md

### Skills 层（`skills/`）

每个子目录是一个 Claude Code Skill，包含 `SKILL.md`（YAML frontmatter + Markdown 工作流说明）。

| Skill | 职责 |
|-------|------|
| `bootstrap-china-network` | 主入口：诊断环境并批量配置所有工具 |
| `diagnose-network-environment` | 网络环境诊断 |
| `fix-python-mirror` | pip/uv/poetry |
| `fix-node-mirror` | npm/pnpm/yarn |
| `fix-docker-mirror` | Docker CE 安装源 + Docker Hub daemon.json |
| `fix-apt-mirror` | Ubuntu/Debian APT |
| `fix-homebrew-mirror` | Homebrew |
| `fix-conda-mirror` | Conda/Anaconda |
| `fix-rust-mirror` | Cargo |
| `fix-go-proxy` | Go module proxy |
| `fix-flutter-mirror` | Flutter SDK |

### CI/CD（`.github/workflows/`）

- `mirror-health.yml` — 每天北京时间 08:00 运行 `check_mirrors.py`，输出 `reports/report.json`
- `readme-refresh.yml` — 当 `data/mirrors.yml` 或 `scripts/` 变更时，自动运行 `render_readme.py` 并提交更新的 README

## Key Conventions

- **镜像优先级**：清华 TUNA（priority: 1）> 中科大 USTC（priority: 2）> 阿里云等商业镜像（priority: 3）
- **Docker 区分**：`docker-ce` 类别是安装源（APT repo），`docker-hub` 类别是镜像加速（daemon.json `registry-mirrors`），两者用途不同，不能混淆
- **幂等性**：所有 setup 脚本可重复安全执行，不会产生重复配置
- **配置备份**：备份存放在项目根目录 `.backup/` 下（由 `common.sh` 中 `BACKUP_DIR` 定义）
- **README 生成**：`README.md` 是自动生成文件，不要直接手动编辑其镜像表格部分，修改 `data/mirrors.yml` 后运行 `render_readme.py`
