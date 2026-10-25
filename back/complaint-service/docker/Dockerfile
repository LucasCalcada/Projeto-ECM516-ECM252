FROM dart:3.13.5-sdk AS build
WORKDIR /app

COPY back/complaint-service/pubspec.yaml back/complaint-service/pubspec.lock ./
RUN dart pub get --enforce-lockfile

COPY back/complaint-service/bin ./bin
COPY back/complaint-service/lib ./lib
RUN dart compile exe bin/server.dart -o /app/server \
    && dart compile exe bin/migrate.dart -o /app/migrate

FROM debian:trixie-slim AS runtime
WORKDIR /app
COPY --from=build /app/server /app/bin/server
COPY --from=build /app/migrate /app/bin/migrate
COPY --from=build /etc/ssl/certs /etc/ssl/certs
COPY back/complaint-service/migrations ./migrations

ENV HOST=0.0.0.0 PORT=8007
EXPOSE 8007
CMD ["/bin/sh", "-c", "/app/bin/migrate && exec /app/bin/server"]
