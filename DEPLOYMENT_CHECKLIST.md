# LightRAG Deployment Checklist

Complete this checklist to set up automatic deployment on your Hetzner VPS.

---

## Phase 1: VPS Preparation (15 minutes)

- [ ] SSH access to VPS (116.203.193.178) confirmed
- [ ] Running as root or with sudo privileges
- [ ] Internet connectivity verified

### Automated Setup Option (Recommended)

- [ ] Download setup script:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/leandrocabralmovement/LightRAG/main/setup-vps.sh -o setup-vps.sh
  ```

- [ ] Run setup script:
  ```bash
  bash setup-vps.sh
  ```

- [ ] Follow prompts:
  - [ ] Confirm system update
  - [ ] Confirm Docker installation
  - [ ] Enter OpenAI API key
  - [ ] Set admin credentials
  - [ ] Confirm .env review
  - [ ] Confirm Docker build and start

- [ ] Verify installation:
  ```bash
  curl http://localhost:9621/health
  ```

### Manual Setup Option

Skip this section if you used the automated setup above.

- [ ] **Update system:**
  ```bash
  apt update && apt upgrade -y
  ```

- [ ] **Install Docker:**
  ```bash
  curl -fsSL https://get.docker.com | sh
  ```

- [ ] **Install Docker Compose:**
  ```bash
  apt install -y docker-compose
  ```

- [ ] **Clone repository:**
  ```bash
  cd /opt
  git clone https://github.com/leandrocabralmovement/LightRAG.git lightrag
  cd lightrag
  ```

- [ ] **Setup environment:**
  ```bash
  cp env.example .env
  nano .env  # Edit with your API keys
  ```

- [ ] **Create directories:**
  ```bash
  mkdir -p /opt/lightrag/data/{rag_storage,inputs,tiktoken}
  chmod 755 /opt/lightrag/data
  chmod +x /opt/lightrag/deploy.sh
  ```

- [ ] **Make log file writable:**
  ```bash
  mkdir -p /var/log
  touch /var/log/lightrag-deploy.log
  chmod 666 /var/log/lightrag-deploy.log
  ```

- [ ] **Start containers:**
  ```bash
  docker-compose -f docker-compose.prod.yml up -d --build
  ```

- [ ] **Verify:**
  ```bash
  docker ps | grep lightrag
  curl http://localhost:9621/health
  ```

---

## Phase 2: GitHub SSH Keys Setup (10 minutes)

### On Local Machine

- [ ] **Generate SSH key pair:**
  ```bash
  ssh-keygen -t ed25519 -C "github-actions-lightrag" -f ~/.ssh/github_lightrag -N ""
  ```

- [ ] **Verify keys created:**
  ```bash
  ls -la ~/.ssh/github_lightrag*
  ```

### Add Public Key to VPS

- [ ] **Option A - Using ssh-copy-id (easiest):**
  ```bash
  ssh-copy-id -i ~/.ssh/github_lightrag.pub root@116.203.193.178
  ```

- [ ] **Option B - Manual (if ssh-copy-id doesn't work):**
  ```bash
  ssh root@116.203.193.178 "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
  ```

  Then:
  ```bash
  cat ~/.ssh/github_lightrag.pub | ssh root@116.203.193.178 "cat >> ~/.ssh/authorized_keys"
  ```

  Then:
  ```bash
  ssh root@116.203.193.178 "chmod 600 ~/.ssh/authorized_keys"
  ```

- [ ] **Test SSH connection:**
  ```bash
  ssh -i ~/.ssh/github_lightrag root@116.203.193.178 "echo 'SSH works!'"
  ```

---

## Phase 3: GitHub Secrets Configuration (5 minutes)

### Get Private Key Content

- [ ] **Copy private key to clipboard:**
  ```bash
  cat ~/.ssh/github_lightrag | pbcopy  # macOS
  # or
  cat ~/.ssh/github_lightrag | xclip -selection clipboard  # Linux
  # or manually open and copy from:
  cat ~/.ssh/github_lightrag
  ```

### Add Secrets to GitHub

- [ ] Navigate to: **GitHub.com → Your Repository → Settings**

- [ ] Go to: **Secrets and variables → Actions**

- [ ] **Create Secret: `VPS_HOST`**
  - Name: `VPS_HOST`
  - Value: `116.203.193.178`
  - Click "Add secret"

- [ ] **Create Secret: `VPS_USER`**
  - Name: `VPS_USER`
  - Value: `root`
  - Click "Add secret"

- [ ] **Create Secret: `VPS_SSH_PRIVATE_KEY`**
  - Name: `VPS_SSH_PRIVATE_KEY`
  - Value: (Paste entire private key including `-----BEGIN` and `-----END`)
  - Click "Add secret"

- [ ] **Verify all 3 secrets are created:**
  - [ ] `VPS_HOST` = `116.203.193.178`
  - [ ] `VPS_USER` = `root`
  - [ ] `VPS_SSH_PRIVATE_KEY` = (long private key)

### Optional: Slack Notifications

- [ ] **If want Slack notifications:**
  - [ ] Create Slack webhook: https://api.slack.com/messaging/webhooks
  - [ ] Add secret `SLACK_WEBHOOK_URL` with webhook URL value

---

## Phase 4: Verify Workflow Configuration (5 minutes)

- [ ] **Check workflow file exists:**
  ```bash
  ls -la .github/workflows/deploy-to-vps.yml
  ```

- [ ] **Verify workflow content:**
  ```bash
  cat .github/workflows/deploy-to-vps.yml | grep -E "(VPS_|deploy.sh)"
  ```

- [ ] **Deploy script exists on VPS:**
  ```bash
  ssh root@116.203.193.178 "test -f /opt/lightrag/deploy.sh && echo 'Found!'"
  ```

---

## Phase 5: Test Automatic Deployment (10 minutes)

### Option A: Manual Test Push

- [ ] **Clone your fork locally (if not already):**
  ```bash
  git clone https://github.com/YOUR_USERNAME/LightRAG.git
  cd LightRAG
  ```

- [ ] **Create test branch:**
  ```bash
  git checkout -b test-deployment
  ```

- [ ] **Make small test change:**
  ```bash
  echo "# Test deploy - $(date)" >> README.md
  ```

- [ ] **Commit and push:**
  ```bash
  git add README.md
  git commit -m "test: verify deployment workflow"
  git push origin test-deployment
  ```

- [ ] **Create Pull Request:**
  - Go to GitHub → Your Repo → "New Pull Request"
  - Select: base=main, compare=test-deployment
  - Click "Create Pull Request"

- [ ] **Merge to main:**
  - Click "Merge pull request"
  - Delete branch after merge

### Option B: Direct Test Push to Main

- [ ] **Push directly to main:**
  ```bash
  echo "# Deployment test - $(date)" >> README.md
  git add README.md
  git commit -m "test: deployment workflow"
  git push origin main
  ```

### Monitor Deployment

- [ ] **Check GitHub Actions:**
  - Go to: GitHub → Your Repo → **Actions** tab
  - Should see: **"Deploy to Hetzner VPS"** workflow running
  - Wait for completion (should take 1-3 minutes)

- [ ] **Check VPS logs while running:**
  ```bash
  ssh root@116.203.193.178
  tail -f /var/log/lightrag-deploy.log
  ```

- [ ] **Verify container restarted:**
  ```bash
  docker logs lightrag | tail -20
  ```

- [ ] **Test API after deployment:**
  ```bash
  curl http://116.203.193.178:9621/health
  ```

- [ ] **Check GitHub Actions logs:**
  - If workflow failed, click on it to see detailed logs
  - Common issues: SSH key not set properly, deploy script not executable

---

## Phase 6: Production Hardening (Optional)

- [ ] **Setup UFW Firewall:**
  ```bash
  ssh root@116.203.193.178
  apt install -y ufw
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw allow 9621/tcp
  ufw enable
  ```

- [ ] **Setup SSL/HTTPS:**
  - [ ] Install Certbot: `apt install -y certbot`
  - [ ] Configure Nginx (see DEPLOYMENT.md)
  - [ ] Get SSL certificate: `certbot certonly --standalone -d your-domain.com`

- [ ] **Setup Backups:**
  ```bash
  # Add to crontab
  crontab -e
  # Add: 0 2 * * 0 tar -czf /backups/lightrag-$(date +\%Y-\%m-\%d).tar.gz /opt/lightrag/data/
  ```

- [ ] **Monitor Disk Usage:**
  ```bash
  ssh root@116.203.193.178
  df -h
  du -sh /opt/lightrag/data/*
  ```

- [ ] **Setup Log Rotation:**
  ```bash
  sudo nano /etc/logrotate.d/lightrag
  # Add:
  # /var/log/lightrag-deploy.log {
  #   daily
  #   rotate 10
  #   compress
  #   delaycompress
  #   notifempty
  #   create 0666 root root
  # }
  ```

---

## Phase 7: Verify Complete Workflow (Optional)

Test that updates are automatically deployed:

- [ ] **Make a code change locally:**
  ```bash
  # Edit a file, e.g., add a comment
  git add .
  git commit -m "chore: test automatic deployment"
  git push origin main
  ```

- [ ] **Watch GitHub Actions:**
  - Workflow should trigger automatically
  - Should complete in 2-3 minutes

- [ ] **Verify on VPS:**
  - Latest code should be pulled
  - Container should be rebuilt and restarted
  - API should be available at http://116.203.193.178:9621

---

## Final Verification Checklist

- [ ] VPS is accessible at 116.203.193.178
- [ ] Docker container is running: `docker ps | grep lightrag`
- [ ] API is responding: `curl http://localhost:9621/health`
- [ ] All GitHub Secrets are set
- [ ] Workflow file exists: `.github/workflows/deploy-to-vps.yml`
- [ ] Deploy script is executable: `/opt/lightrag/deploy.sh`
- [ ] Test deployment succeeded
- [ ] Logs are being generated: `/var/log/lightrag-deploy.log`

---

## Troubleshooting Quick Links

If something goes wrong:

- [ ] **SSH Connection Issues:** See DEPLOYMENT.md → Troubleshooting → SSH Connection Issues
- [ ] **Deployment Fails:** See DEPLOYMENT.md → Troubleshooting → Deployment Script Fails
- [ ] **Container Won't Start:** See DEPLOYMENT.md → Troubleshooting → Container Won't Start
- [ ] **Out of Disk:** See DEPLOYMENT.md → Troubleshooting → Out of Disk Space
- [ ] **Git Pull Fails:** See DEPLOYMENT.md → Troubleshooting → Git Pull Fails

---

## Success Criteria

You're done when:

✅ VPS setup is complete
✅ Docker container is running and healthy
✅ SSH keys are configured and tested
✅ GitHub Secrets are all set
✅ Test deployment succeeded
✅ Automatic deployment is working

**Congratulations! Your LightRAG is now set up for automatic deployment!** 🎉

---

## Next Steps

1. **Configure your LLM Provider:**
   - Update `.env` with your API keys
   - Restart container: `docker-compose restart lightrag`

2. **Access the Web UI:**
   - Open: http://116.203.193.178:9621
   - Login with your admin credentials

3. **Start Using LightRAG:**
   - Upload documents
   - Configure knowledge graph
   - Run queries

4. **Monitor Deployments:**
   - Check GitHub Actions for deployment status
   - Check `/var/log/lightrag-deploy.log` for detailed logs

---

## Support

For issues or questions:
- Check DEPLOYMENT.md for detailed documentation
- See GitHub Issues: https://github.com/leandrocabralmovement/LightRAG/issues
- Join Discord: https://discord.gg/yF2MmDJyGJ

---

**Last Updated:** November 7, 2025
**Checklist Version:** 1.0.0
