# Excalidraw MCP App Server

MCP server that streams hand-drawn Excalidraw diagrams with smooth viewport camera control and interactive fullscreen editing.

![Demo](docs/demo.gif)

## Install

Works with any client that supports [MCP Apps](https://modelcontextprotocol.io/docs/extensions/apps) — Claude, ChatGPT, VS Code, Goose, and others. If something doesn't work, please [open an issue](https://github.com/antonpk1/excalidraw-mcp-app/issues).

### Remote (recommended)

### `https://mcp.excalidraw.com`

For apps that don't yet have an official integration, you can add a custom MCP / connector (naming can vary between apps).

### Local

**Option A: Download Extension**

1. Download `excalidraw-mcp-app.mcpb` from [Releases](https://github.com/antonpk1/excalidraw-mcp-app/releases)
2. Double-click to install in Claude Desktop

**Option B: Build from Source**

```bash
git clone https://github.com/excalidraw/excalidraw-mcp.git
cd excalidraw-mcp-app
pnpm install && pnpm run build
```

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "excalidraw": {
      "command": "node",
      "args": ["/path/to/excalidraw-mcp-app/dist/index.js", "--stdio"]
    }
  }
}
```

Restart Claude Desktop.

## Usage

Example prompts:
- "Draw a cute cat using excalidraw"
- "Draw an architecture diagram showing a user connecting to an API server which talks to a database"

## What are MCP Apps and how can I build one?

Text responses can only go so far. Sometimes users need to interact with data, not just read about it. [MCP Apps](https://github.com/modelcontextprotocol/ext-apps/) is an official Model Context Protocol extension that lets servers return interactive HTML interfaces (data visualizations, forms, dashboards) that render directly in the chat.

- **Getting started for humans**: [documentation](https://modelcontextprotocol.io/docs/extensions/apps)
- **Getting started for AIs**: [skill](https://github.com/modelcontextprotocol/ext-apps/blob/main/plugins/mcp-apps/skills/create-mcp-app/SKILL.md)

## Contributing

PRs welcome! See [Local](#local) above for build instructions.

### Self-hosting with Docker

```bash
docker build -t excalidraw-mcp .
docker run -p 3001:3001 \
  -e EXCALIDRAW_STORE_URL=http://storage:8080/api/v2/scenes/ \
  -e EXCALIDRAW_APP_URL=https://excalidraw.example.com \
  excalidraw-mcp
```

| Variable | Default | Purpose |
|----------|---------|---------|
| `EXCALIDRAW_STORE_URL` | `https://json.excalidraw.com/api/v2/post/` | Scene store `POST` endpoint, as reached by the server |
| `EXCALIDRAW_APP_URL` | `https://excalidraw.com` | Public origin of the Excalidraw app, used in share links |
| `PORT` | `3001` | HTTP port of the MCP server (`/mcp`) |

The widget still loads the Excalidraw editor from `esm.sh`.

### Excalidraw front image

`excalidraw-front/Dockerfile` builds the upstream app and relays `/api/v2/` to your scene store, chosen when the container starts:

```bash
docker run -p 8080:8080 -e EXCALIDRAW_BACKEND_URL=http://storage:8080 excalidraw-front
```

| Variable | Default | Purpose |
|----------|---------|---------|
| `EXCALIDRAW_BACKEND_URL` | `http://storage:8080` | Scene store, without path. It must serve `/api/v2/` |

The image runs as non-root on port 8080. With a read-only root filesystem, mount a volume on `/tmp`.

The `Excalidraw front` workflow checks for a new upstream release every day and pushes `ghcr.io/<owner>/excalidraw-front:<tag>`. Scheduled workflows are off by default on forks: enable them in the Actions tab.

### Deploy your own instance

You can deploy your own copy to Vercel in a few clicks:

1. Fork this repo
2. Go to [vercel.com/new](https://vercel.com/new) and import your fork
3. No environment variables needed — just deploy
4. Your server will be at `https://your-project.vercel.app/mcp`

### Release checklist

<details>
<summary>For maintainers</summary>

```bash
# 1. Bump version in manifest.json and package.json
# 2. Build and pack
pnpm run build && mcpb pack .

# 3. Create GitHub release
gh release create v0.3.0 excalidraw-mcp-app.mcpb --title "v0.3.0" --notes "What changed"

# 4. Deploy to Vercel
vercel --prod
```

</details>

## Credits

Built with [Excalidraw](https://github.com/excalidraw/excalidraw) — a virtual whiteboard for sketching hand-drawn like diagrams.

## License

MIT
