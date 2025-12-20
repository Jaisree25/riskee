#!/bin/bash
# Database restore script
# Usage: ./scripts/db_restore.sh <backup_name>

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check arguments
if [ -z "$1" ]; then
    echo -e "${RED}Error: Backup name required${NC}"
    echo "Usage: $0 <backup_name>"
    echo ""
    echo "Available backups:"
    ls -1 backups/*.sql.gz 2>/dev/null || echo "  No backups found"
    exit 1
fi

# Database connection
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-riskee}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-riskee123}"

export PGPASSWORD=$DB_PASSWORD

# Backup file
BACKUP_DIR="backups"
BACKUP_NAME="$1"
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}.sql"
BACKUP_FILE_GZ="${BACKUP_FILE}.gz"

# Check if backup exists
if [ ! -f "$BACKUP_FILE" ] && [ ! -f "$BACKUP_FILE_GZ" ]; then
    echo -e "${RED}Error: Backup file not found${NC}"
    echo "Looking for: $BACKUP_FILE or $BACKUP_FILE_GZ"
    exit 1
fi

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Database Restore Script${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "${RED}WARNING: This will REPLACE all data in database '${DB_NAME}'${NC}"
echo ""
read -p "Are you sure? Type 'yes' to continue: " confirm

if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

echo ""

# Decompress if needed
if [ -f "$BACKUP_FILE_GZ" ] && [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${YELLOW}[1/4] Decompressing backup...${NC}"
    gunzip -k $BACKUP_FILE_GZ
    echo -e "${GREEN}[OK] Backup decompressed${NC}"
    echo ""
fi

echo -e "${YELLOW}[2/4] Dropping existing tables...${NC}"

# Drop all tables
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME <<EOF
DROP TABLE IF EXISTS model_metadata CASCADE;
DROP TABLE IF EXISTS earnings_calendar CASCADE;
DROP TABLE IF EXISTS market_data CASCADE;
DROP TABLE IF EXISTS predictions CASCADE;
EOF

echo -e "${GREEN}[OK] Tables dropped${NC}"

echo ""
echo -e "${YELLOW}[3/4] Restoring from backup...${NC}"

# Restore backup
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < $BACKUP_FILE

echo -e "${GREEN}[OK] Backup restored${NC}"

echo ""
echo -e "${YELLOW}[4/4] Verifying tables...${NC}"

# Verify tables exist
table_count=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';")

echo -e "${GREEN}[OK] Found $table_count tables${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Database Restore Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
