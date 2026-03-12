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
  <a href="#安装">安装</a> •
  <a href="#支持的工具">支持的工具</a> •
  <a href="#镜像源">镜像源</a>
</p>

---

## 目录

- [为什么需要这个项目？](#为什么需要这个项目)
- [支持的工具](#支持的工具)
- [安装](#安装)
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
3. **Claude Code skills** - 借助 AI 完成配置和诊断
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
{% for cat_id, cat_info in categories.items() %}| {{ cat_info.icon }} {{ cat_info.name }} | {% if cat_id == 'pip' %}pip, uv, poetry{% elif cat_id == 'npm' %}npm, pnpm, yarn{% elif cat_id == 'docker-ce' %}Docker CE install{% elif cat_id == 'docker-hub' %}Docker Hub（镜像加速）{% elif cat_id == 'cargo' %}Cargo{% elif cat_id == 'homebrew' %}Homebrew{% elif cat_id == 'conda' %}Conda/Anaconda{% elif cat_id == 'go' %}Go modules{% elif cat_id == 'flutter' %}Flutter SDK{% elif cat_id == 'github-release' %}GitHub Releases{% elif cat_id == 'github-repo' %}GitHub 仓库 clone 加速{% elif cat_id == 'huggingface' %}Hugging Face models / datasets{% elif cat_id == 'kubernetes-notes' %}K8s registry{% else %}{{ cat_id }}{% endif %} | {% if cat_id == 'kubernetes-notes' %}ℹ️ 说明{% else %}✅ 可用{% endif %} | {% if cat_id in ['pip', 'npm', 'cargo', 'conda'] %}Package Index{% elif cat_id in ['ubuntu', 'alpine'] %}APT Repository{% elif cat_id == 'docker-ce' %}安装源{% elif cat_id == 'docker-hub' %}Registry Mirror{% elif cat_id in ['homebrew', 'github-repo'] %}Git Repository{% elif cat_id == 'go' %}Module Proxy{% elif cat_id == 'flutter' %}SDK Mirror{% elif cat_id == 'github-release' %}Release Asset Mirror{% elif cat_id == 'huggingface' %}Model / Dataset Mirror{% else %}说明{% endif %} |
{% endfor %}

### 核心特性

- ✅ **备份与回滚** - 修改前自动备份配置
- ✅ **代理冲突检测** - 检测代理环境变量冲突
- ✅ **幂等操作** - 重复执行安全
- ✅ **按需临时镜像** - 对 Hugging Face 下载仅在当前命令注入镜像环境变量
- ✅ **多平台支持** - Linux 为主，macOS 部分支持
- ✅ **官方来源** - 优先使用 TUNA、USTC 及厂商官方镜像

---

## 安装

本项目是一个 Claude Code Plugin，包含自包含的 `china-mirror` skill，提供镜像配置和网络诊断功能。

### 方式一：Plugin 安装（推荐）

在 Claude Code 中执行：

```bash
# 添加 marketplace
/plugin marketplace add https://github.com/loredunk/china-mirror-skills

# 安装插件
/plugin install china-mirror-skills@china-mirror-market
```

### 方式二：手动安装

```bash
# 克隆项目
git clone https://github.com/loredunk/china-mirror-skills.git

# 安装 skill 到 Claude Code 全局目录
cp -r china-mirror-skills/china-mirror ~/.claude/skills/
```

### 安装后使用

直接向 Claude Code 提问即可：

```
"帮我配置适合中国网络的开发环境"
"pip install 太慢了，帮我配置国内镜像"
"诊断我的开发环境网络问题"
```

### 其他 AI 编程助手

- **OpenCode** — 将 `china-mirror/skills/china-mirror` 复制到 OpenCode 的 skills 存储路径
- **Codex / 其他兼容工具** — 将 `china-mirror/skills/china-mirror`（包含 `SKILL.md` 和 `scripts/`）放入工具对应的 skills 目录

### Skill 功能

| 功能 | 触发场景 |
|------|---------|
| 一键配置 | "配置国内镜像"、新机器初始化、全部工具一次性配置 |
| 单工具修复 | "pip 太慢"、"npm 超时"、指定某个工具配置镜像 |
| 网络诊断 | "为什么下载慢"、"诊断网络"、检查已安装工具的镜像状态 |
| 备份还原 | 备份当前配置、还原到修改前的状态 |
| Hugging Face 下载 | "帮我下模型"、"hf 下载太慢"、临时使用镜像下载模型或数据集 |

---

## Hugging Face

项目内置了 Hugging Face 的临时镜像下载方式，默认不会写入 shell profile，也不会长期污染环境变量。

### 一次性使用 `huggingface-cli`

```bash
HF_ENDPOINT=https://hf-mirror.com huggingface-cli download gpt2
HF_ENDPOINT=https://hf-mirror.com huggingface-cli download --repo-type dataset wget2 --local-dir ./wget2
```

### 使用内置 `hfd.sh`

```bash
bash china-mirror/skills/china-mirror/scripts/huggingface/download.sh gpt2 --tool hfd
bash china-mirror/skills/china-mirror/scripts/huggingface/download.sh meta-llama/Llama-2-7b --tool hfd --hf_username <your-username> --hf_token <your-token>
```

- 默认临时注入 `HF_ENDPOINT=https://hf-mirror.com`
- 若需要直连官方源，可显式传 `--mirror official`
- `hfd.sh` 来源与用法参考：
  - `https://hf-mirror.com/`
  - `https://gist.github.com/padeoe/697678ab8e528b85a2a7bddafea1fa4f`

---

## 镜像源

### 当前镜像状态

_镜像数据最后更新: {{ updated_at }}_
{% if has_report %}
_健康检查时间: {{ health_checked_at }}_

**汇总**: {{ report_summary.healthy }}/{{ report_summary.total_mirrors }} 个镜像可用（{{ report_summary.health_rate }}%）
{% if report_summary.critical_categories %}

**报警分类**: {{ report_summary.critical_categories | join(', ') }}
{% endif %}
{% else %}
_暂无与当前镜像数据匹配的健康检查数据，请重新运行 `python scripts/check_mirrors.py --output reports/report.json` 获取最新结果。_
{% endif %}

_有健康检查报告时，下表按每日健康检查结果动态排序；无报告时回退到静态优先级。_

{% for cat_id, cat_info in categories.items() %}
#### {{ cat_info.icon }} {{ cat_info.name }}

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
{% for mirror in mirrors_by_category[cat_id] %}| {{ mirror.name }} | [{{ mirror.url }}]({{ mirror.url }}) | {{ status_badge(mirror) }}{% if mirror.response_time_ms is not none %} ({{ mirror.response_time_ms }}ms){% endif %} | {{ mirror.priority }} |
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

本仓库收录的镜像均来自第三方服务，本仓库仅整理配置与使用方式，不对镜像内容、可用性、安全性或合规性做任何承诺。

使用第三方镜像需要你自行判断并信任对应镜像服务。

---

## 致谢

- [清华大学 TUNA](https://mirrors.tuna.tsinghua.edu.cn/) - 主要镜像源
- [中科大 USTC LUG](https://mirrors.ustc.edu.cn/) - 备用镜像源
- [npmmirror](https://npmmirror.com/) - 官方 npm 镜像
- [hf-mirror](https://hf-mirror.com/) - Hugging Face 镜像与下载说明
- [padeoe 的 hfd.sh gist](https://gist.github.com/padeoe/697678ab8e528b85a2a7bddafea1fa4f) - `hfd.sh` 脚本与用法
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


def rank_lookup_from_report(report: dict | None) -> dict[str, dict[str, int]]:
    """Build per-category dynamic rank lookup from the health report."""
    if not report:
        return {}

    rankings = {}
    for category, payload in report.get('category_rankings', {}).items():
        ranked = payload.get('ranked_results', [])
        rankings[category] = {
            result['id']: index for index, result in enumerate(ranked, start=1)
        }
    return rankings


def load_report(report_path: Path) -> dict:
    """Load optional mirror health report"""
    if report_path.exists():
        with open(report_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}


def status_badge(mirror: dict) -> str:
    """Render a human-readable status badge for README tables."""
    live_status = mirror.get('live_status')
    verify = mirror.get('verify', {})
    inconclusive = {f"http_{code}" for code in verify.get('inconclusive_statuses', [])}

    if live_status == 'ok':
        return "✅ 正常"
    if live_status == 'timeout':
        return "⏱️ 超时"
    if live_status in inconclusive:
        return f"⚠️ {live_status}"
    if live_status is not None:
        return f"❌ {live_status}"
    if mirror.get('status') == 'active':
        return "✅ 可用"
    if mirror.get('status') == 'deprecated':
        return "⚠️ 已废弃"
    if mirror.get('status') == 'community':
        return "⚠️ 社区维护"
    return "🧪 测试中"


def generate_readme(mirrors_data: dict, report: dict = None) -> str:
    """Generate README content using Jinja2 template"""
    from jinja2 import Environment

    mirrors = [dict(mirror) for mirror in mirrors_data.get('mirrors', [])]
    categories = mirrors_data.get('categories', {})
    updated_at = mirrors_data.get('updated_at', 'unknown')

    # Ignore stale reports generated from an older mirrors.yml snapshot.
    if report:
        report_meta = report.get('metadata', {})
        if report_meta.get('mirror_data_updated') != updated_at:
            report = {}

    mirrors_by_category = group_mirrors_by_category(mirrors)
    rank_lookup = rank_lookup_from_report(report)

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
            mirror['dynamic_rank'] = rank_lookup.get(cat_id, {}).get(mirror['id'])

        cat_mirrors.sort(
            key=lambda mirror: (
                mirror['dynamic_rank'] if mirror['dynamic_rank'] is not None else 10**6,
                mirror.get('priority', 99),
                mirror['name'].lower(),
            )
        )

    report_summary = report.get('summary', {}) if report else {}

    report_meta = report.get('metadata', {}) if report else {}
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
        status_badge=status_badge,
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
