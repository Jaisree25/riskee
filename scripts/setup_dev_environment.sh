#!/bin/bash
# Development environment setup script

set -e

echo "========================================"
echo "Riskee Development Environment Setup"
echo "========================================"
echo ""

# Check Python version
echo "[1/6] Checking Python version..."
python_version=$(python3 --version 2>&1 | awk '{print $2}')
required_version="3.11"

if [[ $(echo -e "$required_version\n$python_version" | sort -V | head -n1) != "$required_version" ]]; then
    echo "Error: Python 3.11+ required. Found: $python_version"
    exit 1
fi
echo "✓ Python $python_version found"
echo ""

# Create virtual environment
echo "[2/6] Creating virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✓ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi
echo ""

# Activate virtual environment
echo "[3/6] Activating virtual environment..."
source venv/bin/activate
echo "✓ Virtual environment activated"
echo ""

# Install dependencies
echo "[4/6] Installing dependencies..."
pip install --upgrade pip setuptools wheel
pip install -e ".[dev]"
echo "✓ Dependencies installed"
echo ""

# Install pre-commit hooks
echo "[5/6] Installing pre-commit hooks..."
pre-commit install
echo "✓ Pre-commit hooks installed"
echo ""

# Run initial checks
echo "[6/6] Running initial checks..."
echo ""
echo "Running ruff..."
ruff check . --fix || true
echo ""
echo "Running tests..."
pytest tests/ -v --tb=short || true
echo ""

echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Start infrastructure: docker-compose up -d"
echo "2. Activate venv: source venv/bin/activate"
echo "3. Run tests: pytest"
echo "4. Start development!"
echo ""
