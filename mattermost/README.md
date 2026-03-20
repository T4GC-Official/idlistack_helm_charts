# Mattermost Helm Deployment (Single-Pod, MySQL Sidecar)

This Helm chart deploys **Mattermost Team Edition** in Kubernetes using:

* A **single pod** containing:

  * Mattermost application

  * MySQL database (sidecar)

* Persistent storage for Mattermost data and MySQL

* Optional **Ingress with TLS** using **Traefik + cert-manager**

* Resource limits suitable for production

## 📁 Directory Structure

```
mattermost/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── pvc.yaml
│   └── _helpers.tpl
└── README.md
```

## ⚙ Prerequisites

### Required (Local & Production)

* Kubernetes cluster

* Helm v3+

* Default StorageClass configured

### Required for Ingress

* Traefik Ingress Controller

* cert-manager

* ClusterIssuer named:

```
letsencrypt-prod
```

## 🚀 Local Setup (No Ingress)

This setup uses **port-forwarding** and does not require a domain.

### 1⃣ Deploy Mattermost

```
helm upgrade --install mattermost . \
  -n mattermost \
  --create-namespace
```

Verify pods:

```
kubectl get pods -n mattermost
```

Both containers should be **Running (2/2)**.

### 2⃣ Access Mattermost Locally

Port-forward the service:

```
kubectl port-forward svc/mattermost-mattermost-service \
  -n mattermost \
  8065:80
```

Open in browser:

```
http://localhost:8065
```

You should see the **Mattermost setup screen**.

### 3⃣ View Logs

Mattermost logs:

```
kubectl logs -n mattermost deploy/mattermost-mattermost -c mattermost
```

MySQL logs:

```
kubectl logs -n mattermost deploy/mattermost-mattermost -c mysql
```

## 🌐 Production Setup (Ingress + TLS)

### 1⃣ DNS Configuration

Create an **A record** pointing to your cluster LoadBalancer:

```
chat.example.com  -->  <LOAD_BALANCER_IP>
```

### 2️⃣ Update `values.yaml`

```
ingress:
  enabled: true
  hosts:
    - host: chat.example.com
  tls:
    - secretName: mattermost-tls
```

⚠️ The domain **must match** the canonical URL used by Mattermost.

### 3⃣ Ingress Details

Ingress configuration:

* Ingress Class: `traefik`

* TLS handled by `cert-manager`

* ClusterIssuer: `letsencrypt-prod`

* Path: `/`

* Backend Service: `mattermost-mattermost-service`

* Backend Port: `80 → 8065`

Ingress annotations:

```
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-prod
```

### 4️⃣ Deploy with Ingress Enabled

```
helm upgrade --install mattermost . -n mattermost
```

Verify ingress:

```
kubectl get ingress -n mattermost
kubectl describe ingress -n mattermost
```

Access once TLS is ready:

```
https://chat.example.com
```

## 🔐 Canonical URL (IMPORTANT)

Mattermost **requires a static canonical URL**.

Configured in `deployment.yaml`:

```
- name: MM_SERVICESETTINGS_SITEURL
  value: "https://chat.example.com"
```

❌ Do NOT dynamically reference ingress values\
✅ Must exactly match the ingress host

## 💾 Storage

| Component  | Path             | Purpose               |
| ---------- | ---------------- | --------------------- |
| MySQL      | /var/lib/mysql   | Database storage      |
| Mattermost | /mattermost/data | File uploads & assets |

PVC is shared using `subPath`.

## 📦 Resource Limits (Production Defaults)

### Mattermost

```
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 1
    memory: 2Gi
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

Suitable for **small to medium teams**.

## 🧪 Health & Networking

* Service exposes port `80` mapped to container `8065`

* Mattermost listens on `:8065`

* Kubernetes manages pod restarts automatically

## 🛠 Troubleshooting

### Port-forward connection refused

* Ensure Service `targetPort` is `8065`

* Ensure Mattermost container is running

### Ingress TLS not ready

* DNS must point to cluster LoadBalancer

* cert-manager must be installed

* `letsencrypt-prod` ClusterIssuer must exist

### Blank page or redirect issues

* Verify `MM_SERVICESETTINGS_SITEURL`

* Domain must match ingress host exactly

## 🚧 Production Recommendations

For larger or critical deployments:

* Use **external MySQL** (RDS / CloudSQL)

* Use **S3-compatible storage** for files

* Enable **Horizontal Pod Autoscaler**

* Separate MySQL into its own StatefulSet

* Manage Mattermost config via ConfigMap

## ✅ Status

This Helm chart is suitable for:

* Local development

* Small production environments

* Single-node or multi-node Kubernetes clusters
