#!/bin/bash

# ============================================================================
# SCRIPT DE NETTOYAGE COMPLET DE L'INFRASTRUCTURE AWS
# ============================================================================

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                  NETTOYAGE DE L'INFRASTRUCTURE AWS                 ║
║                                                                    ║
║  ⚠️  ATTENTION : Cette action est IRRÉVERSIBLE !                  ║
║                                                                    ║
║  Ce script va supprimer :                                         ║
║    ✗ Tous les pods et services Kubernetes                         ║
║    ✗ Les releases Helm                                            ║
║    ✗ Le cluster EKS (nodes inclus)                                ║
║    ✗ La base de données RDS (+ snapshots)                         ║
║    ✗ L'Application Load Balancer                                  ║
║    ✗ Le VPC et tous les composants réseau                         ║
║    ✗ Les buckets S3 (logs + backups)                              ║
║    ✗ Les secrets AWS Secrets Manager                              ║
║    ✗ Les IAM roles                                                ║
║                                                                    ║
║  💰 Coût estimé économisé : ~250-300$/mois                        ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Demander confirmation
echo -e "${YELLOW}"
read -p "Êtes-vous ABSOLUMENT SÛR de vouloir tout supprimer ? (tapez 'YES' en majuscules) : " confirmation
echo -e "${NC}"

if [ "$confirmation" != "YES" ]; then
    echo -e "${GREEN}✅ Annulé. Aucune suppression effectuée.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║               DÉBUT DU NETTOYAGE - Phase 1/5                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# ÉTAPE 1 : Supprimer les releases Helm
# ============================================================================
echo -e "${YELLOW}📦 Étape 1/5 : Suppression des releases Helm...${NC}"

# Vérifier si kubectl est configuré
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${YELLOW}⚠️  kubectl n'est pas configuré, passage à l'étape suivante${NC}"
else
    # Supprimer la release platform
    if helm list -n dev 2>/dev/null | grep -q platform; then
        echo "  → Suppression de la release 'platform'..."
        helm uninstall platform -n dev --wait --timeout 5m || true
        echo -e "${GREEN}  ✅ Release 'platform' supprimée${NC}"
    else
        echo "  ℹ️  Aucune release 'platform' trouvée"
    fi

    # Supprimer External Secrets
    if helm list -n external-secrets-system 2>/dev/null | grep -q external-secrets; then
        echo "  → Suppression de 'external-secrets'..."
        helm uninstall external-secrets -n external-secrets-system --wait --timeout 5m || true
        echo -e "${GREEN}  ✅ Release 'external-secrets' supprimée${NC}"
    fi
fi

echo -e "${GREEN}✅ Étape 1/5 terminée${NC}"
echo ""

# ============================================================================
# ÉTAPE 2 : Supprimer les namespaces Kubernetes
# ============================================================================
echo -e "${YELLOW}🗂️  Étape 2/5 : Suppression des namespaces Kubernetes...${NC}"

if kubectl cluster-info &> /dev/null; then
    # Supprimer les namespaces
    for ns in dev external-secrets-system; do
        if kubectl get namespace $ns &> /dev/null; then
            echo "  → Suppression du namespace '$ns'..."
            kubectl delete namespace $ns --timeout=3m --grace-period=0 --force 2>/dev/null || true
            echo -e "${GREEN}  ✅ Namespace '$ns' supprimé${NC}"
        fi
    done
    
    # Attendre que les LoadBalancers soient supprimés
    echo ""
    echo -e "${YELLOW}⏳ Attente de la suppression des LoadBalancers AWS (90 secondes)...${NC}"
    sleep 90
else
    echo "  ℹ️  Kubernetes non accessible, passage à l'étape suivante"
fi

echo -e "${GREEN}✅ Étape 2/5 terminée${NC}"
echo ""

# ============================================================================
# ÉTAPE 3 : Supprimer les ressources Kubernetes restantes
# ============================================================================
echo -e "${YELLOW}🧹 Étape 3/5 : Nettoyage des ressources Kubernetes restantes...${NC}"

if kubectl cluster-info &> /dev/null; then
    # Supprimer tous les LoadBalancer Services
    echo "  → Suppression des services LoadBalancer..."
    kubectl delete svc --all-namespaces --field-selector spec.type=LoadBalancer --wait=false 2>/dev/null || true
    
    # Supprimer tous les PersistentVolumeClaims
    echo "  → Suppression des PersistentVolumeClaims..."
    kubectl delete pvc --all --all-namespaces --wait=false 2>/dev/null || true
    
    # Attendre un peu
    echo "  → Attente de la suppression (30 secondes)..."
    sleep 30
fi

echo -e "${GREEN}✅ Étape 3/5 terminée${NC}"
echo ""

# ============================================================================
# ÉTAPE 4 : Terraform destroy
# ============================================================================
echo -e "${YELLOW}🏗️  Étape 4/5 : Destruction de l'infrastructure Terraform...${NC}"
echo -e "${RED}⚠️  Cette étape peut prendre 15-25 minutes...${NC}"
echo ""

if [ ! -d "terraform" ]; then
    echo -e "${RED}❌ Dossier terraform/ introuvable${NC}"
    echo "  Assurez-vous d'exécuter ce script depuis la racine du projet"
    exit 1
fi

cd terraform/

# Vérifier que Terraform est initialisé
if [ ! -d ".terraform" ]; then
    echo -e "${YELLOW}  → Initialisation de Terraform...${NC}"
    terraform init
fi

# Détruire l'infrastructure
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           DESTRUCTION TERRAFORM EN COURS...                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

terraform destroy -auto-approve

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Infrastructure Terraform détruite avec succès${NC}"
else
    echo -e "${RED}❌ Erreur lors de la destruction Terraform${NC}"
    echo -e "${YELLOW}ℹ️  Vérifiez manuellement la console AWS${NC}"
fi

echo -e "${GREEN}✅ Étape 4/5 terminée${NC}"
echo ""

# ============================================================================
# ÉTAPE 5 : Nettoyage local
# ============================================================================
echo -e "${YELLOW}🧹 Étape 5/5 : Nettoyage des fichiers locaux...${NC}"

# Récupérer le nom du cluster avant de nettoyer
CLUSTER_NAME=$(terraform output -raw eks_cluster_name 2>/dev/null || echo "microservi-dev")

# Supprimer le contexte kubectl
if [ -n "$CLUSTER_NAME" ]; then
    echo "  → Suppression du contexte kubectl..."
    kubectl config delete-context "arn:aws:eks:eu-west-3:*:cluster/$CLUSTER_NAME" 2>/dev/null || true
    kubectl config delete-cluster "arn:aws:eks:eu-west-3:*:cluster/$CLUSTER_NAME" 2>/dev/null || true
    echo -e "${GREEN}  ✅ Contexte kubectl supprimé${NC}"
fi

# Nettoyer les fichiers Terraform
echo "  → Nettoyage des fichiers Terraform..."
rm -f terraform.tfstate*
rm -f .terraform.lock.hcl
rm -rf .terraform/
echo -e "${GREEN}  ✅ Fichiers Terraform nettoyés${NC}"

cd ..

echo -e "${GREEN}✅ Étape 5/5 terminée${NC}"
echo ""

# ============================================================================
# NETTOYAGE OPTIONNEL : AWS Secrets Manager
# ============================================================================
echo ""
echo -e "${YELLOW}🔐 Nettoyage optionnel : AWS Secrets Manager${NC}"
echo ""
read -p "Voulez-vous aussi supprimer le secret AWS Secrets Manager ? (y/N) : " delete_secret

if [[ "$delete_secret" =~ ^[Yy]$ ]]; then
    echo "  → Suppression du secret 'microservices-platform-dev-secrets'..."
    aws secretsmanager delete-secret \
        --secret-id microservices-platform-dev-secrets \
        --region eu-west-3 \
        --force-delete-without-recovery 2>/dev/null || true
    echo -e "${GREEN}  ✅ Secret supprimé${NC}"
else
    echo "  ℹ️  Secret conservé"
fi

# ============================================================================
# RÉSUMÉ FINAL
# ============================================================================
echo ""
echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                    ✅ NETTOYAGE TERMINÉ !                         ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${GREEN}📋 Ressources supprimées :${NC}"
echo "  ✅ Releases Helm (platform, external-secrets)"
echo "  ✅ Namespaces Kubernetes (dev, external-secrets-system)"
echo "  ✅ Cluster EKS + Node Groups"
echo "  ✅ Base de données RDS"
echo "  ✅ Application Load Balancer"
echo "  ✅ VPC et composants réseau (subnets, NAT, IGW)"
echo "  ✅ Security Groups"
echo "  ✅ IAM Roles"
echo "  ✅ Buckets S3 (logs)"
echo "  ✅ Contexte kubectl local"
echo "  ✅ Fichiers Terraform locaux"
if [[ "$delete_secret" =~ ^[Yy]$ ]]; then
    echo "  ✅ Secret AWS Secrets Manager"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  VÉRIFICATION RECOMMANDÉE                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}💡 Vérifiez manuellement dans la console AWS :${NC}"
echo ""
echo "1. EC2 → Instances (doit être vide)"
echo "   https://eu-west-3.console.aws.amazon.com/ec2/home?region=eu-west-3#Instances:"
echo ""
echo "2. RDS → Databases (doit être vide)"
echo "   https://eu-west-3.console.aws.amazon.com/rds/home?region=eu-west-3#databases:"
echo ""
echo "3. EKS → Clusters (doit être vide)"
echo "   https://eu-west-3.console.aws.amazon.com/eks/home?region=eu-west-3#/clusters"
echo ""
echo "4. EC2 → Load Balancers (doit être vide)"
echo "   https://eu-west-3.console.aws.amazon.com/ec2/home?region=eu-west-3#LoadBalancers:"
echo ""
echo "5. VPC → Your VPCs (vérifier qu'il n'y a plus de VPC du projet)"
echo "   https://eu-west-3.console.aws.amazon.com/vpc/home?region=eu-west-3#vpcs:"
echo ""
echo "6. S3 → Buckets (vérifier les buckets de logs)"
echo "   https://s3.console.aws.amazon.com/s3/buckets?region=eu-west-3"
echo ""

echo -e "${YELLOW}⚠️  IMPORTANT : Vérifiez votre facture AWS dans 24-48h${NC}"
echo "   https://console.aws.amazon.com/billing/home#/bills"
echo ""
echo -e "${GREEN}💰 Économie mensuelle estimée : ~250-300\$${NC}"
echo ""

# Commandes de vérification rapide
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              COMMANDES DE VÉRIFICATION RAPIDE                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

cat << 'EOF'
# Vérifier qu'il ne reste aucune ressource
aws eks list-clusters --region eu-west-3
aws rds describe-db-instances --region eu-west-3
aws ec2 describe-instances --region eu-west-3 --filters "Name=instance-state-name,Values=running"
aws elbv2 describe-load-balancers --region eu-west-3
aws ec2 describe-vpcs --region eu-west-3 --filters "Name=tag:Project,Values=microservices-platform"

# Lister les buckets S3
aws s3 ls | grep microservices

# Vérifier les secrets
aws secretsmanager list-secrets --region eu-west-3 | grep microservices
EOF

echo ""
echo -e "${GREEN}✨ Nettoyage terminé avec succès !${NC}"
echo ""
