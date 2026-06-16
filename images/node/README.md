# Node.js Base Image

Lean, standardized Node.js base for HMPPS apps (Alpine variants).

## Variants

| Tag | Description |
|-----|-------------|
| `24-alpine` | Full Node.js 24 Alpine image including npm, yarn, and corepack |
| `24-alpine-runtime` | Runtime-only image with package managers removed — smaller attack surface for production and fewer reported vulnerabilities from scanning tools |
| `24-distroless` | Distroless runtime image with Node.js only — minimal attack surface (no shell/package manager) |

## Distroless Variant

The distroless variant uses Google's minimal distroless base image, reducing attack surface and image size.

**Notes:**

- No shell/package manager in runtime image (debugging harder).
- Two-stage build: prepare assets in full Node image, run on distroless.
- Requires explicit binary/library copies; fewer implicit dependencies.

## Features

- Node.js Alpine (24 variant)
- Non‑root user `appuser` (UID/GID 2000) and `WORKDIR /app`
- Timezone: `Europe/London`
- Security updates applied at build (`apk upgrade --no-cache`)
- OCI labels: `hmpps.node.base_image`, `hmpps.node.base_variant`, `org.opencontainers.image.base.name`

Registry: `ghcr.io/ministryofjustice/hmpps-node`

Common tags: `24-alpine`, `24-alpine-runtime`, date tags (YYYYMMDD), `latest`

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
- To switch Node version, pick the matching tag (e.g. `24-alpine`).
- Use `24-alpine-runtime` for the final stage of multi-stage builds — npm/yarn are not needed at runtime and their removal reduces the attack surface.

## Usage (multi-stage)

```dockerfile
# Build args available to all stages
ARG BUILD_NUMBER
ARG GIT_REF
ARG GIT_BRANCH

# Stage: build assets
FROM ghcr.io/ministryofjustice/hmpps-node:24-alpine AS build

ARG BUILD_NUMBER
ARG GIT_REF
ARG GIT_BRANCH

# Cache breaking and ensure required build / git args defined
RUN test -n "$BUILD_NUMBER" || (echo "BUILD_NUMBER not set" && false)
RUN test -n "$GIT_REF" || (echo "GIT_REF not set" && false)
RUN test -n "$GIT_BRANCH" || (echo "GIT_BRANCH not set" && false)

WORKDIR /app

COPY package*.json .allowed-scripts.mjs .npmrc ./
RUN NPM_CONFIG_AUDIT=false NPM_CONFIG_FUND=false npm run setup
ENV NODE_ENV='production'

COPY . .
RUN npm run build

RUN npm prune --no-audit --no-fund --omit=dev

# Stage: copy production assets and dependencies
FROM ghcr.io/ministryofjustice/hmpps-node:24-alpine-runtime

ARG BUILD_NUMBER
ARG GIT_REF
ARG GIT_BRANCH

COPY --from=build --chown=appuser:appgroup \
        /app/package.json \
        /app/package-lock.json \
        ./

COPY --from=build --chown=appuser:appgroup \
        /app/dist ./dist

COPY --from=build --chown=appuser:appgroup \
        /app/node_modules ./node_modules

EXPOSE 3000
ENV BUILD_NUMBER=${BUILD_NUMBER}
ENV GIT_REF=${GIT_REF}
ENV GIT_BRANCH=${GIT_BRANCH}
ENV NODE_ENV='production'
USER 2000

CMD [ "node", "dist/server.js" ]
```