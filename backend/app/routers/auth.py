from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import UserDB
from app.schemas.auth import LoginRequest, TokenResponse
from app.schemas.user import UserCreate, UserOut
from app.core.security import verify_password, get_password_hash, create_access_token
from app.core.dependencies import get_current_user, user_db_to_out

router = APIRouter(prefix="/api/auth", tags=["auth"])

@router.post("/login", response_model=TokenResponse)
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(UserDB).filter(UserDB.username == req.username).first()
    if not user or not verify_password(req.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales incorrectas",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuario inactivo",
        )
    
    # Update last login
    user.last_login = datetime.utcnow()
    db.commit()
    db.refresh(user)

    token = create_access_token(subject=user.id)
    user_out = user_db_to_out(user, token=token)
    return TokenResponse(access_token=token, token_type="bearer", user=user_out)

@router.post("/register", response_model=UserOut)
def register(req: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(UserDB).filter(UserDB.username == req.username).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El nombre de usuario ya está en uso",
        )
    roles_list = [r.value if hasattr(r, 'value') else str(r) for r in req.roles]
    user = UserDB(
        username=req.username,
        name=req.name,
        email=req.email,
        hashed_password=get_password_hash(req.password),
        roles=roles_list,
        is_active=req.isActive,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user_db_to_out(user)

@router.get("/me", response_model=UserOut)
def get_me(current_user: UserDB = Depends(get_current_user)):
    return user_db_to_out(current_user)

@router.post("/logout")
def logout():
    return {"message": "Sesión cerrada exitosamente"}
