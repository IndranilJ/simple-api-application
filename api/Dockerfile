# Dockerfile for a FastAPI application
# Expects a requirements.txt in the project root and an ASGI app at `main:app`
FROM python:3.11-slim AS builder

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# Install build dependencies for packages that need compilation
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --upgrade pip \
    && pip install --prefix=/install --no-cache-dir -r requirements.txt

# Final image
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# Copy installed packages from builder stage
COPY --from=builder /install /usr/local

# Copy application source
COPY . /app

# Create a non-root user and give ownership of the app directory
RUN groupadd --system app && useradd --system --gid app app \
    && chown -R app:app /app

USER app

EXPOSE 8000

# Run the app with uvicorn; adjust "main:app" if your entrypoint differs - our main is inside app folder 
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]