# 🇨🇳 China Mirror Skills

<p align="center">
  <strong>强烈推荐用agent来干安装环境的脏活, 用本skills让agent少走弯路。</strong>
</p>

<p align="center">
  <a href="#安装">安装</a> •
  <a href="#支持的工具">支持的工具</a> •
  <a href="#镜像源">镜像源</a>
</p>

---

## 目录

- [支持的工具](#支持的工具)
- [安装](#安装)
- [镜像源](#镜像源)
- [安全与风险](#安全与风险)

---

---

## 支持的工具

| 分类 | 工具 | 状态 | 镜像类型 |
|------|------|------|----------|
| 🐍 Python (pip) | pip, uv, poetry | ✅ 可用 | Package Index |
| 📦 Node.js (npm) | npm, pnpm, yarn | ✅ 可用 | Package Index |
| 🐳 Docker Hub | Docker Hub（镜像加速） | ✅ 可用 | Registry Mirror |
| 🦀 Rust (Cargo) | Cargo | ✅ 可用 | Package Index |
| 🍺 Homebrew | Homebrew | ✅ 可用 | Git Repository |
| 🐍 Conda/Anaconda | Conda/Anaconda | ✅ 可用 | Package Index |
| 🐹 Go | Go modules | ✅ 可用 | Module Proxy |
| 📱 Flutter | Flutter SDK | ✅ 可用 | SDK Mirror |
| 🐳 Docker CE | Docker CE install | ✅ 可用 | 安装源 |
| 🐍 Python（安装本体） | python-install | ✅ 可用 | 说明 |
| 📦 Node.js（安装本体） | node-install | ✅ 可用 | 说明 |
| 🐍 Conda/Miniconda（安装本体） | conda-install | ✅ 可用 | 说明 |
| 🦀 Rust/rustup（安装本体） | rust-install | ✅ 可用 | 说明 |
| 🐹 Go（安装本体） | go-install | ✅ 可用 | 说明 |
| 🐙 GitHub Releases | GitHub Releases | ✅ 可用 | Release Asset Mirror |
| 🐙 GitHub Clone Acceleration | GitHub 仓库 clone 加速 | ✅ 可用 | Git Repository |
| 🤗 Hugging Face | Hugging Face models / datasets | ✅ 可用 | Model / Dataset Mirror |
| 🐧 Ubuntu (apt) | ubuntu | ✅ 可用 | APT Repository |
| 🏔️ Alpine Linux | alpine | ✅ 可用 | APT Repository |

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

### 对于其他agent

- **OpenCode** — 将 `china-mirror/skills/china-mirror` 复制到 OpenCode 的 skills 存储路径
- **OpenClaw** — 将 `china-mirror/skills/china-mirror` 复制到 `~/.openclaw/skills/china-mirror`（全局）或当前工作区的 `skills/china-mirror`（项目级）
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

_镜像数据最后更新: 2026-03-12_
_健康检查时间: 2026-04-17T01:25:54.493028Z_

**汇总**: 30/36 个镜像可用（83.33%）

**报警分类**: docker-hub

_有健康检查报告时，下表按每日健康检查结果动态排序；无报告时回退到静态优先级。_

#### 🐍 Python (pip)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Alibaba Cloud PyPI Mirror | [https://mirrors.aliyun.com/pypi/simple](https://mirrors.aliyun.com/pypi/simple) | ✅ 正常 (204.93ms) | 3 |
| Tsinghua TUNA PyPI Mirror | [https://pypi.tuna.tsinghua.edu.cn/simple](https://pypi.tuna.tsinghua.edu.cn/simple) | ✅ 正常 (1575.55ms) | 1 |
| USTC PyPI Mirror | [https://pypi.mirrors.ustc.edu.cn/simple](https://pypi.mirrors.ustc.edu.cn/simple) | ✅ 正常 (3188.17ms) | 2 |

#### 📦 Node.js (npm)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| npmmirror (Taobao) | [https://registry.npmmirror.com](https://registry.npmmirror.com) | ✅ 正常 (1436.64ms) | 1 |
| Tencent Cloud NPM Mirror | [https://mirrors.cloud.tencent.com/npm/](https://mirrors.cloud.tencent.com/npm/) | ✅ 正常 (2415.37ms) | 2 |

#### 🐳 Docker Hub

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| HLMirror Docker Hub Mirror | [https://docker.hlmirror.com](https://docker.hlmirror.com) | ❌ http_401 (1108.3ms) | 1 |

#### 🦀 Rust (Cargo)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| USTC Rust Crates Mirror | [https://mirrors.ustc.edu.cn/crates.io-index/](https://mirrors.ustc.edu.cn/crates.io-index/) | ✅ 正常 (1845.56ms) | 1 |
| Tsinghua TUNA Rust Crates Mirror | [https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/](https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/) | ✅ 正常 (2137.74ms) | 2 |

#### 🍺 Homebrew

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| USTC Homebrew Mirror | [https://mirrors.ustc.edu.cn/brew.git](https://mirrors.ustc.edu.cn/brew.git) | ✅ 正常 (830.08ms) | 2 |
| Tsinghua TUNA Homebrew Mirror | [https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/](https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/) | ❌ http_404 (1515.63ms) | 1 |

#### 🐍 Conda/Anaconda

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| USTC Anaconda Mirror | [https://mirrors.ustc.edu.cn/anaconda/](https://mirrors.ustc.edu.cn/anaconda/) | ✅ 正常 (755.67ms) | 2 |
| Tsinghua TUNA Anaconda Mirror | [https://mirrors.tuna.tsinghua.edu.cn/anaconda/](https://mirrors.tuna.tsinghua.edu.cn/anaconda/) | ✅ 正常 (849.57ms) | 1 |

#### 🐹 Go

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Alibaba Cloud Go Module Proxy | [https://mirrors.aliyun.com/goproxy/](https://mirrors.aliyun.com/goproxy/) | ✅ 正常 (403.02ms) | 2 |
| China Go Module Proxy | [https://goproxy.cn](https://goproxy.cn) | ✅ 正常 (890.38ms) | 1 |

#### 📱 Flutter

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| CFUG Flutter Mirror | [https://storage.flutter-io.cn](https://storage.flutter-io.cn) | ✅ 正常 (764.37ms) | 1 |

#### 🐳 Docker CE

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| USTC Docker CE Mirror | [https://mirrors.ustc.edu.cn/docker-ce/linux/](https://mirrors.ustc.edu.cn/docker-ce/linux/) | ✅ 正常 (2038.56ms) | 2 |
| Tsinghua TUNA Docker CE Mirror | [https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/](https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/) | ✅ 正常 (2633.95ms) | 1 |

#### 🐍 Python（安装本体）

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Huawei Cloud Python Releases Mirror | [https://mirrors.huaweicloud.com/python/](https://mirrors.huaweicloud.com/python/) | ✅ 正常 (1000.77ms) | 1 |
| Tsinghua TUNA Python Releases Mirror | [https://mirrors.tuna.tsinghua.edu.cn/python-release/](https://mirrors.tuna.tsinghua.edu.cn/python-release/) | ❌ http_404 (907.07ms) | 2 |

#### 📦 Node.js（安装本体）

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Node.js Mirror | [https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/](https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/) | ✅ 正常 (1178.48ms) | 2 |
| npmmirror Node.js Binary Mirror | [https://npmmirror.com/mirrors/node/](https://npmmirror.com/mirrors/node/) | ✅ 正常 (1329.53ms) | 1 |

#### 🐍 Conda/Miniconda（安装本体）

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| USTC Miniconda Installer Mirror | [https://mirrors.ustc.edu.cn/anaconda/miniconda/](https://mirrors.ustc.edu.cn/anaconda/miniconda/) | ✅ 正常 (1182.23ms) | 2 |
| Tsinghua TUNA Miniconda Installer Mirror | [https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/](https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/) | ✅ 正常 (1245.18ms) | 1 |

#### 🦀 Rust/rustup（安装本体）

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Rustup Mirror | [https://mirrors.tuna.tsinghua.edu.cn/rustup](https://mirrors.tuna.tsinghua.edu.cn/rustup) | ✅ 正常 (882.34ms) | 1 |
| USTC Rust Static Mirror | [https://mirrors.ustc.edu.cn/rust-static](https://mirrors.ustc.edu.cn/rust-static) | ✅ 正常 (1436.48ms) | 2 |

#### 🐹 Go（安装本体）

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Alibaba Cloud Go Binary Mirror | [https://mirrors.aliyun.com/golang/](https://mirrors.aliyun.com/golang/) | ✅ 正常 (1511.71ms) | 2 |
| Tsinghua TUNA Go Binary Mirror | [https://mirrors.tuna.tsinghua.edu.cn/golang/](https://mirrors.tuna.tsinghua.edu.cn/golang/) | ❌ http_404 (846.58ms) | 1 |

#### 🐙 GitHub Releases

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| ghfast.top GitHub Proxy | [https://ghfast.top/](https://ghfast.top/) | ✅ 正常 (545.25ms) | 3 |
| USTC GitHub Release Mirror | [https://mirrors.ustc.edu.cn/github-release/](https://mirrors.ustc.edu.cn/github-release/) | ⚠️ http_404 (756.09ms) | 2 |
| Tsinghua TUNA GitHub Release Mirror | [https://mirrors.tuna.tsinghua.edu.cn/github-release/](https://mirrors.tuna.tsinghua.edu.cn/github-release/) | ⚠️ http_404 (908.14ms) | 1 |

#### 🐙 GitHub Clone Acceleration

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| ghfast.top GitHub Clone Proxy | [https://ghfast.top/](https://ghfast.top/) | ✅ 正常 (670.07ms) | 1 |

#### 🤗 Hugging Face

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| hf-mirror Hugging Face Mirror | [https://hf-mirror.com](https://hf-mirror.com) | ✅ 正常 (544.67ms) | 1 |

#### 🐧 Ubuntu (apt)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| USTC Ubuntu Mirror | [https://mirrors.ustc.edu.cn/ubuntu/](https://mirrors.ustc.edu.cn/ubuntu/) | ✅ 正常 (775.34ms) | 2 |
| Tsinghua TUNA Ubuntu Mirror | [https://mirrors.tuna.tsinghua.edu.cn/ubuntu/](https://mirrors.tuna.tsinghua.edu.cn/ubuntu/) | ✅ 正常 (2635.99ms) | 1 |

#### 🏔️ Alpine Linux

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| USTC Alpine Mirror | [https://mirrors.ustc.edu.cn/alpine/](https://mirrors.ustc.edu.cn/alpine/) | ✅ 正常 (796.74ms) | 2 |
| Tsinghua TUNA Alpine Mirror | [https://mirrors.tuna.tsinghua.edu.cn/alpine/](https://mirrors.tuna.tsinghua.edu.cn/alpine/) | ✅ 正常 (904.22ms) | 1 |


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
