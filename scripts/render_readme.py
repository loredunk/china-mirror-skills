#!/usr/bin/env python3
"""
README.md generator for china-mirror-skills

Generates a comprehensive README based on mirrors.yml data and templates.
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime

import yaml


# Jinja2-style template for README
README_TEMPLATE = '''# 🇨🇳 China Mirror Skills

<p align="center">
  <strong>专为中国网络环境优化的 Claude Code 开发工具镜像配置集合</strong>
</p>

<p align="center">
  <a href="#快速开始">快速开始</a> •
  <a href="#支持的工具">支持的工具</a> •
  <a href="#镜像源">镜像源</a>
</p>

---

## 目录

- [为什么需要这个项目？](#为什么需要这个项目)
- [支持的工具](#支持的工具)
- [项目结构](#项目结构)
- [快速开始](#快速开始)
- [Claude Code 使用方式](#claude-code-使用方式)
- [独立脚本](#独立脚本)
- [GitHub Actions](#github-actions)
- [镜像源](#镜像源)
- [安全与风险](#安全与风险)

---

## 为什么需要这个项目？

国内开发者访问官方软件包仓库和开发工具时，常常遇到速度慢或无法访问的问题：

- **PyPI** 下载超时或速度低至 10KB/s
- **npm** 安装包需要等待很长时间
- **Docker Hub** 镜像拉取失败或极慢
- **Rust crates** 下载缓慢
- **GitHub Releases** 下载经常卡住

本项目提供：

1. **经过验证的镜像配置** - 来自高校官方镜像站（清华 TUNA、中科大 USTC）
2. **自动化配置脚本** - 支持备份和回滚
3. **Claude Code skills** - 借助 AI 完成配置
4. **每日健康检查** - 确保镜像源可用性
5. **幂等操作** - 重复执行安全无副作用

> ⚠️ **重要区分**
> - Docker **CE 安装**源 ≠ Docker **Hub** 镜像加速
> - Kubernetes **k8s.gcr.io** 已**废弃**（已迁移至 registry.k8s.io）
> - 优先采用**官方帮助页面**中的配置，而非第三方博客

---

## 支持的工具

| 分类 | 工具 | 状态 | 镜像类型 |
|------|------|------|----------|
{% for cat_id, cat_info in categories.items() %}| {{ cat_info.icon }} {{ cat_info.name }} | {% if cat_id == 'pip' %}pip, uv, poetry{% elif cat_id == 'npm' %}npm, pnpm, yarn{% elif cat_id == 'docker-ce' %}Docker CE install{% elif cat_id == 'docker-hub' %}Docker Hub（镜像加速）{% elif cat_id == 'cargo' %}Cargo{% elif cat_id == 'homebrew' %}Homebrew{% elif cat_id == 'conda' %}Conda/Anaconda{% elif cat_id == 'go' %}Go modules{% elif cat_id == 'flutter' %}Flutter SDK{% elif cat_id == 'kubernetes-notes' %}K8s registry{% else %}{{ cat_id }}{% endif %} | ✅ 可用 | {% if cat_id in ['pip', 'npm', 'cargo', 'conda'] %}Package Index{% elif cat_id in ['ubuntu', 'alpine'] %}APT Repository{% elif cat_id == 'docker-ce' %}安装源{% elif cat_id == 'docker-hub' %}Registry Mirror{% elif cat_id == 'homebrew' %}Git Repository{% elif cat_id == 'go' %}Module Proxy{% elif cat_id == 'flutter' %}SDK Mirror{% else %}说明{% endif %} |
{% endfor %}

### 核心特性

- ✅ **备份与回滚** - 修改前自动备份配置
- ✅ **代理冲突检测** - 检测代理环境变量冲突
- ✅ **幂等操作** - 重复执行安全
- ✅ **多平台支持** - Linux 为主，macOS 部分支持
- ✅ **官方来源** - 优先使用 TUNA、USTC 及厂商官方镜像

---

## 项目结构

```
china-mirror-skills/
├── README.md              # 本文件（自动生成）
├── LICENSE                # MIT 协议
├── data/
│   └── mirrors.yml        # 镜像源配置数据
├── scripts/               # 配置和工具脚本
│   ├── common.sh          # 公共函数
│   ├── check_mirrors.py   # 镜像健康检查
│   ├── render_readme.py   # README 生成器
│   ├── backup_config.sh   # 备份工具
│   ├── restore_config.sh  # 还原工具
│   └── setup_*.sh         # 各工具的配置脚本
├── skills/                # Claude Code skills
│   ├── bootstrap-china-network/   # 主入口
│   ├── fix-python-mirror/         # Python 工具
│   ├── fix-node-mirror/           # Node.js 工具
│   ├── fix-docker-mirror/         # Docker
│   ├── fix-apt-mirror/            # Ubuntu/Debian
│   ├── fix-homebrew-mirror/       # Homebrew
│   ├── fix-conda-mirror/          # Conda
│   ├── fix-rust-mirror/           # Rust/Cargo
│   ├── fix-go-proxy/              # Go
│   ├── fix-flutter-mirror/        # Flutter
│   └── diagnose-network-environment/  # 网络诊断
├── docs/                  # 文档
│   ├── architecture.md    # 技术架构
│   ├── mirrors-policy.md  # 镜像选择标准
│   ├── troubleshooting.md # 常见问题
│   └── examples.md        # 使用示例
└── .github/workflows/     # CI/CD 自动化
    ├── mirror-health.yml  # 每日健康检查
    └── readme-refresh.yml # 自动更新 README
```

---

## 快速开始

### 前置要求

- Python 3.11+
- Bash 4.0+
- Linux（推荐）或 macOS（部分支持）

### 安装

```bash
# 克隆项目
git clone https://github.com/yourusername/china-mirror-skills.git
cd china-mirror-skills

# 安装 Python 依赖
pip install -r requirements.txt

# 或使用 uv
uv pip install -r requirements.txt
```

### 快速检查

```bash
# 检查所有镜像源状态
python scripts/check_mirrors.py
```

### 快速配置

```bash
# 配置 Python pip 镜像
./scripts/setup_pip.sh

# 配置 npm 镜像
./scripts/setup_npm.sh

# 配置 Ubuntu APT 镜像
./scripts/setup_apt.sh --mirror tuna

# 配置 Docker CE 安装源（非 Docker Hub）
./scripts/setup_docker.sh
```

---

## Claude Code 使用方式

### 加载 Skills

在 Claude Code 设置或 CLAUDE.md 中添加本项目的 skills 目录路径。

### 可用 Skills

#### 1. bootstrap-china-network

主入口 - 诊断环境并自动应用适合的配置。

```
"帮我配置适合中国网络的开发环境"
"把 pip、npm 和 Docker 配置成国内镜像"
```

#### 2. fix-python-mirror

配置 pip、uv、poetry 使用国内镜像。

```
"Python 包下载太慢了，帮我配置"
"把 pip 切换到清华镜像"
```

#### 3. fix-node-mirror

配置 npm、pnpm、yarn 使用国内镜像。

```
"npm install 太慢了，帮我搞定"
"配置 npm 使用 npmmirror"
```

#### 4. fix-docker-mirror

配置 Docker CE 安装源和 Docker Hub 镜像加速（daemon.json）。

```
"从国内镜像安装 Docker CE"
"配置 Docker Hub 镜像加速"
```

#### 5. fix-apt-mirror

配置 Ubuntu/Debian APT 镜像源。

```
"让 apt update 快一些"
"切换到清华的 Ubuntu 镜像"
```

#### 6. fix-homebrew-mirror

配置 Homebrew 镜像。

```
"Homebrew 太慢了，帮我配置"
```

#### 7. fix-conda-mirror

配置 Conda/Anaconda 镜像频道。

```
"配置 conda 使用国内镜像"
```

#### 8. fix-rust-mirror

配置 Cargo 使用国内 crates 镜像。

```
"cargo build 下载包太慢了"
```

#### 9. fix-go-proxy

配置 Go 模块代理。

```
"国内 go mod download 很慢"
```

#### 10. fix-flutter-mirror

配置 Flutter SDK 及依赖镜像。

```
"帮我在国内配置 Flutter 环境"
```

#### 11. diagnose-network-environment

分析网络环境，诊断常见问题。

```
"帮我诊断开发环境的网络配置"
"为什么下载这么慢？"
```

---

## 独立脚本

### 备份配置

```bash
# 备份所有支持的配置
./scripts/backup_config.sh --all

# 备份指定工具的配置
./scripts/backup_config.sh --tool pip
```

### 还原配置

```bash
# 列出可用备份
./scripts/restore_config.sh --list

# 从指定备份还原
./scripts/restore_config.sh --tool pip --backup-id 20250306_120000

# 还原最新备份
./scripts/restore_config.sh --tool pip --latest
```

### 脚本参数

所有配置脚本支持以下参数：

```bash
./scripts/setup_<tool>.sh [OPTIONS]

参数说明：
  -m, --mirror MIRROR    指定镜像源 (tuna|ustc|aliyun|...)
  -f, --force            强制覆盖已有配置
  -d, --dry-run          仅显示将要做的修改，不实际执行
  -y, --yes              跳过确认提示
  -h, --help             显示帮助信息
```

---

## GitHub Actions

### 镜像健康检查

**工作流**: `.github/workflows/mirror-health.yml`

- **定时执行**: 每天北京时间 08:00（UTC 00:00），推送到 main 分支时也会触发
- **手动触发**: `workflow_dispatch`
- **功能**: 测试 `data/mirrors.yml` 中所有镜像的 HTTP 连通性
- **输出**: `reports/report.json`

### README 自动更新

**工作流**: `.github/workflows/readme-refresh.yml`

- **触发条件**: 推送到 main 且修改了 `data/mirrors.yml` 或 `scripts/`
- **功能**: 从模板重新生成 README.md
- **自动提交**: 如果 README 有变化则自动提交

---

## 镜像源

### 当前镜像状态

_镜像数据最后更新: {{ updated_at }}_
{% if has_report %}
_健康检查时间: {{ health_checked_at }}_

**汇总**: {{ report_summary.healthy }}/{{ report_summary.total_mirrors }} 个镜像可用（{{ report_summary.health_rate }}%）
{% else %}
_暂无健康检查数据，请查看 [GitHub Actions](../../actions) 获取最新结果。_
{% endif %}

{% for cat_id, cat_info in categories.items() %}
#### {{ cat_info.icon }} {{ cat_info.name }}

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
{% for mirror in mirrors_by_category[cat_id] %}| {{ mirror.name }} | [{{ mirror.url }}]({{ mirror.url }}) | {% if mirror.live_status == 'ok' %}✅ 正常{% elif mirror.live_status == 'timeout' %}⏱️ 超时{% elif mirror.live_status is not none %}❌ {{ mirror.live_status }}{% elif mirror.status == 'active' %}✅ 可用{% elif mirror.status == 'deprecated' %}⚠️ 已废弃{% else %}🧪 测试中{% endif %}{% if mirror.response_time_ms is not none %} ({{ mirror.response_time_ms }}ms){% endif %} | {{ mirror.priority }} |
{% endfor %}

{% endfor %}

### 镜像选择标准

优先采用以下标准选择镜像：

1. **官方背书** - 拥有官方文档的高校镜像（清华 TUNA、中科大 USTC）
2. **可靠性** - 历史在线率和维护承诺
3. **同步频率** - 与上游的同步频率
4. **帮助文档** - 官方帮助页面质量

---

## 安全与风险

### 风险说明

使用第三方镜像需要信任该镜像服务：

1. **包完整性** - 镜像站不应修改软件包内容
2. **TLS 拦截** - 部分网络环境可能拦截 HTTPS 流量
3. **软件包滞后** - 镜像可能落后于上游

### 本项目的风险缓解措施

- ✅ **仅使用 HTTPS** - 所有镜像均使用 TLS 加密
- ✅ **校验和验证** - 脚本保留原始包签名验证
- ✅ **官方来源** - 优先选择有官方背书的镜像
- ✅ **健康监控** - 每日自动检查
- ✅ **备份与回滚** - 随时可以还原原始配置

### 我们不做的事

- ❌ 绕过安全证书
- ❌ 使用未验证的第三方二进制文件
- ❌ 推荐已废弃或已知有问题的镜像
- ❌ 修改软件包内容

---

## 致谢

- [清华大学 TUNA](https://mirrors.tuna.tsinghua.edu.cn/) - 主要镜像源
- [中科大 USTC LUG](https://mirrors.ustc.edu.cn/) - 备用镜像源
- [npmmirror](https://npmmirror.com/) - 官方 npm 镜像
- 所有开源镜像的贡献者和维护者

---

<p align="center">
  <sub>为中国开发者用心打造 ❤️</sub>
</p>
'''


def load_mirrors(yaml_path: Path) -> dict:
    """Load mirror configuration from YAML file"""
    with open(yaml_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def group_mirrors_by_category(mirrors: list) -> dict:
    """Group mirrors by category"""
    groups = {}
    for mirror in mirrors:
        cat = mirror['category']
        if cat not in groups:
            groups[cat] = []
        groups[cat].append(mirror)

    # Sort by priority within each group
    for cat in groups:
        groups[cat].sort(key=lambda x: x.get('priority', 99))

    return groups


def load_report(report_path: Path) -> dict:
    """Load optional mirror health report"""
    if report_path.exists():
        with open(report_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}


def generate_readme(mirrors_data: dict, report: dict = None) -> str:
    """Generate README content using Jinja2 template"""
    from jinja2 import Environment

    mirrors = mirrors_data.get('mirrors', [])
    categories = mirrors_data.get('categories', {})
    mirrors_by_category = group_mirrors_by_category(mirrors)

    # Build per-mirror health status from report
    mirror_health = {}
    if report:
        for result in report.get('results', []):
            mirror_health[result['id']] = result

    # Enrich mirrors_by_category with live health data
    for cat_id, cat_mirrors in mirrors_by_category.items():
        for mirror in cat_mirrors:
            health = mirror_health.get(mirror['id'])
            if health:
                mirror['live_status'] = health['status']
                mirror['response_time_ms'] = health.get('response_time_ms')
            else:
                mirror['live_status'] = None
                mirror['response_time_ms'] = None

    report_meta = report.get('metadata', {}) if report else {}
    report_summary = report.get('summary', {}) if report else {}

    updated_at = mirrors_data.get('updated_at', 'unknown')
    health_checked_at = report_meta.get('generated_at', None)

    env = Environment(keep_trailing_newline=True, trim_blocks=True, lstrip_blocks=True)
    template = env.from_string(README_TEMPLATE)

    return template.render(
        categories=categories,
        mirrors_by_category=mirrors_by_category,
        updated_at=updated_at,
        health_checked_at=health_checked_at,
        report_summary=report_summary,
        has_report=bool(report),
    )


def main():
    """Main entry point"""
    # Determine paths
    script_dir = Path(__file__).parent.absolute()
    project_root = script_dir.parent
    mirrors_path = project_root / 'data' / 'mirrors.yml'
    report_path = project_root / 'reports' / 'report.json'
    readme_path = project_root / 'README.md'

    print("China Mirror Skills - README Generator")
    print("=" * 40)
    print(f"Mirrors file: {mirrors_path}")
    print(f"Output: {readme_path}")

    if not mirrors_path.exists():
        print(f"Error: Mirrors file not found: {mirrors_path}", file=sys.stderr)
        sys.exit(1)

    # Load mirrors configuration
    print("Loading mirrors configuration...")
    mirrors_data = load_mirrors(mirrors_path)

    # Load optional health report
    report = load_report(report_path)
    if report:
        print(f"Loaded health report from: {report_path}")
    else:
        print("No health report found, skipping live status")

    # Generate README
    print("Generating README...")
    readme_content = generate_readme(mirrors_data, report)

    # Write README
    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write(readme_content)

    print(f"✅ README generated: {readme_path}")


if __name__ == '__main__':
    main()
