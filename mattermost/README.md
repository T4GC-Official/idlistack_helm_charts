# Mattermost Helm Chart

A production-ready Helm chart for deploying Mattermost team collaboration server on Kubernetes with MySQL sidecar database.

## Quick Start

### Install the Chart

```bash
helm install mattermost . \
  --set ingress.hosts[0].host=mattermost.example.com \
  --set database.mysql.password=your-db-password \
  --set database.mysql.rootPassword=your-root-password
```

### Uninstall the Chart

```bash
helm uninstall mattermost
```

## Values

### Image Configuration
- `image.repository`: Mattermost image repository (default: `mattermost/mattermost-team-edition`)
- `image.tag`: Mattermost image tag (default: `9.5`)
- `image.pullPolicy`: Image pull policy (default: `IfNotPresent`)

### Mattermost Settings
- `mattermost.port`: Mattermost listen port (default: `8065`)
- `mattermost.nodeEnv`: Node environment (default: `production`)
- `mattermost.resources`: CPU and memory resource limits and requests

### Database Configuration
- `database.client`: Database client type (default: `mysql`)
- `database.mysql.database`: Database name (default: `mattermost`)
- `database.mysql.user`: Database user (default: `mmuser`)
- `database.mysql.password`: Database password (required)
- `database.mysql.rootPassword`: MySQL root password (required)

### Storage
- `storage.mattermostSize`: Mattermost data storage size (default: `10Gi`)
- `storage.mysqlSize`: MySQL data storage size (default: `20Gi`)
- `storage.storageClass`: Storage class name (default: `longhorn`)

### Ingress
- `ingress.enabled`: Enable ingress (default: `true`)
- `ingress.hosts[0].host`: Hostname for ingress
- `ingress.tls[0].secretName`: TLS certificate secret name
- `ingress.tls[0].hosts`: TLS hostnames

### Service
- `service.type`: Service type (default: `ClusterIP`)
- `service.port`: Service port (default: `80`)
- `service.targetPort`: Target port for the service (default: `8065`)

## Architecture

The chart uses a **sidecar pattern** where Mattermost and MySQL run in the same pod:

- **Mattermost Container**: Serves the application on port 8065
- **MySQL Container**: Provides the database on port 3306

This design simplifies deployment for development environments and small deployments. For production environments with scaling requirements, consider using an external managed MySQL database.

## Storage

Two separate PersistentVolumeClaims are created:
- Mattermost data (default 10Gi): Configuration files, uploads, and local data
- MySQL data (default 20Gi): Database storage

## Configuration

The chart uses a ConfigMap for Mattermost configuration and a Secret for sensitive credentials:

- **ConfigMap**: `mattermost-config` contains the server configuration
- **Secret**: `mattermost-secret` contains database credentials

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Longhorn or equivalent persistent volume provider
- Traefik ingress controller (for ingress)

## Supported Kubernetes Versions

- 1.19+
- 1.20+
- 1.21+
- 1.22+
- 1.23+
- 1.24+

## Limitations

- Single-pod deployment with MySQL sidecar is not suitable for horizontal scaling
- MySQL sidecar is recommended only for development and small deployments
- For production use, consider deploying MySQL separately or using cloud-managed databases

## License

This Helm chart is licensed under the MIT License. See the `LICENSE` file for more details.
