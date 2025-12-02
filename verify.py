from fastapi import APIRouter, Depends, HTTPException, status, Request
from app.api.deps import CurrentUser

router = APIRouter(prefix="", tags=["verify"])


@router.get("/verify")
@router.post("/verify")
@router.head("/verify")
def verify_token(
    request: Request,
    current_user: CurrentUser
) -> dict:
    """
    Endpoint utilisé par Traefik ForwardAuth pour vérifier le JWT.
    
    Headers reçus de Traefik :
    - Authorization: Bearer <token>
    
    Retourne :
    - 200 OK si le token est valide
    - 401 Unauthorized si le token est invalide/manquant
    
    Headers retournés à Traefik :
    - X-User-Id: ID de l'utilisateur
    - X-User-Email: Email de l'utilisateur
    """
    
    # Le décorateur CurrentUser lève automatiquement une 401 si le token est invalide
    # Si on arrive ici, c'est que le token est valide
    
    return {
        "status": "authenticated",
        "user_id": str(current_user.id),
        "email": current_user.email,
        "is_active": current_user.is_active,
        "is_superuser": current_user.is_superuser
    }


@router.get("/health")
def health_check():
    """Health check pour vérifier que le service auth est up"""
    return {"status": "healthy", "service": "auth"}