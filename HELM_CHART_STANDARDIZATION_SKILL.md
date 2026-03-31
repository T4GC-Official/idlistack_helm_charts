# Helm Chart Standardization Skill File

## Overview
This skill file provides a systematic approach to standardize Helm charts across the repository, ensuring consistency, best practices, and production-readiness.

## Prerequisites
- Git access to the repository
- Helm 3+ installed
- kubectl installed

---

## Step 1: Branch Analysis & Setup

### 1.1 Fetch and Switch to Target Branch
```bash
git fetch origin <branch-name>
git checkout <branch-name>
echo "Switched to <branch-name> branch"
```

### 1.2 Identify Application Type
- Check `Chart.yaml` for application name
- Review folder structure: `ls -lh` and `ls -lh templates/`
- Understand the application (CMS, messaging, etc.)

### 1.3 Check Existing Files
```bash
ls -la templates/ | grep -E "(config|secret)"
# If empty, ConfigMap and Secrets are missing
```

---

## Step 2: Audit Existing Chart Structure

### 2.1 Files to Review
- [ ] Chart.yaml - metadata completeness
- [ ] values.yaml - organization and structure
- [ ] templates/_helpers.tpl - helper functions
- [ ] templates/deployment.yaml - label consistency
- [ ] templates/service.yaml - port configuration
- [ ] templates/ingress.yaml - ingress setup
- [ ] templates/pvc.yaml - storage configuration
- [ ] Standard files - .helmignore, LICENSE, CHANGELOG.md, README.md

### 2.2 Common Issues to Check
- [ ] Duplicate labels across resources
- [ ] Hardcoded port values
- [ ] Inconsistent naming conventions
- [ ] Missing ConfigMap/Secrets templates
- [ ] Limited helper functions
- [ ] Poor values.yaml organization
- [ ] Missing standard files

---

## Step 3: Create New Branch for Standardization

```bash
git checkout -b <app-name>-revised
echo "✓ Created new branch: <app-name>-revised"
```

---

## Step 4: Update Core Files

### 4.1 Update Chart.yaml
Add complete metadata:
- home, icon, keywords
- maintainers, sources
- Improve description

### 4.2 Restructure values.yaml
Organize into logical sections:
- replicaCount
- image (with pullPolicy)
- App-specific config
- Database config (if applicable)
- Storage settings
- Labels
- Ingress
- Service
- ServiceAccount
- Security settings

### 4.3 Enhance _helpers.tpl
Add these helpers:
```
ghost.name - Application name
ghost.fullname - Fully qualified name
ghost.chart - Chart identifier
ghost.labels - Standard Kubernetes labels
ghost.selectorLabels - Pod selector labels
```

### 4.4 Create ConfigMap (if missing)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "app.fullname" . }}-config
  labels:
    {{- include "app.labels" . | nindent 4 }}
data:
  # App-specific configuration files
```

### 4.5 Create Secrets (if missing)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "app.fullname" . }}-secret
  labels:
    {{- include "app.labels" . | nindent 4 }}
type: Opaque
data:
  # Base64 encoded secrets
```

### 4.6 Update All Templates
Replace hardcoded labels with:
```yaml
labels:
  {{- include "app.labels" . | nindent 4 }}
```

Replace hardcoded values with references from values.yaml

---

## Step 5: Add Standard Files

### 5.1 Create .helmignore
Standard Helm ignore patterns

### 5.2 Create LICENSE
MIT License with year and copyright

### 5.3 Create CHANGELOG.md
Document version history and changes

### 5.4 Update README.md
- Quick start guide
- Prerequisites
- Configuration examples
- Common commands
- Architecture overview

---

## Step 6: Verification

### 6.1 Helm Lint
```bash
helm lint .
# Should pass with 0 errors
```

### 6.2 Template Rendering
```bash
helm template <app-name> . | head -100
# Check output for correct variable substitution
```

### 6.3 File Structure
```bash
ls -lh
ls -lh templates/
```

---

## Step 7: Create K3s Application Profiling Document

### 7.1 Document Name
`K3S_APPLICATION_PROFILING_<APP_NAME>_HELM.md`

### 7.2 Required Sections
1. **Application Overview** - Name, description, owner, environment
2. **Source Repository Details** - URLs, branch, maintainer
3. **Helm Chart Details** - Repository, chart name, version
4. **Container Image Details** - Image, registry, tag, pull policy
5. **Kubernetes Deployment Configuration** - Type, replicas, service, ingress
6. **Resource Allocation** - CPU/Memory requests and limits
7. **Storage Requirements** - PVC size, storage class, mount paths
8. **Network & Security** - Network policies, service accounts, RBAC, dependencies
9. **Scaling Configuration** - HPA settings, replicas
10. **Resource Utilization Monitoring** - Expected usage, monitoring tools
11. **Health Checks** - Liveness, readiness, startup probes
12. **Deployment Notes** - Dependencies, env vars, secrets, special instructions
13. **Advantages/Disadvantages** - App-specific comparison if applicable
14. **Limitations & Considerations** - When to use, when not to use
15. **Deployment Checklist** - Step-by-step verification
16. **Summary Table** - Quick reference

---

## Step 8: Commit and Push Changes

### 8.1 Stage All Changes
```bash
git add -A
```

### 8.2 Commit with Detailed Message
```bash
git commit -m "refactor: standardize <APP_NAME> Helm chart with best practices

- Added/Updated ConfigMap template
- Added/Updated Secrets template
- Enhanced helpers template with standard Kubernetes labels
- Reorganized values.yaml with logical sections
- Updated all templates to use standard label helpers
- Made all hardcoded values configurable
- Added .helmignore, LICENSE, CHANGELOG.md files
- Updated README.md with clear deployment instructions
- Added K3s application profiling document
- Improved security and configuration options
- Passes Helm linting validation"
```

### 8.3 Push to Remote
```bash
git push origin <app-name>-revised
```

---

## Step 9: Verification on Remote

```bash
git log --oneline -3
git branch -v
# Verify new branch exists and is pushed
```

---

## Key Files Checklist

### Root Directory
- [ ] Chart.yaml (enhanced)
- [ ] values.yaml (restructured)
- [ ] README.md (updated)
- [ ] .helmignore (created)
- [ ] LICENSE (created)
- [ ] CHANGELOG.md (created)
- [ ] K3S_APPLICATION_PROFILING_*.md (created)

### Templates Directory
- [ ] _helpers.tpl (enhanced)
- [ ] deployment.yaml (standardized)
- [ ] service.yaml (standardized)
- [ ] ingress.yaml (standardized)
- [ ] pvc.yaml (standardized)
- [ ] configmap.yaml (created if missing)
- [ ] secrets.yaml (created if missing)

---

## Common Patterns by Application Type

### CMS Applications (Ghost, WordPress)
- ConfigMap: Application configuration file (config.production.json, etc.)
- Secrets: Database credentials
- Database: MySQL, SQLite, or PostgreSQL

### Messaging Applications (Mattermost, Slack-like)
- ConfigMap: Server configuration (config.json)
- Secrets: Encryption keys, database credentials, API tokens
- Database: PostgreSQL, MySQL
- Storage: For file uploads, avatars, plugins

### Monitoring Applications (Prometheus, Grafana)
- ConfigMap: Scrape configs, alert rules
- Secrets: API keys, webhooks
- Storage: Time-series data persistence

---

## Notes
- Always create a new branch, never modify the original
- Run `helm lint` before committing
- Test template rendering with `helm template`
- Ensure all hardcoded values move to values.yaml
- Document app-specific configurations in profiling document
- Keep commit messages detailed and descriptive

---

**Skill Version:** 1.0  
**Last Updated:** March 31, 2026  
**Applicable To:** Ghost, Mattermost, WordPress, and similar Helm deployments
