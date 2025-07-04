# Generic App Helm Chart - Comprehensive Test Suite

This directory contains comprehensive end-to-end tests for the simplified generic-app Helm chart using Kyverno Chainsaw.

## Test Structure

### 🧪 Test Categories

1. **Basic Deployment** (`chainsaw-test.yaml`)
   - Proves the simplified chart works
   - Validates core functionality
   - Tests resource auto-calculation
   - Verifies health checks

2. **Validation Tests** (`02-validation-tests/`)
   - Platform guardrails enforcement
   - "latest" tag prevention
   - Resource limit validation
   - Autoscaling boundary checks

3. **Ingress Tests** (`03-ingress-tests/`)
   - Ingress disabled/enabled scenarios
   - TLS configuration with cert-manager
   - Platform-managed defaults (nginx class, paths)
   - Multiple host configurations

4. **Autoscaling Tests** (`04-autoscaling-tests/`)
   - HPA creation and configuration
   - Platform-enforced metrics (75% CPU/Memory)
   - High availability scenarios
   - Custom replica configurations

5. **Platform-Managed Tests** (`05-platform-managed-tests/`)
   - Service auto-creation with port sync
   - Security contexts (hidden from users)
   - Health checks (mandatory)
   - Resource auto-calculation (50% requests)
   - Environment variables

6. **Edge Cases Tests** (`06-edge-cases-tests/`)
   - Required field validation
   - Boundary value testing
   - Port edge cases
   - Upgrade scenarios
   - Complex health check paths

## 🚀 Running Tests

### Run All Tests
```bash
cd tests/e2e
chainsaw test --test-dir .
```

### Run Specific Test Category
```bash
# Basic functionality
chainsaw test --test-dir . --include-test-regex "basic-deployment"

# Validation tests
chainsaw test --test-dir 02-validation-tests

# Ingress tests  
chainsaw test --test-dir 03-ingress-tests

# Autoscaling tests
chainsaw test --test-dir 04-autoscaling-tests

# Platform-managed features
chainsaw test --test-dir 05-platform-managed-tests

# Edge cases
chainsaw test --test-dir 06-edge-cases-tests
```

### Run Tests with Verbose Output
```bash
chainsaw test --test-dir . -v
```

## 📊 Test Coverage

Our comprehensive test suite validates:

### ✅ Platform Guardrails
- **Latest Tag Prevention**: Blocks `latest` tags in repository or tag fields
- **Resource Limits**: Enforces CPU (100m-4000m) and Memory (128Mi-8192Mi) boundaries
- **Autoscaling Bounds**: Validates minReplicas (1-10) and maxReplicas (2-20)

### ✅ Platform-Managed Features
- **Service Auto-Creation**: Always creates ClusterIP service with port sync
- **Security Contexts**: Hidden from users, platform-managed
- **Health Checks**: Mandatory HTTP probes for liveness and readiness
- **Resource Auto-Calc**: Requests = 50% of limits automatically

### ✅ Ingress Simplification
- **Platform Defaults**: Hardcoded nginx class, "/" path, "Prefix" pathType
- **TLS Integration**: Cert-manager with letsencrypt-prod issuer
- **Auto-Generated Secrets**: TLS secret names from release name + "-tls"

### ✅ User Experience
- **Required Fields**: Only expose essential configuration
- **Port Sync**: Single source of truth (container.port)
- **Environment Variables**: Optional and flexible
- **Upgrade Safety**: Maintains platform features across upgrades

### ✅ Edge Cases
- **Boundary Values**: Min/max resource configurations
- **Port Variations**: Different port numbers and protocols
- **Health Check Paths**: Various endpoint formats
- **Upgrade Scenarios**: Version and configuration changes

## 🎯 Test Philosophy

### Platform-Opinionated Testing
- **Reduce Configuration Surface**: Test that complex fields are hidden
- **Enforce Guardrails**: Validate platform prevents dangerous configurations
- **Auto-Calculate Values**: Verify smart defaults work correctly
- **Mandatory Features**: Ensure security and reliability features are enforced

### Comprehensive Coverage
- **Happy Path**: Normal usage scenarios work correctly
- **Error Cases**: Invalid configurations fail gracefully
- **Edge Cases**: Boundary conditions and unusual inputs
- **Integration**: Features work together seamlessly

## 📈 Benefits

1. **Regression Prevention**: Catch breaking changes early
2. **Platform Validation**: Ensure guardrails work as designed
3. **User Experience**: Verify simplified interface functions correctly
4. **Documentation**: Tests serve as living examples
5. **Confidence**: Deploy changes with assurance

## 🛠️ Prerequisites

- Kubernetes cluster (kind, minikube, etc.)
- Helm 3.x installed
- Kyverno Chainsaw installed
- kubectl configured for cluster access

## 🔧 Adding New Tests

1. Create new test directory: `tests/e2e/XX-new-category-tests/`
2. Add `chainsaw-test.yaml` with test specification
3. Follow existing patterns for consistency
4. Update this README with new test category

## 📝 Test Naming Convention

- **Test Files**: `chainsaw-test.yaml` (required by Chainsaw)
- **Test Names**: Descriptive kebab-case (e.g., `basic-deployment`)
- **Step Names**: Action-oriented (e.g., `test-ingress-enabled`)
- **Descriptions**: Clear purpose statements

## 🎪 Example Test Run

```
=== RUN   chainsaw
=== RUN   chainsaw/basic-deployment
    | 15:39:52 | basic-deployment | @chainsaw    | CREATE    | OK    | v1/Namespace @ chainsaw-quality-joey
    | 15:39:56 | basic-deployment | deploy-chart | SCRIPT    | DONE  |
    | 15:39:56 | basic-deployment | deploy-chart | ASSERT    | DONE  | apps/v1/Deployment
    | 15:39:56 | basic-deployment | deploy-chart | ASSERT    | DONE  | v1/Pod
    | 15:39:57 | basic-deployment | deploy-chart | ASSERT    | DONE  | v1/Service
--- PASS: chainsaw/basic-deployment (14.94s)
PASS
```

The test suite ensures our simplified Helm chart delivers on the promise of **reduced complexity without sacrificing functionality**! 🎉 