# HMPPS Java Base Image

Standardized base image for JVM applications in HMPPS. Provides a consistent, lean, non‑root runtime across Ubuntu (Jammy) and distroless variants.

## Supported Variants

| Variant Tag   | OS         | Arch (multi-platform) | Notes |
|---------------|------------|-----------------------|-------|
| 21-jre-jammy  | Ubuntu     | amd64, arm64          | LTS line (Java 21) |
| 25-jre-jammy  | Ubuntu     | amd64, arm64          | Latest (preview until GA) |
| 21-distroless | Distroless | amd64, arm64          | Minimal runtime footprint (no shell/package manager) |
| 25-distroless | Distroless | amd64, arm64          | Minimal runtime footprint (no shell/package manager) |

## Distroless Variant

The distroless variants use Google's minimal distroless base images instead of full OS distributions, reducing attack surface and image size.

**Notes:**

- No shell/package manager in runtime image (debugging harder).
- Two-stage build: prepare assets in Debian (full OS), run on distroless.
- Requires explicit binary/library copies; fewer implicit dependencies.

Images are published to:

```
ghcr.io/ministryofjustice/hmpps-java
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
ARG BASE_IMAGE=eclipse-temurin
ARG BASE_TAG=<variant>
```

These are passed by CI matrix; you can override locally when rebuilding a specific variant:

```bash
docker build \
    --build-arg BASE_TAG=21-jre-alpine \
    --build-arg BASE_IMAGE=eclipse-temurin \
    -t hmpps-eclipse-temurin:21-jre-alpine \
    images/eclipse-temurin/alpine
```

## JVM Defaults Explained

| Option | Effect | Rationale |
|--------|--------|-----------|
| `-XX:+ExitOnOutOfMemoryError` | JVM exits immediately on OOM | Fast restart; avoids wedged process |
| `-XX:MaxRAMPercentage=50.0` | Heap sized to 50% of container limit | Leaves headroom for metaspace/native |

Override by supplying `JAVA_TOOL_OPTIONS` or explicit `-Xmx` in your application image.

The 50% has been judged based off a maximum pod memory limit of 1Gi. If you have set your pod maximum to a greater value
then you could up the percentage to a higher figure without running foul of the linux Out Of Memory Killer.

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
USER 2000
CMD ["java", "-jar", "app.jar"]
```

## Security & Scanning

CI builds multi-arch images daily (weekdays 05:00 UTC). Trivy scans:

| Branch | Output | Blocking |
|--------|--------|----------|
| Default (non-main) | Table (critical/high) | Non-blocking |
| main / scheduled | SARIF uploaded to Security tab | Non-blocking exit code |
