# syntax=docker/dockerfile:1

# HMPPS Node.js Runtime Base Image.
# The digest must resolve to the intended Node 24 Alpine image.
FROM node@sha256:d32cdf619f63fe0471182d08996dd516c6275bb5fd31ae06e55a570bd9e1ad43 AS node-source

LABEL org.opencontainers.image.title="HMPPS Node.js Runtime Base Image"
LABEL org.opencontainers.image.description="Runtime-only container image for HMPPS Node.js applications with package managers removed"
LABEL org.opencontainers.image.source="https://github.com/ministryofjustice/hmpps-base-container-images"
LABEL org.opencontainers.image.vendor="Ministry of Justice"
LABEL org.opencontainers.image.base.name="alpine:3.24.1"
LABEL hmpps.node.base_image="alpine"
LABEL hmpps.node.base_variant="3.24.1"

FROM alpine@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS runtime

ARG APP_UID=2000
ARG APP_GID=2000

RUN apk add --no-cache \
    ca-certificates=20260611-r0 \
    libstdc++=15.2.0-r5 \
    tzdata=2026c-r0 \
    && addgroup \
        --gid "${APP_GID}" \
        --system \
        appgroup \
    && adduser \
        --uid "${APP_UID}" \
        --ingroup appgroup \
        --shell /sbin/nologin \
        --disabled-password \
        --no-create-home \
        --system \
        appuser

COPY --from=node-source /usr/local/bin/node /usr/local/bin/node

ENV NODE_ENV="production"
ENV TZ="Europe/London"

RUN ln -snf \
        "/usr/share/zoneinfo/${TZ}" \
        /etc/localtime \
    && echo "${TZ}" > /etc/timezone \
    && node --version \
    && test ! -e /usr/local/bin/npm \
    && test ! -e /usr/local/bin/npx \
    && test ! -e /usr/local/bin/corepack \
    && test ! -d /usr/local/lib/node_modules

WORKDIR /app
# FROM runtime AS security-upgrades
RUN apk update --no-cache -qq && apk upgrade --no-cache

USER appuser

ENTRYPOINT ["node"]
CMD ["node", "--version"]
