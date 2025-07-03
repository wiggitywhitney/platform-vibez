# Local Kubernetes Cluster Setup

This repository contains a setup script to quickly create and configure a local Kubernetes cluster using [kind](https://kind.sigs.k8s.io/) (Kubernetes IN Docker).

## Prerequisites

- macOS with Homebrew (for automatic installation)
- Docker Desktop (will be started automatically if installed)

## Quick Start

```bash
# Create a cluster with default name "kind"
./setup-k8s-cluster.sh

# Create a cluster with custom name
./setup-k8s-cluster.sh my-cluster
```

## What the Script Does

1. **Checks Prerequisites**: Verifies Docker, kind, and kubectl are installed
2. **Auto-Installation**: Installs missing tools via Homebrew if available
3. **Docker Management**: Starts Docker Desktop if not running
4. **Cluster Creation**: Creates a kind cluster with ingress-ready configuration
5. **Verification**: Waits for all nodes and system pods to be ready
6. **Information**: Displays cluster details and useful commands

## Features

- ✅ Automatic prerequisite checking and installation
- ✅ Colored output with clear status indicators
- ✅ Handles existing clusters (option to recreate)
- ✅ Ingress-ready configuration with port mappings
- ✅ Comprehensive verification and health checks
- ✅ Detailed success summary with quick start commands

## Cluster Configuration

The script creates a cluster with:
- **Control plane** with ingress-ready labels
- **Port mappings**: 80 → 80, 443 → 443 (for ingress)
- **Local storage** provisioner
- **CoreDNS** for service discovery
- **Standard** Kubernetes system components

## Example Usage

```bash
# Create the cluster
./setup-k8s-cluster.sh

# Deploy nginx
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort

# Port forward to access
kubectl port-forward service/nginx 8080:80

# Visit http://localhost:8080 in your browser
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

### Permission Issues
- Make sure script is executable: `chmod +x setup-k8s-cluster.sh`
- Run with proper permissions

### Cluster Issues
- Delete and recreate: `kind delete cluster --name <name>`
- Check system requirements: Docker must have enough resources
- Verify Docker daemon is accessible

## Customization

To modify the cluster configuration, edit the `kind: Cluster` section in the script. See [kind documentation](https://kind.sigs.k8s.io/docs/user/configuration/) for available options.

## Clean Up

```bash
# Delete cluster
kind delete cluster --name <cluster-name>
``` 