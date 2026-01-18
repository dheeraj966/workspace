#!/bin/bash

# Development Environment Setup Script for Linux/macOS
# Usage: chmod +x ./scripts/setup.sh && ./scripts/setup.sh

set -e

echo -e "\033[36mSetting up Antigravity development environment...\033[0m"

# Check Python
echo -e "\033[33mChecking Python installation...\033[0m"
if ! command -v python3 &> /dev/null; then
    echo -e "\033[31mError: Python 3 is not installed. Please install Python 3.8+.\033[0m"
    exit 1
fi
PYTHON_VERSION=$(python3 --version)
echo -e "\033[32m$PYTHON_VERSION\033[0m"

# Create/Verify virtual environment
echo -e "\033[33mSetting up Python virtual environment...\033[0m"
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
    echo -e "\033[32mCreated virtual environment at .venv\033[0m"
else
    echo -e "\033[32mVirtual environment already exists\033[0m"
fi

# Activate virtual environment
echo -e "\033[33mActivating virtual environment...\033[0m"
source .venv/bin/activate
echo -e "\033[32mVirtual environment activated\033[0m"

# Upgrade pip
echo -e "\033[33mUpgrading pip...\033[0m"
python -m pip install --upgrade pip

# Install Python dependencies
if [ -f "requirements.txt" ]; then
    echo -e "\033[33mInstalling Python dependencies...\033[0m"
    pip install -r requirements.txt
fi

# Check Node.js
echo -e "\033[33mChecking Node.js installation...\033[0m"
if ! command -v node &> /dev/null; then
    echo -e "\033[31mError: Node.js is not installed. Please install Node.js 20.10.0 or later.\033[0m"
    exit 1
fi
NODE_VERSION=$(node -v)
echo -e "\033[32mNode.js version: $NODE_VERSION\033[0m"

# Check npm
echo -e "\033[33mChecking npm installation...\033[0m"
if ! command -v npm &> /dev/null; then
    echo -e "\033[31mError: npm is not installed.\033[0m"
    exit 1
fi
NPM_VERSION=$(npm -v)
echo -e "\033[32mnpm version: $NPM_VERSION\033[0m"

# Check Docker (optional)
echo -e "\033[33mChecking Docker installation...\033[0m"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo -e "\033[32mDocker found: $DOCKER_VERSION\033[0m"
else
    echo -e "\033[33mDocker not found (optional for this project)\033[0m"
fi

# Copy environment files
echo -e "\033[33mSetting up environment variables...\033[0m"
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "\033[32mCreated .env file from .env.example\033[0m"
else
    echo -e "\033[32m.env already exists\033[0m"
fi

# Install Node.js dependencies
echo -e "\033[33mInstalling Node.js dependencies...\033[0m"
npm install

# Build project
echo -e "\033[33mBuilding project...\033[0m"
npm run build

echo -e "\033[32mSetup completed successfully!\033[0m"
echo -e "\033[36mVirtual Environment Info:\033[0m"
echo -e "\033[33m  - Python venv location: .venv\033[0m"
echo -e "\033[33m  - To activate: source .venv/bin/activate\033[0m"
echo ""
echo -e "\033[36mNext steps:\033[0m"
echo -e "\033[33m  - Development: npm run dev\033[0m"
echo -e "\033[33m  - Python env: source .venv/bin/activate\033[0m"
echo -e "\033[33m  - Testing: npm test\033[0m"
echo -e "\033[33m  - Docker dev: docker-compose up\033[0m"
