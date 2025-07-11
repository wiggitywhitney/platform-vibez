#!/bin/bash

# Platform Vibez - Cluster Destruction Script
# ===========================================
# Destroys the kind cluster and cleans up local kubeconfig file

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default cluster name
CLUSTER_NAME="${1:-kind}"
KUBECONFIG_FILE="./${CLUSTER_NAME}-kubeconfig.yaml"

echo -e "${RED}🗑️  Destroying Kubernetes Cluster${NC}"
echo "=================================="
echo "Cluster name: ${CLUSTER_NAME}"
echo ""

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    print_warning "Cluster '${CLUSTER_NAME}' not found"
    echo "Available clusters:"
    kind get clusters 2>/dev/null || echo "  (none)"
    exit 1
fi

# Delete the cluster
print_info "Deleting kind cluster '${CLUSTER_NAME}'..."
kind delete cluster --name "${CLUSTER_NAME}"
print_status "Cluster deleted"

# Remove local kubeconfig file
if [[ -f "${KUBECONFIG_FILE}" ]]; then
    print_info "Removing local kubeconfig file..."
    rm "${KUBECONFIG_FILE}"
    print_status "Kubeconfig file removed: ${KUBECONFIG_FILE}"
else
    print_warning "Kubeconfig file not found: ${KUBECONFIG_FILE}"
fi

echo ""
echo "🎉 Cluster '${CLUSTER_NAME}' destroyed successfully!"
echo ""
echo "To create a new cluster:"
echo "  ./setup-k8s-cluster.sh ${CLUSTER_NAME}" 