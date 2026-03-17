# Ghost Helm Chart (Multi-Tenant Ready)

This Helm chart deploys **Ghost CMS** with **SQLite**, **Longhorn PVC**, and **Traefik Ingress** on Kubernetes.
It supports multi-organization deployments using custom labels for easy management.

## 🏗 Features
- SQLite database (no external DB)
- Persistent Volume via Longhorn
- Let's Encrypt SSL via Cert-Manager
- Traefik Ingress
- Multi-tenant labeling (organization, environment, appType)

## 🚀 Install

```bash
kubectl create ns ghost-org1
helm install ghost-org1 ./ghost   -n ghost-org1   --set labels.organization=org1   --set labels.environment=production   --set ingress.hosts[0].host=ghost.org1.example.com   --set ingress.tls[0].secretName=ghost-org1-tls
```

## 🧹 Manage Deployments

List all Ghost pods by organization:
```bash
kubectl get pods -A -l organization=org1
```

Delete all Ghost resources for an org:
```bash
kubectl delete all -l organization=org1,appType=ghost
```

## 📦 Directory Structure
```
ghost/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── _helpers.tpl
    ├── deployment.yaml
    ├── service.yaml
    ├── pvc.yaml
    └── ingress.yaml
```
