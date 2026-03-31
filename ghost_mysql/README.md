# Ghost CMS Helm Chart

Deploy Ghost CMS with MySQL database in Kubernetes using Helm.

## What's Included

- **Ghost CMS** - Blogging platform
- **MySQL Database** - Database backend
- **Persistent Storage** - For Ghost content and database
- **ConfigMap** - Ghost configuration
- **Secrets** - Database credentials
- **Ingress** - Optional TLS-enabled web access

## Prerequisites

- Kubernetes cluster (v1.19+)
- Helm 3+
- Storage provisioner (Longhorn, EBS, NFS, etc.)

## Quick Start

### 1. Set Required Passwords

```bash
export MYSQL_ROOT_PASS="your-mysql-root-password"
export MYSQL_USER_PASS="your-mysql-user-password"
```

### 2. Deploy to Kubernetes

```bash
helm install ghost ./ghost_mysql \
  --namespace ghost \
  --create-namespace \
  --set database.mysql.rootPassword=$MYSQL_ROOT_PASS \
  --set database.mysql.password=$MYSQL_USER_PASS
```

### 3. Access Ghost

Get the service IP:
```bash
kubectl get svc -n ghost
```

Port-forward to access locally:
```bash
kubectl port-forward -n ghost svc/ghost-ghost-service 8080:80
```

Then open: **http://localhost:8080**

## Configure Domain & TLS (Optional)

To enable HTTPS with your domain:

```bash
helm install ghost ./ghost_mysql \
  --namespace ghost \
  --create-namespace \
  --set database.mysql.rootPassword=$MYSQL_ROOT_PASS \
  --set database.mysql.password=$MYSQL_USER_PASS \
  --set ingress.enabled=true \
  --set "ingress.hosts[0].host=blog.yourdomain.com" \
  --set "ingress.tls[0].secretName=ghost-tls" \
  --set "ingress.tls[0].hosts[0]=blog.yourdomain.com"
```

## Customization

### Change Storage Sizes

```bash
--set storage.ghostSize=5Gi \
--set storage.mysqlSize=10Gi
```

### Change Resource Limits

```bash
--set ghost.resources.requests.cpu=500m \
--set ghost.resources.limits.memory=1Gi \
--set mysql.resources.requests.cpu=500m
```

### Use Custom Config File

Create `custom-values.yaml`:

```yaml
database:
  mysql:
    rootPassword: "secure-root-pass"
    password: "secure-user-pass"

storage:
  ghostSize: 5Gi
  mysqlSize: 10Gi

labels:
  organization: my-org
  environment: production
```

Then deploy:
```bash
helm install ghost ./ghost_mysql --namespace ghost --create-namespace -f custom-values.yaml
```

## Common Commands

**Check deployment status:**
```bash
kubectl get all -n ghost
```

**View logs:**
```bash
kubectl logs -n ghost deployment/ghost-ghost -c ghost
kubectl logs -n ghost deployment/ghost-ghost -c mysql
```

**Upgrade deployment:**
```bash
helm upgrade ghost ./ghost_mysql \
  --namespace ghost \
  --set database.mysql.rootPassword=$MYSQL_ROOT_PASS \
  --set database.mysql.password=$MYSQL_USER_PASS
```

**Delete deployment:**
```bash
helm uninstall ghost --namespace ghost
```

## Architecture

Single pod with 2 containers:
- **Ghost Container** - CMS application on port 2368
- **MySQL Container** - Database on port 3306

Both share persistent storage for data persistence.

## License

MIT License - See [LICENSE](LICENSE) for details.

* Helm v3+

* Default StorageClass (Longhorn recommended)

### Required for Ingress

* Traefik Ingress Controller

* cert-manager

* ClusterIssuer named:

```
letsencrypt-prod
```

## 🚀 Local Setup (No Ingress)

This setup is ideal for **local clusters** or environments **without a domain**.

### 1⃣ Deploy Ghost

```
helm upgrade --install ghost-single . \
  -n ghost-mysql \
  --create-namespace
```

Verify pods:

```
kubectl get pods -n ghost-mysql
```

Expected:

```
2/2 Running
```

(Ghost + MySQL containers)

### 2⃣ Access Ghost Locally

Port-forward the service:

```
kubectl port-forward svc/ghost-single-ghost-service \
  -n ghost-mysql \
  2368:80
```

Open in browser:

```
http://localhost:2368
```

You should see the **Ghost setup screen**.

### 3⃣ View Logs

Ghost logs:

```
kubectl logs -n ghost-mysql deploy/ghost-single-ghost -c ghost
```

MySQL logs:

```
kubectl logs -n ghost-mysql deploy/ghost-single-ghost -c mysql
```

## 🌐 Production Setup (Ingress + TLS)

### 1⃣ DNS Configuration

Create an **A record** pointing to your cluster LoadBalancer:

```
blog.example.com  -->  <LOAD_BALANCER_IP>
```

### 2️⃣ Update `values.yaml`

```
ingress:
  enabled: true
  hosts:
    - host: blog.example.com
  tls:
    - secretName: ghost-tls
```

### 3️⃣ Ingress Details

Ingress configuration:

* Ingress Class: `traefik`

* TLS handled by `cert-manager`

* ClusterIssuer: `letsencrypt-prod`

* Path: `/`

* Backend Service: `ghost-single-ghost-service`

* Backend Port: `80 → 2368`

Ingress annotations:

```
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-prod
```

### 4️⃣ Deploy with Ingress Enabled

```
helm upgrade --install ghost-single . -n ghost-mysql
```

Verify ingress:

```
kubectl get ingress -n ghost-mysql
kubectl describe ingress -n ghost-mysql
```

Once TLS is ready, access:

```
https://blog.example.com
```

## 🔐 Canonical URL (IMPORTANT)

Ghost **requires a static canonical URL**.

This is configured via **ConfigMap** (`config.production.json`):

```
"url": "https://blog.example.com"
```

⚠️ The URL **must exactly match** the ingress host\
❌ Do NOT dynamically change this at runtime

## 📄 Configuration via ConfigMap

Ghost uses `config.production.json` from a ConfigMap to manage:

* Canonical URL

* MySQL database configuration

* Logging and log rotation

### Log Rotation Configuration

```
"logging": {
  "path": "/var/lib/ghost/content/logs",
  "useLocalTime": true,
  "level": "info",
  "rotation": {
    "enabled": true,
    "count": 15,
    "period": "1d",
    "size": "10m"
  },
  "transports": ["stdout", "file"]
}
```

## 💾 Storage

| Component | Path                     | Purpose               |
| --------- | ------------------------ | --------------------- |
| MySQL     | `/var/lib/mysql`         | Database storage      |
| Ghost     | `/var/lib/ghost/content` | Content, images, logs |

A **single PVC** is shared using `subPath`.

## 📦 Resource Limits (Production Defaults)

### Ghost

```
resources:
  requests:
    cpu: 300m
    memory: 512Mi
  limits:
    cpu: 1
    memory: 1Gi
```

### MySQL

```
resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

Suitable for **small to medium blogs**.

## 🧪 Health & Networking

* Service exposes port `80` mapped to container `2368`

* Ghost listens on `:2368`

* Kubernetes manages pod restarts automatically

## 🛠 Troubleshooting

### Ghost shows redirect loop

* Verify canonical URL in `config.production.json`

* Must match ingress host exactly

### Ingress TLS not issued

* DNS must point to cluster LoadBalancer

* cert-manager installed

* `letsencrypt-prod` ClusterIssuer exists

### MySQL restart warnings

* Expected on first startup

* Ensure PVC is bound and writable

## 🚧 Production Recommendations

For larger or high-traffic sites:

* Use **external MySQL** (RDS / CloudSQL)

* Use **CDN** for images

* Enable **Horizontal Pod Autoscaler**

* Separate MySQL into StatefulSet

* Regular PVC backups

## ✅ Status

This Helm chart is suitable for:

* Local development

* Small to medium production blogs

* Single-node or multi-node Kubernetes clusters
