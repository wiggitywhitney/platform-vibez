#!/bin/bash

# Local Kubernetes Cluster Setup Script
# This script creates a local kind cluster with all necessary prerequisites

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default cluster name
CLUSTER_NAME="${1:-kind}"

echo -e "${BLUE}🚀 Local Kubernetes Cluster Setup${NC}"
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

print_error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check if Docker is installed
if ! command_exists docker; then
    print_error "Docker is not installed. Please install Docker Desktop first."
fi
print_status "Docker is installed"

# Check if kind is installed
if ! command_exists kind; then
    print_warning "kind is not installed. Installing with brew..."
    if command_exists brew; then
        brew install kind
        print_status "kind installed successfully"
    else
        print_error "Homebrew not found. Please install kind manually: https://kind.sigs.k8s.io/docs/user/quick-start/"
    fi
else
    print_status "kind is installed"
fi

# Check if kubectl is installed
if ! command_exists kubectl; then
    print_warning "kubectl is not installed. Installing with brew..."
    if command_exists brew; then
        brew install kubectl
        print_status "kubectl installed successfully"
    else
        print_error "Homebrew not found. Please install kubectl manually"
    fi
else
    print_status "kubectl is installed"
fi

# Check if Docker is running
echo ""
echo "🐳 Checking Docker status..."
if ! docker ps >/dev/null 2>&1; then
    print_warning "Docker is not running. Starting Docker Desktop..."
    open -a Docker
    
    # Wait for Docker to start
    print_info "Waiting for Docker to start..."
    timeout=60
    while ! docker ps >/dev/null 2>&1 && [ $timeout -gt 0 ]; do
        sleep 2
        timeout=$((timeout - 2))
        echo -n "."
    done
    echo ""
    
    if ! docker ps >/dev/null 2>&1; then
        print_error "Failed to start Docker. Please start Docker Desktop manually."
    fi
fi
print_status "Docker is running"

# Check if cluster already exists
echo ""
echo "🔍 Checking for existing cluster..."
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    print_warning "Cluster '${CLUSTER_NAME}' already exists"
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deleting existing cluster..."
        kind delete cluster --name "${CLUSTER_NAME}"
        print_status "Existing cluster deleted"
    else
        print_info "Using existing cluster"
        kind export kubeconfig --name "${CLUSTER_NAME}"
        print_status "kubectl configured for existing cluster"
        echo ""
        echo "🎉 Cluster '${CLUSTER_NAME}' is ready!"
        kubectl cluster-info
        exit 0
    fi
fi

# Create new cluster
echo ""
echo "🏗️  Creating new cluster..."
print_info "Creating kind cluster '${CLUSTER_NAME}'..."

# Create cluster with custom configuration
kind create cluster --name "${CLUSTER_NAME}" --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

print_status "Cluster created successfully"

# Verify cluster
echo ""
echo "🔍 Verifying cluster..."

# Wait for nodes to be ready
print_info "Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Wait for system pods
print_info "Waiting for system pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s

print_status "All nodes and system pods are ready"

# Display cluster info
echo ""
echo "📊 Cluster Information:"
echo "======================"
kubectl cluster-info
echo ""

echo "📋 Nodes:"
kubectl get nodes -o wide
echo ""

echo "🏃 System Pods:"
kubectl get pods -n kube-system
echo ""

# Final summary
echo ""
echo "🎉 SUCCESS! Your Kubernetes cluster is ready!"
echo "============================================="
echo ""
echo "Cluster Details:"
echo "  • Name: ${CLUSTER_NAME}"
echo "  • Context: kind-${CLUSTER_NAME}"
echo "  • API Server: $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
echo ""
echo "Quick Start Commands:"
echo "  • kubectl get all                    # List all resources"
echo "  • kubectl get pods -A               # List all pods in all namespaces"
echo "  • kubectl create deployment nginx --image=nginx  # Deploy nginx"
echo "  • kubectl expose deployment nginx --port=80 --type=NodePort  # Expose nginx"
echo "  • kubectl port-forward service/nginx 8080:80    # Port forward to access"
echo ""
echo "Cluster Management:"
echo "  • kind get clusters                  # List all clusters"
echo "  • kind delete cluster --name ${CLUSTER_NAME}  # Delete this cluster"
echo "  • kind export kubeconfig --name ${CLUSTER_NAME}  # Export kubeconfig"
echo ""
echo "Happy Kubernetes development! 🚀" 