# HMPPS Node.js Base Image

FROM node:24-alpine

# Metadata
LABEL org.opencontainers.image.title="HMPPS Node.js Base Image"
LABEL org.opencontainers.image.description="Base container image for Node.js applications in HMPPS"
LABEL org.opencontainers.image.source="https://github.com/ministryofjustice/hmpps-base-container-images"
LABEL org.opencontainers.image.vendor="Ministry of Justice"

# Install essential packages and security updates (rarely changes - good for caching)
RUN apk --update-cache upgrade --available \
    && apk --no-cache add \
        curl \
        wget \
        ca-certificates \
        tzdata \
        dumb-init \
        git \
    && rm -rf /var/cache/apk/*

# Set timezone (rarely changes - good for caching)
ENV TZ="Europe/London"
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone