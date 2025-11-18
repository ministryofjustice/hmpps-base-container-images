# Java Base Image

Base image for Java/JVM applications in HMPPS.

## Features

- Eclipse Temurin JRE 21 (Ubuntu Jammy)
- Essential utilities (curl, wget, ca-certificates, dumb-init)
- Timezone: Europe/London
- Security updates applied

## Usage

```dockerfile
FROM --platform=$BUILDPLATFORM eclipse-temurin:21-jdk-jammy AS builder

ARG BUILD_NUMBER
ENV BUILD_NUMBER=${BUILD_NUMBER:-1_0_0}

WORKDIR /app
ADD . .
RUN ./gradlew --no-daemon assemble

FROM ghcr.io/ministryofjustice/hmpps-base-java:latest

ARG BUILD_NUMBER
ENV BUILD_NUMBER=${BUILD_NUMBER:-1_0_0}

RUN addgroup --gid 2000 --system appgroup && \
    adduser --uid 2000 --system appuser --gid 2000

WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /app/build/libs/hmpps-template-kotlin*.jar /app/app.jar
COPY --from=builder --chown=appuser:appgroup /app/build/libs/applicationinsights-agent*.jar /app/agent.jar
COPY --from=builder --chown=appuser:appgroup /app/applicationinsights.json /app
COPY --from=builder --chown=appuser:appgroup /app/applicationinsights.dev.json /app

USER 2000

ENTRYPOINT ["java", "-XX:+AlwaysActAsServerClassMachine", "-javaagent:/app/agent.jar", "-jar", "/app/app.jar"]
```

## Build

```bash
docker build -t hmpps-base-java images/java/
```