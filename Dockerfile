# Image du relais FriendsLocalizer (pur-Dart : crypto/mesh/shelf).
# `dart compile exe` ne compile que le code atteignable depuis bin/server.dart,
# pas les widgets Flutter.
# Note : flutter:stable a Dart 3.12.0 ; pubspec exige ^3.12.1 (Dart 3.12.1 du SDK local).
# On relaxe la contrainte SDK uniquement dans le contexte de build Docker (sed in-place).
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN sed -i 's/sdk: \^3\.12\.1/sdk: ^3.12.0/' pubspec.yaml && flutter pub get
COPY . .
# dart build cli sort un bundle dans build/cli/<arch>/bundle ; on le normalise
# (chemin agnostique à l'archi, requis pour le build multi-arch amd64/arm64).
RUN dart build cli bin/server.dart && cp -r /app/build/cli/*/bundle /app/bundle

# Runtime : Debian slim (libc/ssl pour l'exe natif + curl pour le healthcheck).
FROM debian:stable-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/bundle /app/bundle
ENV PORT=8080
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -fsS http://localhost:8080/health || exit 1
ENTRYPOINT ["/app/bundle/bin/server"]
