# K3s Application Profiling Template - Ghost CMS SQLite Helm Deployment

## 1. Application Overview

**Application Name:**  
Ghost CMS (SQLite Edition)

**Application Description:**  
Ghost is a modern, professional blogging and publishing platform with an embedded SQLite database. This deployment includes Ghost CMS with SQLite database running in the same container's persistent volume. Ideal for small to medium-sized blogs with a simpler, single-database setup.

**Business Owner / Team:**  
idlistack

**Environment (Dev/Staging/Production):**  
Development/Staging (configurable via labels)

**Namespace:**  
`ghost` (recommended, user-configurable during deployment)

---

## 2. Source Repository Details

**Application Repository URL:**  
https://github.com/T4GC-Official/idlistack_helm_charts

**Repository Branch/Tag:**  
`ghost-sqlite-revised` (latest standardized version)

**Maintainer / Contact:**  
Chandru-988 (chandru@tech4goodcommunity.com)

---

## 3. Helm Chart Details

**Helm Repository Name:**  
idlistack (local chart, not published to Helm Hub)

**Helm Repository URL:**  
https://github.com/T4GC-Official/idlistack_helm_charts/tree/ghost-sqlite-revised

**Chart Name:**  
ghost

**Chart Version:**  
0.2.0

**Values File Used (values.yaml path):**  
`./ghost_sqlite/values.yaml`

---

## 4. Container Image Details

**Container Image:**  
`ghost:5`

**Image Registry:**  
Docker Hub (default)

**Image Tag / Version:**  
5 (latest v5.x)

**Image Pull Policy:**  
`IfNotPresent`

**Database Type:**  
SQLite 3 (embedded, no separate container)

---

## 5. Kubernetes Deployment Configuration

**Deployment Type (Deployment/StatefulSet/DaemonSet):**  
`Deployment` (single replica)

**Replica Count:**  
1 (fixed, not scaled horizontally)

**Service Type (ClusterIP/NodePort/LoadBalancer):**  
`ClusterIP` (default, can be changed)

**Ingress Enabled (Yes/No):**  
Yes (optional, configurable)

**Ingress Hostname / Domain:**  
User-configurable (default: empty, must be set during deployment)

**Example Domain:**  
`blog.example.com`

---

## 6. Resource Allocation (Kubernetes Requests & Limits)

**Ghost Container (Including SQLite)**

| Resource | Request | Limit |
|----------|---------|-------|
| **CPU** | 100m | 500m |
| **Memory** | 256Mi | 512Mi |

**Total Pod Resources:**
- **CPU Request:** 100m
- **CPU Limit:** 500m
- **Memory Request:** 256Mi
- **Memory Limit:** 512Mi

---

## 7. Storage Requirements

**Persistent Volume Required (Yes/No):**  
Yes

**Storage Class:**  
`longhorn` (default, configurable)

**Volume Size:**  
`1Gi` (configurable via `storage.size`)

**Mount Path:**  
`/var/lib/ghost/content`

**PVC Name:**  
`{release-name}-pvc`

**What's Stored:**
- Ghost application content
- SQLite database file (`ghost.db`)
- Media uploads
- Blog posts and metadata

---

## 8. Network & Security

### Network Policies Applied (Yes/No)
No (not configured, can be added manually)

### Service Account
**Enabled:** Yes  
**Name:** Auto-generated based on release name  
**Configuration:** `serviceAccount.create: true`

### RBAC Role / RoleBinding
**Status:** Not required for this application

**Recommended Security Context:**
```yaml
podSecurityContext: {}
securityContext: {}
# Can be configured in values.yaml for hardened deployments
```

### External Dependencies (DB, API, etc)
**Internal Database:** Yes (SQLite embedded in container)

**External Dependencies:** 
- Ingress Controller (Traefik - required for Ingress)
- cert-manager (required for TLS/HTTPS)
- Storage provisioner (Longhorn, EBS, NFS, etc.)

---

## 9. Scaling Configuration

### Horizontal Pod Autoscaler Enabled (Yes/No)
No

**Reason:** Not applicable - SQLite doesn't support multi-instance concurrent access. Database locking would cause issues at scale.

### Min Replicas
1 (fixed)

### Max Replicas
1 (fixed)

### Target CPU Utilization %
Not applicable (HPA disabled)

---

## 10. Resource Utilization Monitoring

### Expected CPU Utilization
**Ghost + SQLite:** 50-150m (under normal load)

### Expected RAM Utilization
**Ghost + SQLite:** 200-350Mi (under normal load)

### Expected Storage Utilization
**Total Storage:**
- Typical usage: 500Mi - 2Gi
- Recommended size: 5-10Gi for production
- SQLite DB: Grows with posts, comments, metadata
- Content: Grows with media uploads

### Monitoring Tool (Prometheus/Grafana/etc)
**Recommended:** Prometheus + Grafana

**Metrics to Monitor:**
- Pod CPU usage
- Pod memory usage
- PVC storage usage
- Ghost HTTP requests/errors
- Database file size growth

---

## 11. Health Checks

### Liveness Probe
**Ghost Container:**
```yaml
Type: HTTP GET
Path: /
Port: 2368
Initial Delay: 20 seconds
Period: 10 seconds
Timeout: 5 seconds
Failure Threshold: 5
```

### Readiness Probe
**Ghost Container:**
```yaml
Type: HTTP GET
Path: /
Port: 2368
Initial Delay: 20 seconds
Period: 10 seconds
Timeout: 5 seconds
Failure Threshold: 5
```

### Startup Probe
Not configured (optional, can be added for slower startups)

---

## 12. Deployment Notes

### Configuration Dependencies

**Required Dependencies:**
1. **Kubernetes Cluster v1.19+** - K3s, EKS, GKE, AKS, etc.
2. **Helm 3+** - For chart deployment
3. **kubectl** - For cluster access
4. **Storage Provisioner** - Longhorn recommended, any provisioner works
5. **Ingress Controller** - Traefik (included in K3s by default)
6. **cert-manager** - For TLS certificate management (optional but recommended)

### Environment Variables

**Ghost Container:**
```
url=https://{domain}
database__client=sqlite3
database__connection__filename=/var/lib/ghost/content/data/ghost.db
NODE_ENV=production
```

### Secrets Required
None (SQLite doesn't require credentials)

### Special Deployment Instructions

#### Installation Steps

**Step 1: Create Namespace**
```bash
kubectl create namespace ghost
```

**Step 2: Deploy with Helm**
```bash
helm install ghost ./ghost_sqlite \
  --namespace ghost
```

**Step 3: Verify Deployment**
```bash
kubectl get all -n ghost
kubectl logs -n ghost deployment/ghost-ghost
```

#### Post-Deployment Configuration

**Access Ghost:**
```bash
kubectl port-forward -n ghost svc/ghost-ghost-service 8080:80
# Open: http://localhost:8080
```

**Configure Domain (Optional):**
```bash
helm upgrade ghost ./ghost_sqlite \
  --namespace ghost \
  --set ingress.enabled=true \
  --set "ingress.hosts[0].host=blog.example.com" \
  --set "ingress.tls[0].secretName=ghost-tls" \
  --set "ingress.tls[0].hosts[0]=blog.example.com"
```

#### Storage Class Configuration

**For Longhorn (Recommended):**
```bash
helm repo add longhorn https://charts.longhorn.io
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace
```

**For AWS EBS:**
```bash
--set storage.storageClass=ebs
```

**For NFS:**
```bash
--set storage.storageClass=nfs
```

#### Backup & Recovery Strategy

**Backup PVC Data:**
```bash
kubectl get pvc -n ghost
# Create snapshots using storage class capabilities
# Or use Longhorn's built-in backup features
```

**Database Backup (SQLite):**
```bash
kubectl exec -n ghost deployment/ghost-ghost -- \
  cp /var/lib/ghost/content/data/ghost.db /var/lib/ghost/content/backup-$(date +%Y%m%d).db
```

**Export Database to Host:**
```bash
kubectl cp ghost/ghost-ghost:/var/lib/ghost/content/data/ghost.db ./ghost-backup.db
```

#### Upgrade Procedure

**Update Chart Values:**
```bash
helm upgrade ghost ./ghost_sqlite \
  --namespace ghost
```

**Rollback if Issues:**
```bash
helm rollback ghost -n ghost
```

#### Troubleshooting

**Pod Not Starting:**
```bash
kubectl describe pod -n ghost <pod-name>
kubectl logs -n ghost <pod-name> -c ghost
```

**Persistent Volume Issues:**
```bash
kubectl get pvc -n ghost
kubectl describe pvc -n ghost <pvc-name>
```

**Database File Issues:**
```bash
kubectl exec -n ghost deployment/ghost-ghost -- \
  ls -lh /var/lib/ghost/content/data/
```

**Corrupted SQLite Database:**
```bash
kubectl exec -n ghost deployment/ghost-ghost -- \
  sqlite3 /var/lib/ghost/content/data/ghost.db "PRAGMA integrity_check;"
```

---

## Advantages of SQLite Over MySQL

| Feature | SQLite | MySQL |
|---------|--------|-------|
| **Setup Complexity** | Minimal | Higher |
| **Resource Usage** | Very Low | Higher |
| **Admin Overhead** | None | Significant |
| **Scaling** | Single Instance Only | Horizontal |
| **Deployment Time** | Fast | Slower |
| **Performance** | Good for small-medium | Better for large |

---

## Limitations & Considerations

### Not Recommended For:
- High-concurrency scenarios
- Large-scale deployments (1000+ concurrent users)
- Sites requiring horizontal scaling
- Multi-pod setups

### Best For:
- Small to medium blogs
- Single-writer scenarios
- Low-traffic websites
- Development/staging environments
- Proof-of-concepts

---

## Deployment Checklist

- [ ] Kubernetes cluster is accessible (v1.19+)
- [ ] Helm 3+ is installed
- [ ] Storage provisioner is configured and working
- [ ] Ingress controller is available (Traefik in K3s)
- [ ] cert-manager is installed (for HTTPS)
- [ ] Namespace is created or will be created
- [ ] Helm values are prepared/customized
- [ ] DNS records are configured (if using domain)
- [ ] Backup strategy is documented
- [ ] Monitoring is configured
- [ ] Security policies are reviewed

---

## Summary Table

| Component | Configuration |
|-----------|----------------|
| **Application** | Ghost CMS v5 with SQLite 3 |
| **Deployment Model** | Single Pod |
| **Replicas** | 1 (fixed) |
| **CPU Request/Limit** | 100m / 500m |
| **Memory Request/Limit** | 256Mi / 512Mi |
| **Storage** | 1Gi PVC (Longhorn) |
| **Service Type** | ClusterIP (Ingress optional) |
| **Ingress** | Traefik with TLS support |
| **Health Checks** | Readiness probe enabled |
| **Scaling** | Not applicable |
| **Monitoring** | Prometheus compatible |
| **Backup Strategy** | PVC snapshot or manual export |

---

**Document Version:** 1.0  
**Last Updated:** March 31, 2026  
**Chart Version:** 0.2.0  
**Status:** Development/Staging Ready
