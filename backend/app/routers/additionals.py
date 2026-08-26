import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.menu import (
    GlobalAdditionalDB,
    SpecialAdditionalDB,
    MenuAdditionalAssignmentDB,
    MenuItemDB,
)
from app.models.user import UserDB
from app.schemas.menu import (
    GlobalAdditionalCreate,
    GlobalAdditionalUpdate,
    GlobalAdditionalOut,
    SpecialAdditionalCreate,
    SpecialAdditionalOut,
    MenuAdditionalAssignmentCreate,
    MenuAdditionalAssignmentOut,
    AssignedAdditionalOut,
)
from app.core.dependencies import get_current_user, require_role

router = APIRouter(prefix="/api/additionals", tags=["additionals"])

# --- Global Additionals ---
@router.get("", response_model=List[GlobalAdditionalOut])
def get_global_additionals(
    onlyAvailable: bool = Query(False, alias="onlyAvailable"),
    db: Session = Depends(get_db),
):
    query = db.query(GlobalAdditionalDB)
    if onlyAvailable:
        query = query.filter(GlobalAdditionalDB.available == True)
    items = query.all()
    return [
        GlobalAdditionalOut(
            id=i.id,
            name=i.name,
            priceCents=i.price_cents,
            available=i.available,
        )
        for i in items
    ]

@router.get("/{additional_id}", response_model=GlobalAdditionalOut)
def get_global_additional(additional_id: str, db: Session = Depends(get_db)):
    item = db.query(GlobalAdditionalDB).filter(GlobalAdditionalDB.id == additional_id).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Adicional no encontrado")
    return GlobalAdditionalOut(
        id=item.id,
        name=item.name,
        priceCents=item.price_cents,
        available=item.available,
    )

@router.post("", response_model=GlobalAdditionalOut)
def create_global_additional(
    req: GlobalAdditionalCreate,
    db: Session = Depends(get_db),
    _: UserDB = Depends(require_role(["admin", "cocinero"])),
):
    item_id = req.id if req.id else str(uuid.uuid4())
    item = GlobalAdditionalDB(
        id=item_id,
        name=req.name,
        price_cents=req.priceCents,
        available=req.available,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return GlobalAdditionalOut(
        id=item.id,
        name=item.name,
        priceCents=item.price_cents,
        available=item.available,
    )

@router.put("/{additional_id}", response_model=GlobalAdditionalOut)
def update_global_additional(
    additional_id: str,
    req: GlobalAdditionalUpdate,
    db: Session = Depends(get_db),
    _: UserDB = Depends(require_role(["admin", "cocinero"])),
):
    item = db.query(GlobalAdditionalDB).filter(GlobalAdditionalDB.id == additional_id).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Adicional no encontrado")
    
    if req.name is not None:
        item.name = req.name
    if req.priceCents is not None:
        item.price_cents = req.priceCents
    if req.available is not None:
        item.available = req.available

    db.commit()
    db.refresh(item)
    return GlobalAdditionalOut(
        id=item.id,
        name=item.name,
        priceCents=item.price_cents,
        available=item.available,
    )

@router.delete("/{additional_id}")
def delete_global_additional(
    additional_id: str,
    db: Session = Depends(get_db),
    _: UserDB = Depends(require_role(["admin"])),
):
    item = db.query(GlobalAdditionalDB).filter(GlobalAdditionalDB.id == additional_id).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Adicional no encontrado")
    
    # Cascade delete assignments
    db.query(MenuAdditionalAssignmentDB).filter(
        MenuAdditionalAssignmentDB.additional_id == additional_id,
        MenuAdditionalAssignmentDB.source == "global",
    ).delete(synchronize_session=False)

    db.delete(item)
    db.commit()
    return {"message": "Adicional eliminado correctamente"}

# --- Special Additionals ---
@router.get("/special", response_model=List[SpecialAdditionalOut])
def get_special_additionals(
    menuItemId: Optional[str] = Query(None, alias="menuItemId"),
    db: Session = Depends(get_db),
):
    query = db.query(SpecialAdditionalDB)
    if menuItemId:
        query = query.filter(SpecialAdditionalDB.menu_item_id == menuItemId)
    items = query.all()
    return [
        SpecialAdditionalOut(
            id=i.id,
            menuItemId=i.menu_item_id,
            name=i.name,
            priceCents=i.price_cents,
            available=i.available,
        )
        for i in items
    ]

@router.post("/special", response_model=SpecialAdditionalOut)
def create_special_additional(
    req: SpecialAdditionalCreate,
    db: Session = Depends(get_db),
    _: UserDB = Depends(require_role(["admin", "cocinero"])),
):
    item_id = req.id if req.id else str(uuid.uuid4())
    item = SpecialAdditionalDB(
        id=item_id,
        menu_item_id=req.menuItemId,
        name=req.name,
        price_cents=req.priceCents,
        available=req.available,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return SpecialAdditionalOut(
        id=item.id,
        menuItemId=item.menu_item_id,
        name=item.name,
        priceCents=item.price_cents,
        available=item.available,
    )

@router.delete("/special/{special_id}")
def delete_special_additional(
    special_id: str,
    db: Session = Depends(get_db),
    _: UserDB = Depends(require_role(["admin"])),
):
    item = db.query(SpecialAdditionalDB).filter(SpecialAdditionalDB.id == special_id).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Adicional especial no encontrado")
    
    # Cascade delete assignments
    db.query(MenuAdditionalAssignmentDB).filter(
        MenuAdditionalAssignmentDB.additional_id == special_id,
        MenuAdditionalAssignmentDB.source == "special",
    ).delete(synchronize_session=False)

    db.delete(item)
    db.commit()
    return {"message": "Adicional especial eliminado correctamente"}

# --- Assignments ---
@router.get("/assignments", response_model=List[MenuAdditionalAssignmentOut])
def get_assignments(
    menuItemId: Optional[str] = Query(None, alias="menuItemId"),
    db: Session = Depends(get_db),
):
    query = db.query(MenuAdditionalAssignmentDB)
    if menuItemId:
        query = query.filter(MenuAdditionalAssignmentDB.menu_item_id == menuItemId)
    items = query.all()
    return [
        MenuAdditionalAssignmentOut(
            id=i.id,
            menuItemId=i.menu_item_id,
            source=i.source,
            additionalId=i.additional_id,
        )
        for i in items
    ]

@router.post("/assignments", response_model=MenuAdditionalAssignmentOut)
def create_assignment(
    req: MenuAdditionalAssignmentCreate,
    db: Session = Depends(get_db),
    _: UserDB = Depends(require_role(["admin", "cocinero"])),
):
    stable_id = req.id if req.id else f"menu-additional-assignment:{len(req.menuItemId)}:{req.menuItemId}:{len(req.source)}:{req.source}:{len(req.additionalId)}:{req.additionalId}"
    existing = db.query(MenuAdditionalAssignmentDB).filter(MenuAdditionalAssignmentDB.id == stable_id).first()
    if existing:
        return MenuAdditionalAssignmentOut(
            id=existing.id,
            menuItemId=existing.menu_item_id,
            source=existing.source,
            additionalId=existing.additional_id,
        )
    
    assignment = MenuAdditionalAssignmentDB(
        id=stable_id,
        menu_item_id=req.menuItemId,
        source=req.source,
        additional_id=req.additionalId,
    )
    db.add(assignment)
    db.commit()
    db.refresh(assignment)
    return MenuAdditionalAssignmentOut(
        id=assignment.id,
        menuItemId=assignment.menu_item_id,
        source=assignment.source,
        additionalId=assignment.additional_id,
    )

@router.delete("/assignments/{assignment_id}")
def delete_assignment(
    assignment_id: str,
    db: Session = Depends(get_db),
    _: UserDB = Depends(require_role(["admin", "cocinero"])),
):
    item = db.query(MenuAdditionalAssignmentDB).filter(MenuAdditionalAssignmentDB.id == assignment_id).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Asignación no encontrada")
    
    db.delete(item)
    db.commit()
    return {"message": "Asignación eliminada correctamente"}

@router.get("/assigned/{menu_item_id}", response_model=List[AssignedAdditionalOut])
def get_assigned_additionals(menu_item_id: str, db: Session = Depends(get_db)):
    assignments = db.query(MenuAdditionalAssignmentDB).filter(
        MenuAdditionalAssignmentDB.menu_item_id == menu_item_id
    ).all()
    
    result: List[AssignedAdditionalOut] = []
    for ass in assignments:
        if ass.source == "global":
            g = db.query(GlobalAdditionalDB).filter(GlobalAdditionalDB.id == ass.additional_id).first()
            if g:
                result.append(AssignedAdditionalOut(
                    assignmentId=ass.id,
                    additionalId=g.id,
                    source="global",
                    name=g.name,
                    priceCents=g.price_cents,
                    available=g.available,
                ))
        elif ass.source == "special":
            s = db.query(SpecialAdditionalDB).filter(SpecialAdditionalDB.id == ass.additional_id).first()
            if s:
                result.append(AssignedAdditionalOut(
                    assignmentId=ass.id,
                    additionalId=s.id,
                    source="special",
                    name=s.name,
                    priceCents=s.price_cents,
                    available=s.available,
                ))
    return result
