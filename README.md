# Antigravity - ML Project

A machine learning project built with Node.js, TypeScript, and Docker for automatic adjustment and dynamic configuration.

## Quick Start

### Setup (choose your OS)

**Windows:**
```powershell
.\scripts\setup.ps1
```

**Linux/macOS:**
```bash
chmod +x ./scripts/setup.sh
./scripts/setup.sh
```

### Development

```bash
# Install dependencies
npm install

# Start development server with file watching
npm run dev

# Run tests
npm test

# Run tests in watch mode
npm test:watch

# Run linting and formatting
npm run lint
npm run format

# Type check
npm run type-check

# Build for production
npm run build
```

### Docker Development

```bash
# Build and start development container
docker-compose up

# Shutdown containers
docker-compose down

# Build production image
npm run docker:prod
```

### Cleanup

**Windows:**
```powershell
.\scripts\cleanup.ps1
```

**Linux/macOS:**
```bash
chmod +x ./scripts/cleanup.sh
./scripts/cleanup.sh
```

## Project Structure

```
.
├── src/                    # Source code
├── dist/                   # Compiled output
├── scripts/                # Development scripts
├── tests/                  # Test files
├── .env.example            # Environment variables template
├── package.json            # Dependencies and scripts
├── tsconfig.json           # TypeScript configuration
├── jest.config.js          # Testing configuration
├── .eslintrc.json          # Linting rules
├── .prettierrc.json        # Code formatting rules
├── Dockerfile              # Multi-stage Docker build
└── docker-compose.yml      # Docker Compose setup
```

## Configuration Files

- `.nvmrc` - Node.js version specification (20.10.0)
- `.env.example` - Template for environment variables
- `.gitignore` - Git ignore rules
- `.dockerignore` - Docker build ignore rules
- `.husky.config.js` - Git hooks configuration
- `.lintstagedrc.json` - Pre-commit linting rules

## Available Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server with auto-reload |
| `npm run build` | Build for production |
| `npm run lint` | Lint and fix code |
| `npm run format` | Format code with Prettier |
| `npm test` | Run all tests |
| `npm test:watch` | Run tests in watch mode |
| `npm test:coverage` | Generate test coverage report |
| `npm run type-check` | Check TypeScript types |
| `npm run clean` | Clean build and node_modules |
| `npm run setup` | Install and build |
| `npm run docker:build` | Build Docker image |
| `npm run docker:dev` | Run development container |
| `npm run docker:dev:down` | Stop development container |

## Environment Variables

Copy `.env.example` to `.env` and update values:

```env
NODE_ENV=development
LOG_LEVEL=info
```

## Requirements

- Node.js 20.10.0+
- npm 10.0.0+
- Docker (optional, for containerized development)
- Git

## Git Hooks

Pre-commit hooks automatically run:
- ESLint with fixes
- Prettier formatting
- Type checking
- Tests

## License

MIT
