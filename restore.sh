#!/bin/bash

################################################################################
# LightRAG Restore Script
# Restores PostgreSQL, Neo4j, and LightRAG data from backup
#
# Usage: bash restore.sh <backup_path>
# Example: bash restore.sh ./backups/2024-01-15_10-30-45
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKUP_DIR="$1"
POSTGRES_CONTAINER="lightrag-postgres"
NEO4J_CONTAINER="lightrag-neo4j"
DATA_DIR="${DATA_MOUNT_PATH:-.}/data"

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
    read -p "$(echo -e ${YELLOW})$prompt (y/n)${NC} " response
    [[ "$response" =~ ^[Yy]$ ]]
}

# Validate backup directory
if [ -z "$BACKUP_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
    print_error "Usage: bash restore.sh <backup_path>"
    echo "Example: bash restore.sh ./backups/2024-01-15_10-30-45"
    exit 1
fi

print_header "LightRAG Restore"
print_warning "This will restore your database from backup!"
print_warning "Current data will be OVERWRITTEN!"
echo ""

if ! confirm "Are you sure you want to continue?"; then
    print_info "Restore cancelled"
    exit 0
fi

print_info "Backup source: $BACKUP_DIR"
print_info "Restore start time: $(date)"
echo ""

# Step 1: Check if services are running
print_header "Step 1: Checking services"

if docker ps --format '{{.Names}}' | grep -q "^lightrag$"; then
    print_warning "LightRAG is running"
    if confirm "Stop LightRAG before restore?"; then
        docker-compose stop lightrag
        print_success "LightRAG stopped"
    fi
fi

if docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER}$"; then
    print_info "PostgreSQL container is running"
else
    print_error "PostgreSQL container is not running!"
    if ! confirm "Start PostgreSQL anyway?"; then
        exit 1
    fi
    docker-compose up -d postgres
    sleep 10
fi

if docker ps --format '{{.Names}}' | grep -q "^${NEO4J_CONTAINER}$"; then
    print_info "Neo4j container is running"
else
    print_error "Neo4j container is not running!"
    if ! confirm "Start Neo4j anyway?"; then
        exit 1
    fi
    docker-compose up -d neo4j
    sleep 15
fi

# Step 2: Restore PostgreSQL
print_header "Step 2: Restoring PostgreSQL"

if [ -f "$BACKUP_DIR/postgres-dump.sql" ]; then
    SIZE=$(du -h "$BACKUP_DIR/postgres-dump.sql" | cut -f1)
    print_info "Found PostgreSQL dump: $SIZE"

    # Drop and recreate database (careful!)
    print_warning "Dropping existing lightrag database..."

    docker exec "$POSTGRES_CONTAINER" psql -U lightrag -c \
        "SELECT pg_terminate_backend(pg_stat_activity.pid)
         FROM pg_stat_activity
         WHERE pg_stat_activity.datname = 'lightrag'
         AND pid <> pg_backend_pid();" 2>/dev/null || true

    docker exec "$POSTGRES_CONTAINER" psql -U postgres -c \
        "DROP DATABASE IF EXISTS lightrag;" 2>/dev/null || true

    docker exec "$POSTGRES_CONTAINER" psql -U postgres -c \
        "CREATE DATABASE lightrag;" 2>/dev/null || true

    print_success "Database recreated"

    # Restore dump
    print_info "Restoring PostgreSQL data (this may take a while)..."
    docker exec -i "$POSTGRES_CONTAINER" psql -U lightrag -d lightrag \
        < "$BACKUP_DIR/postgres-dump.sql" 2>/dev/null || {
        print_error "PostgreSQL restore encountered issues"
    }

    print_success "PostgreSQL restore completed"
else
    print_error "PostgreSQL dump not found at: $BACKUP_DIR/postgres-dump.sql"
fi

# Step 3: Restore Neo4j
print_header "Step 3: Restoring Neo4j"

if [ -d "$BACKUP_DIR/neo4j-backup/data" ]; then
    print_info "Found Neo4j backup"

    # Stop Neo4j
    docker-compose stop neo4j || true
    sleep 5

    # Remove old data
    print_warning "Removing old Neo4j data..."
    rm -rf "$DATA_DIR/neo4j"/* 2>/dev/null || true

    # Copy backup data
    print_info "Restoring Neo4j data..."
    cp -r "$BACKUP_DIR/neo4j-backup/data"/* "$DATA_DIR/neo4j/" 2>/dev/null || {
        print_error "Failed to copy Neo4j data"
    }

    # Fix permissions
    chmod -R 755 "$DATA_DIR/neo4j"

    # Start Neo4j
    docker-compose up -d neo4j
    sleep 15

    print_success "Neo4j restore completed"
else
    print_warning "Neo4j backup not found at: $BACKUP_DIR/neo4j-backup/data"
fi

# Step 4: Restore LightRAG data
print_header "Step 4: Restoring LightRAG data"

if [ -d "$BACKUP_DIR/rag_storage" ]; then
    print_info "Found LightRAG storage backup"

    mkdir -p "$DATA_DIR/rag_storage"
    print_warning "Removing old LightRAG storage..."
    rm -rf "$DATA_DIR/rag_storage"/* 2>/dev/null || true

    print_info "Restoring LightRAG storage..."
    cp -r "$BACKUP_DIR/rag_storage"/* "$DATA_DIR/rag_storage/" 2>/dev/null || {
        print_error "Failed to restore LightRAG storage"
    }

    chmod -R 755 "$DATA_DIR/rag_storage"
    print_success "LightRAG storage restored"
else
    print_warning "LightRAG storage not found at: $BACKUP_DIR/rag_storage"
fi

# Step 5: Restore inputs
print_header "Step 5: Restoring inputs"

if [ -d "$BACKUP_DIR/inputs" ]; then
    print_info "Found inputs backup"

    mkdir -p "$DATA_DIR/inputs"
    print_warning "Removing old inputs..."
    rm -rf "$DATA_DIR/inputs"/* 2>/dev/null || true

    print_info "Restoring inputs..."
    cp -r "$BACKUP_DIR/inputs"/* "$DATA_DIR/inputs/" 2>/dev/null || {
        print_error "Failed to restore inputs"
    }

    chmod -R 755 "$DATA_DIR/inputs"
    print_success "Inputs restored"
else
    print_info "No inputs backup found"
fi

# Step 6: Verify restore
print_header "Step 6: Verifying restore"

# Check PostgreSQL
if docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER}$"; then
    POSTGRES_STATUS=$(docker inspect --format='{{.State.Status}}' "$POSTGRES_CONTAINER")
    if [ "$POSTGRES_STATUS" = "running" ]; then
        print_success "PostgreSQL is running"
    else
        print_error "PostgreSQL is not running"
    fi
fi

# Check Neo4j
if docker ps --format '{{.Names}}' | grep -q "^${NEO4J_CONTAINER}$"; then
    NEO4J_STATUS=$(docker inspect --format='{{.State.Status}}' "$NEO4J_CONTAINER")
    if [ "$NEO4J_STATUS" = "running" ]; then
        print_success "Neo4j is running"
    else
        print_error "Neo4j is not running"
    fi
fi

# Final summary
print_header "Restore Complete!"

echo -e "${GREEN}Restoration Summary:${NC}"
echo "  Source: $BACKUP_DIR"
echo "  Time: $(date)"
echo ""

if confirm "Start LightRAG now?"; then
    docker-compose up -d lightrag
    print_success "LightRAG started"

    sleep 5

    if docker ps --format '{{.Names}}' | grep -q "^lightrag$"; then
        print_success "LightRAG is running"
        echo ""
        print_info "Access your application at: http://localhost:9621"
    else
        print_error "LightRAG failed to start"
        echo "Check logs: docker-compose logs lightrag"
    fi
else
    print_info "Start LightRAG manually when ready: docker-compose up -d lightrag"
fi

echo ""
print_warning "IMPORTANT: Verify data integrity before production use!"
echo ""

exit 0
