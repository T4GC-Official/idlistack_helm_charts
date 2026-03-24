# WordPress + MySQL Helm Chart

## Overview

This Helm chart deploys a **WordPress application with a MySQL database** on Kubernetes.

The chart creates a **single Pod containing two containers**:

* WordPress container
* MySQL container

WordPress connects to MySQL using **localhost** because both containers run inside the same pod.

The chart also provisions **PersistentVolumeClaims (PVC)** to store WordPress data and MySQL database files.

---

## Architecture

Deployment
└── Pod
  ├── WordPress Container (port 80)
  └── MySQL Container (port 3306)

Persistent Storage

* wordpress-pvc → stores WordPress files
* mysql-pvc → stores MySQL database

Service

* NodePort service exposes WordPress to the browser

Ingress

* Optional and controlled using `values.yaml`

---

## Prerequisites

* Kubernetes cluster (Minikube recommended for local testing)
* Helm 3 installed
* kubectl configured

---

## Installation

Install the Helm chart:

```
helm install wordpress .
```

Upgrade the release:

```
helm upgrade wordpress .
```

Uninstall the release:

```
helm uninstall wordpress
```

---

## Access the Application

Expose the service using Minikube:

```
minikube service wordpress
```

This will open WordPress in your browser.

---

## Configuration

Configuration values can be modified in `values.yaml`.

Example:

```
wordpress:
  image:
    repository: wordpress
    tag: latest

mysql:
  image:
    repository: mysql
    tag: "8.0"

persistence:
  enabled: true
  size: 1Gi
```

---

## Persistent Storage

The chart creates two PersistentVolumeClaims:

* **wordpress-pvc** – stores WordPress uploads, plugins, and themes
* **mysql-pvc** – stores MySQL database files

This ensures data persists even if the pod restarts.

---

## Ingress

Ingress is optional and disabled by default.

Enable it in `values.yaml`:

```
ingress:
  enabled: true
```

---

## Maintainer

Maintained as part of the **WordPress Helm deployment project**.
