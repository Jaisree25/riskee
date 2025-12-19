# Database migration management script for Windows
# Run with: .\scripts\manage_migrations.ps1 [command]

param(
    [Parameter(Position=0)]
    [string]$Command = "help",
    [Parameter(Position=1)]
    [string]$Name = ""
)

$ErrorActionPreference = "Stop"

# Database connection
$DB_HOST = if ($env:DB_HOST) { $env:DB_HOST } else { "localhost" }
$DB_PORT = if ($env:DB_PORT) { $env:DB_PORT } else { "5432" }
$DB_NAME = if ($env:DB_NAME) { $env:DB_NAME } else { "riskee" }
$DB_USER = if ($env:DB_USER) { $env:DB_USER } else { "postgres" }
$DB_PASSWORD = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "riskee123" }

$env:DATABASE_URL = "postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

Write-Host "========================================"
Write-Host "Database Migration Management"
Write-Host "========================================"
Write-Host ""

function Show-Help {
    Write-Host "Usage: .\manage_migrations.ps1 [command]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  upgrade       - Apply all pending migrations"
    Write-Host "  downgrade     - Rollback last migration"
    Write-Host "  current       - Show current migration version"
    Write-Host "  history       - Show migration history"
    Write-Host "  create [name] - Create a new migration"
    Write-Host "  reset         - Reset database (DROP ALL TABLES)"
    Write-Host "  help          - Show this help message"
    Write-Host ""
}

function Test-DatabaseConnection {
    Write-Host "Checking database connection..." -ForegroundColor Yellow
    try {
        $env:PGPASSWORD = $DB_PASSWORD
        $testQuery = "SELECT 1"
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $testQuery | Out-Null
        Write-Host "[OK] Connected to database" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[ERROR] Cannot connect to database" -ForegroundColor Red
        return $false
    }
}

switch ($Command.ToLower()) {
    "upgrade" {
        if (Test-DatabaseConnection) {
            Write-Host "Applying migrations..." -ForegroundColor Yellow
            alembic upgrade head
            Write-Host "[OK] Migrations applied" -ForegroundColor Green
        }
    }

    "downgrade" {
        if (Test-DatabaseConnection) {
            Write-Host "Rolling back last migration..." -ForegroundColor Yellow
            alembic downgrade -1
            Write-Host "[OK] Migration rolled back" -ForegroundColor Green
        }
    }

    "current" {
        if (Test-DatabaseConnection) {
            Write-Host "Current migration version:" -ForegroundColor Yellow
            alembic current
        }
    }

    "history" {
        Write-Host "Migration history:" -ForegroundColor Yellow
        alembic history --verbose
    }

    "create" {
        if ($Name -eq "") {
            Write-Host "[ERROR] Migration name required" -ForegroundColor Red
            Write-Host "Usage: .\manage_migrations.ps1 create <migration_name>"
            exit 1
        }
        Write-Host "Creating new migration: $Name" -ForegroundColor Yellow
        alembic revision -m $Name
        Write-Host "[OK] Migration created" -ForegroundColor Green
    }

    "reset" {
        if (Test-DatabaseConnection) {
            Write-Host "WARNING: This will DROP ALL TABLES" -ForegroundColor Red
            $confirm = Read-Host "Are you sure? (yes/no)"
            if ($confirm -eq "yes") {
                Write-Host "Dropping all tables..." -ForegroundColor Yellow
                alembic downgrade base
                Write-Host "[OK] Database reset" -ForegroundColor Green
            } else {
                Write-Host "Reset cancelled"
            }
        }
    }

    default {
        Show-Help
    }
}
