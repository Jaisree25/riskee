# Database restore script for Windows
# Usage: .\scripts\db_restore.ps1 <backup_name>

param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$BackupName
)

$ErrorActionPreference = "Stop"

# Database connection
$DB_HOST = if ($env:DB_HOST) { $env:DB_HOST } else { "localhost" }
$DB_PORT = if ($env:DB_PORT) { $env:DB_PORT } else { "5432" }
$DB_NAME = if ($env:DB_NAME) { $env:DB_NAME } else { "riskee" }
$DB_USER = if ($env:DB_USER) { $env:DB_USER } else { "postgres" }
$DB_PASSWORD = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "riskee123" }

$env:PGPASSWORD = $DB_PASSWORD

# Backup file
$BACKUP_DIR = "backups"
$BACKUP_FILE = "$BACKUP_DIR\$BackupName.sql"

# Check if backup exists
if (-not (Test-Path $BACKUP_FILE)) {
    Write-Host "Error: Backup file not found" -ForegroundColor Red
    Write-Host "Looking for: $BACKUP_FILE"
    Write-Host ""
    Write-Host "Available backups:"
    Get-ChildItem "$BACKUP_DIR\*.sql" | ForEach-Object { Write-Host "  $($_.Name)" }
    exit 1
}

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Database Restore Script" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "WARNING: This will REPLACE all data in database '$DB_NAME'" -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "Are you sure? Type 'yes' to continue"

if ($confirm -ne "yes") {
    Write-Host "Restore cancelled"
    exit 0
}

Write-Host ""
Write-Host "[1/3] Dropping existing tables..." -ForegroundColor Yellow

# Drop all tables
$dropSql = @"
DROP TABLE IF EXISTS model_metadata CASCADE;
DROP TABLE IF EXISTS earnings_calendar CASCADE;
DROP TABLE IF EXISTS market_data CASCADE;
DROP TABLE IF EXISTS predictions CASCADE;
"@

psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $dropSql

Write-Host "[OK] Tables dropped" -ForegroundColor Green

Write-Host ""
Write-Host "[2/3] Restoring from backup..." -ForegroundColor Yellow

# Restore backup
Get-Content $BACKUP_FILE | psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME

Write-Host "[OK] Backup restored" -ForegroundColor Green

Write-Host ""
Write-Host "[3/3] Verifying tables..." -ForegroundColor Yellow

# Verify tables exist
$tableCount = psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';"

Write-Host "[OK] Found $($tableCount.Trim()) tables" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Database Restore Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
