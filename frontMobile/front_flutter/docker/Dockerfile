FROM debian:bookworm-slim AS flutter-sdk

ARG FLUTTER_VERSION=3.47.7
ARG FLUTTER_REVISION=abaf9c523780a608bd46686fd5e53740a07077f8
ENV DEBIAN_FRONTEND=noninteractive \
    CI=true \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    PUB_CACHE=/opt/pub-cache \
    PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl git unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/* \
    && git clone --depth 1 --branch "$FLUTTER_VERSION" \
        https://github.com/flutter/flutter.git /opt/flutter \
    && test "$(git -C /opt/flutter rev-parse HEAD)" = "$FLUTTER_REVISION" \
    && flutter config --no-analytics --enable-web \
    && flutter precache --web

FROM flutter-sdk AS dependencies
WORKDIR /app
COPY frontMobile/front_flutter/pubspec.yaml frontMobile/front_flutter/pubspec.lock ./
RUN flutter pub get --enforce-lockfile

FROM dependencies AS build
COPY frontMobile/front_flutter/lib ./lib
COPY frontMobile/front_flutter/web ./web
RUN flutter build web --release --no-pub --no-wasm-dry-run \
    --dart-define=AUTH_URL=/api/auth \
    --dart-define=CORE_URL=/api/core \
    --dart-define=DELIVERY_URL=/api/delivery \
    --dart-define=COMMUNICATION_URL=/api/communication \
    --dart-define=COMPLAINT_URL=/api/complaint \
    --dart-define=VISITOR_URL=/api/visitor \
    --dart-define=RESERVATION_URL=/api/reservation

FROM nginx:1.28-alpine AS runtime
COPY frontMobile/front_flutter/docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
