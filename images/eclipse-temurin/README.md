# HMPPS Java Base Image (Eclipse Temurin)

Standardized base image for JVM applications in HMPPS. Provides a consistent, lean, non‑root runtime across Ubuntu (Jammy) and Alpine variants of Eclipse Temurin JRE.

## Supported Variants

| Variant Tag       | OS     | Arch (multi-platform) | Notes |
|-------------------|--------|-----------------------|-------|
| 21-jre-jammy      | Ubuntu | amd64, arm64          | LTS line (Java 21) |
| 25-jre-jammy      | Ubuntu | amd64, arm64          | Latest (preview until GA) |
| 21-jre-alpine     | Alpine | amd64, arm64          | Smaller footprint |
| 25-jre-alpine     | Alpine | amd64, arm64          | Smaller footprint |

Images are published to:

```
ghcr.io/ministryofjustice/hmpps-eclipse-temurin
```

Tags applied (via GitHub Actions metadata):

| Tag Type | Example | Purpose |
|----------|---------|---------|
| Date schedule | 20241120 | Daily rebuild identifier |
| Branch / PR | initial-commit | Trace source ref |
| SHA | sha-<short> | Exact source immutability |
| latest | latest | Convenience (points to most recent build of a variant) |
| Raw variant | 21-jre-alpine | Upstream base variant clarity |


## Build Args

Dockerfile exposes:

```
ARG JAVA_BASE_IMAGE=eclipse-temurin
ARG JAVA_BASE_TAG=<variant>
```

These are passed by CI matrix; you can override locally when rebuilding a specific variant:

```bash
docker build \
    --build-arg JAVA_BASE_TAG=21-jre-alpine \
    --build-arg JAVA_BASE_IMAGE=eclipse-temurin \
    -t hmpps-eclipse-temurin:21-jre-alpine \
    images/eclipse-temurin/alpine
```

## JVM Defaults Explained

| Option | Effect | Rationale |
|--------|--------|-----------|
| `-XX:+ExitOnOutOfMemoryError` | JVM exits immediately on OOM | Fast restart; avoids wedged process |
| `-XX:MaxRAMPercentage=75.0` | Heap sized to 75% of container limit | Leaves headroom for metaspace/native |

Override by supplying `JAVA_TOOL_OPTIONS` or explicit `-Xmx` in your application image.

## RDS Root Certificate

AWS RDS global bundle is placed at:

```
/home/appuser/.postgresql/root.crt
```

This enables Postgres clients (libpq, JDBC when referencing libpq conventions) to verify SSL without app modification.

## Timezone Handling

We set `TZ=Europe/London` and symlink `/etc/localtime` to zoneinfo. Remove or change by overriding `TZ` and replacing the symlink in a downstream layer.

## Extending the Base (Example: Gradle Multi-Stage)

```dockerfile
FROM --platform=$BUILDPLATFORM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /src
COPY . .
RUN ./gradlew --no-daemon assemble

FROM ghcr.io/ministryofjustice/hmpps-eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=build /src/build/libs/app.jar ./app.jar
USER appuser
CMD ["java", "-jar", "app.jar"]
```

## Security & Scanning

CI builds multi-arch images daily (weekdays 05:00 UTC). Trivy scans:

| Branch | Output | Blocking |
|--------|--------|----------|
| Default (non-main) | Table (critical/high) | Non-blocking |
| main / scheduled | SARIF uploaded to Security tab | Non-blocking exit code |
