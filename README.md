# 🚀 FastAPI Microservices Platform

Plateforme de microservices moderne construite avec **FastAPI**, **Next.js**, et **Kubernetes**.

Déployable sur **k3s (local)** ou **AWS EKS (production)**.

---

## 📋 Table des matières

- [Stack Technique](#-stack-technique)
- [Architecture](#-architecture)
- [Prérequis](#-prérequis)
- [Installation Locale (k3s)](#-installation-locale-k3s)
- [Déploiement AWS (EKS)](#-déploiement-aws-eks)
- [Utilisation](#-utilisation)
- [Développement](#-développement)
- [Documentation](#-documentation)

---

## 🛠️ Stack Technique

### **Backend**
- **FastAPI** 0.115+ - API REST moderne et performante
- **SQLModel** - ORM basé sur SQLAlchemy 2.0
- **PostgreSQL** 17 - Base de données relationnelle
- **JWT** - Authentication avec bcrypt
- **Pydantic** - Validation de données

### **Frontend**
- **Next.js** 14 - Framework React
- **Tailwind CSS** - Styling
- **Axios** - HTTP client
- **TypeScript** - Type safety

### **Infrastructure**
- **Docker** - Containerization
- **Kubernetes** - Orchestration (k3s local / EKS production)
- **Helm** - Package manager Kubernetes
- **Terraform** - Infrastructure as Code
- **Traefik** - Ingress controller

### **AWS Services (Production)**
- **EKS** - Managed Kubernetes
- **RDS** - Managed PostgreSQL
- **ALB** - Application Load Balancer
- **Secrets Manager** - Gestion des secrets
- **Route53** - DNS management
- **ACM** - SSL certificates

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                    CLIENTS                          │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
         ┌───────────────┐
         │  ALB / Traefik│
         └───────┬───────┘
                 │
     ┌───────────┼───────────┐
     ▼           ▼           ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│  Auth   │ │  Users  │ │  Items  │
│ Service │ │ Service │ │ Service │
└────┬────┘ └────┬────┘ └────┬────┘
     │           │           │
     └───────────┴───────────┘
                 │
                 ▼
         ┌──────────────┐
         │  PostgreSQL  │
         │  (RDS / Pod) │
         └──────────────┘
```

**Voir [ARCHITECTURE.md](./ARCHITECTURE.md) pour plus de détails.**

---

## 📦 Prérequis

### **Pour déploiement local (k3s)**

```bash
# Outils requis
- Docker 24+
- kubectl 1.28+
- Helm 3.12+
- k3s ou k3d

# Ressources recommandées
- 2 vCPU
- 4 GB RAM
- 20 GB disque
```

### **Pour déploiement AWS (EKS)**

```bash
# Outils requis
- AWS CLI 2.x
- Terraform 1.5+
- kubectl 1.28+
- Helm 3.12+

# Compte AWS configuré
aws configure
```

---

## 🏠 Installation Locale (k3s)

### **1. Cloner le projet**

```bash
git clone https://github.com/votre-repo/fastapi-microservices-platform.git
cd fastapi-microservices-platform
```

---

### **2. Installer k3s (si pas déjà fait)**

**Sur Linux/Ubuntu :**
```bash
curl -sfL https://get.k3s.io | sh -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

**Ou avec k3d (Docker) :**
```bash
k3d cluster create dev --agents 1 --port "30080:30080@agent:0"
```

---

### **3. Construire les images Docker**

```bash
# Auth service
cd Microservices/auth
docker build -t leogrv22/auth:dev .
docker push leogrv22/auth:dev

# Users service
cd ../users
docker build -t leogrv22/users:dev .
docker push leogrv22/users:dev

# Items service
cd ../items
docker build -t leogrv22/items:dev .
docker push leogrv22/items:dev

# Frontend
cd ../../frontend
docker build -t leogrv22/frontend:dev .
docker push leogrv22/frontend:dev
```

---

### **4. Configurer les variables**

Éditez `overlays/dev/values.yaml` :

```yaml
global:
  useExternalSecrets: false
  
  database:
    host: postgres-postgresql.dev.svc.cluster.local
    port: "5432"
    name: postgres
    user: postgres
    password: postgres  # Changez en production !

auth:
  image:
    tag: dev
    pullPolicy: Always
  service:
    type: NodePort
    nodePort: 30081

# ... (voir le fichier complet)
```

---

### **5. Déployer avec Helm**

```bash
# Créer le namespace
kubectl create namespace dev

# Update dependencies
cd helm/platform
helm dependency update

# Déployer
helm upgrade --install platform . \
  -f ../../overlays/dev/values.yaml \
  -n dev \
  --wait
```

---

### **6. Vérifier le déploiement**

```bash
# Vérifier les pods
kubectl get pods -n dev

# Attendre que tous les pods soient Running
kubectl get pods -n dev -w

# Vérifier les services
kubectl get svc -n dev
```

---

### **7. Créer un utilisateur de test**

```bash
# Se connecter au pod auth
kubectl exec -it -n dev $(kubectl get pod -n dev -l app.kubernetes.io/name=auth -o jsonpath='{.items[0].metadata.name}') -- bash

# Dans le pod, lancer Python
python3

# Créer l'utilisateur
from app.core.security import get_password_hash
from app.models import User
from app.core.db import engine
from sqlmodel import Session, select

with Session(engine) as session:
    # Vérifier si l'utilisateur existe
    user = session.exec(select(User).where(User.email == "admin@test.com")).first()
    
    if not user:
        user = User(
            email="admin@test.com",
            hashed_password=get_password_hash("Test123!"),
            full_name="Admin User",
            is_active=True,
            is_superuser=True
        )
        session.add(user)
        session.commit()
        print("✅ User created!")
    else:
        print("ℹ️ User already exists")
```

---

### **8. Accéder à l'application**

**Récupérer l'IP de votre VM :**
```bash
# Sur la VM
hostname -I | awk '{print $1}'
# Exemple: 54.195.141.244
```

**URLs :**
- Frontend : `http://YOUR_IP:30080/`
- Auth API : `http://YOUR_IP:30081/docs`
- Users API : `http://YOUR_IP:30082/docs`
- Items API : `http://YOUR_IP:30083/docs`

**Credentials par défaut :**
- Email : `admin@test.com`
- Password : `Test123!`

---

## ☁️ Déploiement AWS (EKS)

### **1. Configurer AWS CLI**

```bash
aws configure
# AWS Access Key ID: VOTRE_ACCESS_KEY
# AWS Secret Access Key: VOTRE_SECRET_KEY
# Default region name: eu-west-3
```

---

### **2. Créer le secret dans AWS Secrets Manager**

```bash
aws secretsmanager create-secret \
  --name microservices-platform-dev-secrets \
  --description "Application secrets for dev environment" \
  --secret-string '{
    "rds_master_password": "VotreMotDePasseSecure123!",
    "app_secret_key": "votre-secret-key-random-change-me"
  }' \
  --region eu-west-3
```

---

### **3. Déployer l'infrastructure Terraform**

```bash
cd terraform/

# Initialiser Terraform
terraform init

# Voir le plan
terraform plan

# Déployer (⏳ ~30-40 minutes)
terraform apply
```

**Terraform va créer :**
- VPC avec subnets publics/privés
- EKS Cluster + Node Groups
- RDS PostgreSQL Multi-AZ
- Application Load Balancer
- Security Groups
- IAM Roles

---

### **4. Configurer kubectl**

```bash
# Récupérer la commande depuis Terraform
terraform output configure_kubectl

# Exécuter
aws eks update-kubeconfig --region eu-west-3 --name microservi-dev

# Vérifier la connexion
kubectl get nodes
```

---

### **5. Vérifier External Secrets Operator**

```bash
kubectl get pods -n external-secrets-system
```

Si pas installé :
```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets-system \
  --create-namespace
```

---

### **6. Créer le namespace**

```bash
kubectl create namespace dev
```

---

### **7. Adapter les Helm values pour AWS**

Créez `overlays/aws/values.yaml` :

```yaml
global:
  useExternalSecrets: true  # ← Utiliser AWS Secrets Manager
  
  database:
    host: microservices-platform-dev-db.XXXXXX.eu-west-3.rds.amazonaws.com  # ← Depuis terraform output
    port: "5432"
    name: microservices
    user: postgres

auth:
  image:
    tag: dev
    pullPolicy: Always
  service:
    type: ClusterIP  # ← Plus de NodePort

users:
  image:
    tag: dev
    pullPolicy: Always
  service:
    type: ClusterIP

items:
  image:
    tag: dev
    pullPolicy: Always
  service:
    type: ClusterIP

frontend:
  image:
    tag: dev
    pullPolicy: Always
  service:
    type: ClusterIP

# Désactiver PostgreSQL (on utilise RDS)
postgresql:
  enabled: false
```

---

### **8. Déployer l'application**

```bash
cd helm/platform
helm dependency update

helm upgrade --install platform . \
  -f ../../overlays/aws/values.yaml \
  -n dev \
  --wait
```

---

### **9. Vérifier le déploiement**

```bash
# Pods
kubectl get pods -n dev

# Services
kubectl get svc -n dev

# Ingress
kubectl get ingress -n dev

# Logs
kubectl logs -n dev -l app.kubernetes.io/name=auth -f
```

---

### **10. Accéder à l'application**

**Récupérer l'URL de l'ALB :**
```bash
terraform output alb_dns_name
# microservices-p-dev-alb-XXXXXXX.eu-west-3.elb.amazonaws.com
```

**Tester l'API :**
```bash
ALB_URL=$(terraform output -raw alb_dns_name)
curl http://$ALB_URL/
```

**Note :** Si vous avez configuré un domaine avec Route53, utilisez :
- Frontend : `https://app.votredomaine.com`
- API : `https://api.votredomaine.com`

---

## 📖 Utilisation

### **Login**

```bash
curl -X POST http://YOUR_IP:30081/api/v1/login/access-token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin@test.com&password=Test123!"
```

**Response :**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

---

### **Get Current User**

```bash
TOKEN="your_access_token"

curl http://YOUR_IP:30082/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN"
```

---

### **Create Item**

```bash
curl -X POST http://YOUR_IP:30083/api/v1/items/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My First Item",
    "description": "This is a test item"
  }'
```

---

## 🔧 Développement

### **Structure du projet**

```
fastapi-microservices-platform/
├── Microservices/
│   ├── auth/           # Service d'authentification
│   ├── users/          # Service de gestion des utilisateurs
│   └── items/          # Service de gestion des items
├── frontend/           # Application Next.js
├── helm/
│   ├── platform/       # Umbrella chart
│   ├── auth/          # Subchart auth
│   ├── users/         # Subchart users
│   ├── items/         # Subchart items
│   └── frontend/      # Subchart frontend
├── terraform/          # Infrastructure AWS
├── overlays/
│   ├── dev/           # Config k3s local
│   └── aws/           # Config AWS EKS
└── docs/              # Documentation
```

---

### **Modifier un service**

```bash
# 1. Modifier le code
cd Microservices/auth
nano app/main.py

# 2. Rebuild l'image
docker build -t leogrv22/auth:dev .
docker push leogrv22/auth:dev

# 3. Redéployer
kubectl delete pod -n dev -l app.kubernetes.io/name=auth
```

---

### **Voir les logs**

```bash
# Logs d'un service
kubectl logs -n dev -l app.kubernetes.io/name=auth -f

# Logs de tous les pods
kubectl logs -n dev --all-containers=true -f

# Logs d'un pod spécifique
kubectl logs -n dev POD_NAME -f
```

---

### **Accéder à un pod**

```bash
kubectl exec -it -n dev POD_NAME -- bash
```

---

### **Port-forward pour debug**

```bash
# Forward le port auth
kubectl port-forward -n dev svc/platform-auth 8001:80

# Tester
curl http://localhost:8001/docs
```

---

## 📚 Documentation

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Architecture détaillée
- **[AWS_MIGRATION.md](./AWS_MIGRATION.md)** - Guide de migration k3s → EKS
- **API Documentation** :
  - Auth : `http://YOUR_IP:30081/docs`
  - Users : `http://YOUR_IP:30082/docs`
  - Items : `http://YOUR_IP:30083/docs`

---

## 🧹 Nettoyage

### **Local (k3s)**

```bash
# Supprimer le déploiement Helm
helm uninstall platform -n dev

# Supprimer le namespace
kubectl delete namespace dev

# (Optionnel) Supprimer k3s
/usr/local/bin/k3s-uninstall.sh
```

---

### **AWS (EKS)**

```bash
# Utiliser le script de nettoyage
chmod +x cleanup.sh
./cleanup.sh

# Ou manuellement
helm uninstall platform -n dev
kubectl delete namespace dev
cd terraform/
terraform destroy
```

⚠️ **Attention** : `terraform destroy` supprimera TOUTE l'infrastructure AWS !

---

## 🐛 Troubleshooting

### **Pods en CrashLoopBackOff**

```bash
# Voir les logs
kubectl logs -n dev POD_NAME

# Décrire le pod
kubectl describe pod -n dev POD_NAME
```

### **Connexion base de données échoue**

```bash
# Vérifier le secret
kubectl get secret -n dev database-credentials -o yaml

# Tester la connexion depuis un pod
kubectl run psql-test --rm -it --image=postgres:17 -- \
  psql "postgresql://postgres:PASSWORD@HOST:5432/DATABASE"
```

### **Services inaccessibles**

```bash
# Vérifier les services
kubectl get svc -n dev

# Vérifier les ingress
kubectl get ingress -n dev

# Vérifier Traefik
kubectl get pods -n traefik
```

---

## 🤝 Contributing

Les contributions sont les bienvenues ! Merci de :
1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

---

## 📄 License

Ce projet est sous licence MIT.

---

## 👤 Auteur

**Votre Nom**
- GitHub: [@votreusername](https://github.com/votreusername)

---

## 🙏 Remerciements

- FastAPI
- Next.js
- Kubernetes
- Terraform

---

**Happy coding! 🚀**
