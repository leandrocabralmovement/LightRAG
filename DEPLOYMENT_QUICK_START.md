# Quick Start: Deploy LightRAG on Hetzner VPS

⚡ Complete setup in 15 minutes

## Prerequisites
- VPS IP: `116.203.193.178`
- SSH access as root
- GitHub repository (your fork of LightRAG)

---

## Step 1: VPS Setup (5 minutes)

### 1.1 SSH to VPS
```bash
ssh root@116.203.193.178
```

### 1.2 Install Docker
```bash
curl -fsSL https://get.docker.com | sh && apt install -y docker-compose
```

### 1.3 Clone Repository
```bash
cd /opt
git clone https://github.com/YOUR_USERNAME/LightRAG.git lightrag
cd lightrag
```

### 1.4 Setup Environment
```bash
cp env.example .env
# Edit .env with your API keys
nano .env
```

**Minimum config needed:**
```bash
# OpenAI (or your LLM provider)
OPENAI_API_KEY=sk-...

# Admin credentials
AUTH_ACCOUNTS=admin:change_this_password
```

### 1.5 Make Deploy Script Executable
```bash
chmod +x /opt/lightrag/deploy.sh
mkdir -p /var/log
touch /var/log/lightrag-deploy.log
chmod 666 /var/log/lightrag-deploy.log
```

### 1.6 Initial Deploy
```bash
cd /opt/lightrag
docker-compose -f docker-compose.prod.yml up -d --build
```

Wait 2-3 minutes for Docker build...

### 1.7 Verify
```bash
docker ps | grep lightrag
curl http://localhost:9621/health
```

✅ If you see the container running, VPS is ready!

---

## Step 2: GitHub Setup (5 minutes)

### 2.1 Generate SSH Key (on your local machine)
```bash
ssh-keygen -t ed25519 -C "github-actions-lightrag" -f ~/.ssh/github_lightrag -N ""
```

### 2.2 Add Key to VPS (from local machine)
```bash
ssh-copy-id -i ~/.ssh/github_lightrag.pub root@116.203.193.178
```

### 2.3 Add GitHub Secrets

Go to: **GitHub.com → Your Repo → Settings → Secrets and variables → Actions**

Create these secrets:

| Name | Value |
|------|-------|
| `VPS_HOST` | `116.203.193.178` |
| `VPS_USER` | `root` |
| `VPS_SSH_PRIVATE_KEY` | Output of: `cat ~/.ssh/github_lightrag` |

### 2.4 Verify Workflow

The file `.github/workflows/deploy-to-vps.yml` should exist in your repo.

---

## Step 3: Test Deployment (5 minutes)

### 3.1 Make a Small Change
```bash
# In your local repository
echo "# Updated at $(date)" >> README.md
git add README.md
git commit -m "test deployment"
git push origin main
```

### 3.2 Check GitHub Actions

Go to: **GitHub.com → Your Repo → Actions**

You should see the workflow running. Click on it to see logs.

### 3.3 Verify on VPS

```bash
ssh root@116.203.193.178
tail -f /var/log/lightrag-deploy.log

# Or check container
docker logs lightrag
```

---

## ✅ That's it!

From now on, every time you `git push` to `main`, it will:
1. Trigger GitHub Actions workflow
2. SSH into your VPS
3. Pull latest code
4. Rebuild and restart Docker container

---

## 🔗 Access Your Application

```
http://116.203.193.178:9621
```

Login with credentials set in `.env`:
```
Username: admin
Password: your_password_from_.env
```

---

## 📝 Common Commands

### View deployment status
```bash
ssh root@116.203.193.178
tail -f /var/log/lightrag-deploy.log
```

### View logs
```bash
docker-compose logs -f lightrag
```

### Restart manually
```bash
docker-compose restart lightrag
```

### Pull latest code
```bash
cd /opt/lightrag
git pull origin main
docker-compose up -d --build
```

---

## 🐛 Troubleshooting

### SSH connection fails
```bash
# Test connection
ssh -v root@116.203.193.178

# Verify key
ssh-copy-id -i ~/.ssh/github_lightrag.pub root@116.203.193.178
```

### Container won't start
```bash
ssh root@116.203.193.178
docker logs lightrag
# Check for API key errors in .env
```

### Out of disk space
```bash
docker system prune -a -f
```

---

## 📚 Full Documentation

For more details, see: `DEPLOYMENT.md`

---

**Setup complete! Your LightRAG now deploys automatically on every git push to main.**
