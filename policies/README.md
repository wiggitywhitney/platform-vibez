# Platform Vibez - Governance Policies

This directory contains Kyverno policies that enforce platform governance, security, and resource management standards.

## Policies

### 🏷️ require-labels.yaml
**Category:** Platform Governance  
**Purpose:** Ensures all deployments have required platform labels for observability and governance.  
**Enforces:** Deployments must have a `team` label

### 🔒 disallow-latest-tag.yaml
**Category:** Platform Security  
**Purpose:** Prevents use of 'latest' tag in container images for reproducible deployments.  
**Enforces:** Container images must specify version tags (no `:latest`)

### 📊 require-resource-limits.yaml
**Category:** Platform Resources  
**Purpose:** Ensures all containers have CPU and memory limits for resource management.  
**Enforces:** All containers must specify `cpu` and `memory` limits

### ⚡ enforce-cpu-limits.yaml
**Category:** Platform Resources  
**Purpose:** Ensures CPU limits are within platform bounds to prevent resource hogging.  
**Enforces:** CPU limits must be between 100m and 4000m (0.1 to 4 cores)

## Application

These policies are automatically applied during cluster setup via the `setup-k8s-cluster.sh` script.

To manually apply all policies:
```bash
kubectl apply -f policies/
```

To apply a specific policy:
```bash
kubectl apply -f policies/require-labels.yaml
```

## Validation

All policies use `validationFailureAction: Enforce` which means they will:
- ✅ Block deployments that violate policies
- 🔍 Run validation on existing resources (background scanning)
- 📝 Provide clear error messages when violations occur 