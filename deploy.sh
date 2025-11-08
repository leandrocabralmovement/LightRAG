#!/bin/bash

################################################################################
# LightRAG Deployment Script for Hetzner VPS
# This script is executed on the VPS via GitHub Actions SSH
#
# Prerequisites:
# - Docker and Docker Compose installed
# - Repository cloned at /opt/lightrag
# - .env file configured
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_DIR="/opt/lightrag"
LOG_FILE="/var/log/lightrag-deploy.log"
DOCKER_CONTAINER="lightrag"
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"  # Optional: set via environment variable

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

notify_slack() {
    if [ -n "$SLACK_WEBHOOK" ]; then
        local status=$1
        local message=$2
        local color="good"

        if [ "$status" != "success" ]; then
            color="danger"
        fi

        curl -X POST -H 'Content-type: application/json' \
            --data "{
                \"attachments\": [{
                    \"color\": \"$color\",
                    \"title\": \"LightRAG Deployment $status\",
                    \"text\": \"$message\",
                    \"footer\": \"Hetzner VPS\",
                    \"ts\": $(date +%s)
                }]
            }" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi
}

# Main deployment logic
main() {
    echo "" | tee -a "$LOG_FILE"
    log_info "=========================================="
    log_info "LightRAG Deployment Started"
    log_info "Time: $(date)"
    log_info "=========================================="

    # Check if directory exists
    if [ ! -d "$REPO_DIR" ]; then
        log_error "Repository directory $REPO_DIR does not exist!"
        notify_slack "failed" "Repository directory not found: $REPO_DIR"
        return 1
    fi

    cd "$REPO_DIR"
    log_info "Working directory: $(pwd)"

    # Step 1: Pull latest code
    log_info "Step 1: Pulling latest code from repository..."
    if git pull origin main; then
        log_success "Code pulled successfully"
    else
        log_error "Failed to pull code"
        notify_slack "failed" "Git pull failed"
        return 1
    fi

    # Step 2: Check if .env exists
    if [ ! -f .env ]; then
        log_warning ".env file not found! Using env.example as template."
        if [ -f env.example ]; then
            cp env.example .env
            log_info "Created .env from env.example"
        else
            log_error "Neither .env nor env.example found!"
            notify_slack "failed" ".env configuration missing"
            return 1
        fi
    fi

    # Step 3: Stop running container
    log_info "Step 2: Stopping existing container..."
    if docker ps --format '{{.Names}}' | grep -q "^${DOCKER_CONTAINER}$"; then
        if docker stop "$DOCKER_CONTAINER" 2>/dev/null; then
            log_success "Container stopped"
            sleep 2
        else
            log_warning "Failed to stop container gracefully"
        fi
    else
        log_info "No running container found"
    fi

    # Step 4: Remove old container
    log_info "Step 3: Removing old container..."
    if docker rm "$DOCKER_CONTAINER" 2>/dev/null; then
        log_success "Old container removed"
    else
        log_info "No old container to remove"
    fi

    # Step 5: Prune old images
    log_info "Step 4: Pruning dangling Docker images..."
    docker image prune -f --filter "dangling=true" 2>/dev/null || true

    # Step 6: Build and start with Docker Compose
    log_info "Step 5: Building and starting containers with Docker Compose..."
    if docker-compose up -d --build; then
        log_success "Containers started successfully"
        sleep 3
    else
        log_error "Failed to start containers"
        notify_slack "failed" "Docker Compose failed"
        return 1
    fi

    # Step 7: Verify container is running
    log_info "Step 6: Verifying deployment..."
    sleep 2

    if docker ps --format '{{.Names}}' | grep -q "^${DOCKER_CONTAINER}$"; then
        CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' "$DOCKER_CONTAINER")
        if [ "$CONTAINER_STATUS" = "running" ]; then
            log_success "Container is running"
        else
            log_error "Container is not running (status: $CONTAINER_STATUS)"
            docker logs "$DOCKER_CONTAINER" | tail -20 | tee -a "$LOG_FILE"
            notify_slack "failed" "Container failed to run"
            return 1
        fi
    else
        log_error "Container is not running!"
        notify_slack "failed" "Container not found"
        return 1
    fi

    # Step 8: Test API endpoint
    log_info "Step 7: Testing API endpoint..."
    API_PORT=$(grep "PORT=" .env | cut -d'=' -f2 | tr -d ' ' || echo "9621")
    HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$API_PORT/health 2>/dev/null || echo "000")

    if [ "$HEALTH_CHECK" = "200" ] || [ "$HEALTH_CHECK" = "404" ]; then
        log_success "API is responding (HTTP $HEALTH_CHECK)"
    else
        log_warning "API health check returned HTTP $HEALTH_CHECK (might be expected)"
    fi

    # Step 9: Cleanup
    log_info "Step 8: Cleanup..."
    docker system prune -f --filter "until=72h" 2>/dev/null || true

    # Final status
    log_info "=========================================="
    log_success "Deployment completed successfully!"
    log_info "Deployment Time: $(date)"
    log_info "Container: $DOCKER_CONTAINER"
    log_info "Status: Running"
    log_info "=========================================="

    notify_slack "success" "LightRAG deployed successfully on $(hostname)"

    return 0
}

# Run main function and capture exit code
main
exit_code=$?

exit $exit_code
