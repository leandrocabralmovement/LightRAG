#!/bin/bash

################################################################################
# LightRAG Backup Script
# Backups PostgreSQL, Neo4j, and LightRAG data
#
# Usage: bash backup.sh [destination_dir]
# Example: bash backup.sh /backups
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKUP_DIR="${1:-.}/backups/$(date +%Y-%m-%d_%H-%M-%S)}"
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

# Check if containers are running
check_containers() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER}$"; then
        print_warning "PostgreSQL container not running"
    fi

    if ! docker ps --format '{{.Names}}' | grep -q "^${NEO4J_CONTAINER}$"; then
        print_warning "Neo4j container not running"
    fi
}

# Create backup directory
mkdir -p "$BACKUP_DIR"
print_success "Created backup directory: $BACKUP_DIR"

# Start backup
print_header "LightRAG Backup"
print_info "Backup destination: $BACKUP_DIR"
print_info "Start time: $(date)"

check_containers

# Step 1: Backup PostgreSQL
print_header "Step 1: Backing up PostgreSQL"

if docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER}$"; then
    POSTGRES_DUMP="$BACKUP_DIR/postgres-dump.sql"

    docker exec "$POSTGRES_CONTAINER" pg_dump -U lightrag -d lightrag \
        > "$POSTGRES_DUMP" 2>/dev/null || true

    if [ -f "$POSTGRES_DUMP" ] && [ -s "$POSTGRES_DUMP" ]; then
        SIZE=$(du -h "$POSTGRES_DUMP" | cut -f1)
        print_success "PostgreSQL backup created: $SIZE"
    else
        print_error "PostgreSQL backup failed or empty"
    fi
else
    print_warning "PostgreSQL container not running, skipping database dump"
fi

# Step 2: Backup Neo4j
print_header "Step 2: Backing up Neo4j"

if docker ps --format '{{.Names}}' | grep -q "^${NEO4J_CONTAINER}$"; then
    NEO4J_BACKUP="$BACKUP_DIR/neo4j-backup"
    mkdir -p "$NEO4J_BACKUP"

    # Copy Neo4j data directory
    docker cp "$NEO4J_CONTAINER:/data" "$NEO4J_BACKUP/" 2>/dev/null || true

    if [ -d "$NEO4J_BACKUP/data" ]; then
        SIZE=$(du -sh "$NEO4J_BACKUP" | cut -f1)
        print_success "Neo4j backup created: $SIZE"
    else
        print_error "Neo4j backup failed"
    fi
else
    print_warning "Neo4j container not running, skipping Neo4j backup"
fi

# Step 3: Backup LightRAG data
print_header "Step 3: Backing up LightRAG data"

if [ -d "$DATA_DIR/rag_storage" ]; then
    LIGHTRAG_BACKUP="$BACKUP_DIR/rag_storage"
    cp -r "$DATA_DIR/rag_storage" "$LIGHTRAG_BACKUP" 2>/dev/null || true

    SIZE=$(du -sh "$LIGHTRAG_BACKUP" 2>/dev/null | cut -f1 || echo "0B")
    print_success "LightRAG storage backup created: $SIZE"
else
    print_warning "LightRAG storage directory not found"
fi

# Step 4: Backup inputs
print_header "Step 4: Backing up inputs"

if [ -d "$DATA_DIR/inputs" ]; then
    INPUTS_BACKUP="$BACKUP_DIR/inputs"
    cp -r "$DATA_DIR/inputs" "$INPUTS_BACKUP" 2>/dev/null || true

    SIZE=$(du -sh "$INPUTS_BACKUP" 2>/dev/null | cut -f1 || echo "0B")
    print_success "Inputs backup created: $SIZE"
else
    print_info "No inputs directory to backup"
fi

# Step 5: Create backup metadata
print_header "Step 5: Creating backup metadata"

cat > "$BACKUP_DIR/BACKUP_INFO.txt" << EOF
LightRAG Backup Information
===========================

Backup Date: $(date)
Backup Path: $BACKUP_DIR

Contents:
---------
- postgres-dump.sql: PostgreSQL database dump (includes all vectors)
- neo4j-backup/: Neo4j database files (graph data)
- rag_storage/: LightRAG storage files
- inputs/: Input documents
- BACKUP_INFO.txt: This file

Restore Instructions:
--------------------

1. Stop services:
   docker-compose down

2. Remove old data:
   rm -rf ./data/{postgres,neo4j,rag_storage,inputs}

3. Restore PostgreSQL:
   docker exec lightrag-postgres psql -U lightrag -d lightrag < ./postgres-dump.sql

4. Restore Neo4j:
   cp -r ./neo4j-backup/data/* ./data/neo4j/

5. Restore LightRAG:
   mkdir -p ./data/rag_storage ./data/inputs
   cp -r ./rag_storage/* ./data/rag_storage/
   cp -r ./inputs/* ./data/inputs/

6. Start services:
   docker-compose up -d

Database Passwords (KEEP SECURE):
---------
- PostgreSQL: See .env (POSTGRES_PASSWORD)
- Neo4j: See .env (NEO4J_PASSWORD)

Notes:
------
- Keep this backup in a secure location
- Test restore procedures regularly
- Consider encrypting backups for production
- Upload to remote storage for disaster recovery
EOF

print_success "Backup metadata created"

# Step 6: Create tar archive
print_header "Step 6: Creating compressed archive"

TAR_FILE="$BACKUP_DIR.tar.gz"
if tar -czf "$TAR_FILE" "$BACKUP_DIR" 2>/dev/null; then
    SIZE=$(du -h "$TAR_FILE" | cut -f1)
    print_success "Compressed backup created: $SIZE"
    print_info "File: $TAR_FILE"
else
    print_warning "Failed to create compressed archive"
fi

# Final summary
print_header "Backup Complete!"

echo -e "${GREEN}Backup Summary:${NC}"
echo "  Location: $BACKUP_DIR"
echo "  Archive: $TAR_FILE"
echo "  Time: $(date)"
echo ""

if [ -f "$BACKUP_DIR/postgres-dump.sql" ]; then
    SIZE=$(du -h "$BACKUP_DIR/postgres-dump.sql" | cut -f1)
    echo "  PostgreSQL: $SIZE"
fi

if [ -d "$BACKUP_DIR/neo4j-backup/data" ]; then
    SIZE=$(du -sh "$BACKUP_DIR/neo4j-backup" | cut -f1)
    echo "  Neo4j: $SIZE"
fi

if [ -d "$BACKUP_DIR/rag_storage" ]; then
    SIZE=$(du -sh "$BACKUP_DIR/rag_storage" 2>/dev/null | cut -f1 || echo "0B")
    echo "  LightRAG Storage: $SIZE"
fi

echo ""
print_warning "IMPORTANT: Store backups in a secure location!"
echo ""

exit 0
