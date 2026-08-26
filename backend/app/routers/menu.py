import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.menu import MenuItemDB
from app.models.user import UserDB
from app.schemas.menu import MenuItemCreate, MenuItemUpdate, MenuItemOut, StockAdjustRequest
from app.core.dependencies import get_current_user, require_role
from app.core.websocket_manager import ws_manager

router = APIRouter(prefix="/api/menu", tags=["menu"])

def menu_item_db_to_out(item: MenuItemDB) -> MenuItemOut:
    return MenuItemOut(
        id=item.id,
        name=item.name,
        priceCents=item.price_cents,
        category=item.category,
        available=item.available,
        stock=item.stock,
        modifiers=item.modifiers or [],
        variations=item.variations or [],
        additionalIds=item.additional_ids or [],
    )

@router.get("/categories", response_model=List[str])
def get_categories(db: Session = Depends(get_db)):
    categories = db.query(MenuItemDB.category).distinct().all()
    return [c[0] for c in categories if c[0]]

@router.get("", response_model=List[MenuItemOut])
def get_menu(db: Session = Depends(get_db)):
    items = db.query(MenuItemDB).all()
    return [menu_item_db_to_out(i) for i in items]

@router.get("/{item_id}", response_model=MenuItemOut)
def get_menu_item(item_id: str, db: Session = Depends(get_db)):
    item = db.query(MenuItemDB).filter(MenuItemDB.id == item_id).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Plato no encontrado")
    return menu_item_db_to_out(item)

@router.post("", response_model=MenuItemOut)
async def create_menu_item(
    req: MenuItemCreate,
    db: Session = Depends(get_db),
    _: UserDB = Depends(require_role(["admin", "cocinero"])),
):
    item_id = req.id if req.id else str(uuid.uuid4())
    modifiers_data = [m.model_dump(by_alias=True) for m in req.modifiers]
    variations_data = [v.model_dump(by_alias=True) for v in req.variations]
    
    item = MenuItemDB(
        id=item_id,
        name=req.name,
        price_cents=req.priceCents,
        category=req.category,
        available=req.available,
        stock=req.stock,
        modifiers=modifiers_data,
        variations=variations_data,
        additional_ids=req.additionalIds,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    out = menu_item_db_to_out(item)
    await ws_manager.broadcast("menu_item_created", out.model_dump(by_alias=True))
    return out

@router.put("/{item_id}", response_model=MenuItemOut)
async def update_menu_item(
    item_id: str,
    req: MenuItemUpdate,
    db: Session = Depends(get_db),
    _: UserDB = Depends(require_role(["admin", "cocinero"])),
):
    item = db.query(MenuItemDB).filter(MenuItemDB.id == item_id).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Plato no encontrado")
    
    if req.name is not None:
        item.name = req.name
    if req.priceCents is not None:
        item.price_cents = req.priceCents
    if req.category is not None:
        item.category = req.category
    if req.available is not None:
        item.available = req.available
    if req.stock is not None:
        item.stock = req.stock
    if req.modifiers is not None:
        item.modifiers = [m.model_dump(by_alias=True) for m in req.modifiers]
    if req.variations is not None:
        item.variations = [v.model_dump(by_alias=True) for v in req.variations]
    if req.additionalIds is not None:
        item.additional_ids = req.additionalIds

    db.commit()
    db.refresh(item)
    out = menu_item_db_to_out(item)
    await ws_manager.broadcast("menu_item_updated", out.model_dump(by_alias=True))
    return out

@router.delete("/{item_id}")
async def delete_menu_item(
    item_id: str,
    db: Session = Depends(get_db),
    _: UserDB = Depends(require_role(["admin"])),
):
    item = db.query(MenuItemDB).filter(MenuItemDB.id == item_id).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Plato no encontrado")
    
    db.delete(item)
    db.commit()
    await ws_manager.broadcast("menu_item_deleted", {"id": item_id})
    return {"message": "Plato eliminado correctamente"}

@router.post("/{item_id}/stock")
async def adjust_stock(
    item_id: str,
    req: StockAdjustRequest,
    db: Session = Depends(get_db),
    _: UserDB = Depends(require_role(["admin", "cocinero", "mesero", "cajero"])),
):
    item = db.query(MenuItemDB).filter(MenuItemDB.id == item_id).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Plato no encontrado")
    
    if req.variationId is not None:
        variations = list(item.variations or [])
        var_found = False
        for idx, var in enumerate(variations):
            if var.get("id") == req.variationId:
                current_stock = var.get("stock", 0)
                new_stock = current_stock + req.quantityChange
                if new_stock < 0:
                    raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El stock no puede ser menor a 0")
                variations[idx] = {**var, "stock": new_stock}
                var_found = True
                break
        if not var_found:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Variación no encontrada")
        item.variations = variations
    else:
        new_stock = item.stock + req.quantityChange
        if new_stock < 0:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El stock no puede ser menor a 0")
        item.stock = new_stock

    db.commit()
    db.refresh(item)
    out = menu_item_db_to_out(item)
    await ws_manager.broadcast("stock_updated", {
        "itemId": item_id,
        "variationId": req.variationId,
        "stock": item.stock,
        "item": out.model_dump(by_alias=True),
    })
    return out
