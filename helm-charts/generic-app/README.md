# Generic Application Helm Chart

An **opinionated**, **ultra-simple** Helm chart for deploying stateless applications with smart defaults, auto-calculated resources, and platform guardrails.

## 🎯 Philosophy: Simple by Default, Complex When Needed

This chart is designed for **99% of stateless applications** with:
- **Smart defaults** that work out of the box
- **Platform guardrails** to prevent common mistakes  
- **Zero configuration drift** through auto-synchronization
- **Mandatory best practices** (health checks, resource limits)

For complex stateful applications, use dedicated StatefulSet charts or operators.

## ✅ What's Included (Core Features)

- 🚀 **Deployment** with auto-calculated resource requests (50% of limits)
- 🌐 **Service** (always created, auto-synced to container port)
- 🔄 **HorizontalPodAutoscaler** with hardcoded 75% thresholds
- 🌍 **Ingress** for external access
- 🔍 **Health Checks** (mandatory HTTP probes)
- 🛡️ **Resource Validation** with platform guardrails

## 🚫 What's NOT Included (By Design)

- ❌ **ConfigMaps** → Use `container.env` or external config management
- ❌ **Secrets** → Use external-secrets-operator or vault-injector  
- ❌ **PersistentVolumes** → Use StatefulSet charts for stateful apps
- ❌ **ServiceAccounts** → Default service account works for simple apps

## 🚀 Quick Start

### Simple Web Application
```bash
helm install my-app ./helm-charts/generic-app \
  --set image.repository=nginx \
  --set image.tag=1.25 \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=myapp.local
```

### API Application  
```bash
helm install my-api ./helm-charts/generic-app \
  --set image.repository=my-api \
  --set image.tag=v2.0.0 \
  --set container.port=8080 \
  --set healthChecks.path=/health
```

### Production Deployment with Scaling
```bash
helm install my-prod-app ./helm-charts/generic-app \
  --set image.repository=my-app \
  --set image.tag=v1.5.0 \
  --set container.port=3000 \
  --set resources.cpu=1000m \
  --set resources.memory=1Gi \
  --set autoscaling.enabled=true \
  --set autoscaling.maxReplicas=10
```

## ⚙️ Key Configuration

### 🎯 **Essential** (Always Configure)
```yaml
image:
  repository: "my-app"      # REQUIRED: Your container image
  tag: "v1.0.0"            # REQUIRED: Specific version (no 'latest')

container:
  port: 8080               # SINGLE SOURCE OF TRUTH: Auto-syncs to service/ingress
  env:                     # Environment variables
    - name: ENV_VAR
      value: "value"
```

### 🔧 **Common** (Often Needed)  
```yaml
resources:
  cpu: "500m"              # CPU limit (requests = 50% automatically)
  memory: "512Mi"          # Memory limit (requests = 50% automatically)

healthChecks:
  path: "/health"          # Health check endpoint (mandatory)

ingress:
  enabled: true
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
```

### ⚙️ **Advanced** (Fine-tuning)
```yaml
autoscaling:
  enabled: true
  minReplicas: 3           # HA by default (2+ recommended)
  maxReplicas: 10          # Prevent runaway scaling

# Pod scheduling  
nodeSelector: {}
tolerations: []
affinity: {}
```

## 🛡️ Platform Guardrails

### **Image Validation**
- ❌ No `latest` tags allowed (prevents drift)
- ✅ Must specify repository and tag

### **Resource Guardrails**  
- 🔒 CPU: 100m to 4000m (0.1-4 cores)
- 🔒 Memory: 128Mi to 8192Mi (8Gi), Mi/Gi units only
- 🤖 Requests auto-calculated to 50% of limits

### **Autoscaling Guardrails**
- 🔒 minReplicas: 1 to 10  
- 🔒 maxReplicas: 2 to 20 (hard platform limit)
- 🤖 CPU/Memory thresholds hardcoded to 75%

## 🔄 Smart Auto-Synchronization

**Single Source of Truth: `container.port`**

Set once → Everything syncs automatically:
```yaml
container:
  port: 8080               # You configure this

# Platform automatically creates:
# - Container listens on 8080
# - Service exposes port 8080 → 8080  
# - Ingress routes to port 8080
```

**Zero configuration drift possible!** 🎯

## 📖 Examples

### Example 1: React Frontend
```yaml
image:
  repository: my-frontend
  tag: v2.1.0
container:
  port: 3000
  env:
    - name: REACT_APP_API_URL
      value: "https://api.example.com"
ingress:
  enabled: true
  hosts:
    - host: app.example.com
```

### Example 2: Node.js API
```yaml  
image:
  repository: my-node-api
  tag: v1.5.0
container:
  port: 8080
  env:
    - name: PORT
      value: "8080"
    - name: NODE_ENV
      value: "production"
healthChecks:
  path: "/api/health"
resources:
  cpu: "1000m"
  memory: "1Gi"
autoscaling:
  enabled: true
  maxReplicas: 15
```

## 🚀 Advanced Usage

### Using with External Tools

**External Secrets:**
```yaml
container:
  env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: my-external-secret  # Created by external-secrets-operator
          key: password
```

**External Configuration:**
```yaml
container:
  env:
    - name: CONFIG_FILE
      value: "/config/app.yaml"
  # Mount external ConfigMap as volume (advanced users)
```

## 🔧 Migration from Complex Charts

### Replace ConfigMaps
```yaml
# OLD: Complex ConfigMap
configMap:
  enabled: true
  data:
    config.yaml: |
      database:
        host: postgres
        port: 5432

# NEW: Simple environment variables  
container:
  env:
    - name: DATABASE_HOST
      value: "postgres"
    - name: DATABASE_PORT
      value: "5432"
```

### Replace Custom ServiceAccounts
```yaml
# OLD: Custom ServiceAccount
serviceAccount:
  create: true
  annotations:
    iam.gke.io/gcp-service-account: my-gsa@project.iam.gserviceaccount.com

# NEW: Use workload identity or external tools
# - Configure workload identity at cluster level
# - Use dedicated RBAC charts for complex permissions
# - 99% of apps work fine with default service account
```

## 🎯 When NOT to Use This Chart

❌ **Stateful Applications** - Use StatefulSet charts  
❌ **Databases** - Use database operators (PostgreSQL, MySQL operators)  
❌ **Complex RBAC needs** - Use dedicated service account charts  
❌ **Legacy apps requiring custom service accounts** - Use full-featured charts  
❌ **Apps requiring persistent storage** - Use StatefulSet-based charts  

## 🔄 Upgrading

```bash
# Simple upgrade
helm upgrade my-app ./helm-charts/generic-app --set image.tag=v2.0.0

# With new values file
helm upgrade my-app ./helm-charts/generic-app -f new-values.yaml
```

## 🏗️ Platform Engineering Philosophy

This chart embodies **platform engineering best practices**:

1. **Opinionated Defaults** - Works out of the box
2. **Guardrails** - Prevents common mistakes  
3. **Auto-calculation** - Reduces configuration surface
4. **Fail Fast** - Clear validation with helpful errors
5. **Single Source of Truth** - Eliminates configuration drift

**Simple things should be simple. Complex things should be possible (elsewhere).** 🎯 