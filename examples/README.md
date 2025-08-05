# ACK (AWS Controllers for Kubernetes) Examples

This directory contains example configurations for AWS Controllers for Kubernetes (ACK) demonstrating how to manage AWS resources directly from Kubernetes.

## Prerequisites

1. **ACK Controllers Installed**: Run `./setup-k8s-cluster.sh` to install ACK controllers
2. **AWS Credentials**: Update the `aws-credentials` secret in `ack-system` namespace with your real AWS credentials
3. **Valid AWS Resources**: Replace placeholder values (AMI IDs, subnet IDs, etc.) with actual AWS resource IDs

## Examples

### EC2 Resources
- **`ack-example-instance.yaml`**: Creates an EC2 instance with user data
- **`ack-example-vpc.yaml`**: Creates a VPC and subnet with proper networking

### IAM Resources
- **`ack-example-iam.yaml`**: Creates IAM roles and policies

## Usage

⚠️ **IMPORTANT**: Before applying these examples:

1. **Update AWS credentials**:
   ```bash
   # See docs/ACK-SETUP.md for detailed instructions
   kubectl patch secret aws-credentials -n ack-system --patch='{"data":{"credentials":"<base64-encoded-credentials>"}}'
   kubectl rollout restart deployment -n ack-system
   ```

2. **Replace placeholder values** in the YAML files:
   - AMI IDs (find current AMI IDs for your region)
   - Subnet IDs and VPC IDs
   - Security Group IDs
   - Key pair names

3. **Apply the configurations**:
   ```bash
   # Create IAM resources first
   kubectl apply -f examples/ack-example-iam.yaml
   
   # Create networking resources
   kubectl apply -f examples/ack-example-vpc.yaml
   
   # Create EC2 instance (update subnet ID first)
   kubectl apply -f examples/ack-example-instance.yaml
   ```

4. **Verify resources**:
   ```bash
   # Check Kubernetes resources
   kubectl get instances,vpcs,subnets,roles,policies
   
   # Check AWS Console
   # Verify resources were created in AWS EC2 and IAM dashboards
   ```

## Policy Compliance

All ACK resources will be automatically validated by the Kyverno policy `enforce-aws-us-east-1-region` to ensure they use the us-east-1 region for compliance.

## Cleanup

```bash
# Delete ACK resources (this will delete AWS resources too!)
kubectl delete -f examples/ack-example-instance.yaml
kubectl delete -f examples/ack-example-vpc.yaml  
kubectl delete -f examples/ack-example-iam.yaml
```

⚠️ **WARNING**: Deleting ACK resources in Kubernetes will also delete the corresponding AWS resources!

## Learn More

- [ACK Documentation](https://aws-controllers-k8s.github.io/community/)
- [Platform Vibez ACK Setup Guide](../docs/ACK-SETUP.md)
- [EC2 ACK Controller Reference](https://aws-controllers-k8s.github.io/community/reference/)
- [IAM ACK Controller Reference](https://aws-controllers-k8s.github.io/community/reference/) 