# HMPPS Java Base Image (Temurin Alpine variant)
ARG BASE_IMAGE=eclipse-temurin
ARG BASE_TAG=25.0.2_10-jre-alpine
FROM ${BASE_IMAGE}:${BASE_TAG} AS base

# Re-declare args in-stage for labels
ARG BASE_IMAGE
ARG BASE_TAG

# Metadata
LABEL org.opencontainers.image.title="HMPPS Java Base Image (Alpine)"
LABEL org.opencontainers.image.description="Base container image for Java applications in HMPPS (Alpine variant)"
LABEL org.opencontainers.image.source="https://github.com/ministryofjustice/hmpps-base-container-images"
LABEL org.opencontainers.image.vendor="Ministry of Justice"
LABEL hmpps.java.base_variant="${BASE_TAG}"
LABEL hmpps.java.base_image="${BASE_IMAGE}"
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}:${BASE_TAG}"

WORKDIR /app

# Set timezone (Alpine)
ENV TZ="Europe/London"
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

# Create app user/group (configurable)
ARG APP_UID=2000
ARG APP_GID=2000
RUN addgroup -g ${APP_GID} -S appgroup && \
    adduser -u ${APP_UID} -S appuser -G appgroup

# Install AWS RDS Root cert for Postgres clients
RUN install -d -o appuser -g appgroup /home/appuser/.postgresql
ADD https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem /home/appuser/.postgresql/root.crt
RUN chown appuser:appgroup /home/appuser/.postgresql/root.crt && \
    chmod 0644 /home/appuser/.postgresql/root.crt

# Security upgrades in separate stage for cache control
# Build with: docker buildx build --no-cache-filter=security-upgrades ...
FROM base AS security-upgrades
RUN apk upgrade --no-cache

# Sensible JVM defaults for containers
ENV JAVA_TOOL_OPTIONS="-XX:+ExitOnOutOfMemoryError -XX:MaxRAMPercentage=50.0"

USER ${APP_UID}
