# Listmonk Helm Deployment (App + Postgres)

This Helm chart deploys **Listmonk** in Kubernetes using:

* A **Listmonk application pod**
* A **PostgreSQL database** deployed as a separate pod
* Kubernetes **Service** objects for app and database
* Optional **Ingress with TLS** using **Traefik + cert-manager**
* Simple setup suitable for **local development** and **small production environments**

---

## 📁 Directory Structure

```
listmonk/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── pvc.yaml
│   ├── postgres-deployment.yaml
│   ├── postgres-service.yaml
│   └── _helpers.tpl
└── README.md
```

---

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

---

## 🚀 Local Setup (No Ingress)

This setup exposes Listmonk **internally** and uses **port-forwarding**.
No domain or TLS is required.

### 1⃣ Deploy Listmonk

```
helm upgrade --install listmonk . \
  -n listmonk \
  --create-namespace
```

Verify pods:

```
kubectl get pods -n listmonk
```

Expected:

* `listmonk` pod → **Running**
* `listmonk-postgres` pod → **Running**

---

### 2⃣ Access Listmonk Locally

Port-forward the service:

```
kubectl port-forward svc/listmonk \
  -n listmonk \
  9000:9000
```

Open in browser:

```
http://localhost:9000
```

You should see the **Listmonk login / setup screen**.

---

### 3⃣ View Logs

Listmonk logs:

```
kubectl logs -n listmonk deploy/listmonk
```

Postgres logs:

```
kubectl logs -n listmonk deploy/listmonk-postgres
```

---

## 🌐 Production Setup (Ingress + TLS)

### 1⃣ DNS Configuration

Create an **A record** pointing to your cluster LoadBalancer:

```
listmonk.example.com  -->  <LOAD_BALANCER_IP>
```

---

### 2⃣ Update `values.yaml`

```yaml
ingress:
  hosts:
    - host: listmonk.example.com
  tls:
    - secretName: listmonk-tls
```

⚠️ Empty values (`""`) are allowed but **must be overridden** during deployment for ingress to work.

---

### 3⃣ Ingress Details

Ingress configuration:

* Ingress Class: `traefik`
* TLS handled by `cert-manager`
* ClusterIssuer: `letsencrypt-prod`
* Path: `/`
* Backend Service: `listmonk`
* Backend Port: `9000`

Ingress annotations:

```yaml
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-prod
```

---

### 4⃣ Deploy with Ingress Enabled

```
helm upgrade --install listmonk . -n listmonk
```

Verify ingress:

```
kubectl get ingress -n listmonk
kubectl describe ingress -n listmonk
```

Once TLS is ready, access:

```
https://listmonk.example.com
```

---

## 🔐 Application URL Behavior

Unlike some applications (e.g. Mattermost or Ghost), **Listmonk does not require a strict canonical URL** to boot.

However, for production email links, it is **recommended** that:

* Ingress hostname is stable
* Reverse proxy terminates TLS

Optional (not required for ingress):

```
LISTMONK_app__root_url=https://listmonk.example.com
```

---

## 💾 Storage

| Component | Storage                | Purpose               |
| --------- | ---------------------- | --------------------- |
| Postgres  | (ephemeral by default) | Database data         |
| Listmonk  | None                   | Stateless application |

⚠️ **Production recommendation**: add a PVC to Postgres to avoid data loss on pod restart.

---

## 🧪 Health & Networking

* Listmonk listens on `:9000`
* Service exposes port `9000`
* Readiness probe uses `/health`
* Kubernetes manages restarts automatically

---

## 🛠 Troubleshooting

### Cannot access Listmonk via browser

* Ensure service `listmonk` exists
* Verify pod is listening on port `9000`
* Check readiness probe status

### Ingress TLS not ready

* DNS must point to cluster LoadBalancer
* cert-manager must be installed
* `letsencrypt-prod` ClusterIssuer must exist

### Database connection errors

* Ensure `listmonk-postgres` pod is running
* Verify env vars in `deployment.yaml`
* Check Postgres logs

---

## 🚧 Production Recommendations

For production or growing usage:

* Use **external Postgres** (RDS / CloudSQL)
* Add **PVC for Postgres**
* Enable **resource requests & limits**
* Add **backup strategy** for database
* Secure secrets via **Kubernetes Secrets**

---

## ✅ Status

This Helm chart is suitable for:

* Local development
* Testing and staging environments
* Small production Listmonk deployments

For large-scale or mission-critical setups, external database and backups are strongly recommended.
