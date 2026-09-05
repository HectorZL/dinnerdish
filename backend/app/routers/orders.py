import uuid
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified
from app.database import get_db
from app.models.order import OrderDB
from app.models.table import TableDB
from app.models.menu import MenuItemDB, GlobalAdditionalDB
from app.models.audit import AuditEntryDB
from app.models.user import UserDB
from app.schemas.order import (
    OrderCreateDraft,
    OrderUpdateTable,
    OrderAddItem,
    OrderAddCashierAdditional,
    OrderUpdateItem,
    OrderUpdateStatus,
    OrderUpdateItemStatus,
    OrderOut,
    OrderItemSchema,
    OrderStatusEnum,
    ItemOrderStatusEnum,
    SelectedAdditionalSchema,
)
from app.core.dependencies import get_current_user
from app.core.websocket_manager import ws_manager

router = APIRouter(prefix="/api/orders", tags=["orders"])

def recalculate_order_totals(order: OrderDB):
    items = order.items or []
    subtotal = 0
    for item in items:
        base_price = item.get("priceCents", 0)
        qty = item.get("quantity", 1)
        add_total = sum(a.get("priceCents", 0) for a in item.get("selectedAdditionals", []))
        subtotal += (base_price + add_total) * qty
    
    order.subtotal_cents = subtotal
    order.tax_cents = 0
    order.total_cents = subtotal + order.tax_cents

def order_db_to_out(order: OrderDB) -> OrderOut:
    raw_items = order.items or []
    parsed_items = []
    for it in raw_items:
        parsed_items.append(OrderItemSchema(
            id=it.get("id", str(uuid.uuid4())),
            menuItemId=it.get("menuItemId", ""),
            quantity=it.get("quantity", 1),
            notes=it.get("notes"),
            status=ItemOrderStatusEnum(it.get("status", "pending")) if it.get("status") in ItemOrderStatusEnum._value2member_map_ else ItemOrderStatusEnum.pending,
            modifierIds=it.get("modifierIds", []),
            priceCents=it.get("priceCents", 0),
            name=it.get("name"),
            variationId=it.get("variationId"),
            selectedAdditionals=[
                SelectedAdditionalSchema(
                    id=a.get("id", str(uuid.uuid4())),
                    additionalId=a.get("additionalId", ""),
                    name=a.get("name", ""),
                    priceCents=a.get("priceCents", 0),
                    source=a.get("source", "global"),
                ) for a in it.get("selectedAdditionals", [])
            ],
        ))
    
    return OrderOut(
        id=order.id,
        tableId=order.table_id,
        waiterId=order.waiter_id,
        items=parsed_items,
        status=OrderStatusEnum(order.status) if order.status in OrderStatusEnum._value2member_map_ else OrderStatusEnum.draft,
        subtotalCents=order.subtotal_cents,
        taxCents=order.tax_cents,
        totalCents=order.total_cents,
        createdAt=order.created_at.isoformat() if order.created_at else datetime.utcnow().isoformat(),
        sentToKitchenAt=order.sent_to_kitchen_at.isoformat() if order.sent_to_kitchen_at else None,
        readyAt=order.ready_at.isoformat() if order.ready_at else None,
        notes=order.notes,
    )

@router.get("/active", response_model=List[OrderOut])
def get_active_orders(db: Session = Depends(get_db)):
    orders = db.query(OrderDB).filter(OrderDB.status != "closed").order_by(OrderDB.created_at.desc()).all()
    valid_orders = [
        o for o in orders
        if not (o.status == "draft" and (o.table_id == "unassigned" or not o.items))
    ]
    return [order_db_to_out(o) for o in valid_orders]

@router.get("", response_model=List[OrderOut])
def get_all_orders(db: Session = Depends(get_db)):
    orders = db.query(OrderDB).order_by(OrderDB.created_at.desc()).all()
    return [order_db_to_out(o) for o in orders]

@router.get("/{order_id}", response_model=OrderOut)
def get_order(order_id: str, db: Session = Depends(get_db)):
    order = db.query(OrderDB).filter(OrderDB.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pedido no encontrado")
    return order_db_to_out(order)

@router.post("/draft", response_model=OrderOut)
async def create_draft(
    req: OrderCreateDraft,
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    table_id = req.tableId or "unassigned"
    order = OrderDB(
        id=str(uuid.uuid4()),
        table_id=table_id,
        waiter_id=req.waiterId,
        status="draft",
        subtotal_cents=0,
        tax_cents=0,
        total_cents=0,
        items=[],
        created_at=datetime.utcnow(),
    )
    db.add(order)
    db.commit()
    db.refresh(order)
    out = order_db_to_out(order)
    await ws_manager.broadcast("order_created", out.model_dump(by_alias=True))
    return out

@router.put("/{order_id}/table", response_model=OrderOut)
async def update_order_table(
    order_id: str,
    req: OrderUpdateTable,
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    order = db.query(OrderDB).filter(OrderDB.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pedido no encontrado")
    
    order.table_id = req.tableId
    
    # Update table status to occupied if table exists
    table = db.query(TableDB).filter(TableDB.id == req.tableId).first()
    if table:
        table.status = "occupied"

    db.commit()
    db.refresh(order)
    out = order_db_to_out(order)
    await ws_manager.broadcast("order_updated", out.model_dump(by_alias=True))
    return out

@router.post("/{order_id}/items", response_model=OrderOut)
async def add_item_to_order(
    order_id: str,
    req: OrderAddItem,
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    order = db.query(OrderDB).filter(OrderDB.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pedido no encontrado")
    
    items = list(order.items or [])
    new_item_dict = req.item.model_dump(by_alias=True)
    if not new_item_dict.get("id"):
        new_item_dict["id"] = str(uuid.uuid4())
    
    items.append(new_item_dict)
    order.items = items
    flag_modified(order, "items")
    recalculate_order_totals(order)

    db.commit()
    db.refresh(order)
    out = order_db_to_out(order)
    await ws_manager.broadcast("order_updated", out.model_dump(by_alias=True))
    return out

@router.post("/{order_id}/cashier-additional", response_model=OrderOut)
async def add_cashier_additional(
    order_id: str,
    req: OrderAddCashierAdditional,
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    order = db.query(OrderDB).filter(OrderDB.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pedido no encontrado")
    
    additional = db.query(GlobalAdditionalDB).filter(GlobalAdditionalDB.id == req.additionalId).first()
    add_name = additional.name if additional else "Adicional"
    add_price = additional.price_cents if additional else 0

    item_dict = {
        "id": str(uuid.uuid4()),
        "menuItemId": f"global-additional:{req.additionalId}",
        "quantity": req.quantity,
        "notes": "Adicional de caja",
        "status": "served",
        "modifierIds": [],
        "priceCents": add_price,
        "name": add_name,
        "variationId": None,
        "selectedAdditionals": [],
    }

    items = list(order.items or [])
    items.append(item_dict)
    order.items = items
    flag_modified(order, "items")
    recalculate_order_totals(order)

    # Log audit
    audit = AuditEntryDB(
        id=str(uuid.uuid4()),
        action="add_cashier_additional",
        user_id=req.byUserId,
        timestamp=datetime.utcnow(),
        metadata_json={
            "orderId": order_id,
            "additionalId": req.additionalId,
            "quantity": req.quantity,
        }
    )
    db.add(audit)

    db.commit()
    db.refresh(order)
    out = order_db_to_out(order)
    await ws_manager.broadcast("order_updated", out.model_dump(by_alias=True))
    return out

@router.put("/{order_id}/items", response_model=OrderOut)
async def update_item_in_order(
    order_id: str,
    req: OrderUpdateItem,
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    order = db.query(OrderDB).filter(OrderDB.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pedido no encontrado")
    
    items = list(order.items or [])
    target_id = req.item.id
    updated = False
    for idx, it in enumerate(items):
        if it.get("id") == target_id:
            items[idx] = req.item.model_dump(by_alias=True)
            updated = True
            break
    
    if not updated:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item no encontrado en el pedido")
    
    order.items = items
    flag_modified(order, "items")
    recalculate_order_totals(order)

    db.commit()
    db.refresh(order)
    out = order_db_to_out(order)
    await ws_manager.broadcast("order_updated", out.model_dump(by_alias=True))
    return out

@router.delete("/{order_id}/items/{item_id}", response_model=OrderOut)
async def remove_item_from_order(
    order_id: str,
    item_id: str,
    byUserId: Optional[str] = None,
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    order = db.query(OrderDB).filter(OrderDB.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pedido no encontrado")
    
    items = list(order.items or [])
    items = [it for it in items if it.get("id") != item_id]
    order.items = items
    flag_modified(order, "items")
    recalculate_order_totals(order)

    if byUserId:
        audit = AuditEntryDB(
            id=str(uuid.uuid4()),
            action="remove_order_item",
            user_id=byUserId,
            timestamp=datetime.utcnow(),
            metadata_json={"orderId": order_id, "itemId": item_id}
        )
        db.add(audit)

    db.commit()
    db.refresh(order)
    out = order_db_to_out(order)
    await ws_manager.broadcast("order_updated", out.model_dump(by_alias=True))
    return out

@router.post("/{order_id}/send-to-kitchen", response_model=OrderOut)
async def send_to_kitchen(
    order_id: str,
    db: Session = Depends(get_db),
    current_user: UserDB = Depends(get_current_user),
):
    order = db.query(OrderDB).filter(OrderDB.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pedido no encontrado")
    
    order.status = "sentToKitchen"
    order.sent_to_kitchen_at = datetime.utcnow()
    
    # Update item statuses to sent
    items = list(order.items or [])
    for it in items:
        if it.get("status") in ["pending", "draft", None]:
            it["status"] = "sent"
    order.items = items
    flag_modified(order, "items")

    # Reduce stock for ordered items
    for it in items:
        menu_item_id = it.get("menuItemId")
        if menu_item_id and not menu_item_id.startswith("global-additional:"):
            m_item = db.query(MenuItemDB).filter(MenuItemDB.id == menu_item_id).first()
            if m_item:
                qty = it.get("quantity", 1)
                var_id = it.get("variationId")
                if var_id and m_item.variations:
                    vars_list = list(m_item.variations)
                    for v in vars_list:
                        if v.get("id") == var_id:
                            v["stock"] = max(0, v.get("stock", 0) - qty)
                    m_item.variations = vars_list
                else:
                    m_item.stock = max(0, m_item.stock - qty)

    # Log audit
    audit = AuditEntryDB(
        id=str(uuid.uuid4()),
        action="send_to_kitchen",
        user_id=current_user.id,
        timestamp=datetime.utcnow(),
        metadata_json={"orderId": order_id, "tableId": order.table_id}
    )
    db.add(audit)

    db.commit()
    db.refresh(order)
    out = order_db_to_out(order)
    await ws_manager.broadcast("order_sent_to_kitchen", out.model_dump(by_alias=True))
    return out

@router.put("/{order_id}/status", response_model=OrderOut)
async def update_order_status(
    order_id: str,
    req: OrderUpdateStatus,
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    order = db.query(OrderDB).filter(OrderDB.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pedido no encontrado")
    
    order.status = req.status.value
    if req.status == OrderStatusEnum.ready:
        order.ready_at = datetime.utcnow()
        # Mark all items as ready if not already served
        items = list(order.items or [])
        for it in items:
            if it.get("status") not in ["ready", "served"]:
                it["status"] = "ready"
        order.items = items
        flag_modified(order, "items")
    elif req.status == OrderStatusEnum.prepping:
        items = list(order.items or [])
        for it in items:
            if it.get("status") in ["pending", "sent", None]:
                it["status"] = "preparing"
        order.items = items
        flag_modified(order, "items")
    elif req.status == OrderStatusEnum.closed:
        # Release table if all orders on this table are closed
        table = db.query(TableDB).filter(TableDB.id == order.table_id).first()
        if table:
            other_active = db.query(OrderDB).filter(
                OrderDB.table_id == order.table_id,
                OrderDB.id != order.id,
                OrderDB.status != "closed"
            ).count()
            if other_active == 0:
                table.status = "available"

    # Log audit
    audit = AuditEntryDB(
        id=str(uuid.uuid4()),
        action="update_order_status",
        user_id=req.byUserId,
        timestamp=datetime.utcnow(),
        metadata_json={"orderId": order_id, "newStatus": req.status.value}
    )
    db.add(audit)

    db.commit()
    db.refresh(order)
    out = order_db_to_out(order)
    await ws_manager.broadcast("order_updated", out.model_dump(by_alias=True))
    return out

@router.put("/{order_id}/items/{item_id}/status", response_model=OrderOut)
async def update_order_item_status(
    order_id: str,
    item_id: str,
    req: OrderUpdateItemStatus,
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    order = db.query(OrderDB).filter(OrderDB.id == order_id).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pedido no encontrado")
    
    items = list(order.items or [])
    found = False
    for it in items:
        if it.get("id") == item_id:
            it["status"] = req.status.value
            found = True
            break
    
    if not found:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item no encontrado en el pedido")
    
    order.items = items
    flag_modified(order, "items")

    # Check if all items are ready or served to optionally advance order status
    if all(it.get("status") in ["ready", "served"] for it in items):
        order.status = "ready"
        order.ready_at = datetime.utcnow()
    elif any(it.get("status") == "preparing" for it in items) and order.status == "sentToKitchen":
        order.status = "prepping"

    db.commit()
    db.refresh(order)
    out = order_db_to_out(order)
    await ws_manager.broadcast("order_item_status_updated", {
        "orderId": order_id,
        "itemId": item_id,
        "status": req.status.value,
        "order": out.model_dump(by_alias=True)
    })
    await ws_manager.broadcast("order_updated", out.model_dump(by_alias=True))
    return out
