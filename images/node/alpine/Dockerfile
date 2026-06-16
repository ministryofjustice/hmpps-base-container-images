# HMPPS Node.js Base Image
FROM node:24-alpine AS base

# Metadata
LABEL org.opencontainers.image.title="HMPPS Node.js Base Image"
LABEL org.opencontainers.image.description="Base container image for Node.js applications in HMPPS"
LABEL org.opencontainers.image.source="https://github.com/ministryofjustice/hmpps-base-container-images"
LABEL org.opencontainers.image.vendor="Ministry of Justice"
LABEL hmpps.node.base_variant="24-alpine"
LABEL hmpps.node.base_image="node"
LABEL org.opencontainers.image.base.name="node:24-alpine"

# Create non-root app user (consistent with Java images)
ARG APP_UID=2000
ARG APP_GID=2000
RUN addgroup -g ${APP_GID} -S appgroup && \
    adduser -u ${APP_UID} -S appuser -G appgroup

# Timezone setup (base image already includes tzdata and ca-certificates)
ENV TZ="Europe/London"
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

# Security upgrades in separate stage for cache control
# Build with: docker buildx build --no-cache-filter=security-upgrades ...
FROM base AS security-upgrades
RUN apk upgrade --no-cache

# USER ${APP_UID}

WORKDIR /app