# =============================================================================
# Antigravity ML Dockerfile
# =============================================================================
# Multi-stage build for ML containers (research, redesign, promoter)
# =============================================================================

# -----------------------------------------------------------------------------
# Base Stage - Python runtime with ML dependencies
# -----------------------------------------------------------------------------
FROM python:3.11-slim AS base

WORKDIR /app

# Install system dependencies for ML libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# -----------------------------------------------------------------------------
# Development Stage - Full ML environment with dev tools
# -----------------------------------------------------------------------------
FROM base AS development

# Install additional dev tools
RUN pip install --no-cache-dir \
    ipython \
    jupyter \
    notebook

# Copy source code
COPY . .

# Set Python path
ENV PYTHONPATH=/app

# Default command (overridden by docker-compose)
CMD ["python", "-c", "print('ML Development container ready')"]

# -----------------------------------------------------------------------------
# Production Stage - Minimal runtime for inference
# -----------------------------------------------------------------------------
FROM base AS production

# Copy only necessary files
COPY --from=development /app/src/ml /app/src/ml
COPY --from=development /app/scripts /app/scripts

ENV PYTHONPATH=/app

CMD ["python", "-c", "print('ML Production container ready')"]
