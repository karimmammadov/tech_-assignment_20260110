variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "my-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.5.0.0/16"
}

variable "availability_zones_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 3
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "test"
}

variable "instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 5
}

variable "desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

# Karpenter Variables
variable "enable_karpenter" {
  description = "Enable Karpenter autoscaler"
  type        = bool
  default     = true
}

variable "karpenter_version" {
  description = "Version of Karpenter to install"
  type        = string
  default     = "1.8.3"
}

variable "karpenter_x86_cpu_limit" {
  description = "Maximum CPU resources for x86 node pool"
  type        = string
  default     = "1000"
}

variable "karpenter_x86_memory_limit" {
  description = "Maximum memory resources for x86 node pool"
  type        = string
  default     = "1000Gi"
}

variable "karpenter_arm_cpu_limit" {
  description = "Maximum CPU resources for ARM node pool"
  type        = string
  default     = "1000"
}

variable "karpenter_arm_memory_limit" {
  description = "Maximum memory resources for ARM node pool"
  type        = string
  default     = "1000Gi"
}
