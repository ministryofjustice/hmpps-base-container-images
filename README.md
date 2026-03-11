# HMPPS Base Container Images

Lean, security-focused base images for Java (Temurin JRE) and Node.js applications used across HMPPS.

## Repositories

| Image family | Repository | Example pull |
|--------------|------------|--------------|
| Java (Temurin JRE) | `ghcr.io/ministryofjustice/hmpps-eclipse-temurin` | `docker pull ghcr.io/ministryofjustice/hmpps-eclipse-temurin:21-jre-jammy` |
| Node.js | `ghcr.io/ministryofjustice/hmpps-node` | `docker pull ghcr.io/ministryofjustice/hmpps-node:24-alpine` |

## Variants

Java:
- `21-jre-jammy`
- `25-jre-jammy`
- `21-jre-alpine`
- `25-jre-alpine`

Node:
- `24-alpine`

Python:
- `python3.13-alpine`

All images are built multi-arch: `linux/amd64` and `linux/arm64`.

## Tagging Scheme

Each variant always has its raw variant tag (e.g. `21-jre-jammy`). Additional dynamic tags are **prefixed by the variant** to avoid collisions:

| Tag Type | Example | When Present |
|----------|---------|--------------|
| Schedule date | `21-jre-jammy-20251120` | Only on weekday 05:00 UTC scheduled build |
| Branch | `21-jre-jammy-initial-commit` | On branch builds (non-schedule) |
| PR | `21-jre-jammy-pr-123` | On pull request builds (if enabled) |
| Git SHA | `21-jre-jammy-sha-<shortsha>` | All builds |
| Raw variant | `21-jre-jammy` | All builds |

The `:latest` tag is applied per repository (currently points to the most recently built variant for that family). Consumers should prefer explicit variant tags.

## CI/CD Overview

- Weekday scheduled build: 05:00 UTC (creates date tags)
- Multi-platform build/push via Buildx
- Trivy scan: table output for branch builds; SARIF uploaded on scheduled (or designated) runs

## Security Upgrades

All Dockerfiles use a multi-stage build pattern to ensure OS security patches are always applied fresh:

```dockerfile
FROM base-image AS base
# ... setup steps ...

FROM base AS security-upgrades
RUN apk upgrade --no-cache  # or apt-get upgrade for Ubuntu
```

The CI workflow uses BuildKit's `--no-cache-filter=security-upgrades` to skip the cache for this stage, ensuring `apk upgrade` / `apt-get upgrade` always fetches the latest patches — even when other layers are cached.
