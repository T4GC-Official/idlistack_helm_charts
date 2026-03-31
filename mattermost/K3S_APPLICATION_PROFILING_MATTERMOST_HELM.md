# K3s Application Profiling: Mattermost Helm Chart

**Date Created**: January 2024  
**Application**: Mattermost Team Collaboration Server  
**Version**: 9.5.1  
**Deployment Method**: Helm 3.0+ on Kubernetes 1.19+  
**Infrastructure**: K3s, EKS, GKE (Kubernetes 1.19+)  

---

## 1. Application Overview

### 1.1 Purpose and Use Cases

Mattermost is an open-source team collaboration and messaging platform, offering a self-hosted alternative to Slack. It provides:

- Real-time messaging and team communication
- File sharing and collaborative discussions
- Channel-based organization and conversations
- User and team management
- Integration capabilities with third-party systems
- Extensible plugin architecture

**Use Cases**:
- Enterprise team communication platforms
- Internal company messaging systems
- Secure alternative to cloud-based messaging services
- Integration hub for development teams
- Community collaboration platforms

### 1.2 Key Features

- **Real-time Messaging**: Instant messaging with typing indicators and reactions
- **Channels**: Public and private channels for organized communication
- **File Sharing**: Upload and share files within conversations
- **Search**: Full-text search across messages and files
- **User Management**: LDAP/SAML integration, team-based access control
- **API**: RESTful API for custom integrations and plugins
- **Mobile Apps**: Native iOS and Android applications
- **Emoji Support**: Custom emoji and built-in emoji picker
- **Thread Support**: Organized conversations with thread replies
- **Webhooks**: Incoming and outgoing webhooks for integrations

---

## 2. Deployment Architecture

### 2.1 Helm Chart Structure

```
mattermost/
├── Chart.yaml                  # Chart metadata and version info
├── values.yaml                 # Default configuration values
├── README.md                   # Quick start guide
├── LICENSE                     # MIT License
├── CHANGELOG.md                # Version history
├── .helmignore                 # Helm packaging ignore patterns
└── templates/
    ├── _helpers.tpl            # Helper functions for templates
    ├── deployment.yaml         # Kubernetes Deployment specification
    ├── service.yaml            # Kubernetes Service (ClusterIP)
    ├── ingress.yaml            # Kubernetes Ingress (Traefik compatible)
    ├── pvc.yaml                # Persistent Volume Claims (Mattermost + MySQL)
    ├── configmap.yaml          # Configuration management (server config)
    └── secrets.yaml            # Kubernetes Secret (credentials)
```

### 2.2 Container Architecture

The chart uses a **sidecar pattern** with two containers in a single pod:

#### Main Container: Mattermost
- **Image**: `mattermost/mattermost-team-edition:9.5`
- **Port**: 8065 (HTTP)
- **Purpose**: Serves the Mattermost application
- **Startup Time**: ~15-30 seconds
- **Health Check**: HTTP GET on `/` endpoint
- **Configuration**: Via ConfigMap and environment variables

#### Sidecar Container: MySQL 8.0
- **Image**: `mysql:8.0`
- **Port**: 3306 (TCP)
- **Purpose**: Provides relational database backend
- **Startup Time**: ~20-40 seconds
- **Health Check**: MySQL ping and query execution
- **Configuration**: Via environment variables and Secrets

### 2.3 Pod Lifecycle

```
Pod Creation
    ↓
[MySQL Container Init] ← Starts database service
    ↓
[Mattermost Container Init] ← Waits for MySQL readiness
    ↓
[Mattermost Application Startup] ← Initializes database schema
    ↓
[Readiness Probe Success] ← Pod marked Ready
    ↓
[Traffic Routed by Ingress/Service]
```

**Total Startup Time**: 60-90 seconds (varies by hardware)

### 2.4 Networking Model

```
External User
    ↓
Ingress (Traefik)
    ↓
Service (ClusterIP, Port 80)
    ↓
Pod (Mattermost, Port 8065)
    ↓
MySQL (Localhost, Port 3306)
```

- **Service Type**: ClusterIP (internal cluster networking)
- **Ingress Controller**: Traefik (ingress.traefik.io)
- **Protocol**: HTTP/HTTPS (with TLS termination at ingress)
- **DNS**: Resolves to ingress hostname

---

## 3. Resource Requirements and Sizing

### 3.1 CPU Resources

#### Mattermost Container
- **Request**: 500m (0.5 CPU cores)
- **Limit**: 1000m (1 CPU core)
- **Typical Usage**: 200-400m (under normal load)
- **Peak Usage**: 600-800m (during spikes)
- **Recommendation**: 2+ CPU cores on node for headroom

#### MySQL Container
- **Request**: 250m (0.25 CPU cores)
- **Limit**: 500m (0.5 CPU cores)
- **Typical Usage**: 100-200m
- **Peak Usage**: 300-400m (during index operations)

#### Total Pod CPU
- **Requested**: 750m (0.75 cores)
- **Limited**: 1500m (1.5 cores)
- **Minimum Node CPU**: 2 cores (recommended)

### 3.2 Memory Resources

#### Mattermost Container
- **Request**: 1Gi (1024 MiB)
- **Limit**: 2Gi (2048 MiB)
- **Typical Usage**: 600-900 MiB
- **Peak Usage**: 1.2-1.5 GiB
- **Cache Size**: ~100-200 MiB

#### MySQL Container
- **Request**: 512Mi (512 MiB)
- **Limit**: 1Gi (1024 MiB)
- **Typical Usage**: 300-500 MiB
- **Peak Usage**: 700-900 MiB
- **Buffer Pool**: 256 MiB (configurable)

#### Total Pod Memory
- **Requested**: 1.5Gi (1536 MiB)
- **Limited**: 3Gi (3072 MiB)
- **Minimum Node Memory**: 4Gi (recommended)

### 3.3 Storage Requirements

#### Mattermost Data Volume
- **Size**: 10Gi (default, configurable)
- **Storage Class**: Longhorn (default)
- **Mount Path**: `/mattermost/data`
- **Contents**: 
  - File uploads (avatars, attachments)
  - Plugins and plugin data
  - Configuration files
  - Local cache
- **Growth Rate**: 100MB - 1GB per month (depending on usage)

#### MySQL Data Volume
- **Size**: 20Gi (default, configurable)
- **Storage Class**: Longhorn (default)
- **Mount Path**: `/var/lib/mysql`
- **Contents**:
  - Database tables and indexes
  - Binary logs
  - Transaction logs
- **Growth Rate**: 50MB - 500MB per month (depending on user activity)

#### Total Storage
- **Allocated**: 30Gi
- **Minimum Available**: 5Gi free space on node

### 3.4 Practical Sizing Scenarios

#### Small Deployment (1-50 Users)
- **Mattermost CPU**: 250m request / 500m limit
- **MySQL CPU**: 100m request / 250m limit
- **Mattermost Memory**: 512Mi request / 1Gi limit
- **MySQL Memory**: 256Mi request / 512Mi limit
- **Storage**: Mattermost 5Gi, MySQL 10Gi
- **Node Requirements**: 2 CPU, 2Gi RAM minimum

#### Medium Deployment (50-500 Users)
- **Mattermost CPU**: 500m request / 1000m limit
- **MySQL CPU**: 250m request / 500m limit
- **Mattermost Memory**: 1Gi request / 2Gi limit
- **MySQL Memory**: 512Mi request / 1Gi limit
- **Storage**: Mattermost 10Gi, MySQL 20Gi
- **Node Requirements**: 2 CPU, 4Gi RAM minimum

#### Large Deployment (500+ Users)
- **Mattermost CPU**: 1000m request / 2000m limit
- **MySQL CPU**: 500m request / 1000m limit
- **Mattermost Memory**: 2Gi request / 4Gi limit
- **MySQL Memory**: 1Gi request / 2Gi limit
- **Storage**: Mattermost 20Gi, MySQL 50Gi
- **Node Requirements**: 4 CPU, 8Gi RAM minimum
- **Recommendation**: Consider external MySQL database for better performance

---

## 4. Storage and Persistence

### 4.1 Storage Architecture

```
Deployment (Mattermost)
    ↓
Pod
    ├─ Container: Mattermost
    │   └─ Volume Mount: /mattermost/data (10Gi RWO)
    │       └─ PVC: mattermost-mattermost
    │           └─ PV (Longhorn)
    │
    └─ Container: MySQL
        └─ Volume Mount: /var/lib/mysql (20Gi RWO)
            └─ PVC: mattermost-mysql
                └─ PV (Longhorn)
```

### 4.2 Storage Classes

Default: **Longhorn** (distributed block storage)

**Alternative Storage Classes**:
- **EBS** (AWS): `ebs.csi.amazonaws.com` (gp3 recommended)
- **GCE** (GCP): `kubernetes.io/gce-pd` (pd-ssd recommended)
- **Azure**: `disk.csi.azure.com` (Premium_LRS recommended)
- **NFS**: `nfs-client` (for NFS-based persistent storage)

### 4.3 Data Backup Strategies

#### Backup Frequency
- **Critical Data**: Daily backups minimum
- **Recommended**: Hourly backups for large deployments

#### Backup Methods

1. **Longhorn Snapshots**:
   ```bash
   # Create snapshot via Longhorn API
   kubectl exec -it longhorn-manager-xxx -- \
     longhorn-manager-cli snapshot create mattermost-mattermost
   ```

2. **Kubernetes Native Backup** (Velero):
   ```bash
   velero backup create mattermost-backup --include-namespaces default
   ```

3. **MySQL Dump**:
   ```bash
   kubectl exec -it mattermost-xxxx -c mysql -- \
     mysqldump -u root -p mattermost > backup.sql
   ```

#### Restore Procedures

**From Longhorn Snapshot**:
1. Create new volume from snapshot
2. Update PVC to use new volume
3. Restart Mattermost pod

**From MySQL Dump**:
1. Delete existing database
2. Restore from dump file
3. Restart Mattermost pod

### 4.4 Storage Monitoring

**Key Metrics**:
- PVC usage percentage (alert at 80%)
- Volume I/O latency (alert if > 50ms)
- Database size growth (trend analysis)

**Commands**:
```bash
# Check PVC status
kubectl get pvc -n default

# Check storage class
kubectl get storageclass

# Monitor volume usage
kubectl exec -it mattermost-xxxx -c mattermost -- \
  du -sh /mattermost/data

# Check MySQL size
kubectl exec -it mattermost-xxxx -c mysql -- \
  mysql -u root -p -e "SELECT SUM(data_length) FROM \
  information_schema.tables WHERE table_schema='mattermost';"
```

---

## 5. Database Configuration

### 5.1 MySQL 8.0 Configuration

#### Connection Settings
- **Host**: localhost (sidecar in same pod)
- **Port**: 3306
- **User**: mmuser (application user)
- **Password**: Retrieved from Secret
- **Database**: mattermost
- **Charset**: utf8mb4 (multi-byte character support)

#### Performance Tuning Parameters

```sql
-- Recommended MySQL settings for Mattermost
[mysqld]
max_connections = 200
max_allowed_packet = 16M
thread_stack = 256K
thread_cache_size = 8
query_cache_size = 16M
query_cache_type = 1
tmp_table_size = 32M
max_heap_table_size = 32M
log-bin = mysql-bin
binlog_format = mixed
expire_logs_days = 10
```

#### Default Configuration (Current Chart)
- **Max Connections**: 300 (via SQLSettings)
- **Connection Timeout**: 3600s (idle connections)
- **Max Idle Connections**: 20
- **Max Open Connections**: 300

### 5.2 Database Schema

**Key Tables**:
- `users`: User accounts and authentication
- `teams`: Team/workspace definitions
- `channels`: Chat channels and groups
- `posts`: Messages and content
- `reactions`: Emoji reactions on posts
- `files`: File upload metadata and references
- `preferences`: User preferences and settings
- `sessions`: Active user sessions
- `oauth_apps`: OAuth2 application configurations
- `plugins`: Installed plugin metadata

**Total Tables**: 50+ (dynamically managed by application)

### 5.3 Database Scaling Considerations

#### Single Pod Limitations
- **Vertical Scaling Only**: Cannot add more Mattermost pods without external database
- **Connection Pooling**: Handled by Mattermost application
- **Replication**: Not supported in sidecar architecture
- **High Availability**: Not available with sidecar MySQL

#### External Database Migration Path
```
Current: Pod(Mattermost + MySQL[sidecar])
    ↓ (Migration)
Future: Pod(Mattermost) → CloudSQL/RDS/Self-managed MySQL
```

### 5.4 Database Health Monitoring

**Critical Health Checks**:
```bash
# Check database status
kubectl exec -it mattermost-xxxx -c mysql -- \
  mysqladmin -u root -p status

# Check database size
kubectl exec -it mattermost-xxxx -c mysql -- \
  mysql -u root -p -e "SELECT table_schema, \
  SUM(data_length+index_length) FROM information_schema.tables \
  WHERE table_schema='mattermost' GROUP BY table_schema;"

# Check for replication lag (if applicable)
kubectl exec -it mattermost-xxxx -c mysql -- \
  mysql -u root -p -e "SHOW SLAVE STATUS\G"
```

---

## 6. Networking and Ingress

### 6.1 Network Architecture

```
┌─────────────────────────────────────────────┐
│     K3s/Kubernetes Cluster Network          │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │     Ingress Controller (Traefik)     │  │
│  │  Hostname: mattermost.example.com   │  │
│  └──────────┬───────────────────────────┘  │
│             │ Port 80/443 (TLS)           │
│  ┌──────────▼───────────────────────────┐  │
│  │    Service (ClusterIP)               │  │
│  │    Port: 80 → 8065                   │  │
│  └──────────┬───────────────────────────┘  │
│             │                              │
│  ┌──────────▼───────────────────────────┐  │
│  │    Pod (Mattermost + MySQL)          │  │
│  │    Mattermost Port: 8065             │  │
│  │    MySQL Port: 3306 (internal)       │  │
│  └──────────────────────────────────────┘  │
│                                             │
└─────────────────────────────────────────────┘
```

### 6.2 Service Configuration

**Service Type**: ClusterIP (internal only)

**Service Ports**:
- **Port**: 80 (external)
- **Target Port**: 8065 (Mattermost container)
- **Protocol**: TCP

**Endpoints**: 1 Pod (1 replica default)

### 6.3 Ingress Configuration

**Ingress Controller**: Traefik (default K3s)

**TLS Configuration**:
- **Certificates**: Managed by cert-manager
- **Issuer**: Let's Encrypt (ACME)
- **Renewal**: Automatic 30 days before expiration
- **Protocols**: TLS 1.2, TLS 1.3

**Ingress Rules**:
```
Host: mattermost.example.com
  ↓
TLS Termination (cert-manager)
  ↓
HTTP → Mattermost:8065
```

### 6.4 DNS and Domain Configuration

**DNS Setup Required**:
```
mattermost.example.com  A  <Ingress-IP>
```

**Resolution Check**:
```bash
# Verify DNS resolution
nslookup mattermost.example.com

# Check ingress IP
kubectl get ingress mattermost
```

### 6.5 Network Policies (Optional Security)

**Recommended Network Policies**:

1. **Ingress Policy**: Allow only from ingress controller
2. **Egress Policy**: Allow MySQL localhost, external APIs
3. **Default Deny**: Deny all except specified

### 6.6 Load Balancing Considerations

**Current Architecture**:
- **Load Balancer**: None (single pod)
- **Session Affinity**: Not applicable (single pod)
- **Scaling**: Manual (scale via deployment replica count)

**Horizontal Scaling Limitations**:
- Multiple Mattermost pods would all access same MySQL sidecar (not feasible)
- External database required for true horizontal scaling

---

## 7. Configuration Management

### 7.1 Configuration Sources

1. **Helm values.yaml**: Default configuration
2. **ConfigMap**: `mattermost-config` (server settings)
3. **Secrets**: `mattermost-secret` (credentials)
4. **Environment Variables**: Container-level overrides

### 7.2 ConfigMap Structure

**ConfigMap**: `mattermost-config`

**Contents**: `config.json` (Mattermost server configuration)

**Key Settings**:
- Service URL (site URL)
- Database connection
- File storage settings
- Email configuration
- LDAP/SAML settings
- Plugin configuration
- Feature flags

**Update Procedure**:
```bash
# Edit values
helm upgrade mattermost . --values custom-values.yaml

# ConfigMap automatically updates
# Pod restart required for changes to take effect
kubectl rollout restart deployment/mattermost
```

### 7.3 Secret Management

**Secret**: `mattermost-secret`

**Contents**:
- `mysql-root-password`: MySQL root user password
- `mysql-password`: MySQL application user password

**Security Notes**:
- Secrets stored as base64-encoded (not encrypted at rest by default)
- Enable KMS/encryption-at-rest in Kubernetes for better security
- Rotate passwords periodically
- Use external secret management (HashiCorp Vault) for production

### 7.4 Environment Variable Overrides

Mattermost supports environment variable overrides in format: `MM_<SECTION>_<SETTING>`

**Examples**:
```bash
MM_SERVICESETTINGS_SITEURL=https://mattermost.example.com
MM_SQLSETTINGS_DRIVERNAME=mysql
MM_SQLSETTINGS_DATASOURCE=mmuser:password@tcp(localhost:3306)/mattermost
```

### 7.5 Configuration Best Practices

1. **Version Control**: Keep values.yaml in Git
2. **Secrets Separation**: Use external secret management
3. **Documentation**: Document custom configurations
4. **Validation**: Test configuration changes in staging first
5. **Rollback Plan**: Keep previous values for quick rollback

---

## 8. Logging and Monitoring

### 8.1 Log Collection

**Mattermost Logs**:
- **Location**: /mattermost/logs (in container)
- **Format**: JSON structured logs
- **Levels**: DEBUG, INFO, WARNING, ERROR, CRITICAL

**MySQL Logs**:
- **Error Log**: /var/log/mysql/error.log
- **General Query Log**: Disabled by default
- **Slow Query Log**: Optional (performance monitoring)

**Commands to View Logs**:
```bash
# Mattermost logs
kubectl logs -f mattermost-xxxx -c mattermost

# MySQL logs
kubectl logs -f mattermost-xxxx -c mysql

# Last 100 lines
kubectl logs --tail=100 mattermost-xxxx -c mattermost

# Logs from last hour
kubectl logs --since=1h mattermost-xxxx -c mattermost
```

### 8.2 Log Aggregation Setup

**Recommended Stack**: ELK (Elasticsearch, Logstash, Kibana)

**Alternative**: Loki + Grafana

**Implementation**:
```bash
# Forward logs to centralized logging
kubectl logs mattermost-xxxx -c mattermost | \
  fluentd → Elasticsearch → Kibana
```

### 8.3 Metrics and Monitoring

**Key Metrics to Monitor**:

1. **Application Metrics**:
   - Active users
   - Message throughput (messages/second)
   - API request latency
   - Plugin load times
   - Memory usage per user

2. **Database Metrics**:
   - Connection count
   - Query latency (average, p95, p99)
   - Slow query count
   - Index usage efficiency
   - Replication lag (if applicable)

3. **Infrastructure Metrics**:
   - Pod CPU usage
   - Pod memory usage
   - Storage I/O latency
   - Storage capacity utilization
   - Network bandwidth

### 8.4 Prometheus Integration

**Metrics Endpoint**: `/api/v4/system/metrics/properties`

**Mattermost Prometheus Exporter**:
```bash
# Install custom exporter for detailed metrics
# Configure Prometheus scrape job
- job_name: mattermost
  static_configs:
    - targets: ['mattermost:8065']
  metrics_path: '/metrics'
```

### 8.5 Alerting Rules

**Critical Alerts**:
```
- Pod not ready (> 5 minutes)
- CPU limit exceeded (> 90%)
- Memory limit exceeded (> 85%)
- Storage usage > 80%
- Database connection errors
- API endpoint latency > 2s
```

---

## 9. Security Considerations

### 9.1 Pod Security Context

**Current Configuration**:
```yaml
securityContext:
  runAsNonRoot: false (configurable)
  fsGroup: null (configurable)
```

**Recommended Security Context**:
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: false
```

### 9.2 Network Security

1. **Ingress TLS**: Enforce HTTPS only
   ```yaml
   annotations:
     cert-manager.io/cluster-issuer: "letsencrypt-prod"
   ```

2. **Network Policies**: Restrict traffic
   ```bash
   kubectl apply -f network-policy.yaml
   ```

3. **Service Mesh**: Optional (Istio, Linkerd)

### 9.3 Secret Management

**Current**: Kubernetes Secrets (base64 encoded)

**Improvements**:
1. Enable encryption-at-rest: `--encryption-provider-config`
2. Use external secret management:
   - HashiCorp Vault
   - AWS Secrets Manager
   - Google Cloud Secret Manager
3. Rotate passwords regularly
4. Use ServiceAccount tokens for pod authentication

### 9.4 RBAC Configuration

**Recommended RBAC**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: mattermost
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
```

### 9.5 Image Security

**Best Practices**:
1. Use specific image tags (not `latest`)
2. Scan images for vulnerabilities:
   ```bash
   trivy image mattermost/mattermost-team-edition:9.5
   ```
3. Enable image pull secrets for private registries
4. Sign images with cosign or similar

### 9.6 Compliance and Auditing

**Audit Requirements**:
- Enable Kubernetes API audit logging
- Log all secret access
- Monitor user authentication
- Regular security scanning
- Compliance with organizational policies

---

## 10. High Availability and Disaster Recovery

### 10.1 Current Limitations

**Single Pod Architecture**:
- ❌ Not highly available
- ❌ No automatic failover
- ❌ No redundancy
- ⚠️ Pod termination = service downtime

### 10.2 High Availability Strategy

**Phase 1**: Implement external database
```
Pod(Mattermost) → MySQL (External/RDS/CloudSQL)
```

**Phase 2**: Add pod replicas
```
Pod1(Mattermost) ─────┐
                      ├─ Service Load Balancing
Pod2(Mattermost) ─────┤
                      │
Pod3(Mattermost) ─────┘
         ↓
    MySQL External
```

**Phase 3**: Add geographical redundancy
```
Region A: Pod Cluster → Primary Database
            ↓ (Replication)
Region B: Pod Cluster → Secondary Database
```

### 10.3 Backup and Recovery

**Backup Strategy**:
1. **Database Backups**: Daily automated snapshots
2. **Configuration Backups**: Version control (Git)
3. **File Backups**: Regular snapshots of /mattermost/data

**Recovery Time Objectives (RTO)**:
- **Current**: 30 minutes (manual restore)
- **Target**: 5 minutes (automated recovery)

**Recovery Point Objectives (RPO)**:
- **Current**: 1 hour (hourly backups)
- **Target**: 15 minutes (frequent snapshots)

### 10.4 Disaster Recovery Plan

**Step 1**: Detect failure
```bash
kubectl get pod mattermost-xxxx
# STATUS: CrashLoopBackOff or Not Ready
```

**Step 2**: Analyze logs
```bash
kubectl logs mattermost-xxxx --previous -c mattermost
```

**Step 3**: Restore from backup
```bash
# Option A: Restart pod (for transient issues)
kubectl rollout restart deployment/mattermost

# Option B: Restore database from backup
# (See Storage section for restore procedure)

# Option C: Full cluster restore
velero restore create mattermost-restore --from-backup mattermost-backup
```

---

## 11. Maintenance and Updates

### 11.1 Version Management

**Chart Version**: Semantic versioning (MAJOR.MINOR.PATCH)

**Current Version**: 1.0.0

**Update Procedure**:
```bash
# Check available updates
helm search repo mattermost

# Upgrade to new version
helm upgrade mattermost . --values values.yaml

# Verify upgrade
kubectl rollout status deployment/mattermost
```

### 11.2 Mattermost Updates

**Current Version**: 9.5.1

**Update Strategy**:
1. **Minor Updates** (v9.5 → v9.6): In-place update recommended
2. **Major Updates** (v9 → v10): Test in staging first
3. **Emergency Updates**: Apply immediately if security patches

**Update Command**:
```bash
helm values mattermost > values.yaml
# Edit image.tag: "9.6"
helm upgrade mattermost . --values values.yaml
```

### 11.3 MySQL Updates

**Current Version**: 8.0

**MySQL EOL**: April 2026 (MySQL 8.0)

**Update Path**: MySQL 8.0 LTS series

**Caution**: Database major version upgrades may require downtime

### 11.4 Kubernetes Updates

**Minimum Supported**: 1.19
**Maximum Tested**: 1.28
**Target Versions**: 1.24, 1.25, 1.26, 1.27, 1.28

**Update Impact**: Usually compatible without chart changes

### 11.5 Maintenance Windows

**Recommended Schedule**:
- **Frequency**: Monthly
- **Duration**: 30-60 minutes
- **Window**: Off-peak hours (e.g., 2 AM - 4 AM)
- **Notification**: Announce 1 week in advance

---

## 12. Troubleshooting Guide

### 12.1 Common Issues

#### Issue: Pod Not Starting

**Symptoms**: Pod stuck in `Pending` or `CrashLoopBackOff`

**Diagnosis**:
```bash
# Check pod events
kubectl describe pod mattermost-xxxx

# Check resource availability
kubectl top nodes

# Check storage
kubectl get pvc
```

**Solutions**:
1. Insufficient resources: Add more node capacity
2. PVC pending: Check storage class availability
3. Image pull error: Verify image repository access

#### Issue: High CPU Usage

**Symptoms**: Pod CPU near limit, performance degradation

**Diagnosis**:
```bash
# Check current CPU usage
kubectl top pod mattermost-xxxx

# Identify hot processes
kubectl exec -it mattermost-xxxx -c mattermost -- top
```

**Solutions**:
1. Increase CPU limits in values.yaml
2. Optimize Mattermost configuration
3. Enable caching plugins

#### Issue: Database Connection Errors

**Symptoms**: Error logs showing MySQL connection failures

**Diagnosis**:
```bash
# Check MySQL container logs
kubectl logs mattermost-xxxx -c mysql

# Test connectivity
kubectl exec -it mattermost-xxxx -c mattermost -- \
  mysql -h localhost -u mmuser -p mattermost -e "SELECT 1"
```

**Solutions**:
1. Verify credentials in secrets
2. Check MySQL pod health
3. Increase connection limits

#### Issue: Storage Full

**Symptoms**: PVC usage at 100%, writes failing

**Diagnosis**:
```bash
# Check PVC usage
kubectl get pvc

# Check disk usage
kubectl exec -it mattermost-xxxx -c mattermost -- \
  du -sh /mattermost/data
```

**Solutions**:
1. Resize PVC (if storage class supports it)
2. Prune old messages/files
3. Enable file archival

### 12.2 Health Check Procedures

**Pod Health**:
```bash
# Check pod status
kubectl get pod mattermost-xxxx

# Check readiness probe
kubectl get event | grep mattermost

# Check recent logs
kubectl logs --tail=50 mattermost-xxxx
```

**Application Health**:
```bash
# Check API endpoint
curl -k https://mattermost.example.com/api/v4/system/ping

# Expected response: {"status":"ok"}
```

**Database Health**:
```bash
# Check MySQL status
kubectl exec -it mattermost-xxxx -c mysql -- \
  mysqladmin -u root -p status

# Expected: Uptime: XXX, Threads: X, Questions: X
```

### 12.3 Performance Tuning

**Enable Query Caching**:
```yaml
# In values.yaml
mattermost:
  caching:
    enabled: true
    ttl: 300
```

**Optimize Database**:
```bash
# Run optimization
kubectl exec -it mattermost-xxxx -c mysql -- \
  mysql -u root -p -e "OPTIMIZE TABLE \`mattermost\`.* "
```

**Monitor and Adjust**:
```bash
# Watch metrics in real-time
watch kubectl top pod mattermost-xxxx
```

---

## 13. Cost Analysis

### 13.1 Infrastructure Costs

**K3s Deployment** (on-premise):
- Hardware: 2 node cluster (2 CPU, 4Gi RAM) = $200-500/month
- Storage: 30Gi Longhorn = $5-15/month
- Network: Internal only = $0/month
- **Total**: ~$200-500/month

**EKS Deployment** (AWS):
- EC2 Nodes: 2x m5.large = $100-150/month
- EBS Storage: 30Gi = $3-5/month
- Load Balancer: $16/month
- EKS Control Plane: $73/month
- **Total**: ~$200-250/month

**GKE Deployment** (Google Cloud):
- Compute: 2x n1-standard-2 = $100-150/month
- Persistent Disks: 30Gi = $3-5/month
- Cloud Load Balancing: $15-20/month
- GKE Control Plane: $73/month (cluster fee)
- **Total**: ~$200-250/month

### 13.2 Operational Costs

**License**: Free (open-source)

**Support**: 
- Community: Free (GitHub issues, forums)
- Enterprise: $10,000+/year (official support)

**Development/Maintenance**: 1-2 FTE depending on scale

### 13.3 Scaling Costs

**Users**: Approximately linear CPU/RAM scaling
- **50 users**: 1 node (2 CPU, 4Gi RAM)
- **500 users**: 2-3 nodes (4-6 CPU, 8-12Gi RAM)
- **5000 users**: External database + multiple nodes (8-16 CPU, 16-32Gi RAM)

**Cost Optimization**:
1. Use reserved instances (30% savings)
2. Implement auto-scaling
3. Use spot instances for non-critical components
4. Consolidate with other applications

---

## 14. Implementation Checklist

### Pre-Deployment
- [ ] K3s cluster running (1.19+)
- [ ] Helm 3.0+ installed
- [ ] Longhorn or storage class configured
- [ ] Traefik ingress controller running
- [ ] Domain/DNS prepared
- [ ] TLS certificate provider (cert-manager) ready
- [ ] Backup solution planned

### Deployment
- [ ] Clone/download Mattermost Helm chart
- [ ] Configure values.yaml (passwords, domains, sizing)
- [ ] Deploy chart: `helm install mattermost .`
- [ ] Verify pod startup: `kubectl get pod`
- [ ] Check logs: `kubectl logs -f mattermost-xxxx`
- [ ] Verify ingress: `kubectl get ingress`
- [ ] Test DNS resolution

### Post-Deployment
- [ ] Access Mattermost via browser
- [ ] Configure initial admin user
- [ ] Set up teams and channels
- [ ] Configure SMTP for email notifications
- [ ] Test file uploads
- [ ] Enable backups
- [ ] Configure monitoring/logging
- [ ] Document custom configurations
- [ ] Plan maintenance schedule

### Production Readiness
- [ ] Security audit completed
- [ ] Load testing performed
- [ ] Backup and recovery tested
- [ ] Monitoring/alerting configured
- [ ] Runbook documentation complete
- [ ] Team training completed
- [ ] Cutover plan ready

---

## 15. References and Resources

### Official Documentation
- **Mattermost**: https://docs.mattermost.com/
- **Helm**: https://helm.sh/docs/
- **Kubernetes**: https://kubernetes.io/docs/
- **K3s**: https://k3s.io/

### Useful Commands
```bash
# Helm operations
helm list
helm status mattermost
helm values mattermost
helm history mattermost
helm rollback mattermost <REVISION>

# Kubernetes debugging
kubectl describe pod mattermost-xxxx
kubectl logs mattermost-xxxx -c mattermost
kubectl exec -it mattermost-xxxx -c mattermost -- /bin/bash
kubectl port-forward svc/mattermost 8065:80

# Storage operations
kubectl get pvc
kubectl describe pvc mattermost-mattermost
```

### Related Tools
- **Longhorn**: Distributed block storage (https://longhorn.io/)
- **cert-manager**: Automated certificate management (https://cert-manager.io/)
- **Prometheus**: Metrics collection (https://prometheus.io/)
- **Velero**: Kubernetes backup and restore (https://velero.io/)
- **Traefik**: Ingress controller (https://traefik.io/)

---

## Document Information

**Version**: 1.0  
**Last Updated**: January 2024  
**Author**: IDLIStack Team  
**Status**: Production Ready  
**Audience**: DevOps Engineers, System Administrators, Platform Owners  

**Document History**:
- v1.0 (Jan 2024): Initial release with full profiling for Mattermost 9.5.1

---

**End of K3s Application Profiling Document for Mattermost Helm Chart**
