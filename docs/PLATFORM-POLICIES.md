# Platform Vibez - Governance Policies

This document describes the 4 governance policies that prevent common Kubernetes deployment problems.

> **✅ Status**: All policies are working correctly! Recent fixes resolved the "Pods can't be created" bug where the latest-tag policy was incorrectly targeting Pod resources instead of just Deployments.

## Problems These Policies Solve

Platform policies fix four specific deployment problems that break things in real environments:

1. **"Who owns this broken deployment?"** - Teams deploy apps without labels, making it impossible to track ownership when things break
2. **"Why did my app suddenly change behavior?"** - Teams use `:latest` tags, making deployments unreproducible when the underlying image changes
3. **"One app is consuming the entire cluster"** - Teams deploy without resource limits, causing resource starvation for other applications
4. **"This app is using 50 CPU cores"** - Teams set unreasonable resource limits that waste cluster resources

## 🛡️ Active Policies

### 1. Require Labels (`require-labels.yaml`)
**Problem**: When deployments break, nobody knows which team owns them  
**Solution**: Forces all deployments to have a `team` label  
**Location**: `policies/require-labels.yaml`

**Example**:
```yaml
metadata:
  labels:
    team: "backend"  # Required - identifies owning team
```

**What happens without this**: A deployment breaks at 2 AM. The on-call engineer can't figure out which team to page because there's no ownership information.

### 2. Disallow Latest Tag (`disallow-latest-tag.yaml`)
**Problem**: Teams use `:latest` tags, making deployments unreproducible when base images change  
**Solution**: Blocks `:latest` tags, requires specific version tags  
**Location**: `policies/disallow-latest-tag.yaml`

**Example**:
```yaml
spec:
  containers:
  - image: nginx:1.25.3  # ✅ Good - specific version, reproducible
  - image: nginx:latest  # ❌ Blocked - could change unexpectedly
```

**What happens without this**: Your app works fine in staging with `nginx:latest`. A month later, nginx publishes a new version with breaking changes. Your app suddenly breaks in production with no code changes.

### 3. Require Resource Limits (`require-resource-limits.yaml`)
**Problem**: Containers without resource limits can consume all cluster resources  
**Solution**: Requires all containers to specify CPU and memory limits  
**Location**: `policies/require-resource-limits.yaml`

**Example**:
```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        resources:
          limits:
            cpu: "500m"     # Required - prevents CPU starvation
            memory: "512Mi" # Required - prevents memory pressure
```

**What happens without this**: One team deploys a memory leak. Their app gradually consumes all available memory, causing every other app on the cluster to crash with OOM errors.

### 4. Enforce CPU Limits (`enforce-cpu-limits.yaml`)
**Problem**: Teams set CPU limits that are either too low (causing throttling) or too high (wasting resources)  
**Solution**: Enforces CPU limits between 100m and 4000m (0.1 to 4 cores)  
**Location**: `policies/enforce-cpu-limits.yaml`

**Example**:
```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        resources:
          limits:
            cpu: "200m"     # ✅ Valid - reasonable for most apps
            # cpu: "50m"    # ❌ Blocked - too low, will cause throttling
            # cpu: "5000m"  # ❌ Blocked - too high, wastes resources
```

**What happens without this**: Team A sets CPU limits to 50m. Their app runs fine in development but becomes completely unresponsive under load due to CPU throttling. Team B sets CPU limits to 32 cores for a simple web service, preventing other teams from scheduling their apps.

## 🎯 Compliant Deployment Example

This deployment satisfies all four platform policies:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: compliant-app
  labels:
    team: "platform"       # ✅ Satisfies require-labels policy
spec:
  template:
    spec:
      containers:
      - name: app
        image: nginx:1.25.3  # ✅ Specific version (satisfies disallow-latest-tag)
        resources:
          limits:
            cpu: "200m"      # ✅ Between 100m-4000m (satisfies enforce-cpu-limits)
            memory: "256Mi"  # ✅ Has memory limit (satisfies require-resource-limits)
```

This deployment will be accepted by all policies and deploy successfully.

## 📁 Policy Organization

Policies are organized in the `policies/` directory:

```
policies/
├── README.md                    # Policy documentation
├── require-labels.yaml          # Team ownership tracking
├── disallow-latest-tag.yaml     # Reproducible deployments
├── require-resource-limits.yaml # Resource management
└── enforce-cpu-limits.yaml      # Resource boundaries
```

Each policy is a separate file for easier maintenance and selective application.

## 🔧 Policy Management

**View active policies:**
```bash
kubectl get clusterpolicies
```

**Apply all platform policies:**
```bash
kubectl apply -f policies/
```

**Apply a specific policy:**
```bash
kubectl apply -f policies/require-labels.yaml
```

**Remove all policies (use with caution):**
```bash
kubectl delete -f policies/
```

**Check policy status:**
```bash
kubectl get clusterpolicies -o custom-columns="NAME:.metadata.name,READY:.status.ready"
```

## 📋 Policy Violations

When a policy is violated, you get a clear error message explaining exactly what to fix:

```
error: admission webhook "validate.kyverno.svc-fail" denied the request:
resource Deployment/default/bad-app was blocked due to the following policies

require-labels:
  check-team-label: Deployment must have a 'team' label
```

The error tells you:
- Which policy was violated (`require-labels`)
- Which rule failed (`check-team-label`)
- Exactly what to add (`team` label)

## 🚀 Automatic Application

Platform policies are automatically applied during cluster setup:

1. **Cluster Setup**: Run `./setup-k8s-cluster.sh`
2. **Kyverno Installation**: Script installs Kyverno policy engine
3. **Policy Application**: Script applies all policies from `policies/` directory
4. **Verification**: Script shows which policies were applied successfully

You don't need to manually apply policies - they're part of the platform setup.

## 🎯 Platform Philosophy

These policies enforce the "pit of success" principle:
- **🔐 Security**: No latest tags, proper labeling for accountability
- **📊 Observability**: Required labels enable monitoring and ownership tracking
- **🚀 Reliability**: Resource limits prevent resource starvation and cluster instability
- **🎯 Governance**: Consistent standards across all teams and applications

## 🛠️ Customization

To modify policies for your environment:

1. **Edit individual policy files** in the `policies/` directory
2. **Apply changes**: `kubectl apply -f policies/`
3. **Test with sample deployments** to verify policy behavior
4. **Update documentation** if you change policy requirements

### Example: Changing CPU Limits
To allow higher CPU limits, edit `policies/enforce-cpu-limits.yaml`:

```yaml
# Change from 4000m to 8000m maximum
value: ["1m", "2m", "5m", "10m", "20m", "25m", "30m", "40m", "50m", "60m", "70m", "80m", "90m", "99m", "8001m", "9000m", "10000m"]
```

Then apply: `kubectl apply -f policies/enforce-cpu-limits.yaml`

## 🧪 Testing Policy Changes

Before applying policy changes to important environments:

1. **Test with sample deployments**:
```bash
# Test a compliant deployment
kubectl apply -f tests/e2e/sample-deployment.yaml

# Test a non-compliant deployment (should be blocked)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bad-app
spec:
  template:
    spec:
      containers:
      - name: app
        image: nginx:latest  # Should be blocked
EOF
```

2. **Run the platform test suite**:
```bash
cd tests/e2e
./test-runner.sh
```

This validates that policies work correctly and don't break legitimate deployments.

Platform governance policies ensure consistent, secure, and observable deployments across your entire Kubernetes platform! 🚀 