# HMPPS Node.js Base Image

ARG BASE_IMAGE=ghcr.io/astral-sh/uv
ARG BASE_TAG=python3.13-alpine
FROM ${BASE_IMAGE}:${BASE_TAG}

# Re-declare build args in-stage for label use
ARG BASE_IMAGE
ARG BASE_TAG

# Metadata
LABEL org.opencontainers.image.title="HMPPS python Base Image"
LABEL org.opencontainers.image.description="Base container image for python applications used within HMPPS"
LABEL org.opencontainers.image.source="https://github.com/ministryofjustice/hmpps-base-container-images"
LABEL org.opencontainers.image.vendor="Ministry of Justice"
LABEL hmpps.python.base_variant="${BASE_TAG}"
LABEL hmpps.python.base_image="${BASE_IMAGE}"
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}:${BASE_TAG}"

WORKDIR /app
ARG APP_UID=2000
ARG APP_GID=2000
RUN addgroup -g ${APP_GID} -S appgroup && \
    adduser -u ${APP_UID} -S appuser -G appgroup
RUN chown -R 2000:2000 /app

# Apply security upgrades last for better caching
RUN apk upgrade --no-cache

# update PATH environment variable
ENV PATH=/home/appuser/.local:/app:$PATH
