# Changelog

All notable changes to the Mattermost Helm chart will be documented in this file.

## [1.0.0] - 2024-01-15

### Added
- Initial Helm chart for Mattermost team collaboration server
- Support for MySQL 8.0 as sidecar database
- Persistent storage for Mattermost data and MySQL database
- ConfigMap for Mattermost configuration management
- Secrets for database credentials
- Helper templates for consistent labeling and naming
- Ingress support with TLS configuration
- ServiceAccount for pod security
- Comprehensive values.yaml with organized sections
- Health checks (liveness and readiness probes)
- Support for Kubernetes 1.19+
- Support for Longhorn as default storage provider

### Features
- **Sidecar Architecture**: Mattermost and MySQL running in a single pod for simplified deployment
- **Persistent Storage**: Separate PVCs for Mattermost data (10Gi) and MySQL data (20Gi)
- **Configuration Management**: ConfigMap-based server configuration with dynamic templates
- **Resource Control**: Configurable resource requests and limits for both containers
- **Networking**: ClusterIP service with optional ingress for external access
- **Health Management**: Probes ensure container readiness and liveness

### Default Configuration
- Mattermost v9.5.1
- MySQL 8.0
- 500m CPU / 1Gi RAM for Mattermost
- 250m CPU / 512Mi RAM for MySQL
- Longhorn storage class
- Traefik ingress configuration

## Maintenance

### Supported Kubernetes Versions
- 1.19+
- 1.20+
- 1.21+
- 1.22+
- 1.23+
- 1.24+

### Known Limitations
- Single-pod deployment (not horizontally scalable with MySQL sidecar)
- MySQL sidecar suited for development and small deployments only
- For production, consider using external managed MySQL databases

### Future Enhancements
- Support for external MySQL database
- Horizontal pod autoscaling
- Multi-replica deployments with shared database
- LDAP/SAML authentication integration
- Advanced security policies
