# Node.js Base Image

Base image for Node.js applications in HMPPS.

## Features

- Node.js 24 Alpine
- Essential utilities (curl, wget, ca-certificates, git, dumb-init)
- Timezone: Europe/London
- Security updates applied

## Usage

```dockerfile
FROM ghcr.io/ministryofjustice/hmpps-base-node:latest AS base

RUN addgroup --gid 2000 --system appgroup && \
    adduser --uid 2000 --system appuser --ingroup appgroup

WORKDIR /app

# Build stage
FROM base AS build
COPY package*.json ./
RUN npm ci --no-audit
COPY . .
RUN npm run build
RUN npm prune --no-audit --omit=dev

# Final stage
FROM base
COPY --from=build --chown=appuser:appgroup /app/package*.json ./
COPY --from=build --chown=appuser:appgroup /app/dist ./dist
COPY --from=build --chown=appuser:appgroup /app/node_modules ./node_modules

ENV NODE_ENV='production'
USER 2000
CMD ["npm", "start"]
```

## Build

```bash
docker build -t hmpps-base-node images/node/
```