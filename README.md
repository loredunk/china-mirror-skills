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

_镜像数据最后更新: 2026-05-08_
_健康检查时间: 2026-05-09T01:54:00.178003Z_

**汇总**: 37/38 个镜像可用（97.37%）

_有健康检查报告时，下表按每日健康检查结果动态排序；无报告时回退到静态优先级。_

> 💡 **不想安装 Skill？** 每个分类下方都附了 `🚀 不安装 Skill 也能用` 折叠块，
> 展开复制里面的命令即可临时切换到推荐镜像（默认是健康检查得分最高的那一个）。
> 如果需要同时管理多个工具、自动备份回滚、检测代理冲突，再考虑安装本仓库 Skill。

#### 🐍 Python (pip)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Alibaba Cloud PyPI Mirror | [https://mirrors.aliyun.com/pypi/simple](https://mirrors.aliyun.com/pypi/simple) | ✅ 正常 (341.06ms) | 3 |
| Tsinghua TUNA PyPI Mirror | [https://pypi.tuna.tsinghua.edu.cn/simple](https://pypi.tuna.tsinghua.edu.cn/simple) | ✅ 正常 (3119.64ms) | 1 |
| USTC PyPI Mirror | [https://pypi.mirrors.ustc.edu.cn/simple](https://pypi.mirrors.ustc.edu.cn/simple) | ✅ 正常 (4532.19ms) | 2 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>Alibaba Cloud PyPI Mirror</b>）</summary>

```bash
# 一次性使用（仅当前命令）
pip install -i https://mirrors.aliyun.com/pypi/simple <package>

# 当前 shell 生效（关闭终端后失效）
export PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple

# 永久写入用户配置
pip config set global.index-url https://mirrors.aliyun.com/pypi/simple
```

</details>

#### 📦 Node.js (npm)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| npmmirror (Taobao) | [https://registry.npmmirror.com](https://registry.npmmirror.com) | ✅ 正常 (2494.12ms) | 1 |
| Tencent Cloud NPM Mirror | [https://mirrors.cloud.tencent.com/npm/](https://mirrors.cloud.tencent.com/npm/) | ✅ 正常 (2782.11ms) | 2 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>npmmirror (Taobao)</b>）</summary>

```bash
# 一次性使用
npm install --registry=https://registry.npmmirror.com <package>

# 当前 shell 生效
export NPM_CONFIG_REGISTRY=https://registry.npmmirror.com

# 永久写入用户配置（~/.npmrc）
npm config set registry https://registry.npmmirror.com
# yarn / pnpm 同样的命令把 npm 换成对应工具即可
```

</details>

#### 🐳 Docker Hub

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| DaoCloud Docker Hub Mirror | [https://docker.m.daocloud.io](https://docker.m.daocloud.io) | ✅ 正常 (907.36ms) | 2 |
| 1ms.run Docker Hub Mirror | [https://docker.1ms.run](https://docker.1ms.run) | ✅ 正常 (1287.16ms) | 1 |
| HLMirror Docker Hub Mirror | [https://docker.hlmirror.com](https://docker.hlmirror.com) | ⚠️ 已废弃 (1552.21ms) | 9 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>DaoCloud Docker Hub Mirror</b>）</summary>

> Docker daemon 不读环境变量，必须写入 `daemon.json` 后重启 Docker 才生效。

Linux：
```bash
sudo mkdir -p /etc/docker
echo '{"registry-mirrors": ["https://docker.m.daocloud.io"]}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
```

macOS / Windows：在 Docker Desktop → Settings → Docker Engine 里填
```json
{ "registry-mirrors": ["https://docker.m.daocloud.io"] }
```

</details>

#### 🦀 Rust (Cargo)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Rust Crates Mirror | [https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/](https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/) | ✅ 正常 (1247.66ms) | 2 |
| USTC Rust Crates Mirror | [https://mirrors.ustc.edu.cn/crates.io-index/](https://mirrors.ustc.edu.cn/crates.io-index/) | ✅ 正常 (3209.77ms) | 1 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>Tsinghua TUNA Rust Crates Mirror</b>）</summary>

```bash
# 永久写入用户配置（~/.cargo/config.toml）
mkdir -p ~/.cargo
cat >> ~/.cargo/config.toml <<'EOF'
[source.crates-io]
replace-with = "mirror"

[source.mirror]
registry = "sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/"
EOF
```
> 需要 cargo 1.68+ 才支持 sparse 协议；老版本去掉 `sparse+` 前缀。

</details>

#### 🍺 Homebrew

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Homebrew Mirror | [https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/](https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/) | ✅ 正常 (921.8ms) | 1 |
| USTC Homebrew Mirror | [https://mirrors.ustc.edu.cn/brew.git](https://mirrors.ustc.edu.cn/brew.git) | ✅ 正常 (2611.99ms) | 2 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>Tsinghua TUNA Homebrew Mirror</b>）</summary>

> Homebrew 涉及 4 个环境变量，且不同镜像的子路径不同，复制时请参考
> [Tsinghua TUNA Homebrew Mirror 官方帮助页](https://mirrors.tuna.tsinghua.edu.cn/help/homebrew/)。下面以最常用的两个为例：

```bash
# 当前 shell 生效（USTC 风格）
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
```

</details>

#### 🐍 Conda/Anaconda

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Anaconda Mirror | [https://mirrors.tuna.tsinghua.edu.cn/anaconda/](https://mirrors.tuna.tsinghua.edu.cn/anaconda/) | ✅ 正常 (1010.01ms) | 1 |
| USTC Anaconda Mirror | [https://mirrors.ustc.edu.cn/anaconda/](https://mirrors.ustc.edu.cn/anaconda/) | ✅ 正常 (2834.92ms) | 2 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>Tsinghua TUNA Anaconda Mirror</b>）</summary>

```bash
# 一次性使用（仅当前命令）
conda install -c https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main <package>

# 永久写入 ~/.condarc
conda config --remove-key channels 2>/dev/null || true
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge
conda config --set show_channel_urls yes
```

</details>

#### 🐹 Go

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| China Go Module Proxy | [https://goproxy.cn](https://goproxy.cn) | ✅ 正常 (674.48ms) | 1 |
| Alibaba Cloud Go Module Proxy | [https://mirrors.aliyun.com/goproxy/](https://mirrors.aliyun.com/goproxy/) | ✅ 正常 (809.42ms) | 2 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>China Go Module Proxy</b>）</summary>

```bash
# 一次性使用（仅当前命令）
GOPROXY=https://goproxy.cn,direct go mod tidy

# 当前 shell 生效
export GOPROXY=https://goproxy.cn,direct

# 永久写入 go env
go env -w GOPROXY=https://goproxy.cn,direct
```

</details>

#### 📱 Flutter

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| CFUG Flutter Mirror | [https://storage.flutter-io.cn](https://storage.flutter-io.cn) | ✅ 正常 (467.96ms) | 1 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>CFUG Flutter Mirror</b>）</summary>

```bash
# 当前 shell 生效（Flutter 官方中国网络配置）
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 永久写入 shell profile
echo 'export PUB_HOSTED_URL=https://pub.flutter-io.cn' >> ~/.zshrc
echo 'export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn' >> ~/.zshrc
```

</details>

#### 🐳 Docker CE

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Docker CE Mirror | [https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/](https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/) | ✅ 正常 (1190.04ms) | 1 |
| USTC Docker CE Mirror | [https://mirrors.ustc.edu.cn/docker-ce/linux/](https://mirrors.ustc.edu.cn/docker-ce/linux/) | ✅ 正常 (7386.72ms) | 2 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>Tsinghua TUNA Docker CE Mirror</b>）</summary>

> 把官方 Docker apt 源里的域名替换成镜像域名（Ubuntu/Debian 通用）。

```bash
# 已安装 docker-ce 的系统，把 sources.list.d 里的 download.docker.com 替换为镜像
sudo sed -i.bak 's|download.docker.com|mirrors.tuna.tsinghua.edu.cn/docker-ce|g' \
  /etc/apt/sources.list.d/docker.list
sudo apt update
```

</details>

#### 🐍 Python（安装本体）

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Python Releases Mirror | [https://mirrors.tuna.tsinghua.edu.cn/python/](https://mirrors.tuna.tsinghua.edu.cn/python/) | ✅ 正常 (1016.34ms) | 2 |
| Huawei Cloud Python Releases Mirror | [https://mirrors.huaweicloud.com/python/](https://mirrors.huaweicloud.com/python/) | ✅ 正常 (1256.52ms) | 1 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>Tsinghua TUNA Python Releases Mirror</b>）</summary>

```bash
# 当前 shell 生效（让 pyenv 从国内镜像下载 Python 源码包）
export PYTHON_BUILD_MIRROR_URL=https://mirrors.tuna.tsinghua.edu.cn/python/
pyenv install 3.12.0
```

</details>

#### 📦 Node.js（安装本体）

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Node.js Mirror | [https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/](https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/) | ✅ 正常 (1329.56ms) | 2 |
| npmmirror Node.js Binary Mirror | [https://npmmirror.com/mirrors/node/](https://npmmirror.com/mirrors/node/) | ✅ 正常 (1399.4ms) | 1 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>Tsinghua TUNA Node.js Mirror</b>）</summary>

```bash
# 当前 shell 生效（让 nvm 从国内镜像下载 Node.js 二进制）
export NVM_NODEJS_ORG_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/
nvm install 20

# fnm 用户改为
export FNM_NODE_DIST_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/
```

</details>

#### 🐍 Conda/Miniconda（安装本体）

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Miniconda Installer Mirror | [https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/](https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/) | ✅ 正常 (1455.8ms) | 1 |
| USTC Miniconda Installer Mirror | [https://mirrors.ustc.edu.cn/anaconda/miniconda/](https://mirrors.ustc.edu.cn/anaconda/miniconda/) | ✅ 正常 (2241.44ms) | 2 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>Tsinghua TUNA Miniconda Installer Mirror</b>）</summary>

```bash
# Linux x86_64：直接下载并安装 Miniconda
wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

</details>

#### 🦀 Rust/rustup（安装本体）

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Rustup Mirror | [https://mirrors.tuna.tsinghua.edu.cn/rustup](https://mirrors.tuna.tsinghua.edu.cn/rustup) | ✅ 正常 (1009.18ms) | 1 |
| USTC Rust Static Mirror | [https://mirrors.ustc.edu.cn/rust-static](https://mirrors.ustc.edu.cn/rust-static) | ✅ 正常 (1673.61ms) | 2 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>Tsinghua TUNA Rustup Mirror</b>）</summary>

```bash
# 当前 shell 生效（rustup 安装/更新走国内镜像）
export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
export RUSTUP_UPDATE_ROOT=https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

</details>

#### 🐹 Go（安装本体）

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Alibaba Cloud Go Binary Mirror | [https://mirrors.aliyun.com/golang/](https://mirrors.aliyun.com/golang/) | ✅ 正常 (4045.41ms) | 1 |
| Tsinghua TUNA Go Binary Mirror | [https://mirrors.tuna.tsinghua.edu.cn/golang/](https://mirrors.tuna.tsinghua.edu.cn/golang/) | ⚠️ 已废弃 (1011.47ms) | 9 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>Alibaba Cloud Go Binary Mirror</b>）</summary>

```bash
# Linux x86_64：直接下载并解压 Go
wget https://mirrors.aliyun.com/golang/go1.22.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
```

</details>

#### 🐙 GitHub Releases

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| ghfast.top GitHub Proxy | [https://ghfast.top/](https://ghfast.top/) | ✅ 正常 (721.83ms) | 3 |
| Tsinghua TUNA GitHub Release Mirror | [https://mirrors.tuna.tsinghua.edu.cn/github-release/](https://mirrors.tuna.tsinghua.edu.cn/github-release/) | ✅ 正常 (994.9ms) | 1 |
| USTC GitHub Release Mirror | [https://mirrors.ustc.edu.cn/github-release/](https://mirrors.ustc.edu.cn/github-release/) | ✅ 正常 (1646.86ms) | 2 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>ghfast.top GitHub Proxy</b>）</summary>

```bash
# ghfast 通用代理：在原始 GitHub URL 前面拼接前缀即可
curl -L -O https://ghfast.top/https://github.com/<owner>/<repo>/releases/download/<tag>/<asset>

# TUNA / USTC 选择性镜像：把 https://github.com 替换为镜像前缀（仅收录的仓库可用）
# 例：https://mirrors.tuna.tsinghua.edu.cn/github-release/git-for-windows/git/...
```

</details>

#### 🐙 GitHub Clone Acceleration

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| ghfast.top GitHub Clone Proxy | [https://ghfast.top/](https://ghfast.top/) | ✅ 正常 (1901.39ms) | 1 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>ghfast.top GitHub Clone Proxy</b>）</summary>

```bash
# 一次性使用（仅这一次 clone）
git clone https://ghfast.top/https://github.com/<owner>/<repo>.git

# 永久重写：让 git 把所有 github.com 的 clone 自动走镜像
git config --global url."https://ghfast.top/https://github.com/".insteadOf "https://github.com/"
```

</details>

#### 🤗 Hugging Face

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| hf-mirror Hugging Face Mirror | [https://hf-mirror.com](https://hf-mirror.com) | ✅ 正常 (2751.64ms) | 1 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>hf-mirror Hugging Face Mirror</b>）</summary>

```bash
# 推荐：仅当前命令注入镜像（最安全，不污染环境）
HF_ENDPOINT=https://hf-mirror.com huggingface-cli download gpt2

# 当前 shell 生效
export HF_ENDPOINT=https://hf-mirror.com
```
> 不建议把 `HF_ENDPOINT` 写入 shell profile，会持续把流量导向镜像。

</details>

#### 🐧 Ubuntu (apt)

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Ubuntu Mirror | [https://mirrors.tuna.tsinghua.edu.cn/ubuntu/](https://mirrors.tuna.tsinghua.edu.cn/ubuntu/) | ✅ 正常 (1204.01ms) | 1 |
| USTC Ubuntu Mirror | [https://mirrors.ustc.edu.cn/ubuntu/](https://mirrors.ustc.edu.cn/ubuntu/) | ✅ 正常 (4336.12ms) | 2 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>Tsinghua TUNA Ubuntu Mirror</b>）</summary>

```bash
# Ubuntu 24.04+（DEB822 格式）
sudo sed -i.bak 's|http://archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g; s|http://security.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' \
  /etc/apt/sources.list.d/ubuntu.sources

# Ubuntu 22.04 及以前
sudo sed -i.bak 's|http://archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g; s|http://security.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' \
  /etc/apt/sources.list

sudo apt update
```
> sed 第一次运行会备份原文件到同名 `.bak`，便于回滚。

</details>

#### 🏔️ Alpine Linux

| 镜像名称 | 地址 | 状态 | 优先级 |
|---------|------|------|--------|
| Tsinghua TUNA Alpine Mirror | [https://mirrors.tuna.tsinghua.edu.cn/alpine/](https://mirrors.tuna.tsinghua.edu.cn/alpine/) | ✅ 正常 (976.47ms) | 1 |
| USTC Alpine Mirror | [https://mirrors.ustc.edu.cn/alpine/](https://mirrors.ustc.edu.cn/alpine/) | ✅ 正常 (1626.13ms) | 2 |

<details>
<summary>🚀 不安装 Skill 也能用：复制下面这段（推荐镜像：<b>Tsinghua TUNA Alpine Mirror</b>）</summary>

```bash
sudo sed -i.bak 's|dl-cdn.alpinelinux.org|mirrors.tuna.tsinghua.edu.cn|g' /etc/apk/repositories
sudo apk update
```

</details>


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
