#!/bin/bash
# Database migration management script

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Database connection
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-riskee}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-riskee123}"

export DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

echo "========================================"
echo "Database Migration Management"
echo "========================================"
echo ""

# Function to show help
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  upgrade       - Apply all pending migrations"
    echo "  downgrade     - Rollback last migration"
    echo "  current       - Show current migration version"
    echo "  history       - Show migration history"
    echo "  create [name] - Create a new migration"
    echo "  reset         - Reset database (DROP ALL TABLES)"
    echo "  help          - Show this help message"
    echo ""
}

# Function to check database connection
check_connection() {
    echo -e "${YELLOW}Checking database connection...${NC}"
    if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1" > /dev/null 2>&1; then
        echo -e "${GREEN}[OK] Connected to database${NC}"
    else
        echo -e "${RED}[ERROR] Cannot connect to database${NC}"
        exit 1
    fi
}

# Parse command
COMMAND="${1:-help}"

case "$COMMAND" in
    upgrade)
        check_connection
        echo -e "${YELLOW}Applying migrations...${NC}"
        alembic upgrade head
        echo -e "${GREEN}[OK] Migrations applied${NC}"
        ;;

    downgrade)
        check_connection
        echo -e "${YELLOW}Rolling back last migration...${NC}"
        alembic downgrade -1
        echo -e "${GREEN}[OK] Migration rolled back${NC}"
        ;;

    current)
        check_connection
        echo -e "${YELLOW}Current migration version:${NC}"
        alembic current
        ;;

    history)
        echo -e "${YELLOW}Migration history:${NC}"
        alembic history --verbose
        ;;

    create)
        if [ -z "$2" ]; then
            echo -e "${RED}[ERROR] Migration name required${NC}"
            echo "Usage: $0 create <migration_name>"
            exit 1
        fi
        echo -e "${YELLOW}Creating new migration: $2${NC}"
        alembic revision -m "$2"
        echo -e "${GREEN}[OK] Migration created${NC}"
        ;;

    reset)
        check_connection
        echo -e "${RED}WARNING: This will DROP ALL TABLES${NC}"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" == "yes" ]; then
            echo -e "${YELLOW}Dropping all tables...${NC}"
            alembic downgrade base
            echo -e "${GREEN}[OK] Database reset${NC}"
        else
            echo "Reset cancelled"
        fi
        ;;

    help|*)
        show_help
        ;;
esac
