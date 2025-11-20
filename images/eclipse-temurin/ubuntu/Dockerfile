# HMPPS Java Base Image
ARG JAVA_BASE_IMAGE=eclipse-temurin
ARG JAVA_BASE_TAG=21-jre-jammy
FROM ${JAVA_BASE_IMAGE}:${JAVA_BASE_TAG}

# Re-declare build args within this stage for later use in labels
ARG JAVA_BASE_IMAGE
ARG JAVA_BASE_TAG

# Metadata
LABEL org.opencontainers.image.title="HMPPS Java Base Image"
LABEL org.opencontainers.image.description="Base container image for Java applications in HMPPS"
LABEL org.opencontainers.image.source="https://github.com/ministryofjustice/hmpps-base-container-images"
LABEL org.opencontainers.image.vendor="Ministry of Justice"
LABEL hmpps.java.base_variant="${JAVA_BASE_TAG}"
LABEL hmpps.java.base_image="${JAVA_BASE_IMAGE}"
LABEL org.opencontainers.image.base.name="${JAVA_BASE_IMAGE}:${JAVA_BASE_TAG}"


WORKDIR /app

# Add default app user and group (configurable)
ARG APP_UID=2000
ARG APP_GID=2000
RUN addgroup --gid ${APP_GID} --system appgroup && \
    adduser --uid ${APP_UID} --system appuser --gid ${APP_GID}

# Set timezone
ENV TZ="Europe/London"
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone

# Install AWS RDS Root cert for Postgres clients (libpq convention)
RUN install -d -o appuser -g appgroup /home/appuser/.postgresql
ADD https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem /home/appuser/.postgresql/root.crt
RUN chown appuser:appgroup /home/appuser/.postgresql/root.crt && \
    chmod 0644 /home/appuser/.postgresql/root.crt

# Apply security upgrades
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Sensible JVM defaults for containers
ENV JAVA_TOOL_OPTIONS="-XX:+ExitOnOutOfMemoryError -XX:MaxRAMPercentage=75.0"

USER ${APP_UID}