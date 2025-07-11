#!/bin/bash

# Platform Vibez - Datadog Agent Verification Script
# ==================================================
# This script verifies that Datadog monitoring infrastructure is running correctly.
# It checks agent connectivity and basic functionality but does not verify actual
# trace collection (requires deploying applications that generate traces).

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo -e "${BLUE}🔍 Datadog Agent Verification${NC}"
echo "================================="
echo ""

# Check if datadog namespace exists
print_info "Checking Datadog namespace..."
if kubectl get namespace datadog >/dev/null 2>&1; then
    print_status "Datadog namespace exists"
else
    print_error "Datadog namespace not found"
    exit 1
fi

# Check DatadogAgent CRD
print_info "Checking DatadogAgent configuration..."
if kubectl get datadogagent datadog -n datadog >/dev/null 2>&1; then
    print_status "DatadogAgent configuration found"
else
    print_error "DatadogAgent configuration not found"
    exit 1
fi

# Check pods status
echo ""
print_info "Checking Datadog pods status..."
kubectl get pods -n datadog

# Count running pods
RUNNING_PODS=$(kubectl get pods -n datadog --field-selector=status.phase=Running --no-headers | wc -l | tr -d ' ')
TOTAL_PODS=$(kubectl get pods -n datadog --no-headers | wc -l | tr -d ' ')

echo ""
if [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ] && [ "$TOTAL_PODS" -gt 0 ]; then
    print_status "All Datadog pods are running ($RUNNING_PODS/$TOTAL_PODS)"
else
    print_warning "Some Datadog pods may not be running ($RUNNING_PODS/$TOTAL_PODS)"
fi

# Check operator status
echo ""
print_info "Checking Datadog operator status..."
if kubectl get pods -l app.kubernetes.io/name=datadog-operator -n datadog --field-selector=status.phase=Running >/dev/null 2>&1; then
    print_status "Datadog operator is running"
else
    print_warning "Datadog operator may not be running"
fi

# Check cluster agent status
echo ""
print_info "Checking cluster agent status..."
if kubectl get pods -l app.kubernetes.io/component=cluster-agent -n datadog --field-selector=status.phase=Running >/dev/null 2>&1; then
    print_status "Datadog cluster agent is running"
else
    print_warning "Datadog cluster agent may not be running"
fi

# Check secret
echo ""
print_info "Checking Datadog secret..."
if kubectl get secret datadog-secret -n datadog >/dev/null 2>&1; then
    print_status "Datadog secret exists"
else
    print_error "Datadog secret not found"
fi

# Check APM configuration
echo ""
print_info "Checking APM configuration..."
if kubectl get datadogagent datadog -n datadog -o jsonpath='{.spec.features.apm.enabled}' 2>/dev/null | grep -q "true"; then
    print_status "APM is enabled in DatadogAgent configuration"
else
    print_warning "APM may not be enabled (requires app deployment to verify traces)"
fi

# Check agent health (if cluster agent is running)
echo ""
print_info "Checking agent health..."
if kubectl get pods -l app.kubernetes.io/component=cluster-agent -n datadog --field-selector=status.phase=Running >/dev/null 2>&1; then
    CLUSTER_AGENT_POD=$(kubectl get pods -l app.kubernetes.io/component=cluster-agent -n datadog -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$CLUSTER_AGENT_POD" ]; then
        echo "Cluster agent pod: $CLUSTER_AGENT_POD"
        if kubectl exec -n datadog "$CLUSTER_AGENT_POD" -- agent health >/dev/null 2>&1; then
            print_status "Datadog agent health check passed"
        else
            print_warning "Datadog agent health check failed or not available"
        fi
    fi
else
    print_warning "Cannot check agent health - cluster agent not running"
fi

# Check connectivity
echo ""
print_info "Checking connectivity to Datadog..."
if [ -n "$CLUSTER_AGENT_POD" ]; then
    if kubectl exec -n datadog "$CLUSTER_AGENT_POD" -- agent check connectivity >/dev/null 2>&1; then
        print_status "Connectivity to Datadog is working"
    else
        print_warning "Connectivity check failed or not available"
    fi
fi

# Summary
echo ""
echo "📊 Verification Summary:"
echo "========================"
echo "• Namespace: $(kubectl get namespace datadog >/dev/null 2>&1 && echo "✅" || echo "❌") datadog"
echo "• DatadogAgent CRD: $(kubectl get datadogagent datadog -n datadog >/dev/null 2>&1 && echo "✅" || echo "❌") configured"
echo "• Secret: $(kubectl get secret datadog-secret -n datadog >/dev/null 2>&1 && echo "✅" || echo "❌") datadog-secret"
echo "• Running Pods: $RUNNING_PODS/$TOTAL_PODS"
echo "• APM Config: $(kubectl get datadogagent datadog -n datadog -o jsonpath='{.spec.features.apm.enabled}' 2>/dev/null | grep -q "true" && echo "✅" || echo "⚠️") enabled"

echo ""
echo "🔗 Next Steps:"
echo "=============="
echo "• Visit your Datadog dashboard: https://app.datadoghq.com"
echo "• Check Infrastructure > Host Map for cluster nodes"
echo "• Review Logs section for log collection"
echo "• To verify APM traces: Deploy applications and check APM > Services"
echo ""

echo "📋 Useful Commands:"
echo "==================="
echo "• kubectl get pods -n datadog                    # Check pod status"
echo "• kubectl logs -n datadog -l app.kubernetes.io/component=agent   # Check node agent logs"
echo "• kubectl logs -n datadog -l app.kubernetes.io/component=cluster-agent   # Check cluster agent logs"
echo "• kubectl describe datadogagent datadog -n datadog  # Detailed config"
echo ""

if [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ] && [ "$TOTAL_PODS" -gt 0 ]; then
    echo "🎉 Datadog monitoring appears to be working correctly!"
else
    echo "⚠️  Some issues detected. Check the logs for more details."
    exit 1
fi 