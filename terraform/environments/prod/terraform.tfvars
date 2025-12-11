# ============================================================================
# PRODUCTION - apisep25.fr
# ============================================================================

aws_region   = "eu-west-3"
project_name = "microservices-platform"
environment  = "prod"

# VPC (différent du DEV)
vpc_cidr             = "10.1.0.0/16"
public_subnets       = ["10.1.1.0/24", "10.1.10.0/24"]
private_subnets_eks  = ["10.1.2.0/24", "10.1.20.0/24"]
private_subnets_rds  = ["10.1.3.0/24", "10.1.30.0/24"]

# EKS
eks_cluster_version      = "1.31"
eks_node_instance_types  = ["t3.medium"]
eks_node_desired_size    = 3
eks_node_min_size        = 2
eks_node_max_size        = 6

# RDS - Plus costaud que dev
rds_instance_class       = "db.t3.medium"
rds_allocated_storage    = 100
rds_engine_version       = "15"
rds_database_name        = "microservices_prod"
rds_master_username      = "dbadmin"
rds_multi_az             = true
rds_backup_retention     = 30

# Domaine
domain_name = "apisep25.fr"

# Tags
tags = {
  Environment = "prod"
  Project     = "microservices-platform"
  Domain      = "apisep25.fr"
  ManagedBy   = "terraform"
}
