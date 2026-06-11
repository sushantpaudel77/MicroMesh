# ============ BUILDER STAGE ============
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    make \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies to a specific directory
RUN pip install --no-cache-dir --user -r requirements.txt

# ============ RUNTIME STAGE ============
FROM python:3.11-slim AS runtime

WORKDIR /app

# Create non-root user
RUN groupadd -r cartservice && \
    useradd -r -g cartservice -d /app -s /sbin/nologin cartservice

# Install only runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy Python packages from builder
COPY --from=builder /root/.local /usr/local

# Copy application code
COPY --chown=cartservice:cartservice . .

# Create necessary directories
RUN mkdir -p /app/logs && \
    chown -R cartservice:cartservice /app

# Switch to non-root user
USER cartservice

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8002/health || exit 1

EXPOSE 8002

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002", "--workers", "1", "--log-level", "info"]