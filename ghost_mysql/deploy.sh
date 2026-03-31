#!/bin/bash

# Ghost Helm Chart Deployment Script
# Simple script to deploy Ghost CMS to Kubernetes

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Ghost Helm Chart Deployer ===${NC}\n"

# Check prerequisites
echo "Checking prerequisites..."
command -v helm >/dev/null 2>&1 || { echo -e "${RED}Error: helm not installed${NC}"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}Error: kubectl not installed${NC}"; exit 1; }
echo -e "${GREEN}✓ Helm and kubectl found${NC}\n"

# Get configuration
read -p "Enter release name (default: ghost): " RELEASE_NAME
RELEASE_NAME=${RELEASE_NAME:-ghost}

read -p "Enter namespace (default: ghost): " NAMESPACE
NAMESPACE=${NAMESPACE:-ghost}

read -sp "Enter MySQL root password: " MYSQL_ROOT_PASS
echo
read -sp "Confirm MySQL root password: " MYSQL_ROOT_PASS_CONFIRM
echo

if [ "$MYSQL_ROOT_PASS" != "$MYSQL_ROOT_PASS_CONFIRM" ]; then
    echo -e "${RED}Error: Passwords do not match${NC}"
    exit 1
fi

read -sp "Enter MySQL user password: " MYSQL_USER_PASS
echo
read -sp "Confirm MySQL user password: " MYSQL_USER_PASS_CONFIRM
echo

if [ "$MYSQL_USER_PASS" != "$MYSQL_USER_PASS_CONFIRM" ]; then
    echo -e "${RED}Error: Passwords do not match${NC}"
    exit 1
fi

# Optional: Ingress setup
read -p "Enable Ingress? (y/n, default: n): " ENABLE_INGRESS
ENABLE_INGRESS=${ENABLE_INGRESS:-n}

INGRESS_ARGS=""
if [[ "$ENABLE_INGRESS" == "y" || "$ENABLE_INGRESS" == "Y" ]]; then
    read -p "Enter domain (e.g., blog.example.com): " DOMAIN
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}Error: Domain cannot be empty${NC}"
        exit 1
    fi
    INGRESS_ARGS="--set ingress.enabled=true --set 'ingress.hosts[0].host=$DOMAIN' --set 'ingress.tls[0].secretName=ghost-tls' --set 'ingress.tls[0].hosts[0]=$DOMAIN'"
fi

# Create namespace
echo -e "\n${BLUE}Creating namespace...${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace ready${NC}"

# Deploy
echo -e "\n${BLUE}Deploying Ghost chart...${NC}"
eval "helm install $RELEASE_NAME . \
  --namespace $NAMESPACE \
  --set database.mysql.rootPassword=$MYSQL_ROOT_PASS \
  --set database.mysql.password=$MYSQL_USER_PASS \
  $INGRESS_ARGS"

echo -e "\n${GREEN}✓ Deployment completed!${NC}\n"

# Show status
echo -e "${BLUE}=== Deployment Status ===${NC}"
kubectl get all -n $NAMESPACE

echo -e "\n${BLUE}=== Next Steps ===${NC}"
echo "1. Wait for pod to be ready:"
echo "   kubectl get pods -n $NAMESPACE -w"
echo ""
echo "2. Access Ghost:"
echo "   kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME-ghost-service 8080:80"
echo "   Open: http://localhost:8080"
echo ""
echo "3. View logs:"
echo "   kubectl logs -n $NAMESPACE deployment/$RELEASE_NAME-ghost -c ghost"
echo "   kubectl logs -n $NAMESPACE deployment/$RELEASE_NAME-ghost -c mysql"
echo ""
