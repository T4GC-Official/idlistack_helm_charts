# WordPress MySQL Helm Chart

A production-ready Helm chart for deploying WordPress with MySQL sidecar database on Kubernetes.

## Quick Start

### Install the Chart

```bash
helm install wordpress . \
  --set ingress.hosts[0].host=wordpress.example.com \
  --set database.mysql.password=your-db-password \
  --set database.mysql.rootPassword=your-root-password
```

### Uninstall the Chart

```bash
helm uninstall wordpress
```

## Values

### Image Configuration
- `image.wordpress.repository`: WordPress image repository (default: `wordpress`)
- `image.wordpress.tag`: WordPress image tag (default: `6.4`)
- `image.mysql.repository`: MySQL image repository (default: `mysql`)
- `image.mysql.tag`: MySQL image tag (default: `8.0`)

### WordPress Settings
- `wordpress.port`: WordPress listen port (default: `80`)
- `wordpress.resources`: CPU and memory resource limits and requests

### Database Configuration
- `database.mysql.database`: Database name (default: `wordpress`)
- `database.mysql.user`: Database user (default: `wordpress`)
- `database.mysql.password`: Database password (required)
- `database.mysql.rootPassword`: MySQL root password (required)

### Storage
- `storage.wordpressSize`: WordPress content storage size (default: `10Gi`)
- `storage.mysqlSize`: MySQL data storage size (default: `20Gi`)
- `storage.storageClass`: Storage class name (default: `longhorn`)

### Ingress
- `ingress.enabled`: Enable ingress (default: `true`)
- `ingress.hosts[0].host`: Hostname for ingress
- `ingress.tls[0].secretName`: TLS certificate secret name

### Service
- `service.type`: Service type (default: `ClusterIP`)
- `service.port`: Service port (default: `80`)
- `service.targetPort`: Target port (default: `80`)

## Architecture

The chart uses a **sidecar pattern** where WordPress and MySQL run in the same pod.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Longhorn or equivalent persistent volume provider
- Traefik ingress controller (for ingress)

## License

This Helm chart is licensed under the MIT License. See the `LICENSE` file for more details.
