# Database backup script for Windows
# Usage: .\scripts\db_backup.ps1 [backup_name]

param(
    [Parameter(Position=0)]
    [string]$BackupName = ""
)

$ErrorActionPreference = "Stop"

# Database connection
$DB_HOST = if ($env:DB_HOST) { $env:DB_HOST } else { "localhost" }
$DB_PORT = if ($env:DB_PORT) { $env:DB_PORT } else { "5432" }
$DB_NAME = if ($env:DB_NAME) { $env:DB_NAME } else { "riskee" }
$DB_USER = if ($env:DB_USER) { $env:DB_USER } else { "postgres" }
$DB_PASSWORD = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "riskee123" }

$env:PGPASSWORD = $DB_PASSWORD

# Backup directory
$BACKUP_DIR = "backups"
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
}

# Backup filename
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
if ($BackupName -eq "") {
    $BackupName = "backup_$TIMESTAMP"
}
$BACKUP_FILE = "$BACKUP_DIR\$BackupName.sql"

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Database Backup Script" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Database: $DB_NAME"
Write-Host "Backup file: $BACKUP_FILE"
Write-Host ""

Write-Host "[1/2] Creating backup..." -ForegroundColor Yellow

# Create backup using pg_dump
pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME `
    --format=plain `
    --no-owner `
    --no-acl `
    --file=$BACKUP_FILE

Write-Host "[OK] Backup created" -ForegroundColor Green

Write-Host ""
Write-Host "[2/2] Backup information..." -ForegroundColor Yellow

# Get file size
$BACKUP_SIZE = (Get-Item $BACKUP_FILE).Length / 1MB
$BACKUP_SIZE_MB = [math]::Round($BACKUP_SIZE, 2)

Write-Host "[OK] Backup complete" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Backup Summary" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Backup file: $BACKUP_FILE"
Write-Host "Size: $BACKUP_SIZE_MB MB"
Write-Host "Created: $(Get-Date)"
Write-Host ""
Write-Host "To restore:"
Write-Host "  .\scripts\db_restore.ps1 $BackupName"
Write-Host ""
