# Cleanup Development Environment
# Usage: ./scripts/cleanup.ps1

Write-Host "Cleaning up development environment..." -ForegroundColor Cyan

# Clean build output
Write-Host "Removing build output..." -ForegroundColor Yellow
Remove-Item -Path dist -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Build output removed" -ForegroundColor Green

# Clean test coverage
Write-Host "Removing test coverage..." -ForegroundColor Yellow
Remove-Item -Path coverage -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Test coverage removed" -ForegroundColor Green

# Clean node modules (optional)
Write-Host "Note: node_modules directory not removed (use 'npm ci' to reinstall)" -ForegroundColor Yellow

Write-Host "Cleanup completed!" -ForegroundColor Green
