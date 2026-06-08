# ── Stage 1: build Flutter web (includes assets/images/*.png) ─────────────
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
COPY assets ./assets
RUN flutter pub get

COPY lib ./lib
COPY web ./web
COPY analysis_options.yaml ./

ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY
RUN test -n "$SUPABASE_URL" && test -n "$SUPABASE_ANON_KEY"
RUN flutter build web --release \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

# ── Stage 2: serve with nginx ───────────────────────────────────────────────
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
