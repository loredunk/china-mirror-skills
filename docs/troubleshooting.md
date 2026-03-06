# Troubleshooting

## Common Issues

### pip: SSL certificate verification failed

**Symptom:**
```
pip install requests
SSL: CERTIFICATE_VERIFY_FAILED
```

**Cause:** Your network may be intercepting HTTPS traffic (corporate proxy, firewall).

**Solution:** Do **not** use `--trusted-host` or `pip config set global.trusted-host` as this disables security. Instead:
1. Check if you have a corporate proxy with custom CA: `echo $HTTPS_PROXY`
2. Install the corporate CA certificate: `sudo update-ca-certificates`
3. If behind a transparent proxy, contact your network admin

---

### npm: ECONNREFUSED or ETIMEDOUT

**Symptom:**
```
npm install
npm ERR! code ECONNREFUSED
```

**Solution:**
```bash
# Verify current registry
npm config get registry

# If not set to npmmirror, set it
npm config set registry https://registry.npmmirror.com

# Test connectivity
npm view npm version
```

---

### npm: Proxy conflict

**Symptom:** npm uses a proxy even after setting the mirror, causing double-proxy issues.

**Solution:**
```bash
# Check for proxy settings
npm config get proxy
npm config get https-proxy

# If you have a proxy set but don't need it for npm
npm config delete proxy
npm config delete https-proxy
```

---

### Docker: Cannot pull images (not Docker CE install)

**Important distinction:**
- `setup_docker.sh` configures Docker **CE installation packages** (apt/yum repo)
- Docker **Hub image pulls** are a separate issue

**For Docker Hub images:** As of 2024, most public mirrors in China are no longer available. Options:
1. Use a VPN or proxy
2. Pull images from a private registry mirror you control
3. Use `registry.cn-hangzhou.aliyuncs.com` for Alibaba Cloud (requires account)

---

### Docker CE: GPG key error during apt install

**Symptom:**
```
The following signatures couldn't be verified because the public key is not available
```

**Solution:**
```bash
# Re-run the setup script which handles GPG key import
./scripts/setup_docker.sh --force

# Or manually add the key
curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

---

### Cargo: SSL handshake failure

**Symptom:**
```
error: failed to fetch `https://mirrors.ustc.edu.cn/crates.io-index/`
Caused by: [SSL: HANDSHAKE_FAILURE]
```

**Solution:**
```bash
# Check your Cargo config
cat ~/.cargo/config.toml

# Ensure you're using the sparse index format
# In ~/.cargo/config.toml:
[source.ustc]
registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"
```

---

### Conda: CondaHTTPError

**Symptom:**
```
CondaHTTPError: HTTP 000 CONNECTION FAILED
```

**Solution:**
```bash
# Check conda config
conda config --show channels
conda config --show channel_alias

# Re-run setup
./scripts/setup_conda.sh

# Verify connectivity
conda search numpy --dry-run
```

---

### Go: GOPROXY not taking effect

**Symptom:** `go get` still connects to `proxy.golang.org` despite setting GOPROXY.

**Solution:**
```bash
# Check environment
go env GOPROXY
go env GONOSUMCHECK

# Set permanently (add to ~/.zshrc or ~/.bashrc)
export GOPROXY=https://goproxy.cn,direct
export GONOSUMDB="*"

# Or use go env -w
go env -w GOPROXY=https://goproxy.cn,direct
go env -w GONOSUMDB="*"
```

---

### Flutter: PUB_HOSTED_URL not recognized

**Symptom:** Flutter pub still connects to `pub.dev` despite setting env vars.

**Solution:**
```bash
# Ensure these are exported (not just set)
export FLUTTER_STORAGE_BASE_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter
export PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/dart-pub

# Verify Flutter sees them
flutter doctor -v | grep -i mirror

# If using a shell profile, source it
source ~/.zshrc
```

---

### Homebrew: git clone fails (macOS)

**Symptom:**
```
fatal: unable to access 'https://github.com/Homebrew/brew/': ...
```

**Solution:**
```bash
# Run the Homebrew mirror setup
./scripts/setup_homebrew.sh

# Verify git remote
git -C "$(brew --repo)" remote -v
```

---

### Backup and Restore Issues

**Cannot find backup:**
```bash
# List all backups
./scripts/restore_config.sh --list

# Backups are stored in
ls ~/.china-mirror-skills/backups/
```

**Restore fails with "No backup found":**
```bash
# Specify exact backup ID from --list output
./scripts/restore_config.sh --tool pip --backup-id 20250306_120000
```

---

## Debugging Tips

### Check proxy environment variables
```bash
env | grep -i proxy
```

Conflicting proxy settings can cause issues when trying to use mirrors directly. The setup scripts warn about this automatically.

### Test mirror reachability manually
```bash
curl -I https://pypi.tuna.tsinghua.edu.cn/simple/pip/
curl -I https://registry.npmmirror.com/npm
curl -I https://mirrors.tuna.tsinghua.edu.cn/ubuntu/dists/
```

### Run the health checker
```bash
python scripts/check_mirrors.py
```

This tests all mirrors in `data/mirrors.yml` and reports which ones are reachable.

### Dry run before applying
All setup scripts support `--dry-run`:
```bash
./scripts/setup_pip.sh --dry-run
./scripts/setup_npm.sh --dry-run
```
