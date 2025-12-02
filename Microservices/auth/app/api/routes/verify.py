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
    '''
    Endpoint utilisé par Traefik ForwardAuth pour vérifier le JWT.
    Retourne 200 si le token est valide, 401 sinon.
    '''
    # Traefik attend juste un 200 OK
    return {
        "user_id": current_user.id,
        "email": current_user.email,
        "is_active": current_user.is_active
    }