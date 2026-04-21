# HMPPS Node.js Runtime Base Image

ARG BASE_IMAGE=node
ARG BASE_TAG=24-alpine
FROM ${BASE_IMAGE}:${BASE_TAG} AS base

# Re-declare build args in-stage for label use
ARG BASE_IMAGE
ARG BASE_TAG

# Metadata
LABEL org.opencontainers.image.title="HMPPS Node.js Runtime Base Image"
LABEL org.opencontainers.image.description="Runtime-only container image for Node.js applications in HMPPS (package managers removed)"
LABEL org.opencontainers.image.source="https://github.com/ministryofjustice/hmpps-base-container-images"
LABEL org.opencontainers.image.vendor="Ministry of Justice"
LABEL hmpps.node.base_variant="${BASE_TAG}"
LABEL hmpps.node.base_image="${BASE_IMAGE}"
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}:${BASE_TAG}"

# Create non-root app user (consistent with Java images)
ARG APP_UID=2000
ARG APP_GID=2000
RUN addgroup -g ${APP_GID} -S appgroup && \
    adduser -u ${APP_UID} -S appuser -G appgroup

# Timezone setup (base image already includes tzdata and ca-certificates)
ENV TZ="Europe/London"
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

# Remove package managers - not needed for production and reduces attack surface
RUN rm -rf /usr/local/lib/node_modules \
           /usr/local/bin/npm \
           /usr/local/bin/npx \
           /usr/local/bin/corepack \
           /usr/local/bin/yarn \
           /usr/local/bin/yarnpkg \
           /opt/yarn-*

# Security upgrades in separate stage for cache control
# Build with: docker buildx build --no-cache-filter=security-upgrades ...
FROM base AS security-upgrades
RUN apk upgrade --no-cache

# USER ${APP_UID}

WORKDIR /app
