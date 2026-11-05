# Excalidraw Self-Hosted

Run [Excalidraw](https://github.com/excalidraw/excalidraw) and its [MCP server](https://github.com/excalidraw/excalidraw-mcp) on your own infrastructure, so shared diagrams are stored with you instead of on excalidraw.com.

This repository is a fork of `excalidraw/excalidraw-mcp`. It adds:

- configurable store and app URLs on the MCP server, plus a Dockerfile
- a front image that relays its API calls to a backend chosen at startup
- a workflow that rebuilds the front image for each Excalidraw release

The scene store is the unmodified [kitsteam/excalidraw-storage-backend](https://github.com/kitsteam/excalidraw-storage-backend) image.

![Demo](docs/demo.gif)

## Architecture

```mermaid
flowchart LR
    client["MCP client"] -->|"/mcp"| mcp["MCP server"]
    mcp -->|"POST scene"| store["Scene store"]
    browser["Browser"] -->|"app and /api/v2/"| front["Excalidraw front (nginx)"]
    front -->|"/api/v2/"| store
    store --> db[("PostgreSQL")]
```

| Component | Image | Port |
|-----------|-------|------|
| Excalidraw front | `ghcr.io/klementxv/excalidraw-front` | 8080 |
| MCP server | Built from this repository | 3001 |
| Scene store | `ghcr.io/kitsteam/excalidraw-storage-backend` | 8080 |
| Database | PostgreSQL | 5432 |

Scenes are encrypted before upload. The key stays in the `#json=<id>,<key>` part of the share link, so neither the store nor the relay receives it.

## Quick start

Save this as `docker-compose.yml` at the root of the repository:

```yaml
services:
  front:
    image: ghcr.io/klementxv/excalidraw-front:v0.18.1
    ports:
      - "8080:8080"
    environment:
      EXCALIDRAW_BACKEND_URL: http://storage:8080

  mcp:
    build: .
    ports:
      - "3001:3001"
    environment:
      EXCALIDRAW_STORE_URL: http://storage:8080/api/v2/scenes/
      EXCALIDRAW_APP_URL: http://localhost:8080

  storage:
    image: ghcr.io/kitsteam/excalidraw-storage-backend:v0.2.5
    environment:
      STORAGE_URI: postgres://postgres:change-me@postgres:5432/excalidraw
      STORAGE_TTL: "31536000000" # One year, in milliseconds

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: change-me
      POSTGRES_DB: excalidraw
    volumes:
      - postgres:/var/lib/postgresql/data

volumes:
  postgres:
```

Then start it:

```bash
docker compose up -d
```

- Excalidraw: <http://localhost:8080>
- MCP endpoint: <http://localhost:3001/mcp>

## Configuration

### Excalidraw front

| Variable | Default | Purpose |
|----------|---------|---------|
| `EXCALIDRAW_BACKEND_URL` | `http://storage:8080` | Scene store, without a path. It must serve `/api/v2/` |

### MCP server

| Variable | Default | Purpose |
|----------|---------|---------|
| `EXCALIDRAW_STORE_URL` | `https://json.excalidraw.com/api/v2/post/` | Scene store `POST` endpoint, as reached by the server |
| `EXCALIDRAW_APP_URL` | `https://excalidraw.com` | Public URL of the front, used in share links |
| `PORT` | `3001` | HTTP port |

### Scene store

| Variable | Default | Purpose |
|----------|---------|---------|
| `STORAGE_URI` | None | PostgreSQL connection string. Required by the image |
| `STORAGE_TTL` | `86400000` (24 hours) | Lifetime of stored data, in milliseconds. Share links stop working after it |
| `BODY_LIMIT` | `50mb` | Maximum upload size |

## Production notes

- **HTTPS:** browsers only allow the decryption of shared scenes over HTTPS or on `localhost`.
- **Scene store access:** the store has no authentication and the front relays it publicly. Limit the request rate and upload size on your ingress.
- **MCP access:** the `/mcp` endpoint has no authentication. Keep it on a private network or behind a proxy that authenticates requests.
- **Read-only containers:** the front and the MCP server both run as non-root, and support a read-only root filesystem if `/tmp` is writable.
- **Checkpoints:** the MCP server keeps them in `/tmp`, separately on each instance. Run a single replica, and use a volume to keep them across restarts.
- **Health checks:** use a TCP check for the MCP server, since `GET /mcp` answers 406. The store exposes `/api/v2/health`.

## Limitations

- The MCP widget still loads the Excalidraw editor and its fonts from `esm.sh`, so the browser needs access to it.
- The front keeps its upstream defaults for live collaboration, image uploads in share links (Firebase) and libraries. These features still use Excalidraw's services.
- Excalidraw releases are rare, so the front can lag well behind excalidraw.com.

## Updates

The `Excalidraw front` workflow checks the latest Excalidraw release every day. It builds and pushes `excalidraw-front:<tag>` and `:latest` only if that tag is not in the registry yet.

To build another version, run the workflow manually with a tag or branch in `ref`. Use `force` to replace an existing image.

GitHub disables scheduled workflows after 60 days without activity on public repositories, so check that this one stays enabled.

To get the MCP server changes from the original project:

```bash
git remote add upstream https://github.com/excalidraw/excalidraw-mcp
git fetch upstream
git merge upstream/main
```

## Development

```bash
pnpm install
pnpm run build
pnpm run serve   # http://localhost:3001/mcp
pnpm run dev:ui  # Widget only, with mock data
```

Architecture details are in [CLAUDE.md](CLAUDE.md).

## Credits

Built on [Excalidraw](https://github.com/excalidraw/excalidraw), [excalidraw-mcp](https://github.com/excalidraw/excalidraw-mcp) and [excalidraw-storage-backend](https://github.com/kitsteam/excalidraw-storage-backend).

## License

MIT
