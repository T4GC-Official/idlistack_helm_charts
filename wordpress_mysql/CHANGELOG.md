# Changelog

All notable changes to the WordPress MySQL Helm chart will be documented in this file.

## [1.0.0] - 2024-01-15

### Added
- Initial Helm chart for WordPress blog platform
- Support for MySQL 8.0 as sidecar database
- Persistent storage for WordPress content and MySQL database
- ConfigMap for WordPress configuration management
- Secrets for database credentials
- Helper templates for consistent labeling and naming
- Ingress support with TLS configuration
- ServiceAccount for pod security
- Comprehensive values.yaml with organized sections
- Health checks (liveness and readiness probes)
- Support for Kubernetes 1.19+
- Support for Longhorn as default storage provider

### Features
- **Sidecar Architecture**: WordPress and MySQL running in a single pod
- **Persistent Storage**: Separate PVCs for WordPress content (10Gi) and MySQL data (20Gi)
- **Configuration Management**: ConfigMap-based configuration with dynamic templates
- **Resource Control**: Configurable resource requests and limits
- **Networking**: ClusterIP service with optional ingress for external access
- **Health Management**: Probes ensure container readiness and liveness

### Default Configuration
- WordPress v6.4
- MySQL 8.0
- 250m CPU / 512Mi RAM for WordPress
- 250m CPU / 512Mi RAM for MySQL
- Longhorn storage class
- Traefik ingress configuration

## Maintenance

### Supported Kubernetes Versions
- 1.19+, 1.20+, 1.21+, 1.22+, 1.23+, 1.24+

### Known Limitations
- Single-pod deployment (not horizontally scalable)
- MySQL sidecar suited for development and small deployments only
- For production, consider using external managed MySQL databases

### Future Enhancements
- Support for external MySQL database
- Horizontal pod autoscaling
- Multi-replica deployments with shared database
- Advanced security policies
