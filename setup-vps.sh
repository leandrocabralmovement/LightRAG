#!/bin/bash

################################################################################
# LightRAG VPS Setup Script
# Automated VPS configuration for Hetzner
#
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/setup-vps.sh | bash
# Or: bash setup-vps.sh
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REPO_URL="https://github.com/leandrocabralmovement/LightRAG.git"
INSTALL_DIR="/opt/lightrag"
REPO_BRANCH="main"

# Functions
print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

confirm() {
    local prompt="$1"
    local response
    read -p "$(echo -e ${BLUE})$prompt (y/n)${NC} " response
    [[ "$response" =~ ^[Yy]$ ]]
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    exit 1
fi

# Start setup
clear
print_header "LightRAG Setup for Hetzner VPS"

print_info "This script will:"
echo "  • Update system packages"
echo "  • Install Docker and Docker Compose"
echo "  • Clone LightRAG repository"
echo "  • Setup directories and permissions"
echo "  • Create configuration files"
echo "  • Build and start Docker containers"
echo ""

if ! confirm "Continue with setup?"; then
    print_warning "Setup cancelled"
    exit 0
fi

# Step 1: Update system
print_header "Step 1: Updating System"
apt update
apt upgrade -y
print_success "System updated"

# Step 2: Install Docker
print_header "Step 2: Installing Docker"
if command -v docker &> /dev/null; then
    print_warning "Docker already installed"
    docker --version
else
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    bash /tmp/get-docker.sh
    print_success "Docker installed"
fi

# Step 3: Install Docker Compose
print_header "Step 3: Installing Docker Compose"
if command -v docker-compose &> /dev/null; then
    print_warning "Docker Compose already installed"
    docker-compose --version
else
    apt install -y docker-compose
    print_success "Docker Compose installed"
fi

# Step 4: Create installation directory
print_header "Step 4: Setting Up Installation Directory"
if [ -d "$INSTALL_DIR" ]; then
    print_warning "Directory $INSTALL_DIR already exists"
    if ! confirm "Overwrite existing installation?"; then
        print_info "Using existing directory"
    else
        rm -rf "$INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
    fi
else
    mkdir -p "$INSTALL_DIR"
    print_success "Created $INSTALL_DIR"
fi

# Step 5: Clone repository
print_header "Step 5: Cloning Repository"
if [ ! -d "$INSTALL_DIR/.git" ]; then
    git clone -b "$REPO_BRANCH" "$REPO_URL" "$INSTALL_DIR"
    print_success "Repository cloned"
else
    cd "$INSTALL_DIR"
    git pull origin "$REPO_BRANCH"
    print_success "Repository updated"
fi

cd "$INSTALL_DIR"

# Step 6: Setup environment
print_header "Step 6: Setting Up Environment"

if [ ! -f ".env" ]; then
    if [ -f ".env.production.example" ]; then
        cp ".env.production.example" ".env"
        print_success "Created .env from .env.production.example"
    elif [ -f "env.example" ]; then
        cp "env.example" ".env"
        print_success "Created .env from env.example"
    else
        print_error "No env.example found!"
        exit 1
    fi

    # Prompt for API key
    print_info "Enter your OpenAI API key (or skip with Enter):"
    read -p "OPENAI_API_KEY: " api_key
    if [ -n "$api_key" ]; then
        sed -i "s/^OPENAI_API_KEY=.*/OPENAI_API_KEY=$api_key/" .env
        print_success "API key configured"
    fi

    # Prompt for admin password
    print_info "Set admin credentials:"
    read -p "Admin username (default: admin): " admin_user
    admin_user=${admin_user:-admin}

    read -sp "Admin password: " admin_pass
    echo ""

    if [ -n "$admin_pass" ]; then
        sed -i "s/^AUTH_ACCOUNTS=.*/AUTH_ACCOUNTS=$admin_user:$admin_pass/" .env
        print_success "Admin credentials configured"
    fi

    print_warning "IMPORTANT: Review .env file and update all required settings"
    print_info "File location: $INSTALL_DIR/.env"
    read -p "Press Enter to continue after reviewing .env..."
else
    print_warning ".env already exists, skipping creation"
fi

# Step 7: Create data directories
print_header "Step 7: Creating Data Directories"
mkdir -p "$INSTALL_DIR/data/rag_storage"
mkdir -p "$INSTALL_DIR/data/inputs"
mkdir -p "$INSTALL_DIR/data/tiktoken"
mkdir -p /var/log
chmod -R 755 "$INSTALL_DIR/data"
chmod 666 /var/log/lightrag-deploy.log 2>/dev/null || touch /var/log/lightrag-deploy.log && chmod 666 /var/log/lightrag-deploy.log
print_success "Data directories created"

# Step 8: Setup deploy script
print_header "Step 8: Setting Up Deployment Script"
chmod +x "$INSTALL_DIR/deploy.sh"
print_success "Deploy script is executable"

# Step 9: Build and start containers
print_header "Step 9: Building Docker Image (This may take 5-10 minutes)"
cd "$INSTALL_DIR"

if confirm "Build and start containers now?"; then
    docker-compose -f docker-compose.prod.yml up -d --build

    print_success "Containers started"

    # Wait for container to be ready
    print_info "Waiting for container to be ready..."
    sleep 10

    if docker ps --format '{{.Names}}' | grep -q "^lightrag$"; then
        print_success "Container is running"

        # Test API
        print_info "Testing API endpoint..."
        if curl -s http://localhost:9621/health &> /dev/null; then
            print_success "API is responding"
        else
            print_warning "API not responding yet, check logs with: docker-compose logs lightrag"
        fi
    else
        print_error "Container failed to start"
        print_info "Check logs: docker-compose logs lightrag"
        exit 1
    fi
else
    print_info "Skipped container setup"
    print_info "To start later, run: cd $INSTALL_DIR && docker-compose -f docker-compose.prod.yml up -d --build"
fi

# Step 10: Display summary
print_header "Setup Complete!"

echo -e "${GREEN}Your LightRAG installation is ready!${NC}\n"

echo "📍 Installation Directory: $INSTALL_DIR"
echo "🐳 Container Name: lightrag"
echo "🌐 Access URL: http://$(hostname -I | awk '{print $1}'):9621"
echo ""

print_info "Next steps:"
echo "  1. Open browser: http://$(hostname -I | awk '{print $1}'):9621"
echo "  2. Login with credentials set in .env"
echo "  3. Configure GitHub SSH keys (see DEPLOYMENT_QUICK_START.md)"
echo ""

print_warning "IMPORTANT REMINDERS:"
echo "  • Save your OpenAI API key securely"
echo "  • Change admin password in .env to something strong"
echo "  • Configure GitHub Secrets for automatic deployment"
echo "  • Review .env for additional settings"
echo ""

print_info "Useful commands:"
echo "  View logs:        docker-compose logs -f lightrag"
echo "  Restart:          docker-compose restart lightrag"
echo "  Stop:             docker-compose stop"
echo "  Check status:     docker ps"
echo "  View deploy logs: tail -f /var/log/lightrag-deploy.log"
echo ""

print_info "Documentation:"
echo "  Quick Start:      DEPLOYMENT_QUICK_START.md"
echo "  Full Guide:       DEPLOYMENT.md"
echo ""

echo -e "${GREEN}Happy RAGing! 🚀${NC}\n"

# Create a summary file
cat > "$INSTALL_DIR/SETUP_SUMMARY.txt" << EOF
LightRAG VPS Setup Summary
Generated: $(date)

Installation Directory: $INSTALL_DIR
Repository: $REPO_URL
Branch: $REPO_BRANCH

Services:
  - LightRAG API: http://$(hostname -I | awk '{print $1}'):9621

Configuration Files:
  - Environment: .env
  - Deploy Script: deploy.sh
  - Docker Compose: docker-compose.prod.yml

Data Directories:
  - Storage: $INSTALL_DIR/data/rag_storage
  - Inputs: $INSTALL_DIR/data/inputs
  - Cache: $INSTALL_DIR/data/tiktoken

Logs:
  - Docker Compose: docker-compose logs
  - Deploy Script: /var/log/lightrag-deploy.log

Next Steps:
  1. Verify .env configuration
  2. Test API: curl http://localhost:9621/health
  3. Configure GitHub SSH keys
  4. Add GitHub Secrets (VPS_HOST, VPS_USER, VPS_SSH_PRIVATE_KEY)
  5. Push code to trigger automatic deployment

For issues or questions, see DEPLOYMENT.md
EOF

print_success "Setup summary saved to: $INSTALL_DIR/SETUP_SUMMARY.txt"
