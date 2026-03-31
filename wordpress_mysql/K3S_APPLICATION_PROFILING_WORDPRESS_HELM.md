# K3s Application Profiling: WordPress MySQL Helm Chart

**Date Created**: January 2024  
**Application**: WordPress Blog Platform  
**Version**: 6.4  
**Deployment Method**: Helm 3.0+ on Kubernetes 1.19+  
**Infrastructure**: K3s, EKS, GKE (Kubernetes 1.19+)  

---

## 1. Application Overview

### 1.1 Purpose and Use Cases

WordPress is the world's most popular content management system (CMS). This Helm chart provides a production-ready deployment with MySQL database running in a sidecar container pattern.

**Use Cases**:
- Blog platforms and publishing sites
- Corporate websites and portfolios
- E-commerce stores (with WooCommerce plugin)
- Content management platforms
- Membership and community sites
- Learning management systems (with plugins)

### 1.2 Key Features

- **Content Management**: Create, edit, and publish posts and pages
- **Media Library**: Manage images, videos, and file uploads
- **Themes**: Customize site appearance with themes
- **Plugins**: Extend functionality with thousands of plugins
- **User Management**: Role-based access control and user management
- **SEO Optimization**: Built-in SEO features and plugin support
- **REST API**: Powerful API for custom integrations
- **Responsive Design**: Mobile-friendly by default
- **Search Functionality**: Full-text search across content
- **Comments System**: Threaded comments with moderation

---

## 2. Deployment Architecture

### 2.1 Helm Chart Structure

```
wordpress_mysql/
├── Chart.yaml                  # Chart metadata and version
├── values.yaml                 # Default configuration
├── README.md                   # Quick start guide
├── LICENSE                     # MIT License
├── CHANGELOG.md                # Version history
├── .helmignore                 # Helm packaging ignore patterns
└── templates/
    ├── _helpers.tpl            # Helper functions
    ├── deployment.yaml         # WordPress + MySQL deployment
    ├── service.yaml            # Kubernetes Service (ClusterIP)
    ├── ingress.yaml            # Kubernetes Ingress
    ├── pvc.yaml                # Persistent Volume Claims
    ├── configmap.yaml          # Configuration management
    └── secrets.yaml            # Credentials (base64-encoded)
```

### 2.2 Container Architecture

**Sidecar pattern** with two containers in a single pod:

#### WordPress Container
- **Image**: `wordpress:6.4`
- **Port**: 80 (HTTP)
- **Purpose**: Serves the WordPress application
- **Startup Time**: ~10-15 seconds
- **Health Check**: HTTP GET on `/` endpoint
- **Mount**: /var/www/html (WordPress files)

#### MySQL Sidecar Container
- **Image**: `mysql:8.0`
- **Port**: 3306
- **Purpose**: Provides relational database backend
- **Startup Time**: ~20-40 seconds
- **Health Check**: MySQL ping and query execution
- **Mount**: /var/lib/mysql (database files)

### 2.3 Pod Lifecycle

```
Pod Creation
    ↓
[MySQL Container Init] ← Starts database service
    ↓
[WordPress Container Init] ← Waits for MySQL readiness
    ↓
[WordPress Application Startup] ← Initializes database
    ↓
[Readiness Probe Success] ← Pod marked Ready
    ↓
[Traffic Routed by Ingress/Service]
```

**Total Startup Time**: 45-60 seconds

### 2.4 Networking Model

```
External User
    ↓
Ingress (Traefik)
    ↓
Service (ClusterIP, Port 80)
    ↓
Pod (WordPress, Port 80)
    ↓
MySQL (Localhost, Port 3306)
```

---

## 3. Resource Requirements and Sizing

### 3.1 CPU Resources

**WordPress Container**
- Request: 250m (0.25 cores)
- Limit: 500m (0.5 cores)
- Typical: 100-200m
- Peak: 300-400m

**MySQL Container**
- Request: 250m (0.25 cores)
- Limit: 500m (0.5 cores)
- Typical: 80-150m
- Peak: 250-350m

**Total Pod CPU**: 500m (requests) | 1000m (limits)

### 3.2 Memory Resources

**WordPress Container**
- Request: 512Mi
- Limit: 1Gi
- Typical: 300-500 MiB
- Peak: 700-900 MiB

**MySQL Container**
- Request: 512Mi
- Limit: 1Gi
- Typical: 300-500 MiB
- Peak: 700-800 MiB

**Total Pod Memory**: 1Gi (requests) | 2Gi (limits)

### 3.3 Storage Requirements

**WordPress Volume** (10Gi)
- WordPress installation
- Theme and plugin files
- User uploads
- Growth: 100-500 MB/month

**MySQL Volume** (20Gi)
- Database tables
- Posts, pages, users
- Comments and metadata
- Growth: 50-200 MB/month

### 3.4 Sizing Scenarios

**Small (1-1000 pageviews/day)**
- CPU: 250m / 500m
- RAM: 512Mi / 1Gi
- Storage: 5Gi + 10Gi

**Medium (1000-10000 pageviews/day)**
- CPU: 500m / 1000m
- RAM: 1Gi / 2Gi
- Storage: 10Gi + 20Gi

**Large (10000+ pageviews/day)**
- CPU: 1000m / 2000m
- RAM: 2Gi / 4Gi
- Storage: 20Gi + 50Gi
- Recommendation: External MySQL + multiple pods

---

## 4. Storage and Persistence

### 4.1 Storage Architecture

```
Deployment (WordPress)
    ↓
Pod
    ├─ Container: WordPress
    │   └─ Mount: /var/www/html (10Gi)
    │       └─ PVC: wordpress-wordpress
    │
    └─ Container: MySQL
        └─ Mount: /var/lib/mysql (20Gi)
            └─ PVC: wordpress-mysql
```

### 4.2 Storage Classes

- **Default**: Longhorn
- **AWS**: EBS (gp3 recommended)
- **GCP**: pd-ssd
- **Azure**: Premium_LRS
- **On-premise**: NFS

### 4.3 Backup Strategy

**Recommended**:
- Database: Daily automated snapshots
- Files: Daily incremental backups
- Frequency: Once per day minimum

**Methods**:
1. Longhorn snapshots
2. Velero (Kubernetes-native)
3. mysqldump for database
4. rsync for file backups

---

## 5. Database Configuration

### 5.1 MySQL 8.0

**Connection**:
- Host: localhost
- Port: 3306
- Database: wordpress
- User: wordpress
- Charset: utf8mb4

**Key Tables**:
- wp_posts: Blog posts and pages
- wp_postmeta: Post metadata
- wp_users: User accounts
- wp_comments: Comments
- wp_options: Site configuration
- wp_links: Links
- wp_terms: Categories and tags

### 5.2 Database Scaling

**Current Limitations**:
- Single pod (no scaling)
- No replication
- No high availability

**Migration Path**:
```
Current: Pod(WordPress + MySQL[sidecar])
    ↓
Future: Pod(WordPress) → External MySQL/RDS/CloudSQL
```

### 5.3 Performance Tuning

```sql
max_connections = 100
tmp_table_size = 32M
max_heap_table_size = 32M
query_cache_size = 16M
innodb_buffer_pool_size = 256M
```

---

## 6. Networking and Ingress

### 6.1 Service Configuration

**Type**: ClusterIP (internal only)  
**Port**: 80 → 80  
**Protocol**: TCP

### 6.2 Ingress Setup

**Controller**: Traefik  
**TLS**: cert-manager with Let's Encrypt  
**Protocols**: TLS 1.2, TLS 1.3

### 6.3 DNS Configuration

```
wordpress.example.com  A  <Ingress-IP>
```

---

## 7. Configuration Management

### 7.1 ConfigMap

Contains:
- WordPress database host
- Database name, user
- Table prefix (wp_)
- Debug mode settings

### 7.2 Secrets

Contains:
- MySQL root password
- MySQL user password
- WordPress database password (base64-encoded)

### 7.3 Environment Variables

WordPress-specific:
- WORDPRESS_DB_HOST
- WORDPRESS_DB_NAME
- WORDPRESS_DB_USER
- WORDPRESS_DB_PASSWORD
- WORDPRESS_CONFIG_EXTRA

---

## 8. Logging and Monitoring

### 8.1 Log Sources

**WordPress**:
- Access logs: /var/log/apache2/access.log
- Error logs: /var/log/apache2/error.log
- WordPress debug: /var/www/html/wp-content/debug.log

**MySQL**:
- Error log: /var/log/mysql/error.log
- Query log: /var/log/mysql/query.log
- Slow query log: /var/log/mysql/slow-query.log

### 8.2 Key Metrics

- Page load time
- Database query time
- Number of active users
- Storage utilization
- CPU and memory usage
- Request latency
- Error rate

---

## 9. Security Considerations

### 9.1 WordPress Security

- Regular updates
- Strong passwords
- HTTPS/TLS enforcement
- Plugin and theme auditing
- File permission management
- Database prefix change
- Disable file editing

### 9.2 Kubernetes Security

- Pod security context
- Network policies
- RBAC configuration
- Secret encryption
- Image scanning
- Resource limits

### 9.3 Database Security

- Strong root password
- Separate application user
- Limited database privileges
- Connection encryption
- Access logging

---

## 10. High Availability and Disaster Recovery

### 10.1 Current Limitations

- Single pod deployment
- No automatic failover
- No redundancy
- Pod termination = service downtime

### 10.2 High Availability Path

**Phase 1**: External database
```
Pod(WordPress) → MySQL External
```

**Phase 2**: Multiple pods
```
Pod1(WordPress) ─┐
Pod2(WordPress) ─┼─ Service Load Balancing
Pod3(WordPress) ─┘
    ↓
MySQL External
```

### 10.3 Backup and Recovery

**RTO**: 30-60 minutes (manual)  
**RPO**: 1 day (daily backups)

---

## 11. Maintenance and Updates

### 11.1 WordPress Updates

- Minor: Automatic or manual (recommended automatic)
- Major: Test in staging first
- Plugins: Test compatibility
- Themes: Test compatibility

### 11.2 MySQL Updates

- Version: 8.0 LTS (supported until 2026)
- Updates: Apply security patches promptly

### 11.3 Kubernetes Compatibility

- Minimum: 1.19
- Tested: 1.19-1.28
- Target: 1.24+

---

## 12. Troubleshooting Guide

### 12.1 Common Issues

**WordPress Won't Start**:
- Check MySQL readiness
- Verify database credentials
- Check disk space
- Review error logs

**Database Connection Errors**:
- Verify MySQL container status
- Check credentials in secrets
- Verify network connectivity

**Storage Full**:
- Check PVC usage
- Clean up old media
- Increase storage size
- Enable backup cleanup

### 12.2 Health Checks

```bash
# Check pod status
kubectl get pod wordpress-xxxx

# Check logs
kubectl logs wordpress-xxxx -c wordpress
kubectl logs wordpress-xxxx -c mysql

# Check MySQL
kubectl exec -it wordpress-xxxx -c mysql -- mysql -u root -p -e "SHOW DATABASES;"

# Check WordPress access
curl http://wordpress.example.com
```

---

## 13. Cost Analysis

### 13.1 Infrastructure Costs

**K3s (on-premise)**:
- Hardware: 2 CPU, 2Gi RAM = $200-300/month

**EKS (AWS)**:
- EC2: m5.large = $75-100/month
- EBS: 30Gi = $3-5/month
- EKS control: $73/month
- Total: ~$150-180/month

**GKE (Google Cloud)**:
- Compute: n1-standard-2 = $75-100/month
- Storage: 30Gi = $3-5/month
- GKE: $73/month
- Total: ~$150-180/month

### 13.2 Operational Costs

- License: Free (open-source)
- Support: Community (free)
- Maintenance: 1-2 FTE depending on usage

---

## 14. Implementation Checklist

### Pre-Deployment
- [ ] K3s cluster running (1.19+)
- [ ] Helm 3.0+ installed
- [ ] Longhorn configured
- [ ] Traefik ingress ready
- [ ] Domain prepared
- [ ] cert-manager ready
- [ ] Backup solution planned

### Deployment
- [ ] Download chart
- [ ] Configure values.yaml
- [ ] Create secrets
- [ ] Deploy: helm install wordpress .
- [ ] Verify pod startup
- [ ] Check logs
- [ ] Test DNS resolution
- [ ] Test HTTPS access

### Post-Deployment
- [ ] Complete WordPress installation
- [ ] Configure site settings
- [ ] Install plugins (carefully)
- [ ] Install theme
- [ ] Configure backups
- [ ] Set up monitoring
- [ ] Document configuration
- [ ] Train team

---

## 15. References and Resources

### Official Documentation
- WordPress: https://wordpress.org/support/
- MySQL: https://dev.mysql.com/doc/
- Helm: https://helm.sh/docs/
- Kubernetes: https://kubernetes.io/docs/
- K3s: https://k3s.io/

### Related Tools
- Longhorn: https://longhorn.io/
- cert-manager: https://cert-manager.io/
- Traefik: https://traefik.io/
- Velero: https://velero.io/

---

**Version**: 1.0  
**Last Updated**: January 2024  
**Status**: Production Ready  

---

**End of K3s Application Profiling Document for WordPress MySQL Helm Chart**
