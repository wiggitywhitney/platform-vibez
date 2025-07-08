#!/bin/bash

# Local Kubernetes Cluster Setup Script
# This script creates a local kind cluster with all necessary prerequisites
# and sets up Datadog infrastructure monitoring
#
# Prerequisites:
# ==============
# Before running this script, you must:
# 1. Install Docker Desktop and ensure it's running
# 2. Have a valid Datadog API key available via either:
#    a) Teller with .teller.yml configuration (recommended for security)
#    b) DATADOG_API_KEY environment variable
# 3. Install Homebrew (for automatic tool installation)
# 4. Have kubectl and kind installed (or allow script to install them)
#
# Usage:
# ======
# Option 1 - Using Teller (recommended):
# ./setup-k8s-cluster.sh [cluster_name]
#
# Option 2 - Using environment variable:
# export DATADOG_API_KEY="your_api_key_here"
# ./setup-k8s-cluster.sh [cluster_name]
#
# Example:
# ========
# # With Teller (requires .teller.yml)
# ./setup-k8s-cluster.sh my-cluster
#
# # With environment variable
# export DATADOG_API_KEY="abcd1234ef567890abcd1234ef567890"
# ./setup-k8s-cluster.sh my-cluster
#
# What this script does:
# ======================
# 1. Creates a local kind Kubernetes cluster
# 2. Installs the Datadog operator via Helm
# 3. Creates Datadog namespace and API key secret
# 4. Deploys DatadogAgent for infrastructure monitoring
# 5. Configures hostname resolution for local development
# 6. Enables APM and log collection

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default cluster name
CLUSTER_NAME="${1:-kind}"

echo -e "${BLUE}🚀 Local Kubernetes Cluster Setup with Datadog Monitoring${NC}"
echo "=========================================================="
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

# Check for Datadog API key - try Teller first, then environment variable
DATADOG_API_KEY_SOURCE=""

# Try to get API key from Teller first
if command_exists teller && [[ -f ".teller.yml" ]]; then
    print_info "Attempting to retrieve Datadog API key from Teller..."
    if TELLER_OUTPUT=$(teller env 2>/dev/null) && echo "$TELLER_OUTPUT" | grep -q "DATADOG_API_KEY="; then
        DATADOG_API_KEY=$(echo "$TELLER_OUTPUT" | grep "DATADOG_API_KEY=" | cut -d'=' -f2)
        DATADOG_API_KEY_SOURCE="teller"
        print_status "Datadog API key retrieved from Teller"
    else
        print_warning "Teller configuration found but failed to retrieve DATADOG_API_KEY"
    fi
fi

# Fall back to environment variable if Teller didn't work
if [[ -z "${DATADOG_API_KEY_SOURCE}" ]] && [[ -n "${DATADOG_API_KEY:-}" ]]; then
    DATADOG_API_KEY_SOURCE="environment"
    print_status "Using DATADOG_API_KEY from environment variable"
fi

# Error if no API key found
if [[ -z "${DATADOG_API_KEY}" ]]; then
    print_error "DATADOG_API_KEY not found. Please either:
1. Set up Teller with .teller.yml (recommended for security), or  
2. Set DATADOG_API_KEY environment variable: export DATADOG_API_KEY=\"your_api_key_here\""
fi

# Validate API key format (should be 32 characters)
if [[ ${#DATADOG_API_KEY} -ne 32 ]]; then
    print_error "DATADOG_API_KEY should be exactly 32 characters long. Current length: ${#DATADOG_API_KEY}"
fi

# Validate API key with Datadog
print_info "Validating API key with Datadog..."
if ! curl -s -H "DD-API-KEY: ${DATADOG_API_KEY}" "https://api.datadoghq.com/api/v1/validate" | grep -q '"valid":true'; then
    print_error "Invalid Datadog API key. Please check your API key and try again."
fi

print_status "DATADOG_API_KEY is set and validated with Datadog"

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

# Check if helm is installed
if ! command_exists helm; then
    print_warning "helm is not installed. Installing with brew..."
    if command_exists brew; then
        brew install helm
        print_status "helm installed successfully"
    else
        print_error "Homebrew not found. Please install helm manually"
    fi
else
    print_status "helm is installed"
fi

# Check if teller is available when .teller.yml exists
if [[ -f ".teller.yml" ]] && ! command_exists teller; then
    print_warning "Found .teller.yml but teller is not installed. Installing with brew..."
    if command_exists brew; then
        brew install teller
        print_status "teller installed successfully"
    else
        print_warning "Homebrew not found. Please install teller manually or use environment variables."
    fi
elif [[ -f ".teller.yml" ]]; then
    print_status "teller is installed and .teller.yml found"
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

# Setup Datadog Infrastructure Monitoring
echo ""
echo "📊 Setting up Datadog Infrastructure Monitoring..."
echo "=================================================="

# Create Datadog namespace
print_info "Creating Datadog namespace..."
kubectl create namespace datadog || true
print_status "Datadog namespace created"

# Create Datadog secret
print_info "Creating Datadog API key secret..."
kubectl create secret generic datadog-secret \
    --from-literal api-key="${DATADOG_API_KEY}" \
    --namespace=datadog \
    --dry-run=client -o yaml | kubectl apply -f -
print_status "Datadog secret created"

# Add Datadog Helm repository
print_info "Adding Datadog Helm repository..."
helm repo add datadog https://helm.datadoghq.com || true
helm repo update
print_status "Datadog Helm repository added"

# Install Datadog operator
print_info "Installing Datadog operator..."
if ! helm list -n datadog | grep -q my-datadog-operator; then
    helm install my-datadog-operator datadog/datadog-operator --namespace datadog
    print_status "Datadog operator installed"
else
    print_status "Datadog operator already installed"
fi

# Wait for operator to be ready
print_info "Waiting for Datadog operator to be ready..."
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=datadog-operator -n datadog --timeout=300s

# Deploy DatadogAgent configuration
print_info "Deploying DatadogAgent configuration..."
kubectl apply -f datadog-agent.yaml

print_status "DatadogAgent configuration deployed"

# Wait for Datadog agents to be ready
print_info "Waiting for Datadog agents to be ready..."
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=datadog-cluster-agent -n datadog --timeout=300s

# Wait a bit more for node agents (they take longer to start)
print_info "Waiting for Datadog node agents to be ready..."
sleep 30

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

echo "📈 Datadog Monitoring:"
kubectl get pods -n datadog
echo ""

# Final summary
echo ""
echo "🎉 SUCCESS! Your Kubernetes cluster with Datadog monitoring is ready!"
echo "====================================================================="
echo ""
echo "Cluster Details:"
echo "  • Name: ${CLUSTER_NAME}"
echo "  • Context: kind-${CLUSTER_NAME}"
echo "  • API Server: $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
echo ""
echo "Datadog Monitoring:"
echo "  • Namespace: datadog"
echo "  • Infrastructure monitoring: ✅ Enabled"
echo "  • APM (Application Performance Monitoring): ✅ Enabled"
echo "  • Log collection: ✅ Enabled"
echo "  • Hostname resolution: ✅ Configured for local development"
echo ""
echo "Quick Start Commands:"
echo "  • kubectl get all                    # List all resources"
echo "  • kubectl get pods -A               # List all pods in all namespaces"
echo "  • kubectl get pods -n datadog       # Check Datadog agent status"
echo "  • kubectl logs -n datadog -l app.kubernetes.io/name=datadog-cluster-agent  # Check Datadog logs"
echo "  • kubectl create deployment nginx --image=nginx  # Deploy nginx"
echo "  • kubectl expose deployment nginx --port=80 --type=NodePort  # Expose nginx"
echo "  • kubectl port-forward service/nginx 8080:80    # Port forward to access"
echo ""
echo "Cluster Management:"
echo "  • kind get clusters                  # List all clusters"
echo "  • kind delete cluster --name ${CLUSTER_NAME}  # Delete this cluster"
echo "  • kind export kubeconfig --name ${CLUSTER_NAME}  # Export kubeconfig"
echo ""

echo "Happy Kubernetes development with monitoring! 🚀📊" 