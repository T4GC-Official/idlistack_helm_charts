# K3s Application Profiling: Listmonk PostgreSQL Helm Chart

**Date Created**: January 2024  
**Application**: Listmonk Newsletter Manager  
**Version**: 3.0.0  
**Deployment Method**: Helm 3.0+ on Kubernetes 1.19+  
**Infrastructure**: K3s, EKS, GKE (Kubernetes 1.19+)  

---

## 1. Application Overview

### 1.1 Purpose and Use Cases

Listmonk is a self-hosted, lightweight newsletter and mailing list manager. This Helm chart provides a production-ready deployment with PostgreSQL database running in a sidecar container pattern.

**Use Cases**:
- Email newsletter distribution
- Mailing list management
- Campaign automation
- Subscriber engagement tracking
- Email marketing automation
- Open source newsletter platforms
- Internal communication systems
- Customer notification systems

### 1.2 Key Features

- **Newsletter Management**: Create, schedule, and send newsletters
- **Subscriber Management**: Import, segment, and manage subscribers
- **Campaign Automation**: Automated email workflows and campaigns
- **Templates**: Built-in and custom email templates
- **Analytics**: Open rates, click rates, bounce handling
- **Segmentation**: Advanced subscriber segmentation
- **API**: RESTful API for integrations
- **Webhooks**: Event-based webhooks for integrations
- **SMTP Integration**: Multiple SMTP provider support
- **Media Library**: Manage attachments and images

---

## 2. Deployment Architecture

### 2.1 Helm Chart Structure

```
listmonk/
├── Chart.yaml                  # Chart metadata and version
├── values.yaml                 # Default configuration
├── README.md                   # Quick start guide
├── LICENSE                     # MIT License
├── CHANGELOG.md                # Version history
├── .helmignore                 # Helm packaging ignore patterns
└── templates/
    ├── _helpers.tpl            # Helper functions
    ├── deployment.yaml         # Listmonk + PostgreSQL deployment
    ├── service.yaml            # Kubernetes Service (ClusterIP)
    ├── ingress.yaml            # Kubernetes Ingress
    ├── pvc.yaml                # Persistent Volume Claims
    ├── configmap.yaml          # Configuration management
    └── secrets.yaml            # Credentials (base64-encoded)
```

### 2.2 Container Architecture

**Sidecar pattern** with two containers in a single pod:

#### Listmonk Container
- **Image**: `listmonk/listmonk:3.0.0`
- **Port**: 9000 (HTTP API)
- **Admin Port**: 9001 (Admin panel)
- **Purpose**: Self-hosted newsletter manager
- **Startup Time**: ~10-20 seconds
- **Health Check**: HTTP GET on `/health` endpoint
- **Mount**: /listmonk (application data)

#### PostgreSQL Sidecar Container
- **Image**: `postgres:15-alpine`
- **Port**: 5432
- **Purpose**: Provides relational database backend
- **Startup Time**: ~20-30 seconds
- **Health Check**: pg_isready query
- **Mount**: /var/lib/postgresql/data (database files)

### 2.3 Pod Lifecycle

```
Pod Creation
    ↓
[PostgreSQL Container Init] ← Starts database service
    ↓
[Listmonk Container Init] ← Waits for PostgreSQL readiness
    ↓
[Listmonk Application Startup] ← Initializes database
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
Service (ClusterIP, Port 9000)
    ↓
Pod (Listmonk, Port 9000)
    ↓
PostgreSQL (Localhost, Port 5432)
```

---

## 3. Resource Requirements and Sizing

### 3.1 CPU Resources

**Listmonk Container**
- Request: 250m (0.25 cores)
- Limit: 500m (0.5 cores)
- Typical: 100-200m
- Peak: 300-400m

**PostgreSQL Container**
- Request: 250m (0.25 cores)
- Limit: 500m (0.5 cores)
- Typical: 80-150m
- Peak: 250-350m

**Total Pod CPU**: 500m (requests) | 1000m (limits)

### 3.2 Memory Resources

**Listmonk Container**
- Request: 512Mi
- Limit: 1Gi
- Typical: 300-500 MiB
- Peak: 700-900 MiB

**PostgreSQL Container**
- Request: 512Mi
- Limit: 1Gi
- Typical: 300-500 MiB
- Peak: 700-800 MiB

**Total Pod Memory**: 1Gi (requests) | 2Gi (limits)

### 3.3 Storage Requirements

**Listmonk Volume** (5Gi)
- Listmonk installation
- Configuration files
- Upload data
- Growth: 100-300 MB/month

**PostgreSQL Volume** (10Gi)
- Database tables
- Subscribers and campaigns
- Analytics data
- Growth: 500MB-1GB/month (depending on subscriber count)

### 3.4 Sizing Scenarios

**Small (100-10k subscribers)**
- CPU: 250m / 500m
- RAM: 512Mi / 1Gi
- Storage: 5Gi + 10Gi

**Medium (10k-100k subscribers)**
- CPU: 500m / 1000m
- RAM: 1Gi / 2Gi
- Storage: 5Gi + 20Gi

**Large (100k+ subscribers)**
- CPU: 1000m / 2000m
- RAM: 2Gi / 4Gi
- Storage: 10Gi + 50Gi
- Recommendation: External managed PostgreSQL

---

## 4. Storage and Persistence

### 4.1 Storage Architecture

```
Deployment (Listmonk)
    ↓
Pod
    ├─ Container: Listmonk
    │   └─ Mount: /listmonk (5Gi)
    │       └─ PVC: listmonk-listmonk
    │
    └─ Container: PostgreSQL
        └─ Mount: /var/lib/postgresql/data (10Gi)
            └─ PVC: listmonk-postgres
```

### 4.2 Storage Classes

- **Default**: Longhorn
- **AWS**: EBS (gp3 recommended)
- **GCP**: pd-ssd
- **Azure**: Premium_LRS
- **On-premise**: NFS

### 4.3 Backup Strategy

**Recommended**:
- Database: Daily automated snapshots (pg_dump)
- Files: Daily incremental backups
- Frequency: Once per day minimum
- Retention: 30 days

**Methods**:
1. Longhorn snapshots
2. Velero (Kubernetes-native)
3. pg_dump for database dumps
4. rsync for file backups

---

## 5. Database Configuration

### 5.1 PostgreSQL 15

**Connection**:
- Host: localhost
- Port: 5432
- Database: listmonk
- User: listmonk
- Charset: UTF-8

**Key Tables**:
- subscribers: Subscriber records
- lists: Mailing lists
- campaigns: Email campaigns
- messages: Sent messages
- attachments: Email attachments
- templates: Email templates
- bounces: Bounce records
- logs: Activity logs

### 5.2 Database Scaling

**Current Limitations**:
- Single pod (no scaling)
- No replication
- No high availability

**Migration Path**:
```
Current: Pod(Listmonk + PostgreSQL[sidecar])
    ↓
Future: Pod(Listmonk) → External PostgreSQL/RDS/CloudSQL
```

### 5.3 Performance Tuning

```sql
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 4MB
min_wal_size = 2GB
max_wal_size = 8GB
```

---

## 6. Networking and Ingress

### 6.1 Service Configuration

**Type**: ClusterIP (internal only)  
**Port**: 9000 → 9000  
**Protocol**: TCP

### 6.2 Ingress Setup

**Controller**: Traefik  
**TLS**: cert-manager with Let's Encrypt  
**Protocols**: TLS 1.2, TLS 1.3

### 6.3 DNS Configuration

```
listmonk.example.com  A  <Ingress-IP>
```

---

## 7. Configuration Management

### 7.1 ConfigMap

Contains:
- PostgreSQL connection host
- PostgreSQL database name
- PostgreSQL user
- Listmonk API address
- Admin panel address

### 7.2 Secrets

Contains:
- PostgreSQL root password (POSTGRES_PASSWORD)
- PostgreSQL user password
- Listmonk database password (base64-encoded)

### 7.3 Environment Variables

Listmonk-specific:
- LISTMONK_db__host
- LISTMONK_db__port
- LISTMONK_db__user
- LISTMONK_db__password
- LISTMONK_db__database
- LISTMONK_app__address
- LISTMONK_admin__address

---

## 8. Logging and Monitoring

### 8.1 Log Sources

**Listmonk**:
- Application logs: stdout/stderr
- Access logs: Container logs
- Error logs: Container logs
- API logs: Request/response logs

**PostgreSQL**:
- Error log: /var/log/postgresql/postgresql.log
- Query log: postgres logs
- Slow query log: log_min_duration_statement setting

### 8.2 Key Metrics

- Email send rate (messages/hour)
- Campaign completion rate
- Subscriber count
- Bounce rate
- Open rate
- Click rate
- CPU and memory usage
- Database query time
- Storage utilization

---

## 9. Security Considerations

### 9.1 Listmonk Security

- Admin credentials management
- API token security
- SMTP credentials encryption
- Subscriber data protection
- GDPR compliance (data export/deletion)
- Rate limiting for APIs
- CORS configuration

### 9.2 Kubernetes Security

- Pod security context
- Network policies
- RBAC configuration
- Secret encryption
- Image scanning
- Resource limits
- Read-only file system

### 9.3 Database Security

- Strong root password
- Separate application user
- Limited database privileges
- Connection encryption
- Access logging
- Parameter queries (SQL injection prevention)

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
Pod(Listmonk) → PostgreSQL External
```

**Phase 2**: Multiple pods with shared database
```
Pod1(Listmonk) ─┐
Pod2(Listmonk) ─┼─ Service Load Balancing
Pod3(Listmonk) ─┘
    ↓
PostgreSQL External (RDS/CloudSQL)
```

### 10.3 Backup and Recovery

**RTO**: 30-60 minutes (manual)  
**RPO**: 1 day (daily backups)

---

## 11. Maintenance and Updates

### 11.1 Listmonk Updates

- Version: 3.0.0 (latest)
- Update frequency: Monitor GitHub releases
- Backup before updates
- Test in staging first
- Zero-downtime deployment possible

### 11.2 PostgreSQL Updates

- Version: 15-alpine (LTS until 2026)
- Updates: Apply security patches promptly
- Major version upgrades: Plan migration path

### 11.3 Kubernetes Compatibility

- Minimum: 1.19
- Tested: 1.19-1.28
- Target: 1.24+

---

## 12. Troubleshooting Guide

### 12.1 Common Issues

**Listmonk Won't Start**:
- Check PostgreSQL readiness
- Verify database credentials
- Check disk space
- Review error logs

**Email Send Failures**:
- Verify SMTP configuration
- Check SMTP credentials
- Review send rate limits
- Check sender reputation

**Database Connection Errors**:
- Verify PostgreSQL container status
- Check credentials in secrets
- Verify network connectivity

**High Memory Usage**:
- Check large campaign sizes
- Review subscriber count
- Monitor database query performance

### 12.2 Health Checks

```bash
# Check pod status
kubectl get pod listmonk-xxxx

# Check logs
kubectl logs listmonk-xxxx -c listmonk
kubectl logs listmonk-xxxx -c postgres

# Check PostgreSQL
kubectl exec -it listmonk-xxxx -c postgres -- psql -U listmonk -d listmonk -c "SELECT COUNT(*) FROM subscribers;"

# Check Listmonk API
curl http://listmonk.example.com/health
```

---

## 13. Cost Analysis

### 13.1 Infrastructure Costs

**K3s (on-premise)**:
- Hardware: 2 CPU, 2Gi RAM = $200-300/month

**EKS (AWS)**:
- EC2: t3.medium = $30-40/month
- EBS: 15Gi = $1.50-2/month
- EKS control: $73/month
- Total: ~$105-115/month

**GKE (Google Cloud)**:
- Compute: n1-standard-1 = $30-40/month
- Storage: 15Gi = $1.50-2/month
- GKE: $73/month
- Total: ~$105-115/month

### 13.2 Operational Costs

- License: Free (open-source)
- Support: Community (free)
- Maintenance: 0.5-1 FTE depending on usage

---

## 14. Implementation Checklist

### Pre-Deployment
- [ ] K3s cluster running (1.19+)
- [ ] Helm 3.0+ installed
- [ ] Longhorn configured
- [ ] Traefik ingress ready
- [ ] Domain prepared
- [ ] cert-manager ready
- [ ] SMTP provider configured
- [ ] Backup solution planned

### Deployment
- [ ] Download chart
- [ ] Configure values.yaml
- [ ] Set SMTP credentials
- [ ] Create secrets
- [ ] Deploy: helm install listmonk .
- [ ] Verify pod startup
- [ ] Check logs
- [ ] Test DNS resolution
- [ ] Test HTTPS access
- [ ] Login to admin panel

### Post-Deployment
- [ ] Configure email templates
- [ ] Set up subscribers
- [ ] Test email sending
- [ ] Configure webhooks
- [ ] Set up monitoring
- [ ] Configure backups
- [ ] Document configuration
- [ ] Train team

---

## 15. References and Resources

### Official Documentation
- Listmonk: https://listmonk.app/
- PostgreSQL: https://www.postgresql.org/docs/
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

**End of K3s Application Profiling Document for Listmonk PostgreSQL Helm Chart**
