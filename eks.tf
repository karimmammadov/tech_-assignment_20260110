module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access  = true
  endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      before_compute = true
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    main = {
      name = "${var.cluster_name}-node-group"

      instance_types = var.instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      update_config = {
        max_unavailable_percentage = 33
      }

      tags = {
        Environment = var.environment
      }
    }
  }

  enable_cluster_creator_admin_permissions = true

  tags = merge(
    {
      Environment = var.environment
      Terraform   = "true"
    },
    var.enable_karpenter ? {
      "karpenter.sh/discovery" = var.cluster_name
    } : {}
  )

  node_security_group_tags = var.enable_karpenter ? {
    "karpenter.sh/discovery" = var.cluster_name
  } : {}
}
