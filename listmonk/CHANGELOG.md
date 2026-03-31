# Changelog - Listmonk Helm Chart

## [1.0.0] - 2024-01-15

### Features
- Complete Helm 3.0+ deployment with sidecar pattern
- Listmonk 3.0.0 container support
- PostgreSQL 15 sidecar database
- Persistent volume support (5Gi for Listmonk, 10Gi for PostgreSQL)
- ConfigMap and Secrets management for configuration
- Traefik-compatible ingress controller support
- TLS/HTTPS support via cert-manager
- Service account and RBAC support
- Health checks (liveness and readiness probes) for both containers
- Kubernetes 1.19+ compatibility
- Longhorn storage class support

### Default Configuration
- Image: listmonk:3.0.0, postgres:15-alpine
- Listmonk Port: 9000 (app), 9001 (admin)
- PostgreSQL Port: 5432
- Resources: 250m/512Mi requests, 500m/1Gi limits (each)
- Storage: 5Gi Listmonk + 10Gi PostgreSQL
- Storage Class: Longhorn

### Supported Kubernetes Versions
- 1.19, 1.20, 1.21, 1.22, 1.23, 1.24, 1.25, 1.26, 1.27, 1.28

### Known Limitations
- Single pod deployment (not horizontally scalable)
- PostgreSQL sidecar designed for development/testing
- For production HA/DR, use external managed PostgreSQL (RDS, CloudSQL, etc.)
