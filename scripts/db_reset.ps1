# Database reset script for Windows - drops all tables and recreates schema
# Usage: .\scripts\db_reset.ps1

$ErrorActionPreference = "Stop"

# Database connection
$DB_HOST = if ($env:DB_HOST) { $env:DB_HOST } else { "localhost" }
$DB_PORT = if ($env:DB_PORT) { $env:DB_PORT } else { "5432" }
$DB_NAME = if ($env:DB_NAME) { $env:DB_NAME } else { "riskee" }
$DB_USER = if ($env:DB_USER) { $env:DB_USER } else { "postgres" }
$DB_PASSWORD = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "riskee123" }

$env:PGPASSWORD = $DB_PASSWORD

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Database Reset Script" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "WARNING: This will DROP ALL TABLES in database '$DB_NAME'" -ForegroundColor Red
Write-Host "All data will be lost!" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "Are you sure? Type 'yes' to continue"

if ($confirm -ne "yes") {
    Write-Host "Reset cancelled"
    exit 0
}

Write-Host ""
Write-Host "[1/3] Dropping all tables..." -ForegroundColor Yellow

# Drop all tables
$dropSql = @"
DROP TABLE IF EXISTS model_metadata CASCADE;
DROP TABLE IF EXISTS earnings_calendar CASCADE;
DROP TABLE IF EXISTS market_data CASCADE;
DROP TABLE IF EXISTS predictions CASCADE;
"@

psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $dropSql

Write-Host "[OK] All tables dropped" -ForegroundColor Green

Write-Host ""
Write-Host "[2/3] Recreating schema from init script..." -ForegroundColor Yellow

# Run initialization script
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f scripts/init_timescaledb.sql

Write-Host "[OK] Schema recreated" -ForegroundColor Green

Write-Host ""
Write-Host "[3/3] Verifying tables..." -ForegroundColor Yellow

# Verify tables exist
$tableCount = psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';"

Write-Host "[OK] Found $($tableCount.Trim()) tables" -ForegroundColor Green

# List tables
Write-Host ""
Write-Host "Tables in database:"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "\dt"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Database Reset Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  - Run migrations: .\scripts\manage_migrations.ps1 upgrade"
Write-Host "  - Seed data (if needed): .\scripts\db_seed.ps1"
Write-Host ""
