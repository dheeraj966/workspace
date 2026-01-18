#!/bin/bash

# Cleanup Development Environment
# Usage: chmod +x ./scripts/cleanup.sh && ./scripts/cleanup.sh

echo -e "\033[36mCleaning up development environment...\033[0m"

# Clean build output
echo -e "\033[33mRemoving build output...\033[0m"
rm -rf dist/
echo -e "\033[32mBuild output removed\033[0m"

# Clean test coverage
echo -e "\033[33mRemoving test coverage...\033[0m"
rm -rf coverage/
echo -e "\033[32mTest coverage removed\033[0m"

# Clean node modules (optional)
echo -e "\033[33mNote: node_modules directory not removed (use 'npm ci' to reinstall)\033[0m"

echo -e "\033[32mCleanup completed!\033[0m"
