# Ghost CMS Helm Chart (SQLite)

Deploy Ghost CMS with SQLite database in Kubernetes using Helm.

## What's Included

- **Ghost CMS** - Blogging platform
- **SQLite Database** - Lightweight embedded database
- **Persistent Storage** - For Ghost content and database
- **ConfigMap** - Ghost configuration
- **Ingress** - Optional TLS-enabled web access

## Prerequisites

- Kubernetes cluster (v1.19+)
- Helm 3+
- Storage provisioner (Longhorn, EBS, NFS, etc.)

## Quick Start

### 1. Deploy to Kubernetes

```bash
helm install ghost ./ghost_sqlite \
  --namespace ghost \
  --create-namespace
```

### 2. Access Ghost

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
helm install ghost ./ghost_sqlite \
  --namespace ghost \
  --create-namespace \
  --set ingress.enabled=true \
  --set "ingress.hosts[0].host=blog.yourdomain.com" \
  --set "ingress.tls[0].secretName=ghost-tls" \
  --set "ingress.tls[0].hosts[0]=blog.yourdomain.com"
```

## Customization

### Change Storage Size

```bash
--set storage.size=5Gi
```

### Change Resource Limits

```bash
--set ghost.resources.requests.cpu=200m \
--set ghost.resources.limits.memory=1Gi
```

### Use Custom Config File

Create `custom-values.yaml`:

```yaml
storage:
  size: 5Gi

labels:
  organization: my-org
  environment: production
```

Then deploy:
```bash
helm install ghost ./ghost_sqlite --namespace ghost --create-namespace -f custom-values.yaml
```

## Common Commands

**Check deployment status:**
```bash
kubectl get all -n ghost
```

**View logs:**
```bash
kubectl logs -n ghost deployment/ghost-ghost
```

**Upgrade deployment:**
```bash
helm upgrade ghost ./ghost_sqlite --namespace ghost
```

**Delete deployment:**
```bash
helm uninstall ghost --namespace ghost
```

## Architecture

Single pod with Ghost CMS using SQLite as embedded database. SQLite stores data in the persistent volume, making it ideal for small to medium-sized blogs.

**Advantages of SQLite:**
- No database server needed
- Simpler deployment
- Lower resource overhead
- Perfect for single-instance deployments

**Limitations:**
- Not suitable for high-concurrency scenarios
- Cannot be easily scaled horizontally

## License

MIT License - See [LICENSE](LICENSE) for details.
