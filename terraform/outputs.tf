# ============================================================================
# VPC OUTPUTS
# ============================================================================

output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block du VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnets" {
  description = "IDs des subnets publics"
  value       = aws_subnet.public[*].id
}

output "private_subnets_eks" {
  description = "IDs des subnets privés EKS"
  value       = aws_subnet.private_eks[*].id
}

output "private_subnets_rds" {
  description = "IDs des subnets privés RDS"
  value       = aws_subnet.private_rds[*].id
}

# ============================================================================
# EKS OUTPUTS
# ============================================================================

output "eks_cluster_id" {
  description = "ID du cluster EKS"
  value       = module.eks.cluster_id
}

output "eks_cluster_name" {
  description = "Nom du cluster EKS"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint du cluster EKS"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group du cluster EKS"
  value       = aws_security_group.eks_cluster.id
}

output "eks_node_security_group_id" {
  description = "Security group des nodes EKS"
  value       = aws_security_group.eks_nodes.id
}

output "configure_kubectl" {
  description = "Commande pour configurer kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# ============================================================================
# RDS OUTPUTS
# ============================================================================

output "rds_endpoint" {
  description = "Endpoint de la base de données RDS"
  value       = aws_db_instance.postgresql.endpoint
}

output "rds_address" {
  description = "Adresse de la base de données RDS"
  value       = aws_db_instance.postgresql.address
}

output "rds_port" {
  description = "Port de la base de données RDS"
  value       = aws_db_instance.postgresql.port
}

output "rds_database_name" {
  description = "Nom de la base de données"
  value       = aws_db_instance.postgresql.db_name
}

output "database_url" {
  description = "URL complète de connexion à la base de données"
  value       = "postgresql://${var.rds_master_username}:${local.rds_password}@${aws_db_instance.postgresql.endpoint}/${var.rds_database_name}"
  sensitive   = true
}

# ============================================================================
# ALB OUTPUTS
# ============================================================================

output "alb_dns_name" {
  description = "DNS name de l'Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID de l'ALB"
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  description = "ARN de l'ALB"
  value       = aws_lb.main.arn
}

# ============================================================================
# ROUTE53 & DOMAIN OUTPUTS
# ============================================================================

#output "route53_zone_id" {
#  description = "ID de la zone Route53"
#  value       = local.route53_zone_id
#}

#output "api_domain" {
#  description = "Domaine de l'API"
#  value       = "https://api.${var.domain_name}"
#}

#output "app_domain" {
#  description = "Domaine de l'application frontend"
#"  value       = "https://app.${var.domain_name}"
#}

#output "root_domain" {
#  description = "Domaine racine"
#  value       = "https://${var.domain_name}"
#}

# ============================================================================
# CERTIFICATE OUTPUTS
# ============================================================================

#output "acm_certificate_arn" {
#  description = "ARN du certificat ACM"
#  value       = aws_acm_certificate.main.arn
#}

#output "acm_certificate_status" {
#  description = "Statut du certificat ACM"
#  value       = aws_acm_certificate.main.status
#}

# ============================================================================
# S3 OUTPUTS
# ============================================================================

output "alb_logs_bucket" {
  description = "Nom du bucket S3 pour les logs ALB"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "app_data_bucket" {
  description = "Nom du bucket S3 pour les données applicatives"
  value       = aws_s3_bucket.app_data.bucket
}

# ============================================================================
# DEPLOYMENT INFORMATION
# ============================================================================

output "deployment_info" {
  description = "Informations de déploiement"
  value = <<-EOT
    ╔════════════════════════════════════════════════════════════════════════╗
    ║                    DÉPLOIEMENT RÉUSSI !                                ║
    ╚════════════════════════════════════════════════════════════════════════╝
    
    📋 Environnement: ${var.environment}
    🌍 Région: ${var.aws_region}
    
    🔗 URLs:
       - API:      https://api.${var.domain_name}
       - Frontend: https://app.${var.domain_name}
       - Root:     https://${var.domain_name}
    
    🎯 EKS Cluster:
       - Nom:      ${module.eks.cluster_name}
       - Endpoint: ${module.eks.cluster_endpoint}
       - Config:   aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}
    
    🗄️ Base de données:
       - Host:     ${aws_db_instance.postgresql.address}
       - Port:     ${aws_db_instance.postgresql.port}
       - Database: ${aws_db_instance.postgresql.db_name}
    
    🔐 Secrets Kubernetes:
       - kubectl get secret database-credentials -o yaml
    
    📊 Next Steps:
       1. Configure kubectl:
          aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}
       
       2. Vérifier les nodes:
          kubectl get nodes
       
       3. Déployer votre application:
          helm upgrade --install platform ./helm/platform -f ./overlays/${var.environment}/values.yaml -n ${var.environment}
       
       4. Vérifier les pods:
          kubectl get pods -n ${var.environment}
       
       5. Tester l'API:
          curl https://api.${var.domain_name}/health
    EOT
}