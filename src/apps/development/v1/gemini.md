# Ollama (App v1) - Development Analysis

## Overview
**Ollama** is a lightweight, extensible framework for running Large Language Models (LLMs) locally. It serves as **App v1** in the Antigravity project.

- **Stack**: Go (Golang)
- **Primary Interface**: HTTP API (port 11434) & CLI
- **Key Capability**: Inference Server for GGUF/Llama models

## Directory Structure

| Directory | Purpose |
|-----------|---------|
| `cmd/` | CLI entry points (`serve`, `run`, `pull`, `create`) |
| `server/` | HTTP API Routes (`routes.go`) and middleware |
| `llm/` | Low-level LLM inference binding (llama.cpp integration) |
| `api/` | Client library for interacting with the server |

## Development Workflow

### Building
The project uses `go build`. In the Docker container, this is handled by the `Dockerfile`.
```bash
go build -o ollama .
```

### Running Logic
The entry point is `main.go`, which invokes `cmd.NewCLI()`.
- **Server Mode**: `ollama serve` starts the HTTP server.
- **Client Mode**: `ollama run <model>` connects to the server.

### Application Integration
To integrate this into the rest of Antigravity:
1.  **API**: Use the REST API at `http://localhost:11434/api`.
    -   `POST /api/chat`: Chat completion
    -   `POST /api/generate`: Text generation
2.  **Models**: Mount models to `~/.ollama/models` (or `models/stable` in our architecture).

## Next Steps
- Verify `docker-compose up app-v1` works.
- Test model loading from `models/stable`.
