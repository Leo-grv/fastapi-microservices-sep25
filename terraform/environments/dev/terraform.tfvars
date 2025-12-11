# ============================================================================
# TERRAFORM VARIABLES - ENVIRONNEMENT DEV
# ============================================================================

# Général
aws_region   = "eu-west-3"
project_name = "microservices-platform"
environment  = "dev"

# VPC
vpc_cidr             = "10.0.0.0/16"
public_subnets       = ["10.0.1.0/24", "10.0.10.0/24"]
private_subnets_eks  = ["10.0.2.0/24", "10.0.20.0/24"]
private_subnets_rds  = ["10.0.3.0/24", "10.0.30.0/24"]

# EKS
eks_cluster_version   = "1.29"
eks_node_instance_types = ["t3.medium"]
eks_node_desired_size = 2
eks_node_min_size     = 2
eks_node_max_size     = 3

# RDS
rds_instance_class    = "db.t3.small"
rds_allocated_storage = 20
rds_engine_version    = "17.7"
rds_database_name     = "microservices_dev"
rds_master_username   = "dbadmin"
rds_multi_az          = false  # Pas de Multi-AZ en dev pour économiser

# Route53
domain_name         = "leotest.abrdns.com"
create_route53_zone = true  

# Application
docker_images = {
  auth     = "leogrv22/auth:dev"
  users    = "leogrv22/users:dev"
  items    = "leogrv22/items:dev"
  frontend = "leogrv22/frontend:dev"
}

# Tags
tags = {
  Environment = "dev"
  Team        = "Platform"
  CostCenter  = "Development"
}