# Development Environment Setup Script for Windows
# Usage: ./scripts/setup.ps1

Write-Host "Setting up Antigravity development environment..." -ForegroundColor Cyan

# Check Python
Write-Host "Checking Python installation..." -ForegroundColor Yellow
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Python is not installed. Please install Python 3.8+ globally." -ForegroundColor Red
    exit 1
}
$pythonVersion = (python --version)
Write-Host "Python version: $pythonVersion" -ForegroundColor Green

# Create/Verify virtual environment
Write-Host "Setting up Python virtual environment..." -ForegroundColor Yellow
if (-not (Test-Path ".venv")) {
    python -m venv .venv
    Write-Host "Created virtual environment at .venv" -ForegroundColor Green
} else {
    Write-Host "Virtual environment already exists" -ForegroundColor Green
}

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
& ".\.\.venv\Scripts\Activate.ps1"
if ($?) {
    Write-Host "Virtual environment activated" -ForegroundColor Green
} else {
    Write-Host "Warning: Could not activate virtual environment" -ForegroundColor Yellow
}

# Upgrade pip
Write-Host "Upgrading pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip

# Install Python dependencies
if (Test-Path "requirements.txt") {
    Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
    pip install -r requirements.txt
}

# Check Node.js
Write-Host "Checking Node.js installation..." -ForegroundColor Yellow
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Node.js is not installed. Please install Node.js 20.10.0 or later." -ForegroundColor Red
    exit 1
}
$nodeVersion = (node -v)
Write-Host "Node.js version: $nodeVersion" -ForegroundColor Green

# Check npm
Write-Host "Checking npm installation..." -ForegroundColor Yellow
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "Error: npm is not installed." -ForegroundColor Red
    exit 1
}
$npmVersion = (npm -v)
Write-Host "npm version: $npmVersion" -ForegroundColor Green

# Check Docker (optional)
Write-Host "Checking Docker installation..." -ForegroundColor Yellow
if (Get-Command docker -ErrorAction SilentlyContinue) {
    $dockerVersion = (docker --version)
    Write-Host "Docker found: $dockerVersion" -ForegroundColor Green
} else {
    Write-Host "Docker not found (optional for this project)" -ForegroundColor Yellow
}

# Copy environment files
Write-Host "Setting up environment variables..." -ForegroundColor Yellow
if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
    Write-Host "Created .env file from .env.example" -ForegroundColor Green
} else {
    Write-Host ".env already exists" -ForegroundColor Green
}

# Install Node.js dependencies
Write-Host "Installing Node.js dependencies..." -ForegroundColor Yellow
npm install

# Build project
Write-Host "Building project..." -ForegroundColor Yellow
npm run build

Write-Host "Setup completed successfully!" -ForegroundColor Green
Write-Host "Virtual Environment Info:" -ForegroundColor Cyan
Write-Host "  - Python venv location: .venv" -ForegroundColor Yellow
Write-Host "  - To activate: .venv\Scripts\Activate.ps1" -ForegroundColor Yellow
Write-Host "" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  - Development: npm run dev" -ForegroundColor Yellow
Write-Host "  - Python env: .venv\Scripts\Activate.ps1" -ForegroundColor Yellow
Write-Host "  - Testing: npm test" -ForegroundColor Yellow
Write-Host "  - Docker dev: docker-compose up" -ForegroundColor Yellow
