#!/bin/bash
# Database reset script - drops all tables and recreates schema
# Usage: ./scripts/db_reset.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Database connection
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-riskee}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-riskee123}"

export PGPASSWORD=$DB_PASSWORD

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Database Reset Script${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "${RED}WARNING: This will DROP ALL TABLES in database '${DB_NAME}'${NC}"
echo -e "${RED}All data will be lost!${NC}"
echo ""
read -p "Are you sure? Type 'yes' to continue: " confirm

if [ "$confirm" != "yes" ]; then
    echo "Reset cancelled"
    exit 0
fi

echo ""
echo -e "${YELLOW}[1/3] Dropping all tables...${NC}"

# Drop all tables
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME <<EOF
-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS model_metadata CASCADE;
DROP TABLE IF EXISTS earnings_calendar CASCADE;
DROP TABLE IF EXISTS market_data CASCADE;
DROP TABLE IF EXISTS predictions CASCADE;
EOF

echo -e "${GREEN}[OK] All tables dropped${NC}"

echo ""
echo -e "${YELLOW}[2/3] Recreating schema from init script...${NC}"

# Run initialization script
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f scripts/init_timescaledb.sql

echo -e "${GREEN}[OK] Schema recreated${NC}"

echo ""
echo -e "${YELLOW}[3/3] Verifying tables...${NC}"

# Verify tables exist
table_count=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';")

echo -e "${GREEN}[OK] Found $table_count tables${NC}"

# List tables
echo ""
echo "Tables in database:"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "\dt"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Database Reset Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  - Run migrations: ./scripts/manage_migrations.sh upgrade"
echo "  - Seed data (if needed): ./scripts/db_seed.sh"
echo ""
