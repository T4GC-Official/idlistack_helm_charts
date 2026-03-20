# Ghost Helm Deployment (MySQL – Single Pod)

This Helm chart deploys **Ghost CMS** in Kubernetes using:

* A **single pod** containing:

  * Ghost application

  * MySQL database (sidecar)

* Persistent storage for:

  * Ghost content

  * MySQL data

* Optional **Ingress with TLS** using **Traefik + cert-manager**

* ConfigMap-based `config.production.json` for:

  * Canonical URL

  * Database configuration

  * Log rotation

* Resource limits suitable for production workloads

## 📁 Directory Structure

```
ghost_mysql/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── pvc.yaml
│   ├── configmap.yaml
│   └── _helpers.tpl
└── README.md
```

## ⚙ Prerequisites

### Required (Local & Production)

* Kubernetes cluster

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
