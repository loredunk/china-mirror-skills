# 🇨🇳 China Mirror Skills

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
| ☸️ Kubernetes | K8s registry | ✅ 可用 | 说明 |
| 🏔️ Alpine Linux | alpine | ✅ 可用 | APT Repository |

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

- Bash 4.0+
- Linux（推荐）或 macOS（部分支持）

### 快速配置（直接使用脚本）

```bash
# 克隆项目
git clone https://github.com/yourusername/china-mirror-skills.git
cd china-mirror-skills

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

## AI 编程助手使用方式

本项目提供的 skills 可在主流 AI 编程助手中使用，让 AI 直接帮你完成镜像配置。

### Claude Code

将 skills 复制到 Claude Code 全局 skills 目录：

```bash
# 克隆项目
git clone https://github.com/yourusername/china-mirror-skills.git

# 将所有 skills 安装到 Claude Code 全局目录
cp -r china-mirror-skills/skills/* ~/.claude/skills/
```

然后直接向 Claude Code 提问：

```
"帮我配置适合中国网络的开发环境"
"pip install 太慢了，帮我配置国内镜像"
"诊断我的开发环境网络问题"
```

### OpenCode

将本项目目录加入 OpenCode 的 skills 路径配置（参考 OpenCode 文档），
或将 `skills/` 中的各目录复制到 OpenCode 对应的 skills 存储路径。

### Codex / 其他兼容工具

对于支持自定义 skills/instructions 目录的工具，将 `skills/` 下各子目录
（每个包含一个 `SKILL.md`）放入工具对应的 skills 目录即可。

### 可用 Skills

| Skill | 触发场景 |
|-------|---------|
| `bootstrap-china-network` | 全部工具一次性配置，新机器初始化 |
| `diagnose-network-environment` | 诊断网络问题，不做修改 |
| `fix-python-mirror` | pip / uv / poetry 慢或超时 |
| `fix-node-mirror` | npm / yarn / pnpm 慢或超时 |
| `fix-docker-mirror` | Docker CE 安装慢 / docker pull 慢 |
| `fix-apt-mirror` | apt update / install 慢 |
| `fix-homebrew-mirror` | brew update / install 慢 |
| `fix-conda-mirror` | conda install / create 慢 |
| `fix-rust-mirror` | cargo build 下载依赖慢 |
| `fix-go-proxy` | go mod download / go get 慢 |
| `fix-flutter-mirror` | flutter packages get / pub get 慢 |

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

_镜像数据最后更新: 2025-03-06_
_健康检查时间: 2026-03-06T07:26:17.375564Z_

**汇总**: 17/25 个镜像可用（68.0%）

#### 🐍 Python (pip)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA PyPI Mirror | [https://pypi.tuna.tsinghua.edu.cn/simple](https://pypi.tuna.tsinghua.edu.cn/simple) | ✅ 正常 (2134.18ms) | 1 |
| USTC PyPI Mirror | [https://pypi.mirrors.ustc.edu.cn/simple](https://pypi.mirrors.ustc.edu.cn/simple) | ✅ 正常 (2982.75ms) | 2 |
| Alibaba Cloud PyPI Mirror | [https://mirrors.aliyun.com/pypi/simple](https://mirrors.aliyun.com/pypi/simple) | ✅ 正常 (525.22ms) | 3 |

#### 📦 Node.js (npm)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| npmmirror (Taobao) | [https://registry.npmmirror.com](https://registry.npmmirror.com) | ✅ 正常 (2542.44ms) | 1 |
| Tencent Cloud NPM Mirror | [https://mirrors.cloud.tencent.com/npm/](https://mirrors.cloud.tencent.com/npm/) | ✅ 正常 (2112.27ms) | 2 |

#### 🐧 Ubuntu (apt)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Ubuntu Mirror | [https://mirrors.tuna.tsinghua.edu.cn/ubuntu/](https://mirrors.tuna.tsinghua.edu.cn/ubuntu/) | ✅ 正常 (2536.35ms) | 1 |
| USTC Ubuntu Mirror | [https://mirrors.ustc.edu.cn/ubuntu/](https://mirrors.ustc.edu.cn/ubuntu/) | ✅ 正常 (1141.57ms) | 2 |

#### 🐳 Docker CE

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Docker CE Mirror | [https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/](https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/) | ✅ 正常 (2531.26ms) | 1 |
| USTC Docker CE Mirror | [https://mirrors.ustc.edu.cn/docker-ce/linux/](https://mirrors.ustc.edu.cn/docker-ce/linux/) | ✅ 正常 (2128.38ms) | 2 |

#### 🐳 Docker Hub

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| HLMirror Docker Hub Mirror | [https://docker.hlmirror.com](https://docker.hlmirror.com) | ✅ 正常 (96.74ms) | 1 |

#### 🦀 Rust (Cargo)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| USTC Rust Crates Mirror | [https://mirrors.ustc.edu.cn/crates.io-index/](https://mirrors.ustc.edu.cn/crates.io-index/) | ✅ 正常 (1869.95ms) | 1 |
| Tsinghua TUNA Rust Crates Mirror | [https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/](https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/) | ✅ 正常 (2346.53ms) | 2 |
| Rust China Community Mirror | [https://rsproxy.cn/crates.io-index/](https://rsproxy.cn/crates.io-index/) | ❌ unexpected_status (1746.2ms) | 3 |

#### 🍺 Homebrew

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Homebrew Mirror | [https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/](https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/) | ❌ unexpected_status (997.92ms) | 1 |
| USTC Homebrew Mirror | [https://mirrors.ustc.edu.cn/brew.git](https://mirrors.ustc.edu.cn/brew.git) | ✅ 正常 (896.34ms) | 2 |

#### 🐍 Conda/Anaconda

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Anaconda Mirror | [https://mirrors.tuna.tsinghua.edu.cn/anaconda/](https://mirrors.tuna.tsinghua.edu.cn/anaconda/) | ✅ 正常 (986.02ms) | 1 |
| USTC Anaconda Mirror | [https://mirrors.ustc.edu.cn/anaconda/](https://mirrors.ustc.edu.cn/anaconda/) | ✅ 正常 (1364.14ms) | 2 |

#### 🐹 Go

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| China Go Module Proxy | [https://goproxy.cn](https://goproxy.cn) | ❌ unexpected_status (1998.18ms) | 1 |
| USTC Go Module Proxy | [https://goproxy.ustc.edu.cn](https://goproxy.ustc.edu.cn) | ❌ connection_error | 2 |
| Alibaba Cloud Go Module Proxy | [https://mirrors.aliyun.com/goproxy/](https://mirrors.aliyun.com/goproxy/) | ❌ unexpected_status (681.43ms) | 3 |

#### 📱 Flutter

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Flutter Mirror | [https://mirrors.tuna.tsinghua.edu.cn/flutter/](https://mirrors.tuna.tsinghua.edu.cn/flutter/) | ❌ unexpected_status (1040.11ms) | 1 |
| USTC Flutter Mirror | [https://mirrors.ustc.edu.cn/flutter/](https://mirrors.ustc.edu.cn/flutter/) | ❌ unexpected_status (1213.8ms) | 2 |

#### ☸️ Kubernetes

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Official Kubernetes Registry | [https://registry.k8s.io](https://registry.k8s.io) | ❌ unexpected_status (63.08ms) | 1 |

#### 🏔️ Alpine Linux

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Alpine Mirror | [https://mirrors.tuna.tsinghua.edu.cn/alpine/](https://mirrors.tuna.tsinghua.edu.cn/alpine/) | ✅ 正常 (1052.6ms) | 1 |
| USTC Alpine Mirror | [https://mirrors.ustc.edu.cn/alpine/](https://mirrors.ustc.edu.cn/alpine/) | ✅ 正常 (897.82ms) | 2 |


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
