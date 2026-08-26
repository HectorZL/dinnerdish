from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import UserDB
from app.schemas.user import UserCreate, UserUpdate, UserOut
from app.core.security import get_password_hash
from app.core.dependencies import get_current_user, require_role, user_db_to_out

router = APIRouter(prefix="/api/users", tags=["users"])

@router.get("", response_model=List[UserOut])
def get_users(
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    users = db.query(UserDB).all()
    return [user_db_to_out(u) for u in users]

@router.get("/{user_id}", response_model=UserOut)
def get_user(
    user_id: str,
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    user = db.query(UserDB).filter(UserDB.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    return user_db_to_out(user)

@router.post("", response_model=UserOut)
def create_user(
    req: UserCreate,
    db: Session = Depends(get_db),
    _: UserDB = Depends(require_role(["admin"])),
):
    existing = db.query(UserDB).filter(UserDB.username == req.username).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El usuario ya existe")
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

@router.put("/{user_id}", response_model=UserOut)
def update_user(
    user_id: str,
    req: UserUpdate,
    db: Session = Depends(get_db),
    _: UserDB = Depends(require_role(["admin"])),
):
    user = db.query(UserDB).filter(UserDB.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    
    if req.name is not None:
        user.name = req.name
    if req.email is not None:
        user.email = req.email
    if req.password is not None and req.password.strip():
        user.hashed_password = get_password_hash(req.password)
    if req.roles is not None:
        user.roles = [r.value if hasattr(r, 'value') else str(r) for r in req.roles]
    if req.isActive is not None:
        user.is_active = req.isActive
    
    db.commit()
    db.refresh(user)
    return user_db_to_out(user)

@router.delete("/{user_id}")
def delete_user(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: UserDB = Depends(require_role(["admin"])),
):
    if current_user.id == user_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No puedes eliminar tu propio usuario")
    user = db.query(UserDB).filter(UserDB.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    
    db.delete(user)
    db.commit()
    return {"message": "Usuario eliminado correctamente"}
