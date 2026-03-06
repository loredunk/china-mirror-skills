# fix-docker-mirror

## Name

Fix Docker CE Installation Mirror

## Description

Configures Docker CE (Community Edition) installation to use China-based package mirrors. This skill configures where Docker engine packages are downloaded from during installation, NOT Docker Hub image pulls.

⚠️ **IMPORTANT DISTINCTION**:
- **Docker CE Mirror**: Where apt/yum downloads Docker engine packages
- **Docker Hub Registry**: Where `docker pull` gets container images
- These are DIFFERENT and this skill only configures the first one

## When to Use

Use this skill when:
- Installing Docker CE on a new Ubuntu/Debian/CentOS system in China
- `apt-get install docker-ce` is slow or fails
- Docker installation packages download slowly
- You need to set up Docker CE from a China mirror

## Do NOT Use When

- You want to speed up `docker pull` commands (see troubleshooting)
- You need to pull images from Docker Hub (Docker Hub mirrors are deprecated)

## Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| mirror | string | No | Mirror preference: tuna, ustc, aliyun (default: tuna) |
| distro | string | No | Target distro (auto-detected) |
| dry_run | boolean | No | Show what would change without applying (default: false) |

## Steps

### Step 1: Detect Linux Distribution

Check the Linux distribution:
- Ubuntu/Debian: Uses apt
- CentOS/RHEL/Fedora: Uses yum/dnf

### Step 2: Check Prerequisites

Verify requirements:
- Running as root or with sudo
- `curl` and `ca-certificates` installed
- Can modify `/etc/apt/sources.list.d/` or `/etc/yum.repos.d/`

### Step 3: Backup Existing Configuration

Backup existing Docker repository configuration:
- `/etc/apt/sources.list.d/docker.list` (Debian/Ubuntu)
- `/etc/yum.repos.d/docker-ce.repo` (RHEL/CentOS)

### Step 4: Configure Repository

**For Ubuntu/Debian:**

1. Add Docker's GPG key from mirror
2. Add repository to `/etc/apt/sources.list.d/docker.list`
3. Update apt cache

```bash
# Example for Tsinghua mirror
deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu jammy stable
```

**For CentOS/RHEL:**

1. Use `yum-config-manager` to add repository
2. Point to mirror's `docker-ce.repo`

### Step 5: Display Installation Instructions

After configuration, display:
```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io
# or
sudo yum install docker-ce docker-ce-cli containerd.io
```

## Safety Notes

⚠️ **Root Required**: This skill requires root or passwordless sudo

⚠️ **Backup**: Original repository files are backed up

⚠️ **GPG Keys**: Downloads GPG keys from the same mirror for security

⚠️ **Not for Docker Hub**: This does NOT configure image pull acceleration

## Verification

```bash
# Check apt sources
cat /etc/apt/sources.list.d/docker.list

# Check package source
apt-cache policy docker-ce

# Should show the mirror URL, not download.docker.com
```

## Available Mirrors

| Mirror | URL | Priority |
|--------|-----|----------|
| Tsinghua (TUNA) | https://mirrors.tuna.tsinghua.edu.cn/docker-ce | 1 (default) |
| USTC | https://mirrors.ustc.edu.cn/docker-ce | 2 |
| Alibaba Cloud | https://mirrors.aliyun.com/docker-ce | 3 |

## Docker Hub 镜像加速（配置 daemon.json）

Docker Hub 镜像加速通过配置 `/etc/docker/daemon.json` 实现，与 Docker CE 安装源完全独立。

**推荐配置（经验证可用）**：

```json
{
  "registry-mirrors": [
    "https://docker.hlmirror.com"
  ],
  "dns": ["1.1.1.1", "8.8.8.8"]
}
```

**配置步骤**：

```bash
# 创建或编辑 /etc/docker/daemon.json
sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "registry-mirrors": [
    "https://docker.hlmirror.com"
  ],
  "dns": ["1.1.1.1", "8.8.8.8"]
}
EOF

# 重启 Docker 使配置生效
sudo systemctl restart docker

# 验证配置已生效
docker info | grep -A 2 "Registry Mirrors"
```

**验证镜像加速是否生效**：

```bash
# 拉取测试镜像，观察速度
docker pull hello-world
```

> ⚠️ **注意**：配置前先备份原有 daemon.json：
> ```bash
> sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak 2>/dev/null || true
> ```

## Docker Hub Image Pulls (Important Notice)

⚠️ Docker Hub image registry mirrors in China are largely **deprecated** due to Docker policy changes:

- Docker Hub mirror services from TUNA, USTC, and others are discontinued or unreliable
- `k8s.gcr.io` has been **frozen** and migrated to `registry.k8s.io` (March 2023)

**Alternatives for Docker Hub image pulls:**

1. **Use alternative registries** when available:
   ```bash
   # Instead of docker pull nginx
   docker pull m.daocloud.io/docker.io/library/nginx
   ```

2. **Configure Docker daemon with proxy** (not mirror)

3. **Use registry proxies** (different from mirrors)

See `docs/troubleshooting.md` for detailed migration guide.

## Examples

### Example 1: Install Docker CE

```
"Install Docker CE from China mirror"
"Setup Docker installation from Tsinghua mirror"
```

### Example 2: Specific Mirror

```
"Configure Docker CE repository to use USTC"
```

## Troubleshooting

### Issue: GPG key error

**Symptom**: `GPG error: NO_PUBKEY` or key verification fails

**Fix**:
```bash
# Re-add GPG key
sudo rm /etc/apt/keyrings/docker.asc
curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.asc
```

### Issue: Repository not found

**Symptom**: `E: Unable to locate package docker-ce`

**Fix**: Check distribution codename matches:
```bash
lsb_release -cs  # Should match repo line
```

### Issue: Docker pull still slow

**Symptom**: `docker pull nginx` is slow (this is expected!)

**Explanation**: This skill configures Docker CE installation, NOT Docker Hub image pulls.

**See**: Docker Hub section above and `docs/troubleshooting.md`

## Rollback

```bash
# Using restore script
sudo ./scripts/restore_config.sh --tool docker --latest

# Or manually remove
sudo rm /etc/apt/sources.list.d/docker.list
sudo apt-get update
```

## Implementation

```bash
sudo ./scripts/setup_docker.sh --mirror <mirror>
```
