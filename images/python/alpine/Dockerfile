# HMPPS Node.js Base Image

ARG NODE_BASE_IMAGE=ghcr.io/astral-sh/uv
ARG NODE_BASE_TAG=python3.13-alpine
FROM ${NODE_BASE_IMAGE}:${NODE_BASE_TAG}

# Re-declare build args in-stage for label use
ARG NODE_BASE_IMAGE
ARG NODE_BASE_TAG

# Metadata
LABEL org.opencontainers.image.title="HMPPS python Base Image"
LABEL org.opencontainers.image.description="Base container image for python applications used within HMPPS"
LABEL org.opencontainers.image.source="https://github.com/ministryofjustice/hmpps-base-container-images"
LABEL org.opencontainers.image.vendor="Ministry of Justice"
LABEL hmpps.node.base_variant="${NODE_BASE_TAG}"
LABEL hmpps.node.base_image="${NODE_BASE_IMAGE}"
LABEL org.opencontainers.image.base.name="${NODE_BASE_IMAGE}:${NODE_BASE_TAG}"

# Apply security upgrades last for better caching
RUN apk upgrade --no-cache

ARG APP_UID=2000
ARG APP_GID=2000
RUN addgroup -g ${APP_GID} -S appgroup && \
    adduser -u ${APP_UID} -S appuser -G appgroup
USER 2000
# Ensure the workdir is owned by the unprivileged user before switching
WORKDIR /app
RUN chown -R 2000:2000 /app
