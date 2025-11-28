# Docker Images for Python 3.13

This repository provides lightweight and optimized Docker images for Python 3.13, based on two different base images: Debian Bookworm Slim and Alpine Linux. These images are hosted on GitHub Container Registry (GHCR).

## Supported Variants

| Variant Tag               | OS          | Arch (multi-platform) | Notes                          |
|---------------------------|-------------|-----------------------|--------------------------------|
| python3.13-alpine         | Alpine      | amd64, arm64          | Lightweight and minimal image  |


## Features

- Non‑root user `appuser` (UID/GID 2000) and `WORKDIR /app`

Registry: `ghcr.io/ministryofjustice/hmpps-python`

Common tags: `python3.13-alpine`, `python3.13-bookworm-slim`, date tags (YYYYMMDD), `latest`

## Usage (simple)

```dockerfile
FROM ghcr.io/astral-sh/uv:python3.13-alpine
WORKDIR /app

RUN addgroup -g 2000 appgroup && \
    adduser -u 2000 -G appgroup -h /home/appuser -D appuser
RUN chown -R appuser:appgroup /app

# update PATH environment variable
ENV PATH=/home/appuser/.local:/app:$PATH
USER 2000
```

## Notes

- Add dependencies hmpps-sre-python-lib and any other like veracode-api-signing, azure-identity etc in your pyproject.toml file and then run `uv sync`

## Usage (multi-stage)

```dockerfile
# Base (provides non-root user, TZ Europe/London, security upgrades)
FROM ghcr.io/ministryofjustice/hmpps-python:python3.13-alpine AS base

# Optional build metadata
ARG BUILD_NUMBER
ARG GIT_REF
ARG GIT_BRANCH
ENV BUILD_NUMBER=${BUILD_NUMBER} \
	GIT_REF=${GIT_REF} \
	GIT_BRANCH=${GIT_BRANCH}

WORKDIR /app

# initialise uv
COPY pyproject.toml .
RUN uv sync

# create the /app/trivy directory f
# copy the dependencies from builder stage
RUN chown -R appuser:appgroup /app
COPY classes classes
COPY processes processes
RUN chown -R appuser:appgroup /app/classes /app/processes
COPY --chown=appuser:appgroup  ./sharepoint_discovery.py /app/sharepoint_discovery.py

CMD [ "uv", "run", "python", "-u", "/app/sharepoint_discovery.py" ]
```