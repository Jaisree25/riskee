#!/bin/bash
# Database backup script
# Usage: ./scripts/db_backup.sh [backup_name]

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Database connection
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-riskee}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-riskee123}"

export PGPASSWORD=$DB_PASSWORD

# Backup directory
BACKUP_DIR="backups"
mkdir -p $BACKUP_DIR

# Backup filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="${1:-backup_${TIMESTAMP}}"
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}.sql"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Database Backup Script${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "Database: $DB_NAME"
echo "Backup file: $BACKUP_FILE"
echo ""

echo -e "${YELLOW}[1/3] Creating backup...${NC}"

# Create backup using pg_dump
pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME \
    --format=plain \
    --no-owner \
    --no-acl \
    --verbose \
    > $BACKUP_FILE 2>&1

echo -e "${GREEN}[OK] Backup created${NC}"

echo ""
echo -e "${YELLOW}[2/3] Compressing backup...${NC}"

# Compress backup
gzip -f $BACKUP_FILE

BACKUP_FILE_GZ="${BACKUP_FILE}.gz"

echo -e "${GREEN}[OK] Backup compressed${NC}"

echo ""
echo -e "${YELLOW}[3/3] Backup information...${NC}"

# Get file size
BACKUP_SIZE=$(ls -lh $BACKUP_FILE_GZ | awk '{print $5}')

echo -e "${GREEN}[OK] Backup complete${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Backup Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Backup file: $BACKUP_FILE_GZ"
echo "Size: $BACKUP_SIZE"
echo "Created: $(date)"
echo ""
echo "To restore:"
echo "  gunzip $BACKUP_FILE_GZ"
echo "  ./scripts/db_restore.sh $BACKUP_NAME"
echo ""
