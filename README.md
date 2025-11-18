# HMPPS Base Container Images

Standardized base container images for HMPPS applications with security optimizations and common utilities.

## Images

| Image | Base | Registry |
|-------|------|----------|
| **Java** | Eclipse Temurin JRE 21 | `ghcr.io/ministryofjustice/hmpps-base-java` |
| **Node.js** | Node.js 24 Alpine | `ghcr.io/ministryofjustice/hmpps-base-node` |

## Usage

```dockerfile
# Java
FROM ghcr.io/ministryofjustice/hmpps-base-java:20241118
RUN addgroup --gid 2000 --system appgroup && \
    adduser --uid 2000 --system appuser --gid 2000
COPY --chown=appuser:appgroup app.jar /app/
USER 2000
CMD ["java", "-jar", "/app/app.jar"]

# Node.js
FROM ghcr.io/ministryofjustice/hmpps-base-node:20241118
RUN addgroup --gid 2000 --system appgroup && \
    adduser --uid 2000 --system appuser --ingroup appgroup
COPY --chown=appuser:appgroup . /app/
USER 2000
CMD ["npm", "start"]
```

## Features

- Security updates applied
- Essential utilities (curl, wget, ca-certificates, git, dumb-init)
- Timezone: Europe/London
- Minimal footprint

## Development

```bash
# Build locally
docker build -t hmpps-base-java images/java/
docker build -t hmpps-base-node images/node/
```

## CI/CD

- **Builds**: Weekdays 5 AM UTC
- **Multi-platform**: AMD64 + ARM64
- **Security scanning**: Trivy with GitHub Security integration
- **Registry**: GitHub Container Registry