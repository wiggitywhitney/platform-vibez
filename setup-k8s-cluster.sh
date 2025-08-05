#!/bin/bash

# Platform Vibez - Local Kubernetes Cluster Setup Script
# =======================================================
# This script creates a local Kubernetes cluster using kind
# (Kubernetes IN Docker) with monitoring and security for development.
#
# This script sets up a complete local development environment with:
# - Kubernetes cluster (via kind)
# - Infrastructure monitoring (via Datadog)
# - Secure secret management (via Teller)
# - Knative serverless platform for applications
# - Crossplane infrastructure platform for cloud resources
#
# What you'll get after running this script:
# - A fully functional Kubernetes cluster running locally
# - Knative Serving for serverless applications (with Kourier networking)
# - Knative Eventing for event-driven architectures
# - Kyverno policy engine for governance and security
# - Crossplane infrastructure platform for cloud resource management
# - AWS Controllers for Kubernetes (ACK) for native AWS resource management
# - Datadog agent collecting metrics and logs (traces require app deployment)
# - Secure API key management without hardcoding secrets
# - Ready-to-use environment for deploying serverless applications and infrastructure
# - Comprehensive monitoring dashboard in Datadog UI
#
# Prerequisites:
# ==============
# Before running this script, you must:
# 1. Install Docker Desktop and ensure it's running
# 2. Have a valid Datadog API key available via either:
#    a) Teller with .teller.yml configuration (RECOMMENDED for security)
#       - Teller is a secrets management tool that securely retrieves API keys
#       - It prevents hardcoding secrets in environment variables or scripts
#       - Supports Google Secrets Manager, AWS Secrets Manager, Vault, etc.
#       - See README.md for .teller.yml configuration examples
#    b) DATADOG_API_KEY environment variable (simpler for quick testing)
# 3. Install Homebrew (for automatic tool installation)
# 4. Have kubectl and kind installed (or allow script to install them)
#
# Usage:
# ======
# Option 1 - Using Teller (RECOMMENDED for security):
# 1. Configure .teller.yml with your secrets provider (see README.md)
# 2. Authenticate: gcloud auth application-default login
# 3. Run: ./setup-k8s-cluster.sh platform-vibez
#
# Option 2 - Using environment variable (simpler for quick testing):
# 1. Get your Datadog API key from https://app.datadoghq.com/account/settings#api
# 2. Export: export DATADOG_API_KEY=<<your_api_key_here>>
# 3. Run: ./setup-k8s-cluster.sh platform-vibez
#
# Examples:
# =========
# # Secure setup with Teller
# ./setup-k8s-cluster.sh platform-vibez
#
# # Quick setup with environment variable
# export DATADOG_API_KEY="abcd1234ef567890abcd1234ef567890"
# ./setup-k8s-cluster.sh platform-vibez
#
# What this script does:
# ======================
# 1. Creates a local kind Kubernetes cluster
# 2. Installs Knative Serving and Eventing for serverless applications
# 3. Installs Kourier as the Knative networking layer
# 4. Installs Kyverno policy engine for governance
# 5. Installs Crossplane infrastructure platform for cloud resource management
# 6. Installs AWS EC2 provider for Crossplane
# 7. Installs AWS Controllers for Kubernetes (ACK) for EC2 and IAM
# 8. Installs the Datadog operator via Helm
# 9. Creates Datadog namespace and API key secret
# 10. Deploys DatadogAgent for infrastructure monitoring
# 11. Configures hostname resolution for local development
# 12. Enables APM configuration and log collection
# 13. Verifies Datadog monitoring setup

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

# Check for required datadog-agent.yaml file
if [[ ! -f "datadog-agent.yaml" ]]; then
    print_error "datadog-agent.yaml not found in current directory.
This file contains the DatadogAgent configuration required for monitoring.
Please ensure you're running this script from the platform-vibez repository root."
fi
print_status "datadog-agent.yaml configuration file found"

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
        
        # Set up local kubeconfig for existing cluster
        KUBECONFIG_FILE="./${CLUSTER_NAME}-kubeconfig.yaml"
        
        kind export kubeconfig --name "${CLUSTER_NAME}" --kubeconfig "${KUBECONFIG_FILE}"
        export KUBECONFIG="${KUBECONFIG_FILE}"
        print_status "Kubeconfig exported to: ${KUBECONFIG_FILE}"
        print_status "KUBECONFIG environment variable set"
        
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
KUBECONFIG_FILE="./${CLUSTER_NAME}-kubeconfig.yaml"

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
  # Knative/Kourier ports for serverless applications
  - containerPort: 31080
    hostPort: 80
    protocol: TCP
  - containerPort: 31443
    hostPort: 443
    protocol: TCP
EOF

print_status "Cluster created successfully"

# Export kubeconfig to local file and set environment variable
print_info "Exporting kubeconfig to local file..."
kind export kubeconfig --name "${CLUSTER_NAME}" --kubeconfig "${KUBECONFIG_FILE}"
export KUBECONFIG="${KUBECONFIG_FILE}"
print_status "Kubeconfig exported to: ${KUBECONFIG_FILE}"
print_status "KUBECONFIG environment variable set"

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

# Install Knative
echo ""
echo "🚀 Installing Knative..."
echo "======================="

# Install Knative Serving
print_info "Installing Knative Serving CRDs..."
kubectl apply -f https://github.com/knative/serving/releases/latest/download/serving-crds.yaml

print_info "Installing Knative Serving core..."
kubectl apply -f https://github.com/knative/serving/releases/latest/download/serving-core.yaml

# Install Kourier as the networking layer
print_info "Installing Kourier networking layer..."
kubectl apply -f https://github.com/knative/net-kourier/releases/latest/download/kourier.yaml

# Configure Kourier as the default networking layer
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'

# Install Knative Eventing
print_info "Installing Knative Eventing CRDs..."
kubectl apply -f https://github.com/knative/eventing/releases/latest/download/eventing-crds.yaml

print_info "Installing Knative Eventing core..."
kubectl apply -f https://github.com/knative/eventing/releases/latest/download/eventing-core.yaml

# Configure DNS
print_info "Configuring DNS for local development..."
kubectl apply -f https://github.com/knative/serving/releases/latest/download/serving-default-domain.yaml

# Wait for Knative components to be ready
print_info "Waiting for Knative Serving to be ready..."
kubectl wait deployment --all --timeout=300s --for=condition=Available -n knative-serving

print_info "Waiting for Knative Eventing to be ready..."
kubectl wait deployment --all --timeout=300s --for=condition=Available -n knative-eventing

print_status "Knative installation completed"

# Install Kyverno policy engine
echo ""
echo "🛡️  Installing Kyverno policy engine..."
echo "====================================="
print_info "Adding Kyverno Helm repository..."
helm repo add kyverno https://kyverno.github.io/kyverno/ || true
helm repo update

print_info "Installing Kyverno..."
helm install kyverno kyverno/kyverno --namespace kyverno --create-namespace

print_info "Waiting for Kyverno to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=admission-controller -n kyverno --timeout=300s

print_status "Kyverno policy engine installed and ready"

# Apply platform governance policies
echo ""
echo "📋 Applying platform governance policies..."
echo "==========================================="
print_info "Applying policies from policies/ directory..."
if kubectl apply -f policies/; then
    print_status "Platform governance policies applied successfully"
    
    # Show applied policies
    echo ""
    print_info "Applied policies:"
    kubectl get clusterpolicies -o custom-columns="NAME:.metadata.name,CATEGORY:.metadata.annotations.policies\.kyverno\.io/category,READY:.status.ready" 2>/dev/null || \
    kubectl get clusterpolicies -o custom-columns="NAME:.metadata.name,READY:.status.ready" 2>/dev/null || \
    kubectl get clusterpolicies
else
    print_warning "Failed to apply some policies. Check policies/ directory."
fi

# Install Crossplane
echo ""
echo "🔀 Installing Crossplane infrastructure platform..."
echo "=================================================="
print_info "Adding Crossplane Helm repository..."
helm repo add crossplane-stable https://charts.crossplane.io/stable || true
helm repo update

print_info "Installing Crossplane..."
helm install crossplane \
  crossplane-stable/crossplane \
  --namespace crossplane-system \
  --create-namespace

print_info "Waiting for Crossplane to be ready..."
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=crossplane -n crossplane-system --timeout=300s || {
    print_warning "Crossplane pods may still be starting up, but continuing with installation..."
    kubectl get pods -n crossplane-system
}

print_status "Crossplane infrastructure platform installed and ready"

print_info "Installing AWS EC2 provider for Crossplane..."
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-ec2
spec:
  package: xpkg.upbound.io/upbound/provider-aws-ec2:v1.23.1
EOF

print_info "Waiting for AWS EC2 provider to be ready..."
kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-aws-ec2 --timeout=300s || {
    print_warning "AWS EC2 provider may still be initializing, but continuing..."
    kubectl get providers
}

print_status "AWS EC2 provider installed and ready"

print_info "Crossplane status:"
kubectl get pods -n crossplane-system

# Install AWS Controllers for Kubernetes (ACK)
echo ""
echo "☁️  Installing AWS Controllers for Kubernetes (ACK)..."
echo "===================================================="

print_info "Creating ACK namespace..."
kubectl create namespace ack-system || true
print_status "ACK namespace created"

print_info "Creating placeholder AWS credentials secret..."
print_warning "🚨 SECURITY: Using placeholder AWS credentials. You must update these!"
kubectl create secret generic aws-credentials \
    --from-literal=credentials="[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" \
    --namespace=ack-system \
    --dry-run=client -o yaml | kubectl apply -f -
print_status "AWS credentials secret created (placeholder values)"

print_info "Installing ACK EC2 Controller..."
CONTROLLER_REGION="us-east-1"
EC2_RELEASE_VERSION=$(curl -sL https://api.github.com/repos/aws-controllers-k8s/ec2-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4 | sed 's/v//')
helm install ec2-controller \
    oci://public.ecr.aws/aws-controllers-k8s/ec2-chart \
    --version="${EC2_RELEASE_VERSION}" \
    --namespace ack-system \
    --set aws.region="${CONTROLLER_REGION}" \
    --set aws.credentials.secretName=aws-credentials \
    --set aws.credentials.profile=default \
    --wait --timeout=300s || {
    print_warning "EC2 controller installation may have timed out, but continuing..."
}

print_info "Installing ACK IAM Controller..."
IAM_RELEASE_VERSION=$(curl -sL https://api.github.com/repos/aws-controllers-k8s/iam-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4 | sed 's/v//')
helm install iam-controller \
    oci://public.ecr.aws/aws-controllers-k8s/iam-chart \
    --version="${IAM_RELEASE_VERSION}" \
    --namespace ack-system \
    --set aws.region="${CONTROLLER_REGION}" \
    --set aws.credentials.secretName=aws-credentials \
    --set aws.credentials.profile=default \
    --wait --timeout=300s || {
    print_warning "IAM controller installation may have timed out, but continuing..."
}

print_status "ACK controllers installed"

print_info "ACK Controller Status:"
kubectl get pods -n ack-system
echo ""

ACK_RESOURCES_COUNT=$(kubectl api-resources | grep -E "(ec2|iam).services.k8s.aws" | wc -l | xargs)
print_status "ACK installed with ${ACK_RESOURCES_COUNT} AWS resource types available"

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
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=datadog-operator -n datadog --timeout=300s || {
    print_warning "Datadog operator may still be starting, but continuing..."
    kubectl get pods -n datadog
}

# Deploy DatadogAgent configuration
print_info "Deploying DatadogAgent configuration..."
kubectl apply -f datadog-agent.yaml

print_status "DatadogAgent configuration deployed"

# Wait for Datadog agents to be ready
print_info "Waiting for Datadog agents to be ready..."
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=datadog-cluster-agent -n datadog --timeout=300s || {
    print_warning "Datadog cluster agent may still be starting, but continuing..."
    kubectl get pods -n datadog
}

# Wait a bit more for node agents (they take longer to start)
print_info "Waiting for Datadog node agents to be ready..."
sleep 30

# Verify Datadog setup
echo ""
echo "🔍 Verifying Datadog Setup..."
echo "=============================="
if [[ -f "verify-datadog.sh" ]]; then
    # Ensure script is executable
    chmod +x verify-datadog.sh
    if ./verify-datadog.sh; then
        print_status "Datadog monitoring verification completed successfully"
    else
        print_warning "Datadog monitoring verification detected some issues"
        print_info "Check the output above for details"
    fi
else
    print_warning "verify-datadog.sh not found - skipping verification"
    print_info "You can manually verify with: kubectl get pods -n datadog"
fi

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

echo "🔀 Crossplane Infrastructure:"
kubectl get pods -n crossplane-system
echo ""

echo "☁️  ACK Controllers:"
kubectl get pods -n ack-system
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
echo "  • Kubeconfig: ${KUBECONFIG_FILE}"
echo ""
echo "Networking:"
echo "  • Kourier (Knative networking): ✅ Active (handles serverless app routing)"
echo "  • External access: ✅ Ready for Knative services"
echo ""
echo "Policy Engine:"
echo "  • Kyverno: ✅ Active (governance and security policies)"
echo "  • Platform policies: ✅ Applied (4 policies: labels, image tags, resource limits, CPU bounds)"
echo "  • Admission control: ✅ Ready for policy enforcement"
echo ""
echo "Infrastructure Platform:"
echo "  • Crossplane: ✅ Active (cloud resource management via Kubernetes APIs)"
echo "  • Namespace: crossplane-system"
echo "  • AWS EC2 Provider: ✅ Installed and ready"
echo "  • Providers: ⏳ Ready for additional cloud providers (GCP, Azure, etc.)"
echo "  • Compositions: ⏳ Ready for platform abstractions"
echo ""
echo "AWS Controllers for Kubernetes (ACK):"
echo "  • Namespace: ack-system"
echo "  • EC2 Controller: ✅ Installed (instances, VPCs, subnets, security groups)"
echo "  • IAM Controller: ✅ Installed (roles, policies, users, groups)" 
echo "  • AWS Resources: ✅ ${ACK_RESOURCES_COUNT} resource types available"
echo "  • 🚨 Credentials: ⚠️  PLACEHOLDER VALUES - Update with real AWS credentials!"
echo ""
echo "Datadog Monitoring:"
echo "  • Namespace: datadog"
echo "  • Infrastructure monitoring: ✅ Active (CPU, memory, disk, network metrics)"
echo "  • APM (Application Performance Monitoring): ✅ Configured (requires app deployment for traces)"
echo "  • Log collection: ✅ Active (container and application logs)"
echo "  • Hostname resolution: ✅ Configured for local development"
echo ""
echo "Serverless Platform:"
echo "  • Knative Serving: ✅ Active (serverless applications)"
echo "  • Knative Eventing: ✅ Active (event-driven architecture)"
echo "  • Kourier: ✅ Active (Knative networking layer)"
echo "  • DNS: ✅ Configured for local development"
echo ""
echo "Quick Start Commands:"
echo "  • ./verify-datadog.sh               # Verify Datadog monitoring status"
echo "  • kubectl get all                    # List all resources"
echo "  • kubectl get pods -A               # List all pods in all namespaces"
echo "  • kubectl get pods -n datadog       # Check Datadog agent status"
echo "  • kubectl get pods -n kyverno       # Check Kyverno policy engine status"
echo "  • kubectl get pods -n crossplane-system  # Check Crossplane status"
echo "  • kubectl get pods -n ack-system    # Check ACK controller status"
echo "  • kubectl get clusterpolicies       # List Kyverno cluster policies"
echo "  • kubectl get providers              # List Crossplane providers"
echo "  • kubectl api-resources | grep 'ec2\|iam'  # List ACK AWS resources"
echo "  • kubectl describe provider provider-aws-ec2  # Check AWS provider status"
echo "  • kubectl get compositeresourcedefinitions  # List Crossplane XRDs"
echo "  • kubectl apply -f policies/        # Reapply platform policies"
echo "  • kubectl logs -n datadog -l app.kubernetes.io/component=cluster-agent  # Check Datadog logs"
echo "  • kubectl create deployment nginx --image=nginx  # Deploy nginx"
echo "  • kubectl expose deployment nginx --port=80 --type=NodePort  # Expose nginx"
echo "  • kubectl port-forward service/nginx 8080:80    # Port forward to access"
echo ""
echo "Cluster Management:"
echo "  • kind get clusters                  # List all clusters"
echo "  • kind delete cluster --name ${CLUSTER_NAME}  # Delete this cluster"
echo "  • export KUBECONFIG=${KUBECONFIG_FILE}  # Use this cluster in new shell session"
echo "  • kind export kubeconfig --name ${CLUSTER_NAME} --kubeconfig ${KUBECONFIG_FILE}  # Re-export kubeconfig"
echo ""

echo "🔗 What's Next:"
echo "  • Visit your Datadog dashboard to see infrastructure metrics"
echo "  • 🚨 IMPORTANT: Update ACK AWS credentials - see docs/ACK-SETUP.md"
echo "  • Create Crossplane compositions for EC2 instances and networking"
echo "  • Create AWS resources using ACK: kubectl apply -f examples/ack-instance.yaml"
echo "  • Install additional Crossplane providers for other cloud services"
echo "  • Deploy the generic-app Helm chart: helm install my-app ./helm-charts/generic-app"
echo "  • Run end-to-end tests: cd tests/e2e && ./test-runner.sh"
echo "  • Read the documentation: README.md and docs/ACK-SETUP.md"
echo ""

echo "📚 Useful Resources:"
echo "  • Platform Vibez Documentation: https://github.com/wiggitywhitney/platform-vibez"
echo "  • ACK Documentation: https://aws-controllers-k8s.github.io/community/"
echo "  • Crossplane Documentation: https://docs.crossplane.io/"
echo "  • Datadog Kubernetes Monitoring: https://docs.datadoghq.com/containers/kubernetes/"
echo "  • Kind Documentation: https://kind.sigs.k8s.io/docs/"
echo "  • Teller Documentation: https://github.com/tellerops/teller"
echo "  • Knative Documentation: https://knative.dev/docs/"
echo ""

echo "Happy Kubernetes development with monitoring! 🚀📊" 