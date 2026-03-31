# Changelog - WhatoMate Helm Chart

## [1.0.0] - 2024-01-15

### Features
- Complete Helm 3.0+ deployment with best practices
- WhatoMate WhatsApp Bot Integration 1.0.0
- PostgreSQL 15 database backend
- Redis 7 caching layer
- Persistent volume support (10Gi for uploads, 20Gi PostgreSQL, 10Gi Redis)
- ConfigMap and Secrets management for configuration
- Traefik-compatible ingress controller support
- TLS/HTTPS support via cert-manager
- Service account and RBAC support
- Health checks (liveness and readiness probes)
- Kubernetes 1.19+ compatibility
- Longhorn storage class support

### Default Configuration
- Image: shridh0r/whatomate:latest
- Port: 8080
- PostgreSQL: 15-alpine (external dependency)
- Redis: 7-alpine (external dependency)
- Resources: 500m/512Mi requests, 1000m/1Gi limits
- Storage: 10Gi uploads + 20Gi PostgreSQL + 10Gi Redis
- Storage Class: Longhorn

### Supported Kubernetes Versions
- 1.19, 1.20, 1.21, 1.22, 1.23, 1.24, 1.25, 1.26, 1.27, 1.28

### Known Limitations
- Single pod deployment (use HPA for scaling)
- PostgreSQL and Redis as external dependencies (managed charts)
- Requires Meta WhatsApp API credentials
