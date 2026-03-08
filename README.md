# 🇨🇳 China Mirror Skills

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
| 🐍 Python (pip) | pip, uv, poetry | ✅ 可用 | Package Index |
| 📦 Node.js (npm) | npm, pnpm, yarn | ✅ 可用 | Package Index |
| 🐧 Ubuntu (apt) | ubuntu | ✅ 可用 | APT Repository |
| 🐳 Docker CE | Docker CE install | ✅ 可用 | 安装源 |
| 🐳 Docker Hub | Docker Hub（镜像加速） | ✅ 可用 | Registry Mirror |
| 🦀 Rust (Cargo) | Cargo | ✅ 可用 | Package Index |
| 🍺 Homebrew | Homebrew | ✅ 可用 | Git Repository |
| 🐍 Conda/Anaconda | Conda/Anaconda | ✅ 可用 | Package Index |
| 🐹 Go | Go modules | ✅ 可用 | Module Proxy |
| 📱 Flutter | Flutter SDK | ✅ 可用 | SDK Mirror |
| 🐙 GitHub Releases | GitHub Releases | ✅ 可用 | Release Asset Mirror |
| 🐙 GitHub Project Mirrors | GitHub 仓库 clone 加速 | ✅ 可用 | Git Repository |
| ☸️ Kubernetes | K8s registry | ℹ️ 说明 | 说明 |
| 🏔️ Alpine Linux | alpine | ✅ 可用 | APT Repository |

### 核心特性

- ✅ **备份与回滚** - 修改前自动备份配置
- ✅ **代理冲突检测** - 检测代理环境变量冲突
- ✅ **幂等操作** - 重复执行安全
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
cp -r china-mirror-skills/skills/china-mirror ~/.claude/skills/
```

### 安装后使用

直接向 Claude Code 提问即可：

```
"帮我配置适合中国网络的开发环境"
"pip install 太慢了，帮我配置国内镜像"
"诊断我的开发环境网络问题"
```

### 其他 AI 编程助手

- **OpenCode** — 将 `skills/china-mirror` 复制到 OpenCode 的 skills 存储路径
- **Codex / 其他兼容工具** — 将 `skills/china-mirror`（包含 `SKILL.md` 和 `scripts/`）放入工具对应的 skills 目录

### Skill 功能

| 功能 | 触发场景 |
|------|---------|
| 一键配置 | "配置国内镜像"、新机器初始化、全部工具一次性配置 |
| 单工具修复 | "pip 太慢"、"npm 超时"、指定某个工具配置镜像 |
| 网络诊断 | "为什么下载慢"、"诊断网络"、检查已安装工具的镜像状态 |
| 备份还原 | 备份当前配置、还原到修改前的状态 |

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

_镜像数据最后更新: 2026-03-07_
_健康检查时间: 2026-03-08T01:10:40.321569Z_

**汇总**: 23/30 个镜像可用（76.67%）

#### 🐍 Python (pip)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA PyPI Mirror | [https://pypi.tuna.tsinghua.edu.cn/simple](https://pypi.tuna.tsinghua.edu.cn/simple) | ✅ 正常 (1352.33ms) | 1 |
| USTC PyPI Mirror | [https://pypi.mirrors.ustc.edu.cn/simple](https://pypi.mirrors.ustc.edu.cn/simple) | ✅ 正常 (2405.56ms) | 2 |
| Alibaba Cloud PyPI Mirror | [https://mirrors.aliyun.com/pypi/simple](https://mirrors.aliyun.com/pypi/simple) | ✅ 正常 (220.18ms) | 3 |

#### 📦 Node.js (npm)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| npmmirror (Taobao) | [https://registry.npmmirror.com](https://registry.npmmirror.com) | ✅ 正常 (1836.32ms) | 1 |
| Tencent Cloud NPM Mirror | [https://mirrors.cloud.tencent.com/npm/](https://mirrors.cloud.tencent.com/npm/) | ✅ 正常 (2894.38ms) | 2 |

#### 🐧 Ubuntu (apt)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Ubuntu Mirror | [https://mirrors.tuna.tsinghua.edu.cn/ubuntu/](https://mirrors.tuna.tsinghua.edu.cn/ubuntu/) | ✅ 正常 (1125.2ms) | 1 |
| USTC Ubuntu Mirror | [https://mirrors.ustc.edu.cn/ubuntu/](https://mirrors.ustc.edu.cn/ubuntu/) | ✅ 正常 (2266.02ms) | 2 |

#### 🐳 Docker CE

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Docker CE Mirror | [https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/](https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/) | ✅ 正常 (1125.45ms) | 1 |
| USTC Docker CE Mirror | [https://mirrors.ustc.edu.cn/docker-ce/linux/](https://mirrors.ustc.edu.cn/docker-ce/linux/) | ✅ 正常 (1759.14ms) | 2 |

#### 🐳 Docker Hub

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| HLMirror Docker Hub Mirror | [https://docker.hlmirror.com](https://docker.hlmirror.com) | ✅ 正常 (114.53ms) | 1 |

#### 🦀 Rust (Cargo)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| USTC Rust Crates Mirror | [https://mirrors.ustc.edu.cn/crates.io-index/](https://mirrors.ustc.edu.cn/crates.io-index/) | ✅ 正常 (1426.22ms) | 1 |
| Tsinghua TUNA Rust Crates Mirror | [https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/](https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/) | ✅ 正常 (1265.97ms) | 2 |
| Rust China Community Mirror | [https://rsproxy.cn/crates.io-index/](https://rsproxy.cn/crates.io-index/) | ❌ http_404 (1312.26ms) | 3 |

#### 🍺 Homebrew

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Homebrew Mirror | [https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/](https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/) | ❌ http_404 (678.94ms) | 1 |
| USTC Homebrew Mirror | [https://mirrors.ustc.edu.cn/brew.git](https://mirrors.ustc.edu.cn/brew.git) | ✅ 正常 (1433.09ms) | 2 |

#### 🐍 Conda/Anaconda

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Anaconda Mirror | [https://mirrors.tuna.tsinghua.edu.cn/anaconda/](https://mirrors.tuna.tsinghua.edu.cn/anaconda/) | ✅ 正常 (987.8ms) | 1 |
| USTC Anaconda Mirror | [https://mirrors.ustc.edu.cn/anaconda/](https://mirrors.ustc.edu.cn/anaconda/) | ✅ 正常 (1715.68ms) | 2 |

#### 🐹 Go

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| China Go Module Proxy | [https://goproxy.cn](https://goproxy.cn) | ✅ 正常 (1190.69ms) | 1 |
| USTC Go Module Proxy | [https://goproxy.ustc.edu.cn](https://goproxy.ustc.edu.cn) | ❌ dns_error | 2 |
| Alibaba Cloud Go Module Proxy | [https://mirrors.aliyun.com/goproxy/](https://mirrors.aliyun.com/goproxy/) | ✅ 正常 (480.23ms) | 3 |

#### 📱 Flutter

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Flutter Mirror | [https://mirrors.tuna.tsinghua.edu.cn/flutter/](https://mirrors.tuna.tsinghua.edu.cn/flutter/) | ❌ http_404 (746.51ms) | 1 |
| USTC Flutter Mirror | [https://mirrors.ustc.edu.cn/flutter/](https://mirrors.ustc.edu.cn/flutter/) | ⚠️ http_404 (735.87ms) | 2 |

#### 🐙 GitHub Releases

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA GitHub Release Mirror | [https://mirrors.tuna.tsinghua.edu.cn/github-release/](https://mirrors.tuna.tsinghua.edu.cn/github-release/) | ⚠️ http_404 (706.35ms) | 1 |
| USTC GitHub Release Mirror | [https://mirrors.ustc.edu.cn/github-release/](https://mirrors.ustc.edu.cn/github-release/) | ⚠️ http_404 (800.79ms) | 2 |
| ghfast.top GitHub Proxy | [https://ghfast.top/](https://ghfast.top/) | ✅ 正常 (753.61ms) | 3 |

#### 🐙 GitHub Project Mirrors

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Flutter SDK Git Mirror | [https://mirrors.tuna.tsinghua.edu.cn/git/flutter-sdk.git](https://mirrors.tuna.tsinghua.edu.cn/git/flutter-sdk.git) | ✅ 正常 (7913.59ms) | 1 |
| ghfast.top GitHub Clone Proxy | [https://ghfast.top/](https://ghfast.top/) | ✅ 正常 (775.52ms) | 2 |

#### ☸️ Kubernetes

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Official Kubernetes Registry | [https://registry.k8s.io](https://registry.k8s.io) | ✅ 正常 (83.3ms) | 1 |

#### 🏔️ Alpine Linux

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Alpine Mirror | [https://mirrors.tuna.tsinghua.edu.cn/alpine/](https://mirrors.tuna.tsinghua.edu.cn/alpine/) | ✅ 正常 (679.03ms) | 1 |
| USTC Alpine Mirror | [https://mirrors.ustc.edu.cn/alpine/](https://mirrors.ustc.edu.cn/alpine/) | ✅ 正常 (791.01ms) | 2 |


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
