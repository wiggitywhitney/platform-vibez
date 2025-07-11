# Platform Vibez - Kubernetes Platform Engineering

## What is Platform Vibez?

Platform Vibez solves three specific problems that developers face when working with Kubernetes:

1. **Local Development Hell**: Setting up a working Kubernetes environment locally takes hours of fighting with Docker, networking, and configuration files
2. **Generic App Deployment Complexity**: Every team reinvents the same Helm chart patterns for basic web applications, leading to inconsistent configurations
3. **Missing Platform Guardrails**: Without governance policies, teams deploy applications with latest tags, no resource limits, and missing labels that break monitoring

This repository provides a working solution: a complete local Kubernetes platform with monitoring, security policies, and a battle-tested Helm chart that works for 80% of web applications.

## What This Gives You

A complete local Kubernetes development environment with:
- **5-minute cluster setup**: Script handles Docker, kind, networking, and monitoring automatically
- **Working monitoring**: Datadog integration that actually shows meaningful metrics for your apps
- **Security policies that enforce good practices**: No more latest tags, missing resource limits, or unlabeled deployments
- **Generic Helm chart**: Deploy most web apps with just image, port, and resource requirements
- **Comprehensive testing**: Chainsaw test suite validates that everything actually works

This is useful for learning Kubernetes, developing applications, or building platform engineering capabilities without needing cloud resources.

## 📚 Documentation

📖 **[Complete Documentation Index](docs/README.md)** - All platform documentation in one place

### Key Documentation:
- **[Platform Policies](docs/PLATFORM-POLICIES.md)** - 4 governance policies that prevent common deployment problems
- **[Generic App Chart](helm-charts/generic-app/README.md)** - One Helm chart that works for most stateless applications
- **[E2E Testing](tests/e2e/README.md)** - Chainsaw test suite that validates the entire platform

## Features

- ✅ **5-Minute Setup**: Script installs tools, creates cluster, configures monitoring automatically
- ✅ **Real Monitoring**: Datadog operator with automatic configuration that actually works  
- ✅ **Platform Governance**: 4 Kyverno policies prevent common deployment mistakes
- ✅ **Generic App Deployment**: One Helm chart handles 80% of web application deployment patterns
- ✅ **Automated Testing**: Chainsaw test suite validates policies, charts, and monitoring
- ✅ **Secure Secret Management**: Teller integration with Google Secrets Manager
- ✅ **Ingress-Ready**: Pre-configured nginx ingress with port forwarding

## Prerequisites

### Required
- macOS with Homebrew (for automatic installation)
- Docker Desktop (will be started automatically if installed)

### For Datadog Monitoring
Choose **one** of these approaches:

#### Option 1: Teller (Recommended - Most Secure)
```bash
# Install Teller
brew install teller

# Authenticate with Google Cloud
gcloud auth application-default login

# Configure .teller.yml (see Secret Management section below)
# Then Teller can retrieve secrets from Google Secrets Manager
```

#### Option 2: Environment Variable
```bash
# Set API key directly (simpler for quick testing)
export DATADOG_API_KEY="your_api_key_here"
```

## Quick Start

### Basic Cluster Setup
```bash
# Create a cluster with default name "kind"
./setup-k8s-cluster.sh

# Create a cluster with custom name
./setup-k8s-cluster.sh platform-vibez
```

### With Datadog Monitoring
```bash
# Using Teller (recommended)
./setup-k8s-cluster.sh platform-vibez

# Using environment variable
export DATADOG_API_KEY="your_api_key_here"
./setup-k8s-cluster.sh platform-vibez
```

### Deploy Your First App
```bash
# Deploy a web app using the generic chart
helm install my-app ./helm-charts/generic-app \
  --set image.repository=nginx \
  --set image.tag=1.25 \
  --set container.port=80 \
  --set healthChecks.path=/ \
  --set resources.cpu=100m \
  --set resources.memory=128Mi \
  --set labels.team=platform

# Enable ingress for external access
helm upgrade my-app ./helm-charts/generic-app \
  --reuse-values \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=my-app.local

# Add to /etc/hosts: 127.0.0.1 my-app.local
# Visit http://my-app.local in browser
```

### Run Platform Tests
```bash
# Validate the entire platform works correctly
cd tests/e2e
./test-runner.sh

# Results: 6 passed, 0 failed
# ✅ All tests passed!
```

## What the Script Does

The setup script solves the "local Kubernetes is painful" problem by automating everything:

1. **Prerequisites Check**: Installs Docker, kind, kubectl, helm, and monitoring tools automatically
2. **Secret Validation**: Tests your Datadog API key against their validation endpoint before proceeding  
3. **Cluster Creation**: Creates kind cluster with ingress ports (80/443) mapped to localhost
4. **Ingress Setup**: Installs nginx ingress controller and waits for it to be ready
5. **Policy Engine**: Installs Kyverno and applies 4 governance policies from `policies/` directory
6. **Monitoring Setup**: Deploys Datadog operator with infrastructure monitoring configuration
7. **Verification**: Runs health checks to ensure everything is actually working

After 5 minutes, you have a working Kubernetes platform with monitoring and governance.

## Platform Governance Policies

The `policies/` directory contains 4 Kyverno policies that prevent common deployment problems:

- **`require-labels.yaml`**: Forces teams to add `team` labels so you can track which deployments belong to which team
- **`disallow-latest-tag.yaml`**: Blocks `:latest` tags that make deployments unreproducible (allows specific versions like `nginx:1.25`)
- **`require-resource-limits.yaml`**: Requires CPU and memory limits so one app can't consume the entire cluster
- **`enforce-cpu-limits.yaml`**: Ensures CPU limits are reasonable (100m to 4000m) to prevent resource hogging

These policies are automatically applied during cluster setup. When teams try to deploy something that violates a policy, they get a clear error message explaining what to fix.

## Generic App Helm Chart

The `helm-charts/generic-app/` directory contains a single Helm chart that handles 80% of web application deployment patterns:

- **Auto-calculated resource requests**: Sets requests to 50% of limits automatically
- **Consistent health checks**: Configures liveness and readiness probes
- **Ingress integration**: Optional ingress with automatic TLS via cert-manager
- **Horizontal Pod Autoscaler**: Optional HPA based on CPU utilization
- **Opinionated defaults**: Sensible defaults that reduce configuration burden

Instead of every team writing their own Helm charts, they can use this one with minimal configuration.

## Secret Management with Teller

### Configuration
The `.teller.yml` file configures secure secret retrieval:

```yaml
project: <<your-project-name-here>>
providers:
  google_secrets_manager:
    kind: google_secretmanager
    maps:
      - id: secrets
        path: projects/<<your-google-cloud-project-id-here>>
        keys:
          <<your-secret-name-here>>: DATADOG_API_KEY
```

**Replace with your values:**
- `<<your-project-name-here>>`: Any descriptive name for your project
- `<<your-google-cloud-project-id-here>>`: Your actual Google Cloud project ID
- `<<your-secret-name-here>>`: The name of your secret in Google Secrets Manager

### Usage
```bash
# View secrets (masked for security)
teller show

# Export secrets as environment variables (plaintext output)
teller env

# Load secrets into your current shell session
eval $(teller env)
# This executes the output of 'teller env' in your current shell,
# making all secrets available as environment variables.
# After running this, you can use $DATADOG_API_KEY in your commands.
```

## Datadog Monitoring

Datadog is a monitoring platform that provides dashboards and alerts for your infrastructure. This setup automatically configures Datadog to monitor your local Kubernetes cluster.

### What's Included
- **Datadog Operator**: Manages Datadog agents via Kubernetes CRDs
- **Node Agent**: Collects metrics from each cluster node (CPU, memory, disk usage)
- **Cluster Agent**: Aggregates cluster-level metrics and application traces
- **Pre-configured Setup**: Sensible defaults for infrastructure monitoring

### Verification
```bash
# Check Datadog pods
kubectl get pods -n datadog

# View agent logs
kubectl logs -n datadog -l app=datadog-agent

# Check cluster agent
kubectl logs -n datadog -l app=datadog-cluster-agent
```

## Platform Testing

The `tests/e2e/` directory contains a Chainsaw test suite that validates the entire platform:

- **Basic deployment**: Tests that the generic Helm chart works
- **Policy validation**: Verifies that governance policies actually block bad deployments
- **Ingress functionality**: Tests that external access works
- **Autoscaling**: Validates HPA configuration
- **Edge cases**: Tests boundary conditions and upgrade scenarios

```bash
# Run all tests in parallel
cd tests/e2e
./test-runner.sh

# Run individual test with detailed output
chainsaw test --config chainsaw.yaml --test-file basic-deployment-test.yaml
```

## Cluster Configuration

The script creates a cluster with:
- **Control plane** with ingress-ready labels
- **Port mappings**: 80 → 80, 443 → 443 (for ingress)
- **Datadog monitoring** with automatic node discovery
- **Kyverno policies** for governance and security
- **nginx ingress** controller for external access
- **Local storage** provisioner
- **CoreDNS** for service discovery

## Example Usage

```bash
# Create monitored cluster with policies
./setup-k8s-cluster.sh platform-vibez

# Deploy a compliant application
helm install my-api ./helm-charts/generic-app \
  --set image.repository=nginx \
  --set image.tag=1.25.3 \
  --set container.port=80 \
  --set healthChecks.path=/health \
  --set resources.cpu=200m \
  --set resources.memory=256Mi \
  --set labels.team=backend \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=my-api.local

# Add to /etc/hosts
echo "127.0.0.1 my-api.local" | sudo tee -a /etc/hosts

# Visit http://my-api.local in browser
# Check Datadog dashboard for metrics
```

## Managing Clusters

```bash
# List all clusters
kind get clusters

# Delete a cluster
kind delete cluster --name <cluster-name>

# Export kubeconfig for existing cluster
kind export kubeconfig --name <cluster-name>
```

## Useful Commands

```bash
# Basic operations
kubectl get all                    # List all resources
kubectl get pods -A               # List all pods in all namespaces
kubectl get nodes                 # List cluster nodes

# Platform governance
kubectl get clusterpolicies       # List Kyverno policies
kubectl apply -f policies/        # Reapply platform policies

# Monitoring
kubectl get pods -n datadog       # Check Datadog pods
kubectl get datadogagent -n datadog # Check Datadog CRD

# Generic app deployments
helm list                         # List deployed applications
helm install <name> ./helm-charts/generic-app --set key=value
helm upgrade <name> ./helm-charts/generic-app --reuse-values --set key=newvalue

# Testing
cd tests/e2e && ./test-runner.sh  # Run all platform tests

# Debugging
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/bash

# Port forwarding
kubectl port-forward service/<service> <local-port>:<remote-port>
```

## Troubleshooting

### Docker Issues
- Ensure Docker Desktop is installed and running
- Check Docker daemon: `docker ps`
- Restart Docker Desktop if needed

### Teller Issues
- Verify Google Cloud authentication: `gcloud auth list`
- Check application default credentials: `gcloud auth application-default login`
- Test Teller connectivity: `teller show`

### Datadog Issues
- Verify API key format (32-character hex string)
- Check secret creation: `kubectl get secret -n datadog`
- Review agent logs: `kubectl logs -n datadog -l app=datadog-agent`

### Policy Issues
- Check policy status: `kubectl get clusterpolicies`
- View policy violations: `kubectl get events --field-selector type=Warning`
- Test policy with sample deployment: `kubectl apply -f policies/`

### Permission Issues
- Make sure script is executable: `chmod +x setup-k8s-cluster.sh`
- Run with proper permissions

### Cluster Issues
- Delete and recreate: `kind delete cluster --name <name>`
- Check system requirements: Docker must have enough resources
- Verify Docker daemon is accessible

## Security Best Practices

### ✅ Recommended
- Use Teller for secret management
- Store API keys in Google Secrets Manager
- Validate API keys before use
- Use application default credentials
- Apply platform governance policies

### ❌ Avoid
- Committing API keys to version control
- Using plain text API keys in scripts
- Storing secrets in environment files tracked by git
- Deploying applications with `:latest` tags
- Skipping resource limits on containers

## Customization

### Modifying Cluster Configuration
Edit the `kind: Cluster` section in the setup script. See [kind documentation](https://kind.sigs.k8s.io/docs/user/configuration/) for available options.

### Customizing Platform Policies
Edit individual policy files in the `policies/` directory, then apply:
```bash
kubectl apply -f policies/
```

### Customizing Monitoring
Modify the `datadog-agent.yaml` file or update the script's DatadogAgent CRD settings.

### Extending the Generic App Chart
The `helm-charts/generic-app/` chart can be extended with additional features. See the chart's README for configuration options.

## Clean Up

```bash
# Delete cluster
kind delete cluster --name <cluster-name>

# Clean up local files
rm -f ./*-kubeconfig.yaml
``` 