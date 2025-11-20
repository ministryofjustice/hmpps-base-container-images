# Node.js Base Image

Lean, standardized Node.js base for HMPPS apps (Alpine variants).

## Features

- Node.js Alpine (24, 25 variants)
- Non‑root user `appuser` (UID/GID 2000) and `WORKDIR /app`
- Timezone: `Europe/London`
- Security updates applied at build (`apk upgrade --no-cache`)
- OCI labels: `hmpps.node.base_image`, `hmpps.node.base_variant`, `org.opencontainers.image.base.name`

Registry: `ghcr.io/ministryofjustice/hmpps-node`

Common tags: `24-alpine`, `25-alpine`, date tags (YYYYMMDD), `latest`

## Usage (simple)

```dockerfile
FROM ghcr.io/ministryofjustice/hmpps-node:24-alpine
WORKDIR /app
COPY --chown=appuser:appgroup package*.json ./
RUN npm ci --omit=dev --no-audit
COPY --chown=appuser:appgroup . .
ENV NODE_ENV=production
USER 2000
CMD ["npm", "start"]
```

## Notes

- Add build tools (git, curl, etc.) in your app image only if needed.
- To switch Node version, pick the matching tag (e.g. `25-alpine`).

## Usage (multi-stage)

```dockerfile
# Base (provides non-root user, TZ Europe/London, security upgrades)
FROM ghcr.io/ministryofjustice/hmpps-node:24-alpine AS base

# Optional build metadata
ARG BUILD_NUMBER
ARG GIT_REF
ARG GIT_BRANCH
ENV BUILD_NUMBER=${BUILD_NUMBER} \
	GIT_REF=${GIT_REF} \
	GIT_BRANCH=${GIT_BRANCH}

WORKDIR /app

# Build stage
FROM base AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci --no-audit

COPY . .
ENV NODE_ENV=production
RUN npm run build && npm prune --no-audit --omit=dev

# Final stage
FROM base
WORKDIR /app

COPY --from=build --chown=appuser:appgroup /app/package*.json ./
COPY --from=build --chown=appuser:appgroup /app/dist ./dist
COPY --from=build --chown=appuser:appgroup /app/node_modules ./node_modules

EXPOSE 3000
ENV NODE_ENV=production
# Ensure run as appuser, must be numeric user id
USER 2000 
CMD ["npm", "start"]
```