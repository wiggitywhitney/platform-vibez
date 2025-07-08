# Platform Vibez - Local Kubernetes Setup

## What is Platform Vibez?

Platform Vibez is an experiment in "vibe coding" a platform on Kubernetes - a playground for exploring what it feels like to build opinionated, delightful developer experiences on top of Kubernetes infrastructure.

This repository contains a setup script to quickly create and configure a local Kubernetes cluster using [kind](https://kind.sigs.k8s.io/) (Kubernetes IN Docker) with monitoring and security for development.

## What This Gives You

A complete local Kubernetes development environment with:
- **Kubernetes cluster** running locally via Docker
- **Monitoring dashboard** to see what's happening in your cluster
- **Secure secret management** so you don't hardcode API keys
- **Ready-to-use setup** that works out of the box

This is useful for learning Kubernetes, developing applications, or experimenting with containerized deployments without needing cloud resources.

## Features

- ✅ **Secure Secret Management**: Teller integration with Google Secrets Manager
- ✅ **Infrastructure Monitoring**: Datadog operator with automatic configuration  
- ✅ **Secure Credential Handling**: API key validation and secure credential handling
- ✅ **Auto-Installation**: Installs missing tools via Homebrew if available
- ✅ **Ingress-Ready**: Pre-configured for nginx ingress controller
- ✅ **Health Checks**: Comprehensive verification and monitoring validation

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

## What the Script Does

1. **Security First**: Validates Datadog API key against Datadog's validation endpoint
2. **Secret Management**: Retrieves API key via Teller (preferred) or environment variable
3. **Prerequisites Check**: Verifies Docker, kind, kubectl, and monitoring tools
4. **Auto-Installation**: Installs missing tools including Teller if needed
5. **Cluster Creation**: Creates kind cluster with ingress-ready configuration
6. **Datadog Setup**: Deploys Datadog operator with pre-configured monitoring setup
7. **Comprehensive Verification**: Validates cluster health and monitoring setup

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

## Cluster Configuration

The script creates a cluster with:
- **Control plane** with ingress-ready labels
- **Port mappings**: 80 → 80, 443 → 443 (for ingress)
- **Datadog monitoring** with automatic node discovery
- **Secure credential handling** with validated API keys
- **Local storage** provisioner
- **CoreDNS** for service discovery

## Example Usage

```bash
# Create monitored cluster
./setup-k8s-cluster.sh platform-vibez

# Deploy nginx
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort

# Port forward to access
kubectl port-forward service/nginx 8080:80

# Visit http://localhost:8080 in your browser
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

# Monitoring
kubectl get pods -n datadog       # Check Datadog pods
kubectl get datadogagent -n datadog # Check Datadog CRD

# Deployments
kubectl create deployment <name> --image=<image>
kubectl expose deployment <name> --port=<port> --type=NodePort
kubectl scale deployment <name> --replicas=<count>

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

### ❌ Avoid
- Committing API keys to version control
- Using plain text API keys in scripts
- Storing secrets in environment files tracked by git

## Customization

To modify the cluster configuration, edit the `kind: Cluster` section in the script. See [kind documentation](https://kind.sigs.k8s.io/docs/user/configuration/) for available options.

For Datadog configuration, modify the `datadog-agent.yaml` file or update the script's DatadogAgent CRD settings.

## Clean Up

```bash
# Delete cluster
kind delete cluster --name <cluster-name>
``` 