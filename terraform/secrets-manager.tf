# ============================================================================
# LIRE LES SECRETS DEPUIS AWS SECRETS MANAGER
# ============================================================================

data "aws_secretsmanager_secret" "app_secrets" {
  name = "${var.project_name}-${var.environment}-secrets"
}

data "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = data.aws_secretsmanager_secret.app_secrets.id
}

# Parser le JSON
locals {
  app_secrets = jsondecode(data.aws_secretsmanager_secret_version.app_secrets.secret_string)
  
  rds_password = local.app_secrets.rds_master_password
  app_secret   = local.app_secrets.app_secret_key
}

# ============================================================================
# CRÉER UN SECRET KUBERNETES AVEC LES VALEURS
# ============================================================================

# Ce secret sera utilisé si ESO n'est pas encore installé
resource "kubernetes_secret" "database_credentials" {
  depends_on = [module.eks, aws_db_instance.postgresql]

  metadata {
    name      = "database-credentials"
    namespace = "default"
  }

  data = {
    DATABASE_URL = "postgresql://${var.rds_master_username}:${local.rds_password}@${aws_db_instance.postgresql.endpoint}/${var.rds_database_name}"
    SECRET_KEY   = local.app_secret
    DB_HOST      = aws_db_instance.postgresql.address
    DB_PORT      = tostring(aws_db_instance.postgresql.port)
    DB_NAME      = var.rds_database_name
    DB_USERNAME  = var.rds_master_username
    DB_PASSWORD  = local.rds_password
  }

  type = "Opaque"
}