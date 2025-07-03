# Generic Application Helm Chart

A flexible, reusable Helm chart for deploying generic applications with deployment, service, and ingress resources.

## Overview

This chart provides a standardized way to deploy applications to Kubernetes with common configurations and best practices built-in. It's designed to be flexible enough to handle most application deployment scenarios while maintaining simplicity.

## Features

- ✅ **Deployment** with configurable replicas, resources, and health checks
- ✅ **Service** with flexible port and type configuration
- ✅ **Ingress** with TLS support and multiple host/path configurations
- ✅ **ConfigMap** and **Secret** support for application configuration
- ✅ **PersistentVolumeClaim** for stateful applications
- ✅ **HorizontalPodAutoscaler** for automatic scaling
- ✅ **ServiceAccount** with configurable permissions
- ✅ **Security contexts** and **pod security policies**
- ✅ **Node selection**, **tolerations**, and **affinity** rules

## Installation

```bash
# Install with default values
helm install my-app ./helm-charts/generic-app

# Install with custom values
helm install my-app ./helm-charts/generic-app -f my-values.yaml

# Install with specific values
helm install my-app ./helm-charts/generic-app \
  --set image.repository=nginx \
  --set image.tag=1.25 \
  --set ingress.enabled=true
```

## Configuration

### Essential Values to Expose

#### 🚀 **Application Basics** (Required)
```yaml
app:
  name: "my-application"     # Application name (optional, uses chart name)
  version: "1.0.0"          # Application version (optional, uses chart appVersion)

image:
  repository: "nginx"        # Container image repository
  tag: "latest"             # Image tag
  pullPolicy: IfNotPresent  # Image pull policy
```

#### 🔧 **Container Configuration**
```yaml
container:
  port: 80                  # Container port
  protocol: TCP             # Protocol (TCP/UDP)
  env:                      # Environment variables
    - name: ENV_VAR
      value: "value"

replicaCount: 1            # Number of replicas
```

#### 🏥 **Health & Resources**
```yaml
healthChecks:
  enabled: true
  livenessProbe:
    httpGet:
      path: /health
      port: http

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

#### 🌐 **Networking**
```yaml
service:
  enabled: true
  type: ClusterIP           # ClusterIP, NodePort, LoadBalancer
  port: 80

ingress:
  enabled: false
  className: "nginx"
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
```

### Optional Advanced Configuration

#### 📈 **Auto-scaling**
```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

#### 💾 **Persistent Storage**
```yaml
persistence:
  enabled: true
  size: 1Gi
  mountPath: /data
  storageClass: "fast-ssd"
```

#### 🔐 **Configuration & Secrets**
```yaml
configMap:
  enabled: true
  data:
    config.yaml: |
      key: value

secret:
  enabled: true
  data:
    secret-key: base64-encoded-value
```

## Examples

### Simple Web Application
```bash
helm install my-web-app ./helm-charts/generic-app \
  --set image.repository=nginx \
  --set image.tag=1.25 \
  --set service.enabled=true \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=myapp.local
```

### API with Database
```bash
helm install my-api ./helm-charts/generic-app \
  -f examples/api-example.yaml
```

### Stateful Application
```bash
helm install my-stateful-app ./helm-charts/generic-app \
  --set persistence.enabled=true \
  --set persistence.size=10Gi \
  --set replicaCount=1
```

## Value Categories for End Users

### 🎯 **Essential (Always expose)**
- `image.repository` & `image.tag` - What to deploy
- `container.port` - Application port
- `service.enabled` & `service.port` - Basic networking
- `ingress.enabled` & `ingress.hosts` - External access

### 🔧 **Common (Often needed)**
- `replicaCount` - Scaling
- `container.env` - Environment configuration
- `resources` - CPU/Memory limits
- `healthChecks` - Health check paths
- `persistence.enabled` - Storage needs

### ⚙️ **Advanced (Power users)**
- `autoscaling.*` - Auto-scaling configuration
- `nodeSelector`, `tolerations`, `affinity` - Scheduling
- `securityContext` - Security settings
- `serviceAccount.*` - RBAC configuration

### 🔐 **Platform-specific (Managed by platform team)**
- `podSecurityContext` - Security policies
- `imagePullSecrets` - Registry access
- `ingress.className` & `ingress.annotations` - Ingress controller config

## Best Practices

1. **Use specific image tags** in production (avoid `latest`)
2. **Set resource requests and limits** for predictable performance
3. **Enable health checks** for reliable deployments
4. **Use ConfigMaps** for non-sensitive configuration
5. **Use Secrets** for sensitive data (passwords, API keys)
6. **Enable autoscaling** for variable workloads
7. **Configure ingress** for external access with proper TLS

## Upgrading

```bash
# Upgrade with new values
helm upgrade my-app ./helm-charts/generic-app -f new-values.yaml

# Upgrade with inline values
helm upgrade my-app ./helm-charts/generic-app --set image.tag=v2.0.0
```

## Uninstalling

```bash
helm uninstall my-app
``` 