# Platform Vibez - Governance Policies

This document describes the platform governance policies enforced by Kyverno.

> **✅ Status**: All policies are now working correctly! Recent fixes resolved issues with latest tag detection and CPU limits validation.

## 🛡️ Active Policies

### 1. Require Labels (`require-labels`)
**Purpose**: Ensures observability and governance  
**Requirement**: All deployments must have a `team` label  
**Example**:
```yaml
metadata:
  labels:
    team: "backend"  # Required
```

### 2. Disallow Latest Tag (`disallow-latest-tag`)
**Purpose**: Ensures reproducible deployments  
**Requirement**: Container images must use specific version tags, not `:latest`  
**Example**:
```yaml
spec:
  containers:
  - image: nginx:1.25.3  # ✅ Good - specific version
  - image: nginx:latest  # ❌ Blocked - latest tag
```

### 3. Require Resource Limits (`require-resource-limits`)
**Purpose**: Resource management and cluster stability  
**Requirement**: All containers must specify CPU and memory limits  
**Example**:
```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        resources:
          limits:
            cpu: "500m"     # Required
            memory: "512Mi" # Required
```

### 4. Enforce CPU Limits (`enforce-cpu-limits`)
**Purpose**: Prevent resource hogging and ensure fair resource allocation  
**Requirement**: CPU limits must be between 100m and 4000m (0.1 to 4 cores)  
**Example**:
```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        resources:
          limits:
            cpu: "200m"     # ✅ Valid - between 100m-4000m
            # cpu: "50m"    # ❌ Blocked - too low
            # cpu: "5000m"  # ❌ Blocked - too high
```

## 🎯 Compliant Deployment Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: compliant-app
  labels:
    team: "platform"       # ✅ Required by require-labels
spec:
  template:
    spec:
      containers:
      - name: app
        image: nginx:1.25.3  # ✅ Specific version (not latest)
        resources:
          limits:
            cpu: "200m"      # ✅ Between 100m-4000m (enforce-cpu-limits)
            memory: "256Mi"  # ✅ Required by require-resource-limits
```

This deployment satisfies all four platform policies and will be accepted.

## 🔧 Policy Management

**View active policies:**
```bash
kubectl get clusterpolicies
```

**Apply platform policies:**
```bash
kubectl apply -f platform-policies.yaml
```

**Remove policies (use with caution):**
```bash
kubectl delete -f platform-policies.yaml
```

## 📋 Policy Violations

When a policy is violated, you'll see a detailed error message:
```
error: admission webhook "validate.kyverno.svc-fail" denied the request:
resource Deployment/default/bad-app was blocked due to the following policies
```

The error will specify:
- Which policy was violated
- What rule failed
- The exact requirement needed

## 🎯 Platform Philosophy

These policies enforce:
- **🔐 Security**: No latest tags, proper labeling
- **📊 Observability**: Required labels for monitoring
- **🚀 Reliability**: Resource limits prevent resource starvation
- **🎯 Governance**: Consistent standards across the platform

## 🛠️ Customization

To modify policies for your environment:
1. Edit `platform-policies.yaml`
2. Apply changes: `kubectl apply -f platform-policies.yaml`
3. Test with sample deployments

Platform policies ensure consistent, secure, and observable deployments! 🚀 