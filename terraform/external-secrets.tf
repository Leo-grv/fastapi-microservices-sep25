# ============================================================================
# EXTERNAL SECRETS OPERATOR
# ============================================================================

# Installer ESO via Helm
resource "helm_release" "external_secrets" {
  depends_on = [module.eks]

  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = "external-secrets-system"
  version    = "0.9.11"

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

# Créer le SecretStore dans chaque namespace
resource "kubectl_manifest" "secret_store_default" {
  depends_on = [helm_release.external_secrets]

  yaml_body = <<-YAML
    apiVersion: external-secrets.io/v1beta1
    kind: SecretStore
    metadata:
      name: aws-secrets-store
      namespace: default
    spec:
      provider:
        aws:
          service: SecretsManager
          region: ${var.aws_region}
          auth:
            jwt:
              serviceAccountRef:
                name: default
  YAML
}

resource "kubectl_manifest" "secret_store_dev" {
  depends_on = [helm_release.external_secrets]

  yaml_body = <<-YAML
    apiVersion: external-secrets.io/v1beta1
    kind: SecretStore
    metadata:
      name: aws-secrets-store
      namespace: dev
    spec:
      provider:
        aws:
          service: SecretsManager
          region: ${var.aws_region}
          auth:
            jwt:
              serviceAccountRef:
                name: default
  YAML
}

# ExternalSecret pour synchroniser AWS → K8s
resource "kubectl_manifest" "external_secret" {
  depends_on = [
    kubectl_manifest.secret_store_default,
    aws_db_instance.postgresql
  ]

  yaml_body = <<-YAML
    apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    metadata:
      name: database-credentials
      namespace: default
    spec:
      refreshInterval: 1h
      secretStoreRef:
        name: aws-secrets-store
        kind: SecretStore
      target:
        name: database-credentials
        creationPolicy: Owner
      dataFrom:
        - extract:
            key: ${var.project_name}-${var.environment}-secrets
      data:
        - secretKey: DATABASE_URL
          remoteRef:
            key: ${var.project_name}-${var.environment}-secrets
            property: DATABASE_URL_COMPUTED
  YAML
}