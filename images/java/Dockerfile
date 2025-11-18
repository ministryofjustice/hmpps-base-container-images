# HMPPS Java Base Image

FROM eclipse-temurin:21-jre-jammy

# Metadata
LABEL org.opencontainers.image.title="HMPPS Java Base Image"
LABEL org.opencontainers.image.description="Base container image for Java applications in HMPPS"
LABEL org.opencontainers.image.source="https://github.com/ministryofjustice/hmpps-base-container-images"
LABEL org.opencontainers.image.vendor="Ministry of Justice"

# Install essential packages and security updates (rarely changes - good for caching)
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        ca-certificates \
        tzdata \
        dumb-init \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set timezone (rarely changes - good for caching)
ENV TZ="Europe/London"
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone
