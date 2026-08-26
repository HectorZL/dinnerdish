from typing import List, Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import UserDB
from app.core.security import decode_access_token
from app.schemas.user import UserOut

security_scheme = HTTPBearer(auto_error=False)

def user_db_to_out(user: UserDB, token: Optional[str] = None) -> UserOut:
    roles_list = user.roles if isinstance(user.roles, list) else [str(user.roles)]
    primary_role = roles_list[0] if len(roles_list) > 0 else "mesero"
    return UserOut(
        id=user.id,
        username=user.username,
        name=user.name,
        email=user.email,
        role=primary_role,
        roles=roles_list,
        token=token,
        lastLogin=user.last_login.isoformat() if user.last_login else None,
        isActive=user.is_active,
    )

def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme),
    db: Session = Depends(get_db)
) -> UserDB:
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No se proporcionó token de autenticación",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = credentials.credentials
    payload = decode_access_token(token)
    if not payload or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user_id = payload["sub"]
    user = db.query(UserDB).filter(UserDB.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario no encontrado",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuario inactivo",
        )
    return user

def require_role(allowed_roles: List[str]):
    def role_checker(current_user: UserDB = Depends(get_current_user)) -> UserDB:
        user_roles = current_user.roles if isinstance(current_user.roles, list) else [str(current_user.roles)]
        # admin has access to everything
        if "admin" in user_roles:
            return current_user
        if any(role in allowed_roles for role in user_roles):
            return current_user
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permisos para realizar esta acción",
        )
    return role_checker
