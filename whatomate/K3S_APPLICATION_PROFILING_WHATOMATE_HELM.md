# K3s Application Profiling: WhatoMate PostgreSQL Redis Helm Chart

**Date Created**: January 2024  
**Application**: WhatoMate WhatsApp Bot Integration  
**Version**: 1.0.0  
**Deployment Method**: Helm 3.0+ on Kubernetes 1.19+  
**Infrastructure**: K3s, EKS, GKE (Kubernetes 1.19+)  

---

## 1. Application Overview

### 1.1 Purpose and Use Cases

WhatoMate is a WhatsApp Bot integration platform that synchronizes conversations with a CRM dashboard. It connects Meta's WhatsApp Cloud API with a CRM backend, providing intelligent chatbot capabilities.

**Use Cases**:
- Customer support automation via WhatsApp
- Lead generation and qualification
- CRM contact synchronization
- Automated message routing
- Multi-channel communication hub
- Appointment scheduling
- Customer engagement tracking
- Sales pipeline automation

### 1.2 Key Features

- **WhatsApp Integration**: Direct connection to Meta WhatsApp Cloud API
- **CRM Synchronization**: Real-time contact and conversation sync
- **AI Fallbacks**: OpenAI-powered intelligent replies
- **Flow Management**: Dynamic menu and routing system
- **SQLite State**: Local message history and context tracking
- **API Authentication**: X-API-Key header authorization
- **Message Queue**: Reliable message delivery system
- **Rich Media Support**: Image and document handling
- **Webhook Handling**: Meta webhook integration

---

## 2. Deployment Architecture

### 2.1 Helm Chart Structure

```
whatomate/
├── Chart.yaml                  # Chart metadata and version
├── values.yaml                 # Default configuration
├── README.md                   # Quick start guide
├── LICENSE                     # MIT License
├── CHANGELOG.md                # Version history
├── .helmignore                 # Helm packaging ignore patterns
└── templates/
    ├── _helpers.tpl            # Helper functions
    ├── deployment.yaml         # WhatoMate deployment
    ├── service.yaml            # Kubernetes Service (ClusterIP)
    ├── ingress.yaml            # Kubernetes Ingress
    ├── pvc.yaml                # Persistent Volume Claim (uploads)
    ├── configmap.yaml          # Configuration management
    └── secrets.yaml            # Credentials (base64-encoded)
```

### 2.2 Container Architecture

**Single container** pattern with external dependencies:

#### WhatoMate Container
- **Image**: `shridh0r/whatomate:latest`
- **Port**: 8080 (HTTP API)
- **Purpose**: WhatsApp Bot integration engine
- **Startup Time**: ~10-15 seconds
- **Health Check**: HTTP GET on `/` endpoint
- **Mount**: /app/uploads (file uploads)

#### PostgreSQL (External Dependency)
- **Image**: `postgres:15-alpine`
- **Port**: 5432
- **Purpose**: Primary data store
- **Managed by**: Bitnami Helm chart
- **Startup Time**: ~20-30 seconds

#### Redis (External Dependency)
- **Image**: `redis:7-alpine`
- **Port**: 6379
- **Purpose**: Session and cache storage
- **Managed by**: Bitnami Helm chart
- **Startup Time**: ~5-10 seconds

### 2.3 Pod Lifecycle

```
Pod Creation
    ↓
[WhatoMate Container Init] ← Connects to PostgreSQL
    ↓
[PostgreSQL Readiness Check] ← Database ready
    ↓
[Redis Readiness Check] ← Cache ready
    ↓
[Application Startup] ← Initializes connections
    ↓
[Readiness Probe Success] ← Pod marked Ready
    ↓
[Traffic Routed by Ingress/Service]
```

**Total Startup Time**: 30-60 seconds

### 2.4 Networking Model

```
External User / Meta API
    ↓
Ingress (Traefik)
    ↓
Service (ClusterIP, Port 8080)
    ↓
Pod (WhatoMate, Port 8080)
    ↓
PostgreSQL (External, Port 5432)
    ↓
Redis (External, Port 6379)
```

---

## 3. Resource Requirements and Sizing

### 3.1 CPU Resources

**WhatoMate Container**
- Request: 500m (0.5 cores)
- Limit: 1000m (1 core)
- Typical: 200-400m
- Peak: 700-900m

**PostgreSQL** (external)
- Request: 500m (depends on config)
- Limit: 1000m (depends on config)

**Redis** (external)
- Request: 250m (depends on config)
- Limit: 500m (depends on config)

**Total Pod CPU**: 500m (requests) | 1000m (limits)

### 3.2 Memory Resources

**WhatoMate Container**
- Request: 512Mi
- Limit: 1Gi
- Typical: 300-500 MiB
- Peak: 700-900 MiB

**PostgreSQL** (external)
- Request: 512Mi (depends on config)
- Limit: 1Gi (depends on config)

**Redis** (external)
- Request: 256Mi (depends on config)
- Limit: 512Mi (depends on config)

**Total Pod Memory**: 512Mi (requests) | 1Gi (limits)

### 3.3 Storage Requirements

**Uploads Volume** (10Gi)
- Attachment files
- Media uploads
- Conversation history
- Growth: 100-500 MB/month

**PostgreSQL Volume** (20Gi)
- Contacts, conversations, messages
- Settings and configuration
- Growth: 500MB-2GB/month (depending on message volume)

**Redis Volume** (10Gi)
- Session data
- Cache entries
- Queue data

### 3.4 Sizing Scenarios

**Small (100-1k conversations/day)**
- CPU: 500m / 1000m
- RAM: 512Mi / 1Gi
- Storage: 10Gi + 20Gi + 10Gi

**Medium (1k-10k conversations/day)**
- CPU: 1000m / 2000m
- RAM: 1Gi / 2Gi
- Storage: 10Gi + 50Gi + 20Gi

**Large (10k+ conversations/day)**
- CPU: 2000m / 4000m
- RAM: 2Gi / 4Gi
- Storage: 20Gi + 100Gi + 50Gi
- Recommendation: Multi-instance deployment with load balancer

---

## 4. Storage and Persistence

### 4.1 Storage Architecture

```
Deployment (WhatoMate)
    ↓
Pod
    ├─ Container: WhatoMate
    │   └─ Mount: /app/uploads (10Gi)
    │       └─ PVC: whatomate-uploads
    │
    └─ External Services
        ├─ PostgreSQL (20Gi persistent)
        └─ Redis (10Gi persistent)
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
- Redis: Daily snapshots (RDB)
- Frequency: Once per day minimum
- Retention: 30 days

**Methods**:
1. Longhorn snapshots
2. Velero (Kubernetes-native)
3. pg_dump for database dumps
4. Redis bgsave for snapshots
5. rsync for file backups

---

## 5. Database Configuration

### 5.1 PostgreSQL 15

**Connection**:
- Host: whatomate-postgresql (internal)
- Port: 5432
- Database: whatomate
- User: whatomate
- Charset: UTF-8
- SSL Mode: disable (internal, can enable for external)

**Key Tables**:
- contacts: Contact information
- conversations: Chat conversations
- messages: Individual messages
- sessions: User sessions
- settings: Application settings
- webhooks: Webhook logs

### 5.2 Redis Configuration

**Connection**:
- Host: whatomate-redis-master (internal)
- Port: 6379
- Database: 0
- Password: optional

**Use Cases**:
- Session storage
- Message queue
- Cache layer
- Rate limiting
- Real-time updates

### 5.3 Performance Tuning

```sql
-- PostgreSQL
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
```

---

## 6. Networking and Ingress

### 6.1 Service Configuration

**Type**: ClusterIP (internal only)  
**Port**: 8080 → 8080  
**Protocol**: TCP

### 6.2 Ingress Setup

**Controller**: Traefik  
**TLS**: cert-manager with Let's Encrypt  
**Protocols**: TLS 1.2, TLS 1.3

### 6.3 DNS Configuration

```
whatomate.example.com  A  <Ingress-IP>
```

### 6.4 Webhook Integration

```
Meta Webhook → https://whatomate.example.com/webhook
Inbound Messages → POST /api/messages/webhook
Outbound Delivery → POST to Meta API
```

---

## 7. Configuration Management

### 7.1 ConfigMap

Contains:
- Database connection details
- Redis connection details
- Application environment settings
- JWT configuration
- API endpoints

### 7.2 Secrets

Contains:
- Database password (base64-encoded)
- Redis password (base64-encoded)
- JWT secret (base64-encoded)
- Encryption key (base64-encoded)
- Meta WhatsApp API credentials (not in chart, set via values)

### 7.3 Environment Variables

WhatoMate-specific:
- DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD
- REDIS_HOST, REDIS_PORT
- JWT_SECRET, ENCRYPTION_KEY
- APP_ENVIRONMENT, APP_DEBUG
- Meta API credentials (set separately)

---

## 8. Logging and Monitoring

### 8.1 Log Sources

**WhatoMate**:
- Application logs: stdout/stderr
- API access logs: Request/response
- Error logs: Exception stack traces
- Business logs: Message sent, contact sync events

**PostgreSQL**:
- Error log: postgres logs
- Query log: slow queries
- Activity log: connections

**Redis**:
- Command log: redis logs
- Replication log: sync events

### 8.2 Key Metrics

- Messages sent/received (messages/hour)
- Conversation completion rate
- Contact sync success rate
- API response time (ms)
- Database query time (ms)
- Cache hit rate
- Error rate (%)
- CPU and memory usage
- Storage utilization
- Connection count

---

## 9. Security Considerations

### 9.1 Application Security

- Meta API credentials encryption
- X-API-Key header authentication
- JWT token signing
- HTTPS/TLS enforcement
- Rate limiting on API endpoints
- Input validation for all API calls
- SQL injection prevention (parameterized queries)
- CORS configuration

### 9.2 Kubernetes Security

- Pod security context
- Network policies
- RBAC configuration
- Secret encryption at rest
- Image scanning
- Resource limits
- Read-only file system where possible

### 9.3 Database Security

- Strong root password
- Separate application user with limited privileges
- Connection encryption (can enable in production)
- Access logging
- Parameter queries for SQL injection prevention
- Regular backups with encryption

---

## 10. High Availability and Disaster Recovery

### 10.1 Current Limitations

- Single pod deployment
- No automatic failover
- No redundancy
- Pod termination = service downtime (brief)
- Database and Redis are external (managed by Bitnami charts)

### 10.2 High Availability Path

**Phase 1**: Scale horizontally
```
Pod1(WhatoMate) ─┐
Pod2(WhatoMate) ─┼─ Service Load Balancing
Pod3(WhatoMate) ─┘
    ↓
PostgreSQL External (managed)
```

**Phase 2**: Managed database services
```
Pods(WhatoMate) → PostgreSQL RDS/CloudSQL
                → Redis Elasticache/Memorystore
```

### 10.3 Backup and Recovery

**RTO**: 30-60 minutes (with restore)  
**RPO**: 1 day (daily backups)

**Disaster Recovery Plan**:
1. Daily automated database backups
2. Daily file backups (uploads)
3. Redis snapshots
4. Helm chart stored in version control
5. Values stored securely (encrypted)

---

## 11. Maintenance and Updates

### 11.1 WhatoMate Updates

- Version: 1.0.0 (latest)
- Update frequency: Monitor GitHub releases
- Zero-downtime deployment: Yes (rolling update)
- Backup before updates: Recommended
- Test in staging: Recommended

### 11.2 Dependencies Updates

**PostgreSQL**: 15-alpine LTS (supported until 2025)  
**Redis**: 7-alpine (supported until 2024)  
**Bitnami Charts**: Update independently

### 11.3 Kubernetes Compatibility

- Minimum: 1.19
- Tested: 1.19-1.28
- Target: 1.24+

---

## 12. Troubleshooting Guide

### 12.1 Common Issues

**WhatoMate Won't Start**:
- Check PostgreSQL connectivity
- Verify Redis availability
- Review database credentials
- Check disk space

**Messages Not Syncing**:
- Verify Meta API credentials
- Check database connection
- Review webhook logs
- Verify API key authentication

**Database Connection Errors**:
- Verify PostgreSQL pod status
- Check network policies
- Review database credentials
- Check connection pool settings

**Memory/CPU Issues**:
- Check conversation volume
- Review message queue
- Monitor cache hits
- Scale up resources if needed

### 12.2 Health Checks

```bash
# Check pod status
kubectl get pod whatomate-xxxx

# Check logs
kubectl logs whatomate-xxxx -c whatomate

# Check database connectivity
kubectl exec -it whatomate-xxxx -- \
  curl http://localhost:8080/health

# Check PostgreSQL
kubectl get pod whatomate-postgresql-0

# Check Redis
kubectl get pod whatomate-redis-master-0
```

---

## 13. Cost Analysis

### 13.1 Infrastructure Costs

**K3s (on-premise)**:
- Hardware: 4 CPU, 4Gi RAM = $400-500/month

**EKS (AWS)**:
- EC2: m5.xlarge = $160-180/month
- EBS: 40Gi = $4-5/month
- RDS PostgreSQL: $50-100/month (optional)
- Elasticache: $30-50/month (optional)
- EKS control: $73/month
- Total: ~$300-400/month

**GKE (Google Cloud)**:
- Compute: n1-standard-2 = $75-100/month
- Cloud SQL: $50-100/month (optional)
- Memorystore: $30-50/month (optional)
- GKE: $73/month
- Total: ~$230-320/month

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
- [ ] Meta WhatsApp API credentials ready
- [ ] Backup solution planned

### Deployment
- [ ] Download chart
- [ ] Configure values.yaml
- [ ] Set Meta API credentials
- [ ] Set JWT secret
- [ ] Create secrets
- [ ] Deploy: helm install whatomate .
- [ ] Verify pod startup
- [ ] Check logs
- [ ] Test DNS resolution
- [ ] Test webhook integration

### Post-Deployment
- [ ] Configure Meta webhook URL
- [ ] Test incoming messages
- [ ] Verify CRM synchronization
- [ ] Configure message templates
- [ ] Set up AI fallbacks
- [ ] Configure rate limiting
- [ ] Set up monitoring
- [ ] Configure backups
- [ ] Document API keys location
- [ ] Train team

---

## 15. References and Resources

### Official Documentation
- WhatoMate: https://github.com/PrasanaKumarA/WhatoMate
- Meta WhatsApp API: https://developers.facebook.com/docs/whatsapp
- PostgreSQL: https://www.postgresql.org/docs/
- Redis: https://redis.io/documentation
- Helm: https://helm.sh/docs/
- Kubernetes: https://kubernetes.io/docs/
- K3s: https://k3s.io/

### Related Tools
- Longhorn: https://longhorn.io/
- cert-manager: https://cert-manager.io/
- Traefik: https://traefik.io/
- Velero: https://velero.io/
- Bitnami Charts: https://bitnami.com/stacks/helm

---

**Version**: 1.0  
**Last Updated**: January 2024  
**Status**: Production Ready  

---

**End of K3s Application Profiling Document for WhatoMate PostgreSQL Redis Helm Chart**
