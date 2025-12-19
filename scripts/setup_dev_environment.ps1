# Development environment setup script for Windows
# Run with: .\scripts\setup_dev_environment.ps1

$ErrorActionPreference = "Stop"

Write-Host "========================================"
Write-Host "Riskee Development Environment Setup"
Write-Host "========================================"
Write-Host ""

# Check Python version
Write-Host "[1/6] Checking Python version..."
try {
    $pythonVersion = (python --version 2>&1).ToString().Split(" ")[1]
    $requiredVersion = [version]"3.11.0"
    $currentVersion = [version]$pythonVersion

    if ($currentVersion -lt $requiredVersion) {
        Write-Host "Error: Python 3.11+ required. Found: $pythonVersion" -ForegroundColor Red
        exit 1
    }
    Write-Host "[OK] Python $pythonVersion found" -ForegroundColor Green
} catch {
    Write-Host "Error: Python not found or not in PATH" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Create virtual environment
Write-Host "[2/6] Creating virtual environment..."
if (!(Test-Path "venv")) {
    python -m venv venv
    Write-Host "[OK] Virtual environment created" -ForegroundColor Green
} else {
    Write-Host "[OK] Virtual environment already exists" -ForegroundColor Green
}
Write-Host ""

# Activate virtual environment
Write-Host "[3/6] Activating virtual environment..."
& .\venv\Scripts\Activate.ps1
Write-Host "[OK] Virtual environment activated" -ForegroundColor Green
Write-Host ""

# Install dependencies
Write-Host "[4/6] Installing dependencies..."
python -m pip install --upgrade pip setuptools wheel
python -m pip install -e ".[dev]"
Write-Host "[OK] Dependencies installed" -ForegroundColor Green
Write-Host ""

# Install pre-commit hooks
Write-Host "[5/6] Installing pre-commit hooks..."
pre-commit install
Write-Host "[OK] Pre-commit hooks installed" -ForegroundColor Green
Write-Host ""

# Run initial checks
Write-Host "[6/6] Running initial checks..."
Write-Host ""
Write-Host "Running ruff..."
ruff check . --fix
Write-Host ""
Write-Host "Running tests..."
pytest tests/ -v --tb=short
Write-Host ""

Write-Host "========================================"
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Start infrastructure: docker-compose up -d"
Write-Host "2. Activate venv: .\venv\Scripts\Activate.ps1"
Write-Host "3. Run tests: pytest"
Write-Host "4. Start development!"
Write-Host ""
