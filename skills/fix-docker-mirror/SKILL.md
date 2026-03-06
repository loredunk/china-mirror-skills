---
name: fix-docker-mirror
description: |
  Configure Docker in China: (1) Docker CE installation — replace the official apt/yum repo with a
  China mirror (TUNA, USTC) so docker-ce packages download fast; (2) Docker Hub image acceleration —
  configure /etc/docker/daemon.json with registry-mirrors so docker pull is faster. Use this skill
  whenever installing Docker CE is slow in China, docker-ce packages fail to download, docker pull
  is slow, or the user wants to set up Docker on a Linux server in China. If the user says
  "安装 docker 太慢", "docker pull 好慢", or similar, always use this skill.
---

# Configure Docker Mirrors

This skill handles two distinct Docker mirror scenarios. Clarify with the user which they need,
or apply both if setting up Docker from scratch.

## Scenario A: Docker CE Installation Mirror (apt/yum repo)

Configures where `apt-get install docker-ce` downloads packages from.

**1. Detect distribution**
```bash
source /etc/os-release && echo "ID=$ID VERSION_CODENAME=$VERSION_CODENAME"
```

**2. Run the setup script** (requires sudo):
```bash
sudo ./scripts/setup_docker.sh --mirror <tuna|ustc|aliyun>
```

**3. Install Docker CE**:
```bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

**4. Verify repo source**:
```bash
cat /etc/apt/sources.list.d/docker.list
apt-cache policy docker-ce   # URL should show mirror, not download.docker.com
```

## Scenario B: Docker Hub Image Acceleration (daemon.json)

Configures where `docker pull` fetches container images from.

**Write `/etc/docker/daemon.json`**:
```json
{
  "registry-mirrors": [
    "https://docker.hlmirror.com"
  ],
  "dns": ["1.1.1.1", "8.8.8.8"]
}
```

**Apply**:
```bash
sudo systemctl restart docker
docker info | grep -A 2 "Registry Mirrors"
```

> Backup first: `sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak 2>/dev/null || true`

## Available Docker CE Mirrors

| Mirror | URL | Priority |
|--------|-----|----------|
| Tsinghua TUNA | https://mirrors.tuna.tsinghua.edu.cn/docker-ce | 1 (default) |
| USTC | https://mirrors.ustc.edu.cn/docker-ce | 2 |
| Alibaba Cloud | https://mirrors.aliyun.com/docker-ce | 3 |

## Important Notes

- Docker CE mirror ≠ Docker Hub mirror — they are completely independent
- `k8s.gcr.io` is **deprecated** (frozen March 2023); the new registry is `registry.k8s.io`
- GPG key for Docker CE is fetched from the same mirror for security

## Rollback Docker CE

```bash
sudo ./scripts/restore_config.sh --tool docker --latest
# Or: sudo rm /etc/apt/sources.list.d/docker.list && sudo apt-get update
```
