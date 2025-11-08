# LightRAG - Automated Deployment Guide

Complete guide to set up automatic deployment of LightRAG on Hetzner VPS.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [VPS Setup](#vps-setup)
3. [GitHub Configuration](#github-configuration)
4. [Deployment Process](#deployment-process)
5. [Monitoring and Maintenance](#monitoring-and-maintenance)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required on VPS:
- Ubuntu 20.04+ or Debian 11+
- Docker installed
- Docker Compose installed
- Git installed
- SSH access (port 22 or custom)
- Sudo privileges (or root access)

### Required on GitHub:
- Repository ownership/admin access
- Personal Access Token (or use GITHUB_TOKEN)

---

## VPS Setup

### Step 1: Initial VPS Configuration

Connect to your VPS:
```bash
ssh root@116.203.193.178
```

### Step 2: Install Docker and Docker Compose

```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install -y docker-compose

# Verify installation
docker --version
docker-compose --version
```

### Step 3: Clone Repository

```bash
# Create directory
mkdir -p /opt/lightrag
cd /opt/lightrag

# Clone from your fork (replace with your username)
git clone https://github.com/YOUR_USERNAME/LightRAG.git .

# Or if you already have it:
# cd existing_lightrag_directory
```

### Step 4: Prepare Environment

```bash
# Copy environment template
cp env.example .env

# Edit .env with your configuration
nano .env
```

**Important .env variables:**
```bash
# Server
HOST=0.0.0.0
PORT=9621

# Paths (already set in docker-compose)
WORKING_DIR=/app/data/rag_storage
INPUT_DIR=/app/data/inputs
TIKTOKEN_CACHE_DIR=/app/data/tiktoken

# LLM Configuration (set your provider)
# For OpenAI:
OPENAI_API_KEY=sk-...

# For Ollama:
# OLLAMA_BASE_URL=http://ollama:11434

# Authentication (optional but recommended)
AUTH_ACCOUNTS=admin:your_secure_password
TOKEN_SECRET=your_jwt_secret_key

# Logging
LOG_LEVEL=INFO
VERBOSE=False
```

### Step 5: Create Data Directories

```bash
# Create data directories
mkdir -p /opt/lightrag/data/rag_storage
mkdir -p /opt/lightrag/data/inputs
mkdir -p /opt/lightrag/data/tiktoken

# Set permissions
chmod -R 755 /opt/lightrag/data
```

### Step 6: Make Deploy Script Executable

```bash
# Make the deploy script executable
chmod +x /opt/lightrag/deploy.sh

# Create log directory
mkdir -p /var/log
touch /var/log/lightrag-deploy.log
chmod 666 /var/log/lightrag-deploy.log
```

### Step 7: Initial Docker Build and Run

```bash
cd /opt/lightrag

# Use production compose file
docker-compose -f docker-compose.prod.yml up -d --build
```

Wait a few minutes for the build to complete. You can check progress with:
```bash
docker-compose logs -f lightrag
```

### Step 8: Verify Deployment

```bash
# Check if container is running
docker ps | grep lightrag

# Check logs
docker-compose logs lightrag

# Test API
curl http://localhost:9621/health
```

---

## GitHub Configuration

### Step 1: Generate SSH Key Pair

On your **local machine** (not on the VPS):

```bash
# Generate SSH key without passphrase (GitHub Actions cannot handle passphrases)
ssh-keygen -t ed25519 -C "github-actions-lightrag" -f ~/.ssh/github_lightrag -N ""

# Show the private key (you'll need this for GitHub)
cat ~/.ssh/github_lightrag
```

### Step 2: Add Public Key to VPS

On the **VPS**:

```bash
# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add the public key to authorized_keys
echo "YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Or do it from your local machine:
```bash
ssh-copy-id -i ~/.ssh/github_lightrag.pub root@116.203.193.178
```

### Step 3: Add GitHub Secrets

Go to your GitHub repository:
1. Navigate to **Settings → Secrets and variables → Actions**
2. Create these secrets:

| Secret Name | Value |
|------------|-------|
| `VPS_HOST` | `116.203.193.178` |
| `VPS_USER` | `root` |
| `VPS_SSH_PRIVATE_KEY` | Content of `~/.ssh/github_lightrag` (the private key) |

**To get the private key:**
```bash
cat ~/.ssh/github_lightrag
# Copy the entire content including -----BEGIN... and -----END...
```

### Step 4: (Optional) Add Slack Notifications

If you want Slack notifications on deployment:

1. Create a Slack webhook: https://api.slack.com/messaging/webhooks
2. Add to GitHub Secrets:
   - Name: `SLACK_WEBHOOK_URL`
   - Value: Your webhook URL

3. On VPS, add to root's `.bashrc` or `/etc/environment`:
```bash
export SLACK_WEBHOOK="YOUR_WEBHOOK_URL"
```

Or directly in the deploy.sh (not recommended for security).

### Step 5: Verify Workflow

Check that the workflow file exists and is valid:

```bash
# In your local repository
git cat-file -p HEAD:.github/workflows/deploy-to-vps.yml
```

---

## Deployment Process

### Automatic Deployments

The deployment **automatically triggers** when:
- ✅ You push code to the **main** branch
- ✅ Files outside `.github/**`, `docs/**`, `*.md` are changed
- ❌ Does NOT trigger on README changes (to save resources)

### Manual Deployment

Trigger deployment manually:

1. Go to **Actions** tab on GitHub
2. Select **"Deploy to Hetzner VPS"**
3. Click **"Run workflow"**
4. Select environment (production/staging)

### Deployment Steps

The GitHub Action will:
1. ✅ Check out your code
2. ✅ Set up SSH connection to VPS
3. ✅ Execute `/opt/lightrag/deploy.sh` on VPS
4. ✅ Clean up SSH keys

The VPS script will:
1. Pull latest code from repository
2. Stop the running container
3. Build a new Docker image
4. Start containers with `docker-compose up -d --build`
5. Verify the container is healthy
6. Clean up old Docker images

### Monitor Deployment

View deployment status:
```bash
# On GitHub: Actions tab → "Deploy to Hetzner VPS"
# View logs for detailed status
```

On VPS:
```bash
# Check deployment logs
tail -f /var/log/lightrag-deploy.log

# Check Docker status
docker ps
docker-compose logs -f lightrag
```

---

## Production Optimization

### Enable SSL/HTTPS

Use Nginx as reverse proxy:

1. **Install Certbot:**
```bash
apt install -y certbot python3-certbot-nginx
```

2. **Create `nginx.conf`** in `/opt/lightrag/`:
```nginx
upstream lightrag {
    server lightrag:9621;
}

server {
    listen 80;
    server_name your-domain.com;
    client_max_body_size 100M;

    location / {
        proxy_pass http://lightrag;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

3. **Uncomment Nginx in docker-compose.prod.yml**

4. **Run Certbot:**
```bash
certbot certonly --standalone -d your-domain.com
```

### Resource Limits

The `docker-compose.prod.yml` includes resource limits:
- **CPU**: 2 cores max, 1 core reserved
- **Memory**: 4GB max, 2GB reserved

Adjust based on your VPS resources:
```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 4G
```

### Backup Strategy

```bash
# Backup data directory weekly
crontab -e

# Add:
0 2 * * 0 tar -czf /backups/lightrag-$(date +\%Y-\%m-\%d).tar.gz /opt/lightrag/data/
```

---

## Monitoring and Maintenance

### Health Checks

Monitor container health:
```bash
# View health status
docker inspect lightrag | grep -A 5 "Health"

# Manual health check
curl -v http://localhost:9621/health
```

### View Logs

```bash
# Real-time logs
docker-compose logs -f lightrag

# Last 100 lines
docker-compose logs --tail 100 lightrag

# Deployment script logs
tail -f /var/log/lightrag-deploy.log
```

### Restart Container

```bash
# Graceful restart
docker-compose restart lightrag

# Force rebuild
docker-compose up -d --build
```

### Clean Up

```bash
# Remove stopped containers
docker container prune -f

# Remove unused images
docker image prune -f

# Remove unused volumes
docker volume prune -f

# Full cleanup (WARNING: removes all unused Docker objects)
docker system prune -a -f
```

### Update Code Manually

```bash
cd /opt/lightrag
git pull origin main
docker-compose -f docker-compose.prod.yml up -d --build
```

---

## Troubleshooting

### SSH Connection Issues

```bash
# Test SSH connection
ssh -v root@116.203.193.178

# If key-based auth fails, check authorized_keys
ssh root@116.203.193.178 "cat ~/.ssh/authorized_keys"

# Check SSH logs on server
tail -f /var/log/auth.log | grep sshd
```

### Deployment Script Fails

```bash
# Run script manually for debugging
bash -x /opt/lightrag/deploy.sh

# Check logs
cat /var/log/lightrag-deploy.log

# Check Docker daemon
systemctl status docker
docker ps
```

### Container Won't Start

```bash
# Check logs
docker logs lightrag

# Check if port is already in use
lsof -i :9621

# Check Docker build errors
docker-compose build --no-cache lightrag

# Increase Docker memory
docker update --memory 4g lightrag
```

### Out of Disk Space

```bash
# Check disk usage
df -h

# Clean Docker objects
docker system prune -a -f

# Remove old images
docker image prune -a --filter "until=72h" -f
```

### Permission Denied

```bash
# Make deploy script executable
chmod +x /opt/lightrag/deploy.sh

# Make log file writable
chmod 666 /var/log/lightrag-deploy.log

# Add user to docker group (if not using root)
usermod -aG docker $USER
```

### Git Pull Fails

```bash
# Check if repository is properly set
cd /opt/lightrag
git remote -v

# Try manual pull
git pull origin main

# If credentials are needed:
git config --global credential.helper store
# Then run pull again and enter credentials
```

---

## Security Considerations

### 1. SSH Key Management
- ✅ Never commit private keys to repository
- ✅ Use dedicated SSH key for GitHub Actions
- ✅ Regenerate keys periodically
- ✅ Store keys securely in GitHub Secrets

### 2. Environment Variables
- ✅ Never commit `.env` to repository
- ✅ Use strong API keys (OpenAI, etc.)
- ✅ Rotate secrets regularly
- ✅ Use `.gitignore` to prevent accidental commits

### 3. Docker Security
- ✅ Use specific image tags (not just `latest`)
- ✅ Enable container health checks
- ✅ Set resource limits
- ✅ Use read-only volumes where possible
- ✅ Drop unnecessary capabilities

### 4. VPS Firewall
```bash
# Install UFW
apt install -y ufw

# Allow SSH
ufw allow 22/tcp

# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Allow application port (if needed)
ufw allow 9621/tcp

# Enable firewall
ufw enable
```

### 5. Regular Updates
```bash
# Update system weekly
apt update && apt upgrade -y

# Update Docker images periodically
docker pull ghcr.io/hkuds/lightrag:latest
```

---

## Support and Issues

- **GitHub Issues**: https://github.com/leandrocabralmovement/LightRAG/issues
- **LightRAG Repo**: https://github.com/HKUDS/LightRAG
- **Discord Community**: https://discord.gg/yF2MmDJyGJ

---

## Changelog

### v1.0.0 (Initial Setup)
- Automated deployment to Hetzner VPS
- GitHub Actions workflow
- Docker Compose production configuration
- Health checks and monitoring
- SSL/HTTPS support ready

---

**Last Updated**: November 7, 2025
**Maintained by**: Your Organization
