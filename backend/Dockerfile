# API image for Render (ADR-0008). Build: docker build -t stark-vms-api backend
FROM eclipse-temurin:21-jdk AS build
WORKDIR /src
# Dependencies first, so code-only changes reuse this layer.
COPY gradlew settings.gradle build.gradle ./
COPY gradle gradle
RUN sh gradlew --no-daemon dependencies > /dev/null
COPY src src
RUN sh gradlew --no-daemon bootJar -x test

FROM eclipse-temurin:21-jre
WORKDIR /app
RUN useradd --system --uid 10001 app
COPY --from=build /src/build/libs/*.jar app.jar
USER app
# Render's free instance has 512 MB: keep the heap well inside it. Serial GC uses the least memory.
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=70 -XX:+UseSerialGC -XX:TieredStopAtLevel=1"
EXPOSE 9001
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
