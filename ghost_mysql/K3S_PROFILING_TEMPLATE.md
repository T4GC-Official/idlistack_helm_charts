# K3s Application Profiling Template - Ghost CMS Helm Deployment

## 1. Application Overview

**Application Name:**  
Ghost CMS

**Application Description:**  
Ghost is a modern, professional blogging and publishing platform with a MySQL database backend. This deployment includes both Ghost CMS application and MySQL database as sidecar containers in a single pod with persistent storage for content and database data.

**Business Owner / Team:**  
idlistack

**Environment (Dev/Staging/Production):**  
Production (configurable via labels)

**Namespace:**  
`ghost` (recommended, user-configurable during deployment)

---

## 2. Source Repository Details

**Application Repository URL:**  
https://github.com/T4GC-Official/idlistack_helm_charts

**Repository Branch/Tag:**  
`ghost-mysql-revised` (latest standardized version)

**Maintainer / Contact:**  
Chandru-988 (chandru@tech4goodcommunity.com)

---

## 3. Helm Chart Details

**Helm Repository Name:**  
idlistack (local chart, not published to Helm Hub)

**Helm Repository URL:**  
https://github.com/T4GC-Official/idlistack_helm_charts/tree/ghost-mysql-revised

**Chart Name:**  
ghost

**Chart Version:**  
0.2.0

**Values File Used (values.yaml path):**  
`./ghost_mysql/values.yaml`

---

## 4. Container Image Details

### Ghost Container
**Container Image:**  
`ghost:5`

**Image Registry:**  
Docker Hub (default)

**Image Tag / Version:**  
5 (latest v5.x)

**Image Pull Policy:**  
`IfNotPresent`

### MySQL Container (Sidecar)
**Container Image:**  
`mysql:8.0`

**Image Registry:**  
Docker Hub (default)

**Image Tag / Version:**  
8.0 (latest v8.0.x)

**Image Pull Policy:**  
`IfNotPresent`

---

## 5. Kubernetes Deployment Configuration

**Deployment Type (Deployment/StatefulSet/DaemonSet):**  
`Deployment` (single replica, both containers as sidecars)

**Replica Count:**  
1 (not scaled horizontally due to sidecar database)

**Service Type (ClusterIP/NodePort/LoadBalancer):**  
`ClusterIP` (default, can be changed to NodePort or LoadBalancer)

**Ingress Enabled (Yes/No):**  
Yes (optional, configurable)

**Ingress Hostname / Domain:**  
User-configurable (default: empty, must be set during deployment)

**Example Domain:**  
`blog.example.com`

---

## 6. Resource Allocation (Kubernetes Requests & Limits)

### Ghost Container
| Resource | Request | Limit |
|----------|---------|-------|
| **CPU** | 200m | 500m |
| **Memory** | 256Mi | 512Mi |

### MySQL Container (Sidecar)
| Resource | Request | Limit |
|----------|---------|-------|
| **CPU** | 250m | 1000m (1Gi) |
| **Memory** | 512Mi | 1Gi |

**Total Pod Resources:**
- **CPU Request:** 450m
- **CPU Limit:** 1500m
- **Memory Request:** 768Mi
- **Memory Limit:** 1536Mi

---

## 7. Storage Requirements

### Ghost Content Storage
**Persistent Volume Required (Yes/No):**  
Yes

**Storage Class:**  
`longhorn` (default, configurable)

**Volume Size:**  
`1Gi` (configurable via `storage.ghostSize`)

**Mount Path:**  
`/var/lib/ghost/content`

**PVC Name:**  
`{release-name}-ghost-pvc`

### MySQL Data Storage
**Persistent Volume Required (Yes/No):**  
Yes

**Storage Class:**  
`longhorn` (same as Ghost, configurable)

**Volume Size:**  
`2Gi` (configurable via `storage.mysqlSize`)

**Mount Path:**  
`/var/lib/mysql`

**PVC Name:**  
`{release-name}-mysql-pvc`

---

## 8. Network & Security

### Network Policies Applied (Yes/No)
No (not configured, can be added manually)

### Service Account
**Enabled:** Yes  
**Name:** Auto-generated based on release name  
**Configuration:** `serviceAccount.create: true`

### RBAC Role / RoleBinding
**Status:** Not required for this application (no elevated privileges needed)

**Recommended Security Context:**
```yaml
podSecurityContext: {}
securityContext: {}
# Can be configured in values.yaml for hardened deployments
```

### External Dependencies (DB, API, etc)
**Internal Database:** Yes (MySQL runs as sidecar container)

**External Dependencies:** 
- Ingress Controller (Traefik - required for Ingress)
- cert-manager (required for TLS/HTTPS)
- Storage provisioner (Longhorn, EBS, NFS, etc.)

---

## 9. Scaling Configuration

### Horizontal Pod Autoscaler Enabled (Yes/No)
No

**Reason:** Not applicable due to sidecar database. MySQL cannot be independently scaled.

**Future Consideration:** Separate MySQL deployment would enable HPA for Ghost containers.

### Min Replicas
1 (fixed)

### Max Replicas
1 (fixed)

### Target CPU Utilization %
Not applicable (HPA disabled)

---

## 10. Resource Utilization Monitoring

### Expected CPU Utilization
**Ghost Container:** 100-300m (under normal load)  
**MySQL Container:** 150-250m (under normal load)  
**Total:** 250-550m (well within allocated resources)

### Expected RAM Utilization
**Ghost Container:** 200-350Mi  
**MySQL Container:** 400-700Mi  
**Total:** 600-1050Mi (under allocated 1536Mi limit)

### Expected Storage Utilization
**Ghost Content:** Grows with blog posts, media uploads  
- Typical usage: 500Mi - 5Gi
- Recommended size: 5-10Gi for production

**MySQL Data:** Grows with posts, comments, metadata  
- Typical usage: 500Mi - 3Gi
- Recommended size: 10Gi+ for production

### Monitoring Tool (Prometheus/Grafana/etc)
**Recommended:** Prometheus + Grafana

**Metrics to Monitor:**
- Pod CPU usage
- Pod memory usage
- PVC storage usage
- Ghost HTTP requests/errors
- MySQL connection count
- MySQL query performance

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

**MySQL Container:**
```yaml
Type: Exec
Command: mysqladmin ping -h 127.0.0.1 -u root -p${MYSQL_ROOT_PASSWORD}
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

**MySQL Container:**
```yaml
Type: Exec
Command: mysqladmin ping -h 127.0.0.1 -u root -p${MYSQL_ROOT_PASSWORD}
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
4. **Storage Provisioner** - Longhorn recommended, but any provisioner works
5. **Ingress Controller** - Traefik (included in K3s by default)
6. **cert-manager** - For TLS certificate management (optional but recommended)

### Environment Variables

**Ghost Container:**
```
database__client=mysql
database__connection__host=127.0.0.1
database__connection__user=ghost
database__connection__password=(from secret)
database__connection__database=ghost
database__connection__port=3306
database__connection__reconnect=true
NODE_ENV=production
```

**MySQL Container:**
```
MYSQL_ROOT_PASSWORD=(from secret)
MYSQL_DATABASE=ghost
MYSQL_USER=ghost
MYSQL_PASSWORD=(from secret)
```

### Secrets Required

**Secret Name:** `{release-name}-secret`

**Secret Keys:**
- `mysql-root-password` - MySQL root user password (base64 encoded)
- `mysql-password` - MySQL ghost user password (base64 encoded)

**Security Notes:**
- Never commit secrets to git
- Use Kubernetes native secrets or external secret management
- Rotate passwords regularly
- Use strong, random passwords (min 16 characters)

### Special Deployment Instructions

#### Installation Steps

**Step 1: Set Passwords**
```bash
export MYSQL_ROOT_PASS="your-secure-root-password"
export MYSQL_USER_PASS="your-secure-user-password"
```

**Step 2: Create Namespace**
```bash
kubectl create namespace ghost
```

**Step 3: Deploy with Helm**
```bash
helm install ghost ./ghost_mysql \
  --namespace ghost \
  --set database.mysql.rootPassword=$MYSQL_ROOT_PASS \
  --set database.mysql.password=$MYSQL_USER_PASS
```

**Step 4: Verify Deployment**
```bash
kubectl get all -n ghost
kubectl logs -n ghost deployment/ghost-ghost -c ghost
```

#### Post-Deployment Configuration

**Access Ghost:**
```bash
kubectl port-forward -n ghost svc/ghost-ghost-service 8080:80
# Open: http://localhost:8080
```

**Configure Domain (Optional):**
```bash
helm upgrade ghost ./ghost_mysql \
  --namespace ghost \
  --set ingress.enabled=true \
  --set "ingress.hosts[0].host=blog.example.com" \
  --set "ingress.tls[0].secretName=ghost-tls" \
  --set "ingress.tls[0].hosts[0]=blog.example.com"
```

#### Storage Class Configuration

**For Longhorn (Recommended):**
```bash
# Ensure Longhorn is installed
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

**Database Backup (Manual):**
```bash
kubectl exec -n ghost deployment/ghost-ghost -c mysql -- \
  mysqldump -u root -p$MYSQL_ROOT_PASS ghost > ghost-backup.sql
```

#### Upgrade Procedure

**Update Chart Values:**
```bash
helm upgrade ghost ./ghost_mysql \
  --namespace ghost \
  --set database.mysql.rootPassword=$MYSQL_ROOT_PASS \
  --set database.mysql.password=$MYSQL_USER_PASS
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
kubectl logs -n ghost <pod-name> -c mysql
```

**Persistent Volume Issues:**
```bash
kubectl get pvc -n ghost
kubectl describe pvc -n ghost <pvc-name>
```

**Database Connection Issues:**
```bash
kubectl exec -n ghost deployment/ghost-ghost -c mysql -- \
  mysql -u ghost -p$MYSQL_USER_PASS -e "SHOW DATABASES;"
```

---

## Deployment Checklist

- [ ] Kubernetes cluster is accessible (v1.19+)
- [ ] Helm 3+ is installed
- [ ] Storage provisioner is configured and working
- [ ] Ingress controller is available (Traefik in K3s)
- [ ] cert-manager is installed (for HTTPS)
- [ ] MySQL passwords are generated (strong, random)
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
| **Application** | Ghost CMS v5 + MySQL 8.0 |
| **Deployment Model** | Single Pod, Sidecar Architecture |
| **Replicas** | 1 (fixed) |
| **CPU Request/Limit** | 450m / 1500m |
| **Memory Request/Limit** | 768Mi / 1536Mi |
| **Storage** | Ghost: 1Gi, MySQL: 2Gi (Longhorn) |
| **Service Type** | ClusterIP (Ingress optional) |
| **Ingress** | Traefik with TLS support |
| **Health Checks** | Liveness & Readiness probes enabled |
| **Scaling** | Not applicable (sidecar DB) |
| **Monitoring** | Prometheus compatible |
| **Backup Strategy** | Manual or storage snapshot-based |

---

**Document Version:** 1.0  
**Last Updated:** March 31, 2026  
**Chart Version:** 0.2.0  
**Status:** Production Ready
