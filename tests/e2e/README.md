# Platform Vibez E2E Tests

Comprehensive end-to-end tests for the Platform Vibez Kubernetes platform, organized by functional categories for better maintainability and targeted testing.

## 🗂️ Test Organization

Our tests are organized into logical categories to improve maintainability, debugging, and development workflow:

```
tests/e2e/
├── policies/                          # 🛡️ Platform Governance Tests
│   ├── require-labels-policy-test.yaml
│   ├── disallow-latest-tag-policy-test.yaml
│   ├── require-resource-limits-policy-test.yaml
│   └── enforce-cpu-limits-policy-test.yaml
├── application/                       # 🚀 Helm Chart Application Tests
│   ├── basic-deployment-test.yaml
│   ├── ingress-tests.yaml
│   ├── autoscaling-tests.yaml
│   └── resource-management-tests.yaml
├── integration/                       # 🔗 Full-Stack Integration Tests
│   └── (future integration tests)
├── validation/                        # ✅ Input Validation & Edge Cases
│   ├── validation-tests.yaml
│   └── edge-cases-tests.yaml
├── test-runner.sh                     # Smart test runner with category support
├── chainsaw.yaml                      # Chainsaw configuration
└── README.md                          # This documentation
```

## 🧪 Test Categories

### 🛡️ Platform Governance Tests (`policies/`)

Tests that validate platform security and governance policies enforced by Kyverno:

- **require-labels-policy-test.yaml** - Ensures all deployments have required team labels
- **disallow-latest-tag-policy-test.yaml** - Blocks deployments using `:latest` tags
- **require-resource-limits-policy-test.yaml** - Enforces CPU and memory resource limits
- **enforce-cpu-limits-policy-test.yaml** - Validates CPU limits are within platform boundaries (100m-4000m)

**Purpose**: Prevent common operational issues like resource starvation, unknown deployment ownership, and unstable image tags.

### 🚀 Helm Chart Application Tests (`application/`)

Tests that validate the generic-app Helm chart functionality:

- **basic-deployment-test.yaml** - Core deployment functionality and health checks
- **ingress-tests.yaml** - External access configuration and routing
- **autoscaling-tests.yaml** - Horizontal Pod Autoscaler configuration
- **resource-management-tests.yaml** - Resource requests, limits, and platform defaults

**Purpose**: Ensure the Helm chart works correctly for typical application deployment scenarios.

### 🔗 Full-Stack Integration Tests (`integration/`)

Tests that validate complete workflows across multiple components:

- **Future**: End-to-end application deployment with monitoring
- **Future**: Policy enforcement + application deployment workflows  
- **Future**: Ingress + TLS + monitoring integration

**Purpose**: Catch integration issues that unit tests might miss.

### ✅ Input Validation & Edge Cases (`validation/`)

Tests that validate error handling and boundary conditions:

- **validation-tests.yaml** - Input validation and error handling
- **edge-cases-tests.yaml** - Boundary conditions and unusual scenarios

**Purpose**: Ensure platform gracefully handles invalid inputs and edge cases.

## 🚀 Running Tests

### Smart Test Runner

Use the enhanced test runner for organized, targeted testing:

```bash
# Run all tests
./test-runner.sh

# Run specific category
./test-runner.sh policies
./test-runner.sh application
./test-runner.sh validation

# Run with verbose output
./test-runner.sh -v policies
./test-runner.sh --verbose application

# Show help
./test-runner.sh --help
```

### Category-Specific Testing

**Policy Development Workflow:**
```bash
# When developing/debugging policies
./test-runner.sh policies

# When adding new governance rules
./test-runner.sh policies -v
```

**Application Development Workflow:**
```bash
# When updating the Helm chart
./test-runner.sh application

# When adding new chart features
./test-runner.sh application -v
```

**Validation Workflow:**
```bash
# When implementing error handling
./test-runner.sh validation

# When testing edge cases
./test-runner.sh validation -v
```

### Manual Testing

You can also run individual tests directly:

```bash
# Test specific policy
chainsaw test --config chainsaw.yaml --test-file policies/require-labels-policy-test.yaml

# Test specific application feature
chainsaw test --config chainsaw.yaml --test-file application/autoscaling-tests.yaml
```

## 📊 Test Results

The test runner provides clear categorized results:

```
📊 Test Results Summary
=======================
  Total tests: 10
  Passed: 10
  Failed: 0

✅ All tests passed! 🎉
```

## 🔧 Adding New Tests

### Policy Tests

When adding new Kyverno policies:

1. Create policy YAML in `../../policies/`
2. Add policy test in `policies/[policy-name]-policy-test.yaml`
3. Test with: `./test-runner.sh policies`

### Application Tests

When adding new Helm chart features:

1. Update chart in `../../helm-charts/generic-app/`
2. Add test in `application/[feature-name]-tests.yaml`
3. Test with: `./test-runner.sh application`

### Validation Tests

When adding error handling or edge cases:

1. Add test in `validation/[scenario-name]-tests.yaml`
2. Test with: `./test-runner.sh validation`

## 🎯 Test Design Principles

### 1. Single Responsibility
Each test file has one clear purpose - testing a specific policy, feature, or scenario.

### 2. Isolated Tests
Tests don't depend on each other and can run in parallel safely.

### 3. Descriptive Names
Test files clearly indicate what they test:
- `require-labels-policy-test.yaml` - Tests the require-labels policy
- `autoscaling-tests.yaml` - Tests autoscaling functionality
- `edge-cases-tests.yaml` - Tests edge cases and boundary conditions

### 4. Proper Cleanup
All tests clean up resources in `finally` blocks to prevent interference.

### 5. Clear Success/Failure Criteria
Tests have explicit assertions and clear pass/fail conditions.

## 🏗️ Test Architecture

### Chainsaw Configuration
- **Configuration**: `chainsaw.yaml`
- **Timeout**: 30 seconds for assertions
- **Cleanup**: 30 seconds for resource cleanup
- **Parallel**: Up to 4 concurrent tests

### Test Structure
Each test follows this pattern:
```yaml
apiVersion: chainsaw.kyverno.io/v1alpha1
kind: Test
metadata:
  name: descriptive-test-name
spec:
  description: Clear description of what is being tested
  steps:
  - name: test-step-name
    try:
    - description: What this step does
      # Test implementation
    finally:
    - description: Cleanup actions
      # Cleanup implementation
```

## 🐛 Debugging Test Failures

### View Detailed Output
```bash
# Run with verbose output to see all details
./test-runner.sh -v policies

# Run specific failing test
chainsaw test --config chainsaw.yaml --test-file policies/failing-test.yaml
```

### Common Issues
1. **Resource conflicts**: Tests not cleaning up properly
2. **Policy timing**: Kyverno policies not yet active
3. **Namespace issues**: Tests interfering with each other
4. **Image pull issues**: Network problems affecting test images

### Debugging Tips
1. Run tests individually to isolate issues
2. Check Kubernetes events: `kubectl get events`
3. Check policy status: `kubectl get clusterpolicies`
4. Verify test namespace cleanup: `kubectl get namespaces`

## 📚 Background

This organized structure replaces the previous flat file organization that had become difficult to maintain. The new structure provides:

- **Better maintainability** - Clear separation of concerns
- **Improved debugging** - Targeted test execution
- **Easier development** - Clear places for new tests
- **Professional organization** - Industry standard test structure

The reorganization maintains all existing test functionality while providing a foundation for future growth and easier maintenance. 