provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = "${var.cluster_environment}-cluster-eks-${random_string.suffix.result}"

  should_create_kms_key = var.encryption_type == "KMS" && var.kms_key == null

  encryption_configuration = local.should_create_kms_key ? [{
    encryption_type = "KMS"
    kms_key         = aws_kms_key.kms_key[0].arn
    }] : (var.encryption_type == "KMS" ? [{
      encryption_type = "KMS"
      kms_key         = var.kms_key
  }] : [])

  image_scanning_configuration = [{
    scan_on_push = var.image_scanning_configuration != null ? var.image_scanning_configuration.scan_on_push : var.scan_on_push
  }]

  timeouts = length(var.timeouts) != 0 ? [var.timeouts] : (var.timeouts_delete != null ? [{
    delete = var.timeouts_delete
  }] : [])
}

resource "random_string" "suffix" {
  length  = 12
  special = false
}

resource "aws_kms_key" "kms_key" {
  count       = local.should_create_kms_key ? 1 : 0
  description = "${var.name} KMS key"
}

resource "aws_ecr_repository" "repo" {
  name                 = var.name
  force_delete         = var.force_delete
  image_tag_mutability = var.image_tag_mutability

  dynamic "encryption_configuration" {
    for_each = local.encryption_configuration
    content {
      encryption_type = encryption_configuration.value["encryption_type"]
      kms_key         = encryption_configuration.value["kms_key"]
    }
  }

  dynamic "image_scanning_configuration" {
    for_each = local.image_scanning_configuration
    content {
      scan_on_push = image_scanning_configuration.value["scan_on_push"]
    }
  }

  dynamic "timeouts" {
    for_each = local.timeouts
    content {
      delete = timeouts.value["delete"]
    }
  }

  tags = var.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "cluster-dev-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = local.cluster_name
  cluster_version = "1.27"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name = "${var.cluster_environment}-node-group-1"

      instance_types = ["t2.micro"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name = "${var.cluster_environment}-node-group-2"

      instance_types = ["t2.micro"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}

