terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Configure this with your own S3 bucket
    # bucket = "your-terraform-state-bucket"
    # key    = "container-security/terraform.tfstate"
    # region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Container-Security-Pipeline"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  environment        = var.environment
  repository_name    = var.ecr_repository_name
  image_scan_enabled = true
  encryption_type    = "KMS"
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"

  environment          = var.environment
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  ecr_repository_url  = module.ecr.repository_url
  container_name      = "flask-app"
  container_port      = 5000
  cpu                 = "256"
  memory              = "512"
  desired_count       = 2
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/${var.environment}/flask-app"
  retention_in_days = 7

  kms_key_id = aws_kms_key.cloudwatch.arn
}

# KMS Key for CloudWatch Logs
resource "aws_kms_key" "cloudwatch" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/${var.environment}-cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch.key_id
}

# Security Hub (Optional - for advanced security monitoring)
resource "aws_securityhub_account" "main" {
  count = var.enable_security_hub ? 1 : 0
}