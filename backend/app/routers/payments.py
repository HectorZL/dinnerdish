import uuid
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models.payment import PaymentTransactionDB
from app.models.order import OrderDB
from app.models.table import TableDB
from app.models.cash_drawer import CashDrawerSessionDB
from app.models.audit import AuditEntryDB
from app.models.user import UserDB
from app.schemas.payment import (
    PaymentProcessRequest,
    SplitPaymentRequest,
    PaymentTransactionOut,
    PaymentSummaryOut,
    PaymentMethodEnum,
    PaymentStatusEnum,
)
from app.core.dependencies import get_current_user
from app.core.websocket_manager import ws_manager

router = APIRouter(prefix="/api/payments", tags=["payments"])

def tx_db_to_out(tx: PaymentTransactionDB) -> PaymentTransactionOut:
    return PaymentTransactionOut(
        id=tx.id,
        orderId=tx.order_id,
        processedBy=tx.processed_by,
        amountCents=tx.amount_cents,
        method=PaymentMethodEnum(tx.method) if tx.method in PaymentMethodEnum._value2member_map_ else PaymentMethodEnum.cash,
        status=PaymentStatusEnum(tx.status) if tx.status in PaymentStatusEnum._value2member_map_ else PaymentStatusEnum.completed,
        createdAt=tx.created_at.isoformat() if tx.created_at else datetime.utcnow().isoformat(),
        notes=tx.notes,
    )

@router.post("/process", response_model=PaymentTransactionOut)
async def process_payment(
    req: PaymentProcessRequest,
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    order = db.query(OrderDB).filter(OrderDB.id == req.orderId).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pedido no encontrado")
    
    tx = PaymentTransactionDB(
        id=str(uuid.uuid4()),
        order_id=req.orderId,
        processed_by=req.processedBy,
        amount_cents=req.amountCents,
        method=req.method.value,
        status="completed",
        created_at=datetime.utcnow(),
    )
    db.add(tx)

    # Check total payments made for this order
    existing_txs = db.query(PaymentTransactionDB).filter(
        PaymentTransactionDB.order_id == req.orderId,
        PaymentTransactionDB.status == "completed"
    ).all()
    total_paid = sum(t.amount_cents for t in existing_txs) + req.amountCents

    if total_paid >= order.total_cents:
        order.status = "closed"
        # Check if table should be freed
        table = db.query(TableDB).filter(TableDB.id == order.table_id).first()
        if table:
            other_active = db.query(OrderDB).filter(
                OrderDB.table_id == order.table_id,
                OrderDB.id != order.id,
                OrderDB.status != "closed"
            ).count()
            if other_active == 0:
                table.status = "available"

    # If method is cash, update open cash drawer expected balance
    if req.method == PaymentMethodEnum.cash:
        open_session = db.query(CashDrawerSessionDB).filter(CashDrawerSessionDB.status == "open").first()
        if open_session:
            open_session.expected_balance_cents += req.amountCents

    # Record audit log
    audit = AuditEntryDB(
        id=str(uuid.uuid4()),
        action="process_payment",
        user_id=req.processedBy,
        timestamp=datetime.utcnow(),
        metadata_json={
            "orderId": req.orderId,
            "amountCents": req.amountCents,
            "method": req.method.value,
            "transactionId": tx.id,
        }
    )
    db.add(audit)

    db.commit()
    db.refresh(tx)
    out = tx_db_to_out(tx)
    await ws_manager.broadcast("payment_processed", out.model_dump(by_alias=True))
    return out

@router.post("/split", response_model=List[PaymentTransactionOut])
async def split_payment(
    req: SplitPaymentRequest,
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    order = db.query(OrderDB).filter(OrderDB.id == req.orderId).first()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pedido no encontrado")
    
    results = []
    for amt in req.splitAmountsCents:
        tx = PaymentTransactionDB(
            id=str(uuid.uuid4()),
            order_id=req.orderId,
            processed_by=req.processedBy,
            amount_cents=amt,
            method="cash",
            status="completed",
            created_at=datetime.utcnow(),
            notes="Pago dividido",
        )
        db.add(tx)
        results.append(tx)

    db.commit()
    return [tx_db_to_out(t) for t in results]

@router.post("/{transaction_id}/refund", response_model=PaymentTransactionOut)
async def refund_payment(
    transaction_id: str,
    db: Session = Depends(get_db),
    current_user: UserDB = Depends(get_current_user),
):
    tx = db.query(PaymentTransactionDB).filter(PaymentTransactionDB.id == transaction_id).first()
    if not tx:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Transacción no encontrada")
    
    tx.status = "refunded"
    
    # Audit log
    audit = AuditEntryDB(
        id=str(uuid.uuid4()),
        action="refund_payment",
        user_id=current_user.id,
        timestamp=datetime.utcnow(),
        metadata_json={
            "transactionId": transaction_id,
            "orderId": tx.order_id,
            "amountCents": tx.amount_cents,
        }
    )
    db.add(audit)

    db.commit()
    db.refresh(tx)
    out = tx_db_to_out(tx)
    await ws_manager.broadcast("payment_refunded", out.model_dump(by_alias=True))
    return out

@router.get("/history/{order_id}", response_model=List[PaymentTransactionOut])
def get_payment_history(order_id: str, db: Session = Depends(get_db)):
    txs = db.query(PaymentTransactionDB).filter(PaymentTransactionDB.order_id == order_id).all()
    return [tx_db_to_out(t) for t in txs]

@router.get("/summary", response_model=List[PaymentSummaryOut])
def get_payment_summary(
    startDate: Optional[str] = Query(None, alias="startDate"),
    endDate: Optional[str] = Query(None, alias="endDate"),
    db: Session = Depends(get_db),
):
    query = db.query(
        PaymentTransactionDB.method,
        func.sum(PaymentTransactionDB.amount_cents).label("total_amount"),
        func.count(PaymentTransactionDB.id).label("count")
    ).filter(PaymentTransactionDB.status == "completed")

    if startDate:
        try:
            dt_start = datetime.fromisoformat(startDate)
            query = query.filter(PaymentTransactionDB.created_at >= dt_start)
        except Exception:
            pass
    if endDate:
        try:
            dt_end = datetime.fromisoformat(endDate)
            query = query.filter(PaymentTransactionDB.created_at <= dt_end)
        except Exception:
            pass

    rows = query.group_by(PaymentTransactionDB.method).all()
    summary = []
    for r in rows:
        method_str = r[0]
        total_cents = r[1] or 0
        count = r[2] or 0
        method_enum = PaymentMethodEnum(method_str) if method_str in PaymentMethodEnum._value2member_map_ else PaymentMethodEnum.other
        summary.append(PaymentSummaryOut(
            method=method_enum,
            totalAmountCents=total_cents,
            transactionCount=count,
        ))
    return summary
