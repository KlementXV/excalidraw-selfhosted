# --- Stage 1: build the widget and bundle the server --------------------------
FROM node:26-slim AS build

WORKDIR /build
# scripts/: the postinstall installs the bun binary used by the build.
COPY package.json pnpm-lock.yaml .npmrc ./
COPY scripts/ ./scripts/
RUN npm install -g pnpm@10.11.0 && pnpm install --frozen-lockfile

COPY . .
RUN pnpm run build

# --- Stage 2: runtime ---------------------------------------------------------
FROM node:26-slim

WORKDIR /app
# The server is a single bundle: no node_modules at runtime.
COPY --from=build /build/dist ./dist

ENV NODE_ENV=production
ENV PORT=3001
EXPOSE 3001

# Checkpoints are written to $TMPDIR/excalidraw-mcp-checkpoints: mount a volume on
# /tmp to keep them, and to run with a read-only root filesystem.
USER node
CMD ["node", "dist/index.js"]
