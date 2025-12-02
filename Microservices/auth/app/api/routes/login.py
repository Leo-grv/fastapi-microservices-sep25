from datetime import timedelta
from typing import Annotated, Any
import logging

from fastapi import APIRouter, Depends, HTTPException, Request, Response
from fastapi.security import OAuth2PasswordRequestForm

from app.core import security
from app.core.config import settings
from app.api.deps import SessionDep, CurrentUser
from app.models import Token, UserPublic, UserCreate
from app import crud

# Logger
logger = logging.getLogger(__name__)

router = APIRouter(prefix="", tags=["auth"])


# ---------------------------------------------------------------------------
# HEALTH CHECK
# ---------------------------------------------------------------------------
@router.get("/health")
def health_check():
    """Health check endpoint pour monitoring"""
    return {
        "status": "healthy",
        "service": "auth",
        "version": "1.0.0"
    }


# ---------------------------------------------------------------------------
# LOGIN : /api/v1/login/access-token
# ---------------------------------------------------------------------------
@router.post(f"{settings.API_V1_STR}/login/access-token", response_model=Token)
def login_access_token(
    session: SessionDep,
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()]
) -> Any:
    """
    OAuth2 compatible token login.
    
    Returns:
        Token: JWT access token
    """
    user = crud.authenticate(
        session=session,
        email=form_data.username,
        password=form_data.password
    )

    if not user:
        logger.warning(f"Failed login attempt for: {form_data.username}")
        raise HTTPException(
            status_code=400, 
            detail="Incorrect email or password"
        )
    
    if not user.is_active:
        logger.warning(f"Inactive user tried to login: {user.email}")
        raise HTTPException(
            status_code=400,
            detail="Inactive user"
        )

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    logger.info(f"User logged in successfully: {user.email}")

    return {
        "access_token": security.create_access_token(user.id, access_token_expires),
        "token_type": "bearer",
    }


# ---------------------------------------------------------------------------
# REGISTER : /api/v1/users/
# ---------------------------------------------------------------------------
@router.post(f"{settings.API_V1_STR}/users/", response_model=UserPublic)
def register_user(session: SessionDep, user_in: UserCreate) -> Any:
    """
    Create new user.
    
    Args:
        user_in: User creation data
        
    Returns:
        UserPublic: Created user
    """
    
    # Vérifier si l'email existe déjà
    existing_user = crud.get_user_by_email(session=session, email=user_in.email)
    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )
    
    logger.info(f"Creating new user: {user_in.email}")
    
    user = crud.create_user(session=session, user_create=user_in)
    
    logger.info(f"User created successfully: {user.email}")

    return UserPublic(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        is_active=user.is_active,
        is_superuser=user.is_superuser
    )


# ---------------------------------------------------------------------------
# VERIFY TOKEN (pour Traefik ForwardAuth)
# ---------------------------------------------------------------------------
@router.get(f"{settings.API_V1_STR}/auth/verify")
@router.post(f"{settings.API_V1_STR}/auth/verify")
@router.head(f"{settings.API_V1_STR}/auth/verify")
def verify_token(
    request: Request,
    current_user: CurrentUser
):
    """
    Verify JWT token for Traefik ForwardAuth.
    
    This endpoint is called by Traefik to verify authentication.
    Returns 200 if token is valid, 401 otherwise.
    
    Headers returned to Traefik:
        X-User-Id: User's ID
        X-User-Email: User's email
        X-User-Active: User's active status
        X-User-Superuser: User's superuser status
    """
    
    # Vérifier que l'utilisateur est actif
    if not current_user.is_active:
        logger.warning(f"Inactive user attempted access: {current_user.email}")
        raise HTTPException(
            status_code=403,
            detail="User account is disabled"
        )
    
    # Headers à propager aux services downstream via Traefik
    headers = {
        "X-User-Id": str(current_user.id),
        "X-User-Email": current_user.email,
        "X-User-Active": str(current_user.is_active),
        "X-User-Superuser": str(current_user.is_superuser),
    }
    
    logger.debug(f"Token verified for user: {current_user.email}")
    
    return Response(status_code=200, headers=headers)


# ---------------------------------------------------------------------------
# LOGOUT (optionnel - pour token blacklisting si vous l'implémentez)
# ---------------------------------------------------------------------------
@router.post(f"{settings.API_V1_STR}/logout")
def logout(current_user: CurrentUser):
    """
    Logout endpoint (placeholder).
    
    Note: With JWT, true logout requires token blacklisting
    which needs Redis or similar. For now, this is just a placeholder.
    Client should delete the token on their side.
    """
    logger.info(f"User logged out: {current_user.email}")
    
    return {
        "message": "Successfully logged out",
        "note": "Please delete your token on the client side"
    }