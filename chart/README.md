# Excalidraw Helm chart

Deploys the Excalidraw front, the scene store, PostgreSQL and the MCP server.

## Install

```bash
helm install excalidraw oci://ghcr.io/klementxv/charts/excalidraw -n excalidraw --create-namespace \
  --set publicUrl=https://excalidraw.example.com \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set ingress.tlsSecretName=excalidraw-tls

helm test excalidraw -n excalidraw
```

Each version is also attached as a `.tgz` to the [GitHub releases](https://github.com/KlementXV/excalidraw-selfhosted/releases).

## Main options

| Option | Default | Purpose |
|--------|---------|---------|
| `publicUrl` | `https://excalidraw.example.com` | Public URL: route host and MCP share links |
| `mcp.enabled` | `true` | Deploy the MCP server |
| `mcp.expose` | `false` | Also route `/mcp` on the public host |
| `ingress.enabled` | `false` | Create an Ingress |
| `gateway.enabled` | `false` | Create an HTTPRoute |
| `gateway.parentRefs` | `[]` | Gateway to attach to, required with `gateway.enabled` |
| `global.imageRegistry` | `""` | Registry for every image. Repositories keep their path, such as `kitsteam/excalidraw-storage-backend` |
| `imagePullSecrets` | `[]` | Pull secrets for every pod |
| `postgresql.persistence.storageClass` | `""` | StorageClass of the database. Empty: cluster default |
| `postgresql.persistence.size` | `5Gi` | Database volume size |
| `postgresql.enabled` | `true` | Deploy PostgreSQL |
| `externalDatabase.existingSecret` | `""` | Secret with the connection string, when `postgresql.enabled` is `false` |
| `storage.ttl` | `31536000000` | Scene lifetime in milliseconds (one year) |
| `networkPolicy.enabled` | `true` | Keep the store and database internal, and limit access to the MCP server |

All options are commented in [values.yaml](values.yaml).

## Examples

Gateway API. The Gateway must already exist:

```yaml
publicUrl: https://excalidraw.example.com
gateway:
  enabled: true
  parentRefs:
    - name: main
      namespace: gateway
      sectionName: https
```

Private registry, chosen StorageClass and no MCP server:

```yaml
global:
  imageRegistry: registry.example.com
imagePullSecrets:
  - name: my-registry
postgresql:
  persistence:
    storageClass: fast-ssd
mcp:
  enabled: false
```

External database:

```bash
kubectl -n excalidraw create secret generic excalidraw-db \
  --from-literal=uri='postgres://user:password@db.example.com:5432/excalidraw'
```

```yaml
postgresql:
  enabled: false
externalDatabase:
  existingSecret: excalidraw-db
```

## Good to know

- **HTTPS:** browsers only decrypt shared scenes over HTTPS or on `localhost`, so use an `https` `publicUrl` in production.
- **Public store:** the front relays the store without authentication. Set an upload limit and a rate limit on your ingress or gateway. The controller's upload limit must allow `storage.bodyLimit`.
- **MCP access:** `/mcp` has no authentication. With `networkPolicy.enabled`, only pods of the release namespace and `networkPolicy.mcpFrom` can reach it.
- **NetworkPolicy:** with `mcp.expose`, set `networkPolicy.controllerFrom` to the namespace of your controller. The default is `kube-system`.
- **Checkpoints:** the MCP server keeps them in `/tmp`, so a pod restart loses them. Keep `mcp.replicaCount` at 1.
- **Uninstall:** `helm uninstall` keeps the database volume and its password Secret, so a reinstall finds the scenes again. Delete the PVC and the `<release>-excalidraw-postgresql` Secret to remove them.
