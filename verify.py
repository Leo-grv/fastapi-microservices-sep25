#!/usr/bin/env python3
"""
Script de vérification de la santé de l'application
Vérifie que tous les services sont accessibles et fonctionnels
"""

import sys
import time
import requests
from typing import Dict, List, Tuple
from dataclasses import dataclass
from colorama import Fore, Style, init

# Initialiser colorama
init(autoreset=True)

@dataclass
class Service:
    """Représente un service à vérifier"""
    name: str
    url: str
    endpoints: List[str]
    requires_auth: bool = False


class HealthChecker:
    """Vérifie la santé des services"""
    
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip('/')
        self.token = None
        self.results: Dict[str, bool] = {}
        
    def print_header(self):
        """Affiche l'en-tête du script"""
        print(f"\n{Fore.CYAN}{'='*70}")
        print(f"{Fore.CYAN}{'  VÉRIFICATION DE LA SANTÉ DES SERVICES':^70}")
        print(f"{Fore.CYAN}{'='*70}{Style.RESET_ALL}\n")
        print(f"{Fore.YELLOW}Base URL: {self.base_url}{Style.RESET_ALL}\n")
    
    def print_section(self, title: str):
        """Affiche un titre de section"""
        print(f"\n{Fore.BLUE}{'─'*70}")
        print(f"{Fore.BLUE}{title}")
        print(f"{Fore.BLUE}{'─'*70}{Style.RESET_ALL}\n")
    
    def check_endpoint(self, service_name: str, endpoint: str, method: str = "GET", 
                       data: dict = None, require_auth: bool = False) -> Tuple[bool, str]:
        """Vérifie un endpoint"""
        url = f"{self.base_url}{endpoint}"
        
        try:
            headers = {}
            if require_auth and self.token:
                headers["Authorization"] = f"Bearer {self.token}"
            
            if method == "GET":
                response = requests.get(url, headers=headers, timeout=5)
            elif method == "POST":
                response = requests.post(url, headers=headers, json=data, timeout=5)
            else:
                return False, f"Méthode {method} non supportée"
            
            if response.status_code in [200, 201]:
                return True, f"✅ OK (HTTP {response.status_code})"
            else:
                return False, f"❌ ERREUR (HTTP {response.status_code})"
                
        except requests.exceptions.ConnectionError:
            return False, "❌ CONNEXION REFUSÉE"
        except requests.exceptions.Timeout:
            return False, "❌ TIMEOUT"
        except Exception as e:
            return False, f"❌ ERREUR: {str(e)}"
    
    def login(self, email: str = "admin@test.com", password: str = "Test123!") -> bool:
        """Se connecte et récupère un token JWT"""
        self.print_section("🔐 AUTHENTIFICATION")
        
        login_url = f"{self.base_url}:30081/api/v1/login/access-token"
        
        print(f"  → Tentative de connexion avec {email}...")
        
        try:
            response = requests.post(
                login_url,
                data={
                    "username": email,
                    "password": password
                },
                headers={"Content-Type": "application/x-www-form-urlencoded"},
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                self.token = data.get("access_token")
                print(f"{Fore.GREEN}  ✅ Authentification réussie !{Style.RESET_ALL}")
                print(f"  → Token: {self.token[:20]}...{self.token[-20:]}")
                return True
            else:
                print(f"{Fore.RED}  ❌ Échec de l'authentification (HTTP {response.status_code}){Style.RESET_ALL}")
                print(f"  → {response.text}")
                return False
                
        except Exception as e:
            print(f"{Fore.RED}  ❌ Erreur lors de l'authentification: {str(e)}{Style.RESET_ALL}")
            return False
    
    def check_service(self, service: Service):
        """Vérifie tous les endpoints d'un service"""
        self.print_section(f"📡 {service.name.upper()}")
        
        all_ok = True
        
        for endpoint in service.endpoints:
            success, message = self.check_endpoint(
                service.name,
                endpoint,
                require_auth=service.requires_auth
            )
            
            status_icon = "✅" if success else "❌"
            color = Fore.GREEN if success else Fore.RED
            
            print(f"  {status_icon} {endpoint:<50} {color}{message}{Style.RESET_ALL}")
            
            if not success:
                all_ok = False
            
            time.sleep(0.5)  # Éviter de surcharger les services
        
        self.results[service.name] = all_ok
        print()
    
    def print_summary(self):
        """Affiche le résumé des vérifications"""
        self.print_section("📊 RÉSUMÉ")
        
        total = len(self.results)
        passed = sum(1 for v in self.results.values() if v)
        failed = total - passed
        
        print(f"  Total de services vérifiés : {total}")
        print(f"  {Fore.GREEN}✅ Services OK : {passed}{Style.RESET_ALL}")
        print(f"  {Fore.RED}❌ Services KO : {failed}{Style.RESET_ALL}")
        print()
        
        # Détails par service
        for service_name, is_ok in self.results.items():
            status = f"{Fore.GREEN}✅ OK" if is_ok else f"{Fore.RED}❌ KO"
            print(f"  {status:<20} {service_name}{Style.RESET_ALL}")
        
        print(f"\n{Fore.CYAN}{'='*70}{Style.RESET_ALL}\n")
        
        # Code de sortie
        if failed > 0:
            print(f"{Fore.RED}❌ ÉCHEC : Certains services ne fonctionnent pas correctement{Style.RESET_ALL}")
            return 1
        else:
            print(f"{Fore.GREEN}✅ SUCCÈS : Tous les services fonctionnent correctement !{Style.RESET_ALL}")
            return 0


def main():
    """Point d'entrée principal"""
    
    # Récupérer l'URL depuis les arguments ou utiliser la valeur par défaut
    if len(sys.argv) > 1:
        base_url = sys.argv[1]
    else:
        # Essayer de détecter si on est sur AWS ou en local
        import subprocess
        try:
            result = subprocess.run(
                ["kubectl", "get", "svc", "-n", "dev", "platform-frontend", "-o", "jsonpath='{.spec.type}'"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if "NodePort" in result.stdout:
                # Local k3s
                base_url = "http://54.195.141.244"  # Remplacer par votre IP
            else:
                # AWS EKS avec ALB
                print("⚠️  Détection automatique non implémentée pour AWS")
                print("Usage: python3 verify.py <BASE_URL>")
                print("Exemple AWS: python3 verify.py http://microservices-p-dev-alb-xxx.elb.amazonaws.com")
                print("Exemple local: python3 verify.py http://54.195.141.244")
                sys.exit(1)
        except:
            print("⚠️  Impossible de détecter l'environnement")
            print("Usage: python3 verify.py <BASE_URL>")
            sys.exit(1)
    
    # Créer le checker
    checker = HealthChecker(base_url)
    checker.print_header()
    
    # Se connecter
    if not checker.login():
        print(f"\n{Fore.RED}❌ Impossible de continuer sans authentification{Style.RESET_ALL}")
        sys.exit(1)
    
    # Définir les services à vérifier
    services = [
        Service(
            name="Auth Service",
            url=f"{base_url}:30081",
            endpoints=[
                ":30081/docs",
                ":30081/health",
                ":30081/api/v1/login/test-token",
            ],
            requires_auth=False
        ),
        Service(
            name="Users Service",
            url=f"{base_url}:30082",
            endpoints=[
                ":30082/docs",
                ":30082/api/v1/users/me",
            ],
            requires_auth=True
        ),
        Service(
            name="Items Service",
            url=f"{base_url}:30083",
            endpoints=[
                ":30083/docs",
                ":30083/api/v1/items/",
            ],
            requires_auth=True
        ),
        Service(
            name="Frontend",
            url=f"{base_url}:30080",
            endpoints=[
                ":30080/",
            ],
            requires_auth=False
        ),
    ]
    
    # Vérifier chaque service
    for service in services:
        checker.check_service(service)
    
    # Afficher le résumé
    exit_code = checker.print_summary()
    
    # Suggestions
    if exit_code != 0:
        print(f"\n{Fore.YELLOW}💡 SUGGESTIONS DE DÉBOGAGE :{Style.RESET_ALL}\n")
        print("1. Vérifiez que tous les pods sont Running :")
        print("   kubectl get pods -n dev\n")
        print("2. Vérifiez les logs des services en erreur :")
        print("   kubectl logs -n dev -l app.kubernetes.io/name=auth\n")
        print("3. Vérifiez les services :")
        print("   kubectl get svc -n dev\n")
        print("4. Testez la connectivité réseau :")
        print(f"   curl -v {base_url}:30081/health\n")
    else:
        print(f"\n{Fore.GREEN}🎉 Votre application est prête à être utilisée !{Style.RESET_ALL}\n")
        print(f"📝 Accès :")
        print(f"   Frontend:  {base_url}:30080/")
        print(f"   Auth API:  {base_url}:30081/docs")
        print(f"   Users API: {base_url}:30082/docs")
        print(f"   Items API: {base_url}:30083/docs")
        print()
    
    sys.exit(exit_code)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n{Fore.YELLOW}⚠️  Vérification interrompue par l'utilisateur{Style.RESET_ALL}")
        sys.exit(130)
    except Exception as e:
        print(f"\n{Fore.RED}❌ Erreur inattendue: {str(e)}{Style.RESET_ALL}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
