# Listmonk Helm Chart

Listmonk is a self-hosted, lightweight newsletter and mailing list manager. This Helm chart provides a production-ready deployment with PostgreSQL database running in a sidecar container pattern.

## Quick Start

```bash
# Add the chart repository
helm repo add idlistack https://charts.idlistack.in
helm repo update

# Install the chart
helm install listmonk idlistack/listmonk \
  --namespace listmonk \
  --create-namespace \
  --values values.yaml
```

## Configuration

### Core Values
- `listmonk.port`: Application port (default: 9000)
- `listmonk.adminPort`: Admin panel port (default: 9001)
- `database.name`: PostgreSQL database name
- `database.user`: PostgreSQL user
- `database.password`: PostgreSQL password (change for production)

### Storage
- `storage.listmonkSize`: Listmonk data volume (default: 5Gi)
- `storage.postgresSize`: PostgreSQL volume (default: 10Gi)
- `storage.storageClass`: Storage class name (default: longhorn)

### Ingress
```yaml
ingress:
  enabled: true
  hosts:
    - host: listmonk.example.com
  tls:
    - secretName: listmonk-tls
      hosts:
        - listmonk.example.com
```

## Architecture

The chart uses a **sidecar pattern** with two containers in a single pod:

1. **Listmonk Container** (3.0.0)
   - Runs on port 9000 (app) and 9001 (admin panel)
   - Mounts to `/listmonk` for data persistence
   - Resource limits: 500m CPU, 1Gi memory

2. **PostgreSQL Sidecar** (15-alpine)
   - Runs on port 5432
   - Mounts to `/var/lib/postgresql/data` for data persistence
   - Resource limits: 500m CPU, 1Gi memory

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Longhorn storage controller (or alternative storage class)
- Traefik ingress controller
- cert-manager (for TLS support)

## License

MIT License - See LICENSE file for details
