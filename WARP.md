# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Antigravity is an ML (Machine Learning) project built with Node.js, TypeScript, Docker, and Python. The project emphasizes developer-friendly setup with automatic environment configuration, cross-platform support (Windows, Linux, macOS), containerized development workflows, and isolated Python virtual environments.

## Quick Commands

### Development
- `npm run dev` - Start development server with file watching
- `npm run build` - Compile TypeScript to JavaScript
- `npm test` - Run all unit tests
- `npm test:watch` - Run tests in watch mode
- `npm run lint` - Lint and automatically fix code issues
- `npm run format` - Format code with Prettier
- `npm run type-check` - Perform TypeScript type checking without emitting files

### Docker & Containers
- `npm run docker:build` - Build production Docker image
- `npm run docker:dev` - Start development container with docker-compose
- `npm run docker:dev:down` - Stop development containers

### Cleanup & Maintenance
- `npm run clean` - Remove build artifacts and node_modules
- `npm run setup` - Full setup: install dependencies and build

### Setup Scripts (Platform-specific)
- **Windows**: `.\scripts\setup.ps1` - PowerShell setup with dependency checks
- **Linux/macOS**: `./scripts/setup.sh` - Bash setup with dependency validation

### Python Virtual Environment
- **Location**: `.venv/` directory (isolated from system Python)
- **Windows activation**: `.venv\Scripts\Activate.ps1`
- **Linux/macOS activation**: `source .venv/bin/activate`
- **Auto-created**: Setup scripts automatically create and activate venv
- **Dependencies**: Install via `pip install -r requirements.txt`

## Architecture & Structure

### Directory Layout
```
src/                  # TypeScript source code
├── index.ts          # Main application entry point
├── __tests__/        # Unit tests (Jest)
dist/                 # Compiled JavaScript output (generated)
scripts/              # Cross-platform setup and cleanup scripts
```

### Core Technologies
- **Language**: TypeScript (ES2020 module system) & Python 3.8+
- **Runtime**: Node.js 20.10.0+ (locked via .nvmrc)
- **Package Managers**: npm (Node.js), pip (Python)
- **Testing**: Jest with ts-jest preset
- **Linting**: ESLint + @typescript-eslint for type-aware linting
- **Code Formatting**: Prettier (100 char line width, 2-space tabs)
- **Containerization**: Docker multi-stage builds + docker-compose
- **Python Environment**: Virtual environment (.venv) for isolation

### Configuration Files

| File | Purpose |
|------|---------|
| `package.json` | npm scripts, dependencies, project metadata |
| `tsconfig.json` | TypeScript strict mode, ES2020 target, module resolution |
| `.eslintrc.json` | ESLint rules, parser configuration |
| `.prettierrc.json` | Code formatting standards |
| `jest.config.ts` | Jest testing framework configuration with ts-jest |
| `.nvmrc` | Node.js version lock (20.10.0) |
| `Dockerfile` | Multi-stage build (development/builder/production stages) |
| `docker-compose.yml` | Local development orchestration with volume mounts |
| `.env.example` | Template for environment variables (copy to .env) |
| `.gitignore` | Excludes node_modules, dist, .env, IDE files |
| `.dockerignore` | Excludes development files from Docker builds |
| `.husky.config.js` | Git hook configuration (pre-commit/pre-push) |
| `.lintstagedrc.json` | Pre-commit linting of staged TypeScript files |
| `requirements.txt` | Python dependencies for pip installation |

## Development Workflow

### First Time Setup
1. Run platform-specific setup script (`./scripts/setup.ps1` or `./scripts/setup.sh`)
2. Script checks Node.js, npm, and Docker availability
3. Creates `.env` file from `.env.example`
4. Installs dependencies via `npm install`
5. Builds project with `npm run build`

### Daily Development
```bash
npm run dev        # Start with file watching
npm test:watch     # Run tests as you code
npm run lint       # Fix linting issues before commit
```

### Before Committing
Git hooks automatically run via Husky:
- ESLint fixes staged files
- Prettier formats staged files
- Type checking runs
- All tests must pass

### Docker Development
```bash
docker-compose up          # Start dev container with hot-reload
# Edit code locally, container reflects changes
docker-compose down        # Stop containers
```

## Key Dependencies

### Production-Ready
- (Currently empty - add as needed)

### Development
- **typescript** - TypeScript compiler and type definitions
- **@typescript-eslint/parser** - ESLint support for TypeScript
- **@typescript-eslint/eslint-plugin** - Type-aware ESLint rules
- **eslint** - Code linting
- **prettier** - Code formatting
- **jest** - Unit test framework
- **ts-jest** - TypeScript support for Jest
- **@types/node** - Node.js type definitions

## Environment Configuration

The project uses `.env` files for environment-specific configuration:
- `.env.example` - Template with documented variables
- `.env` - Local development (created by setup script, git-ignored)
- Variables: `NODE_ENV`, `LOG_LEVEL`

## Python Virtual Environment

### Setup & Activation
A Python virtual environment is automatically created in `.venv/` directory during setup for complete isolation from system Python.

Windows (PowerShell):
```powershell
.venv\Scripts\Activate.ps1
```

Linux/macOS (Bash):
```bash
source .venv/bin/activate
```

### Python Dependencies
- File: `requirements.txt`
- Install: `pip install -r requirements.txt`
- Update: Add new dependencies and run pip install or let setup script handle it
- Deactivate: Run `deactivate` when done

### Benefits of Virtual Environment
- Isolation: Project dependencies don't affect system Python
- Reproducibility: Same versions across all developers
- Clean Environment: Only necessary packages installed
- Easy Cleanup: Delete `.venv/` directory to reset

## Docker Architecture

### Multi-Stage Build
1. **base** - Node.js 20.10.0 Alpine image, sets /app workdir
2. **development** - Install all deps, mount code volume, watch mode enabled
3. **builder** - Production deps only, compiles TypeScript
4. **production** - Minimal image with compiled code and production deps only

### Docker Compose
- Service name: `app`
- Mounts source code and node_modules as separate volumes
- Port 3000 exposed
- Auto-restart unless stopped
- Runs `npm run dev` with file watching

## Git Integration

### Ignored Files
- `node_modules/` - Dependencies
- `dist/`, `build/` - Build artifacts
- `.env`, `.env.local` - Environment variables
- `coverage/` - Test coverage reports
- `.vscode/`, `.idea/` - IDE configuration
- OS files (`.DS_Store`, `Thumbs.db`)

### Pre-commit Hooks
Configured via `.husky.config.js` and `.lintstagedrc.json`:
- Auto-fixes TypeScript linting issues
- Auto-formats with Prettier
- Validates type safety
- Prevents commits without passing tests

## Testing

### Running Tests
```bash
npm test              # Run once
npm test:watch        # Watch mode during development
npm test:coverage     # Generate coverage report
```

### Test Structure
- Test files: `src/**/*.test.ts` or `src/**/*.spec.ts`
- Jest environment: Node.js (not browser)
- TypeScript modules: ESM with proper extensions
- Coverage reports in `coverage/` directory

## Automatic Adjustments & Flexibility

### Environment Auto-Detection
Setup scripts automatically:
- Detect OS (Windows/Linux/macOS) and use appropriate tooling
- Check for required tools (Node.js, npm, Docker)
- Provide clear error messages if dependencies missing
- Copy environment template to create `.env`

### Configurable Elements
All major settings can be adjusted:
- **Node.js version**: Edit `.nvmrc`
- **Build target**: Change `tsconfig.json` `target` field
- **ESLint rules**: Modify `.eslintrc.json`
- **Prettier formatting**: Update `.prettierrc.json`
- **Docker resources**: Edit `docker-compose.yml` with memory/CPU limits
- **Port mappings**: Adjust port forwarding in `docker-compose.yml`

## Common Tasks for WARP

### Adding a New Dependency
1. Add to `package.json` `devDependencies` or `dependencies`
2. Run `npm install`
3. Update `Dockerfile` if needed for production builds

### Running a Single Test
```bash
npm test -- src/__tests__/specific.test.ts
```

### Debugging in Docker
```bash
docker-compose exec app npm run dev
# Or connect a debugger to port 9229 after enabling in Dockerfile
```

### Building for Production
```bash
npm run build                  # Compile TypeScript
npm run docker:prod           # Build production image
docker run -p 3000:3000 antigravity:prod
```

### Type Checking Without Build
```bash
npm run type-check            # Check types only, don't emit files
```

## Notes for Future Agents

- **Windows compatibility**: All scripts have both `.ps1` (PowerShell) and `.sh` variants
- **Docker optional**: The project works without Docker; containers are for development convenience
- **ESM modules**: Project uses `"type": "module"` in package.json for ES module support
- **No pre-existing code**: src/ directory minimal with only entry point and example test to get started quickly
- **Multi-stage Docker builds**: Keeps production images lean and separate from development dependencies
