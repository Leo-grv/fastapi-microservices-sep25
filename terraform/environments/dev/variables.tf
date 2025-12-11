# ============================================================================
# VARIABLES GÉNÉRALES
# ============================================================================

variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "microservices-platform"
}

variable "environment" {
  description = "Environnement (dev ou prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment doit être 'dev' ou 'prod'."
  }
}

# ============================================================================
# VPC
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "CIDR blocks des subnets publics"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.10.0/24"]
}

variable "private_subnets_eks" {
  description = "CIDR blocks des subnets privés pour EKS"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.20.0/24"]
}

variable "private_subnets_rds" {
  description = "CIDR blocks des subnets privés pour RDS"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.30.0/24"]
}

# ============================================================================
# EKS
# ============================================================================

variable "eks_cluster_version" {
  description = "Version du cluster EKS"
  type        = string
  default     = "1.28"
}

variable "eks_node_instance_types" {
  description = "Types d'instance pour les nodes EKS"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  description = "Nombre désiré de nodes"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Nombre minimum de nodes"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Nombre maximum de nodes"
  type        = number
  default     = 4
}

# ============================================================================
# RDS
# ============================================================================

variable "rds_instance_class" {
  description = "Classe d'instance RDS"
  type        = string
  default     = "db.t3.small"
}

variable "rds_allocated_storage" {
  description = "Stockage alloué en GB"
  type        = number
  default     = 20
}

variable "rds_engine_version" {
  description = "Version de PostgreSQL"
  type        = string
  default     = "17.2"
}

variable "rds_database_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "microservices"
}

variable "rds_master_username" {
  description = "Username master RDS"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "rds_multi_az" {
  description = "Activer Multi-AZ pour RDS"
  type        = bool
  default     = false
}

# ============================================================================
# ROUTE53 & CERTIFICAT
# ============================================================================

variable "domain_name" {
  description = "Nom de domaine principal"
  type        = string
  default     = "leotest.abrdns.com"
}

variable "create_route53_zone" {
  description = "Créer une nouvelle zone Route53 (false si zone existe déjà)"
  type        = bool
  default     = false
}

# ============================================================================
# APPLICATION
# ============================================================================

variable "docker_images" {
  description = "Images Docker des microservices"
  type = object({
    auth     = string
    users    = string
    items    = string
    frontend = string
  })
  default = {
    auth     = "leogrv22/auth:dev"
    users    = "leogrv22/users:dev"
    items    = "leogrv22/items:dev"
    frontend = "leogrv22/frontend:dev"
  }
}

# ============================================================================
# TAGS
# ============================================================================

variable "tags" {
  description = "Tags additionnels"
  type        = map(string)
  default     = {}
}