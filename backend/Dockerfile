# ==============================================================================
# Production Dockerfile for Local Skill Exchange FastAPI Backend
# ==============================================================================
FROM python:3.11-slim

# Prevent Python from writing .pyc files and enable unbuffered logging
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    ENVIRONMENT=production

WORKDIR /app

# Install build dependencies for compiled extensions if needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Layer caching: copy requirements first
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /app/requirements.txt

# Build-time verification: ensure critical dependencies are installed and importable
RUN python -c "import email_validator; print('email-validator installed:', email_validator.__version__)"

# Copy application source code and seeding datasets
COPY app/ /app/app/
COPY data/ /app/data/
COPY scripts/ /app/scripts/
COPY run.py /app/run.py
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Ensure uploads directory structure exists
RUN mkdir -p /app/uploads/avatars

# Expose default port
EXPOSE 8000

# Health check probe for container orchestrators
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://127.0.0.1:${PORT:-8000}/health || exit 1

# Production startup via entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]

