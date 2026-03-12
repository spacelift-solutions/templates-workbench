##############################################################################
# Spacelift Private Worker Pool on AWS EC2
#
# This creates:
#   1. A spacelift_worker_pool resource (generates token + private key)
#   2. An EC2 Auto Scaling Group via the official Spacelift module
#   3. A Lambda autoscaler that scales workers based on queue depth
#
# Credentials flow directly from the spacelift_worker_pool resource —
# no manual openssl, no base64 encoding, no copy-paste.
##############################################################################

terraform {
  required_providers {
    spacelift = {
      source = "spacelift-io/spacelift"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

# ------------------------------------------------------------------------------
# Variables — exposed as template inputs via TF_VAR_ env vars
# ------------------------------------------------------------------------------

variable "worker_pool_name" {
  type        = string
  description = "Name for the Spacelift worker pool"
  default     = "aws-ec2-workers"
}

variable "worker_pool_description" {
  type        = string
  description = "Description for the worker pool"
  default     = "Private worker pool on AWS EC2"
}

variable "ec2_instance_type" {
  type        = string
  description = "EC2 instance type for workers"
  default     = "t3.medium"
}

variable "min_size" {
  type        = number
  description = "Minimum number of workers in the ASG"
  default     = 1
}

variable "max_size" {
  type        = number
  description = "Maximum number of workers in the ASG"
  default     = 3
}

variable "vpc_subnet_ids" {
  type        = list(string)
  description = "List of VPC subnet IDs where workers will be deployed"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs to attach to workers"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy workers in"
  default     = "us-east-1"
}

variable "spacelift_api_key_endpoint" {
  type        = string
  description = "Spacelift API endpoint (e.g., https://myaccount.app.spacelift.io)"
}

variable "spacelift_api_key_id" {
  type        = string
  description = "Spacelift API key ID for the autoscaler Lambda"
}

variable "spacelift_api_key_secret" {
  type        = string
  description = "Spacelift API key secret for the autoscaler Lambda"
  sensitive   = true
}

variable "space_id" {
  type        = string
  description = "Spacelift Space ID where the worker pool will be created"
  default     = "root"
}

# ------------------------------------------------------------------------------
# Provider
# ------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------------------------------------
# Worker Pool
#
# Creates the pool in Spacelift and auto-generates:
#   .config      = the SPACELIFT_TOKEN (ready to use)
#   .private_key = the SPACELIFT_POOL_PRIVATE_KEY (already base64-encoded)
#
# This eliminates the manual openssl + base64 workflow entirely.
# ------------------------------------------------------------------------------

resource "spacelift_worker_pool" "this" {
  name        = var.worker_pool_name
  description = var.worker_pool_description
  space_id    = var.space_id
}

# ------------------------------------------------------------------------------
# EC2 Worker Pool Module (v5.5.0)
#
# Uses the official Spacelift module:
#   github.com/spacelift-io/terraform-aws-spacelift-workerpool-on-ec2
#
# v5.x requires AWS provider >= 6.0.0
# For AWS provider 5.x environments, use module version v4.4.4 instead.
#
# What this creates:
#   - Launch Template with Spacelift AMI (CloudWatch Agent pre-installed)
#   - Auto Scaling Group
#   - Lambda function (autoscaler) + CloudWatch schedule
#   - Secrets Manager entries for token + private key
#   - IAM roles for EC2 instances and Lambda
# ------------------------------------------------------------------------------

module "ec2_workers" {
  source = "github.com/spacelift-io/terraform-aws-spacelift-workerpool-on-ec2?ref=v5.5.0"

  # Credentials — passed directly from the spacelift_worker_pool resource.
  # No manual base64. No copy-paste. No whitespace issues.
  secure_env_vars = {
    SPACELIFT_TOKEN            = spacelift_worker_pool.this.config
    SPACELIFT_POOL_PRIVATE_KEY = spacelift_worker_pool.this.private_key
  }

  configuration = <<-EOF
    export SPACELIFT_SENSITIVE_OUTPUT_UPLOAD_ENABLED=true
  EOF

  # EC2 / ASG settings
  ec2_instance_type = var.ec2_instance_type
  min_size          = var.min_size
  max_size          = var.max_size
  worker_pool_id    = spacelift_worker_pool.this.id
  security_groups   = var.security_group_ids
  vpc_subnets       = var.vpc_subnet_ids

  # Autoscaler — Lambda that queries Spacelift queue and adjusts ASG
  spacelift_api_credentials = {
    api_key_endpoint = var.spacelift_api_key_endpoint
    api_key_id       = var.spacelift_api_key_id
    api_key_secret   = var.spacelift_api_key_secret
  }

  autoscaling_configuration = {
    max_create          = 3
    max_terminate       = 3
    schedule_expression = "rate(1 minute)"
    timeout             = 60
  }
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------

output "worker_pool_id" {
  value       = spacelift_worker_pool.this.id
  description = "The ID of the created worker pool — use this in stack settings"
}

output "worker_pool_name" {
  value       = spacelift_worker_pool.this.name
  description = "Name of the worker pool"
}
