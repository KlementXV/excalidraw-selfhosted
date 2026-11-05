# Excalidraw front that relays /api/v2/ to a self-hosted scene store.
#
#   docker build --build-arg EXCALIDRAW_REF=v0.18.1 -t excalidraw-front excalidraw-front/
#   docker run -p 8080:8080 -e EXCALIDRAW_BACKEND_URL=http://storage:8080 excalidraw-front
#
# The JS only knows the relative /api/v2/scenes/ path, so the backend is chosen when the
# container starts: no rebuild, no CORS, and the backend does not have to be public.

# --- Stage 1: build the app from an upstream tag ------------------------------
FROM node:24-slim AS build

ARG EXCALIDRAW_REF

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

RUN test -n "$EXCALIDRAW_REF" \
    && git clone --depth 1 --branch "$EXCALIDRAW_REF" \
       https://github.com/excalidraw/excalidraw.git /opt/node_app

WORKDIR /opt/node_app

# Tags from older release lines cap their engines below this Node. As an env var, this
# also covers the nested yarn calls of the build.
ENV YARN_IGNORE_ENGINES=true

# Optional dependencies must stay: rollup needs @rollup/rollup-linux-x64-gnu.
RUN yarn --frozen-lockfile --network-timeout 600000

ENV NODE_ENV=production
ENV VITE_APP_BACKEND_V2_GET_URL=/api/v2/scenes/
ENV VITE_APP_BACKEND_V2_POST_URL=/api/v2/scenes/
RUN yarn build:app:docker

# --- Stage 2: static files + relay, non-root ----------------------------------
FROM nginxinc/nginx-unprivileged:stable-alpine-slim

COPY --from=build /opt/node_app/excalidraw-app/build /usr/share/nginx/html

COPY excalidraw.conf.template /etc/nginx/templates/excalidraw.conf.template
# The config is rendered in /tmp: it is the only path that must be writable, so the
# image also runs with a read-only root filesystem and a volume on /tmp.
RUN echo 'include /tmp/excalidraw.conf;' > /etc/nginx/conf.d/default.conf

ENV NGINX_ENVSUBST_OUTPUT_DIR=/tmp
ENV NGINX_ENTRYPOINT_LOCAL_RESOLVERS=1
ENV EXCALIDRAW_BACKEND_URL=http://storage:8080

EXPOSE 8080
HEALTHCHECK CMD wget -q -O /dev/null http://127.0.0.1:8080 || exit 1
