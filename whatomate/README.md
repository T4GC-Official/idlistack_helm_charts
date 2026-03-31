# WhatoMate Helm Chart

WhatoMate is a WhatsApp Bot integration with CRM synchronization capabilities. This Helm chart provides a production-ready deployment with PostgreSQL and Redis as managed dependencies.

## Quick Start

```bash
# Add the chart repository
helm repo add idlistack https://charts.idlistack.in
helm repo update

# Install the chart
helm install whatomate idlistack/whatomate \
  --namespace whatomate \
  --create-namespace \
  --values values.yaml
```

## Configuration

### Core Values
- `whatomate.port`: Application port (default: 8080)
- `database.name`: PostgreSQL database name
- `database.user`: PostgreSQL user
- `database.password`: PostgreSQL password (change for production)
- `redis.host`: Redis host
- `jwt.secret`: JWT signing secret (change for production)

### Storage
- `storage.size`: Uploads volume (default: 10Gi)
- `storage.storageClass`: Storage class name (default: longhorn)

### Ingress
```yaml
ingress:
  enabled: true
  hosts:
    - host: whatomate.example.com
  tls:
    - secretName: whatomate-tls
      hosts:
        - whatomate.example.com
```

## Architecture

The chart deploys WhatoMate with:

1. **WhatoMate Container** (1.0.0)
   - Runs on port 8080
   - Connects to PostgreSQL for data persistence
   - Uses Redis for caching and sessions
   - Mounts uploads volume at `/app/uploads`
   - Resource limits: 1000m CPU, 1Gi memory

2. **PostgreSQL** (via Bitnami chart)
   - Database backend
   - 20Gi persistent storage

3. **Redis** (via Bitnami chart)
   - Session and cache storage
   - 10Gi persistent storage

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Longhorn storage controller (or alternative storage class)
- Traefik ingress controller
- cert-manager (for TLS support)

## License

MIT License - See LICENSE file for details
