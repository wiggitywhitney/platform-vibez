# AWS Controllers for Kubernetes (ACK) Setup

## Overview
ACK controllers have been installed for:
- **EC2**: 18 resource types (instances, VPCs, subnets, security groups, etc.)
- **IAM**: 7 resource types (roles, policies, users, etc.)

## Controllers Installed
- `ec2-chart-1754397482`: EC2 Controller v1.4.11
- `iam-chart-1754397484`: IAM Controller v1.4.4

## ⚠️ REQUIRED: Update AWS Credentials

The controllers are currently using placeholder credentials and need to be updated with your real AWS credentials.

### Option 1: Update Secret with Real Credentials

```bash
# Create your AWS credentials file
cat > /tmp/aws-credentials << EOF
[default]
aws_access_key_id = YOUR_ACTUAL_ACCESS_KEY
aws_secret_access_key = YOUR_ACTUAL_SECRET_KEY
EOF

# Update the secret
kubectl delete secret aws-credentials -n ack-system
kubectl create secret generic aws-credentials -n ack-system --from-file=credentials=/tmp/aws-credentials
rm /tmp/aws-credentials

# Restart controllers to pick up new credentials
kubectl rollout restart deployment -n ack-system
```

### Option 2: Use IAM Roles for Service Accounts (IRSA) - Recommended for EKS

If you're running on EKS, it's more secure to use IRSA:

```bash
# Create IAM role with necessary policies
# Update controller to use IRSA instead of credentials secret
helm upgrade ec2-chart-1754397482 oci://public.ecr.aws/aws-controllers-k8s/ec2-chart \
  --version="1.4.11" \
  -n ack-system \
  --set aws.region="us-east-1" \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::ACCOUNT:role/ACK-EC2-Role"
```

## Available EC2 Resources

ACK provides native Kubernetes resources for these EC2 services:

### Compute Resources
- `instances.ec2.services.k8s.aws` - EC2 instances
- `launchtemplates.ec2.services.k8s.aws` - Launch templates
- `capacityreservations.ec2.services.k8s.aws` - Capacity reservations

### Networking Resources
- `vpcs.ec2.services.k8s.aws` - Virtual Private Clouds
- `subnets.ec2.services.k8s.aws` - Subnets
- `internetgateways.ec2.services.k8s.aws` - Internet gateways
- `natgateways.ec2.services.k8s.aws` - NAT gateways
- `routetables.ec2.services.k8s.aws` - Route tables
- `securitygroups.ec2.services.k8s.aws` - Security groups
- `networkacls.ec2.services.k8s.aws` - Network ACLs
- `vpcendpoints.ec2.services.k8s.aws` - VPC endpoints
- `elasticipaddresses.ec2.services.k8s.aws` - Elastic IP addresses

### Advanced Networking
- `transitgateways.ec2.services.k8s.aws` - Transit gateways
- `transitgatewayvpcattachments.ec2.services.k8s.aws` - TGW VPC attachments

### Monitoring & Management
- `flowlogs.ec2.services.k8s.aws` - VPC flow logs
- `dhcpoptions.ec2.services.k8s.aws` - DHCP options

## Available IAM Resources

### Access Management
- `roles.iam.services.k8s.aws` - IAM roles
- `policies.iam.services.k8s.aws` - IAM policies
- `users.iam.services.k8s.aws` - IAM users
- `groups.iam.services.k8s.aws` - IAM groups

### Instance & Service Management
- `instanceprofiles.iam.services.k8s.aws` - Instance profiles
- `openidconnectidentityproviders.iam.services.k8s.aws` - OIDC providers
- `rolepolicyattachments.iam.services.k8s.aws` - Role policy attachments

## Example Usage

### Create an EC2 Instance
```yaml
apiVersion: ec2.services.k8s.aws/v1alpha1
kind: Instance
metadata:
  name: my-instance
spec:
  imageID: ami-0abcdef1234567890
  instanceType: t3.micro
  subnetID: subnet-12345
  securityGroupIDs:
  - sg-12345
  tags:
  - key: Name
    value: my-ack-instance
```

### Create a VPC
```yaml
apiVersion: ec2.services.k8s.aws/v1alpha1
kind: VPC
metadata:
  name: my-vpc
spec:
  cidrBlock: "10.0.0.0/16"
  enableDNSHostnames: true
  enableDNSSupport: true
  tags:
  - key: Name
    value: my-ack-vpc
```

## Status Check

```bash
# Check controller status
kubectl get pods -n ack-system

# Check available resources
kubectl api-resources | grep -E "(ec2|iam).services.k8s.aws"

# View controller logs
kubectl logs -n ack-system -l app.kubernetes.io/name=ec2-chart
kubectl logs -n ack-system -l app.kubernetes.io/name=iam-chart
```

## Integration with Existing Policy

Your existing Kyverno policy `enforce-aws-us-east-1-region` will also validate ACK resources to ensure they use the us-east-1 region for compliance. 