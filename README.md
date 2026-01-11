# EKS Cluster with Karpenter Autoscaling

This Terraform repository deploys a production-ready Amazon EKS cluster with Karpenter autoscaling, supporting both x86 (AMD64) and ARM64 (Graviton) workloads. The cluster is deployed into a dedicated VPC using the official Terraform AWS modules by Anton Babenko.

## Overview

This repository provides a complete Infrastructure as Code (IaC) solution for deploying a production-ready Amazon EKS cluster with the following capabilities:

- **Automated Cluster Deployment**: Complete EKS cluster setup with dedicated VPC, subnets, and networking
- **Karpenter Autoscaling**: Automatic node provisioning based on pod requirements
- **Multi-Architecture Support**: Run workloads on both x86 (AMD64) and ARM64 (Graviton) instances
- **Cost Optimization**: Smart instance selection with support for Spot instances

### Who Should Use This?

- **Platform/Infrastructure Teams**: Deploy and manage the EKS cluster infrastructure
- **Developers**: Deploy applications that automatically run on cost-optimized compute resources

### How It Works

1. **Platform Team**: Uses Terraform to deploy the EKS cluster with Karpenter
2. **Developers**: Deploy Kubernetes workloads with simple node selectors
3. **Karpenter**: Automatically provisions the right instance types (x86 or ARM, Spot or On-Demand)
4. **Result**: Applications run on optimal infrastructure with automatic scaling and cost savings

## Architecture

The infrastructure includes:

- **VPC**: A dedicated VPC with configurable CIDR block
- **Subnets**: Public and private subnets across multiple availability zones (default: 3)
- **NAT Gateways**: One NAT Gateway per availability zone for high availability
- **Internet Gateway**: For public subnet internet access
- **EKS Cluster**: Latest Kubernetes version (default: 1.34)
- **EKS Managed Node Group**: Auto-scaling node group in private subnets
- **Essential Add-ons**: CoreDNS, kube-proxy, VPC CNI, and EKS Pod Identity Agent
- **Karpenter v1.8.3**: Advanced Kubernetes autoscaler with two NodePools:
  - **x86 NodePool**: Supports AMD64 architecture (Spot and On-Demand)
  - **ARM NodePool**: Supports ARM64 architecture (Spot and On-Demand)

## Prerequisites

- Terraform >= 1.5.7
- AWS CLI configured with appropriate credentials
- kubectl (for cluster access after deployment)

## Terraform Providers

This configuration uses the following Terraform providers:

- [hashicorp/aws](https://registry.terraform.io/providers/hashicorp/aws) (~> 6.0)
- [hashicorp/helm](https://registry.terraform.io/providers/hashicorp/helm) (~> 3.0)
- [gavinbunney/kubectl](https://registry.terraform.io/providers/gavinbunney/kubectl) (~> 1.19)

## Infrastructure Deployment

Follow these steps to deploy the EKS cluster infrastructure:

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review and Customize Variables

Create a `terraform.tfvars` file to customize the deployment:

```hcl
aws_region               = "eu-central-1"
cluster_name             = "test"
kubernetes_version       = "1.34"
vpc_cidr                 = "10.5.0.0/16"
availability_zones_count = 3
environment              = "test"
instance_types           = ["t3.medium"]
min_size                 = 1
max_size                 = 5
desired_size             = 2
enable_karpenter         = true
karpenter_version        = "1.8.3"
```

### 3. Plan the Deployment

```bash
terraform plan
```

### 4. Apply the Configuration

```bash
terraform apply
```

Confirm with `yes` when prompted.

### 5. Configure kubectl

After successful deployment, configure kubectl to access your cluster:

```bash
aws eks update-kubeconfig --region <your-region> --name <your-cluster-name>
```

Or use the output command:

```bash
terraform output -raw configure_kubectl | bash -
```

### 6. Verify Cluster Access

```bash
kubectl get nodes
kubectl get pods -A
```

### 7. Verify Karpenter Installation

```bash
# Check Karpenter pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=karpenter

# View NodePools
kubectl get nodepools

# View EC2NodeClasses
kubectl get ec2nodeclasses
```

---

## Developer Guide: Running Workloads on x86 or Graviton Instances

Once the cluster is deployed, developers can easily deploy applications to run on specific CPU architectures. Karpenter will automatically provision the appropriate instance types based on the pod requirements.

### Running on x86 (AMD64) Instances

To deploy a workload on x86 instances, use the `cpu-architecture: x86` node selector:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-x86-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-x86-app
  template:
    metadata:
      labels:
        app: my-x86-app
    spec:
      nodeSelector:
        cpu-architecture: x86
      containers:
      - name: app
        image: nginx:latest
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
```

**Deploy the application:**

```bash
kubectl apply -f my-x86-app.yaml
```

**Verify the pods are running on x86 nodes:**

```bash
kubectl get pods -l app=my-x86-app -o wide
kubectl get nodes -l cpu-architecture=x86
```

### Running on Graviton (ARM64) Instances

To deploy a workload on Graviton (ARM64) instances, use the `cpu-architecture: arm` node selector:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-arm-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-arm-app
  template:
    metadata:
      labels:
        app: my-arm-app
    spec:
      nodeSelector:
        cpu-architecture: arm
      containers:
      - name: app
        image: nginx:latest  # Make sure the image supports ARM64
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
```

**Deploy the application:**

```bash
kubectl apply -f my-arm-app.yaml
```

**Verify the pods are running on ARM nodes:**

```bash
kubectl get pods -l app=my-arm-app -o wide
kubectl get nodes -l cpu-architecture=arm
```

### Using Spot Instances

To request Spot instances specifically (for cost savings on non-critical workloads), add the `karpenter.sh/capacity-type` node selector:

```yaml
spec:
  template:
    spec:
      nodeSelector:
        cpu-architecture: x86
        karpenter.sh/capacity-type: spot
```

### Multi-Architecture Deployment

For workloads that support both architectures, you can omit the architecture selector and let Karpenter choose the most cost-effective option:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-multiarch-app
spec:
  replicas: 5
  selector:
    matchLabels:
      app: my-multiarch-app
  template:
    metadata:
      labels:
        app: my-multiarch-app
    spec:
      # No nodeSelector - Karpenter will choose based on availability and cost
      containers:
      - name: app
        image: myregistry/my-multiarch-image:latest  # Must be a multi-arch image
        resources:
          requests:
            cpu: "250m"
            memory: "256Mi"
```

### How Karpenter Works

When you deploy a pod with specific requirements:

1. **Pod is created** with resource requests and node selectors
2. **Karpenter detects** the pending pod and its requirements
3. **Node is provisioned** automatically with the appropriate instance type (x86 or ARM)
4. **Pod is scheduled** on the new node within seconds
5. **Node is removed** automatically when no longer needed (after 1 minute of being empty)

### Checking Node Provisioning

Watch Karpenter provision nodes in real-time:

```bash
# Watch Karpenter logs
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter -f

# Watch nodes being created
kubectl get nodes -w

# Check which NodePool provisioned nodes
kubectl get nodes -L karpenter.sh/nodepool
```

### Important Notes for Developers

1. **Image Compatibility**: Ensure your container images support the target architecture
   - For ARM workloads, use multi-arch images or ARM64-specific images
   - Check Docker Hub or your registry for architecture support

2. **Resource Requests**: Always specify resource requests for proper scheduling
   - Karpenter uses requests to determine the right instance size

3. **Node Labels**: Available node selectors:
   - `cpu-architecture: x86` or `cpu-architecture: arm`
   - `karpenter.sh/capacity-type: spot` or `karpenter.sh/capacity-type: on-demand`
   - `workload-type: general`

4. **Cost Optimization**:
   - ARM (Graviton) instances typically cost 20% less than x86
   - Spot instances can save up to 90% compared to On-Demand

---

## Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| aws_region | AWS region to deploy resources | string | eu-central-1 |
| cluster_name | Name of the EKS cluster | string | tech_assig |
| kubernetes_version | Kubernetes version (1.34 is latest as of Jan 2025) | string | 1.34 |
| vpc_cidr | CIDR block for VPC | string | 10.5.0.0/16 |
| availability_zones_count | Number of AZs to use | number | 3 |
| environment | Environment name | string | production |
| instance_types | Instance types for node group | list(string) | ["t3.medium"] |
| min_size | Minimum nodes | number | 1 |
| max_size | Maximum nodes | number | 5 |
| desired_size | Desired nodes | number | 2 |
| enable_karpenter | Enable Karpenter autoscaler | bool | true |
| karpenter_version | Version of Karpenter to install | string | 1.8.3 |
| karpenter_x86_cpu_limit | Maximum CPU for x86 node pool | string | 1000 |
| karpenter_x86_memory_limit | Maximum memory for x86 node pool | string | 1000Gi |
| karpenter_arm_cpu_limit | Maximum CPU for ARM node pool | string | 1000 |
| karpenter_arm_memory_limit | Maximum memory for ARM node pool | string | 1000Gi |

## Outputs

After deployment, the following information will be available:

- `cluster_endpoint`: EKS cluster API endpoint
- `cluster_name`: Name of the EKS cluster
- `cluster_version`: Kubernetes version
- `vpc_id`: VPC ID
- `private_subnets`: Private subnet IDs
- `public_subnets`: Public subnet IDs
- `configure_kubectl`: Command to configure kubectl
- `karpenter_irsa_arn`: IAM role ARN for Karpenter IRSA
- `karpenter_instance_profile_name`: Instance profile for Karpenter nodes
- `karpenter_node_iam_role_name`: IAM role name for Karpenter nodes
- `karpenter_queue_name`: SQS queue for interruption handling

View outputs:

```bash
terraform output
```

## Modules Used

This configuration uses the official Terraform AWS modules:

- [terraform-aws-modules/vpc/aws](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws) (~> 6.0)
- [terraform-aws-modules/eks/aws](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws) (~> 21.0)
- [terraform-aws-modules/eks/aws//modules/karpenter](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest/submodules/karpenter) (~> 21.0)


## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Confirm with `yes` when prompted.

## Security Best Practices

- The cluster endpoint is publicly accessible but authenticated
- Worker nodes are deployed in private subnets
- Security groups are automatically configured
- IAM roles follow the principle of least privilege
- Consider enabling cluster encryption and logging for production use

## Troubleshooting

### Issue: Unable to connect to cluster

Ensure your AWS credentials have the necessary permissions and that the cluster creator admin permissions are enabled (default in this configuration).

### Issue: Nodes not joining cluster

Check the node group status and IAM roles. The configuration includes all required IAM policies.

### Issue: Timeout during apply

EKS cluster creation takes 10-15 minutes. NAT Gateways also take several minutes to become available.

## License

This configuration is provided as-is for use in your AWS infrastructure.