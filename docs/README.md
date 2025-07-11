# Platform Vibez Documentation

Welcome to the Platform Vibez documentation! This directory contains comprehensive guides for understanding and using the platform.

## 📚 Available Documentation

### 🛡️ Governance & Policies
- **[Platform Policies](PLATFORM-POLICIES.md)** - Kyverno governance policies enforced cluster-wide

### 🚀 Application Deployment  
- **[Generic App Chart](../helm-charts/generic-app/README.md)** - Opinionated Helm chart for stateless applications

### 🧪 Testing & Validation
- **[E2E Testing](../tests/e2e/README.md)** - Chainsaw test suite for platform validation

## 🎯 Quick Links

### Getting Started
1. **[Main README](../README.md)** - Platform overview and setup instructions
2. **[Generic App Chart](../helm-charts/generic-app/README.md)** - Deploy your first application
3. **[Platform Policies](PLATFORM-POLICIES.md)** - Understand governance requirements

### Platform Management
- **Setup Script**: `../setup-k8s-cluster.sh` - Creates monitored Kubernetes cluster
- **Verification Script**: `../verify-datadog.sh` - Validates monitoring setup
- **Cleanup Script**: `../destroy-k8s-cluster.sh` - Removes cluster

### Configuration Files
- **Datadog Config**: `../datadog-agent.yaml` - Monitoring configuration
- **Platform Policies**: `../platform-policies.yaml` - Governance policies
- **Teller Config**: `../.teller.yml` - Secret management configuration

## 💡 Need Help?

- Check the specific documentation for detailed guidance
- Review example configurations in the repository
- Ensure you understand platform policies before deploying applications

---

**Platform Vibez**: Building delightful developer experiences on Kubernetes 🚀 