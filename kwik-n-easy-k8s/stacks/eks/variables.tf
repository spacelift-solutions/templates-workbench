variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.31"
}

variable "node_instance_type" {
  type        = string
  description = "EC2 instance type for worker nodes"
  default     = "t3.medium"
}

variable "node_count" {
  type        = number
  description = "Number of worker nodes"
  default     = 2
}

variable "multi_az" {
  type        = bool
  description = "Whether to spread nodes across multiple AZs"
  default     = false
}

variable "deletion_protection" {
  type        = bool
  description = "Placeholder for deletion protection tagging"
  default     = false
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}
