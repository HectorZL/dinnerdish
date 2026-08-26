import uuid
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.cash_drawer import CashDrawerSessionDB
from app.models.audit import AuditEntryDB
from app.models.user import UserDB
from app.schemas.cash_drawer import (
    OpenDrawerRequest,
    CloseDrawerRequest,
    ReconcileRequest,
    CashDrawerSessionOut,
    CashDrawerStatusEnum,
)
from app.core.dependencies import get_current_user

router = APIRouter(prefix="/api/cash-drawer", tags=["cash_drawer"])

def session_db_to_out(s: CashDrawerSessionDB) -> CashDrawerSessionOut:
    return CashDrawerSessionOut(
        id=s.id,
        cashierId=s.cashier_id,
        openedAt=s.opened_at.isoformat() if s.opened_at else datetime.utcnow().isoformat(),
        closedAt=s.closed_at.isoformat() if s.closed_at else None,
        startingBalanceCents=s.starting_balance_cents,
        expectedBalanceCents=s.expected_balance_cents,
        actualBalanceCents=s.actual_balance_cents,
        differenceCents=s.difference_cents,
        status=CashDrawerStatusEnum(s.status) if s.status in CashDrawerStatusEnum._value2member_map_ else CashDrawerStatusEnum.open,
    )

@router.post("/open", response_model=CashDrawerSessionOut)
def open_drawer(
    req: OpenDrawerRequest,
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    # Check if there is already an open session
    open_sess = db.query(CashDrawerSessionDB).filter(CashDrawerSessionDB.status == "open").first()
    if open_sess:
        return session_db_to_out(open_sess)
    
    session = CashDrawerSessionDB(
        id=str(uuid.uuid4()),
        cashier_id=req.cashierId,
        opened_at=datetime.utcnow(),
        starting_balance_cents=req.startingBalanceCents,
        expected_balance_cents=req.startingBalanceCents,
        actual_balance_cents=0,
        difference_cents=0,
        status="open",
    )
    db.add(session)

    audit = AuditEntryDB(
        id=str(uuid.uuid4()),
        action="open_cash_drawer",
        user_id=req.cashierId,
        timestamp=datetime.utcnow(),
        metadata_json={
            "sessionId": session.id,
            "startingBalanceCents": req.startingBalanceCents,
        }
    )
    db.add(audit)

    db.commit()
    db.refresh(session)
    return session_db_to_out(session)

@router.post("/close", response_model=CashDrawerSessionOut)
def close_drawer(
    req: CloseDrawerRequest,
    db: Session = Depends(get_db),
    current_user: UserDB = Depends(get_current_user),
):
    session = db.query(CashDrawerSessionDB).filter(CashDrawerSessionDB.id == req.sessionId).first()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sesión no encontrada")
    
    session.closed_at = datetime.utcnow()
    session.actual_balance_cents = req.actualBalanceCents
    session.difference_cents = req.actualBalanceCents - session.expected_balance_cents
    session.status = "closed"

    audit = AuditEntryDB(
        id=str(uuid.uuid4()),
        action="close_cash_drawer",
        user_id=current_user.id,
        timestamp=datetime.utcnow(),
        metadata_json={
            "sessionId": session.id,
            "actualBalanceCents": req.actualBalanceCents,
            "expectedBalanceCents": session.expected_balance_cents,
            "differenceCents": session.difference_cents,
        }
    )
    db.add(audit)

    db.commit()
    db.refresh(session)
    return session_db_to_out(session)

@router.post("/reconcile", response_model=CashDrawerSessionOut)
def reconcile_drawer(
    req: ReconcileRequest,
    db: Session = Depends(get_db),
    current_user: UserDB = Depends(get_current_user),
):
    session = db.query(CashDrawerSessionDB).filter(CashDrawerSessionDB.id == req.sessionId).first()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sesión no encontrada")
    
    session.actual_balance_cents = req.actualBalanceCents
    session.difference_cents = req.actualBalanceCents - session.expected_balance_cents
    session.status = "reconciled"

    audit = AuditEntryDB(
        id=str(uuid.uuid4()),
        action="reconcile_cash_drawer",
        user_id=current_user.id,
        timestamp=datetime.utcnow(),
        metadata_json={
            "sessionId": session.id,
            "actualBalanceCents": req.actualBalanceCents,
            "differenceCents": session.difference_cents,
        }
    )
    db.add(audit)

    db.commit()
    db.refresh(session)
    return session_db_to_out(session)

@router.get("/current", response_model=Optional[CashDrawerSessionOut])
def get_current_session(db: Session = Depends(get_db)):
    session = db.query(CashDrawerSessionDB).filter(CashDrawerSessionDB.status == "open").first()
    if not session:
        return None
    return session_db_to_out(session)

@router.get("/history", response_model=List[CashDrawerSessionOut])
def get_session_history(
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
):
    sessions = db.query(CashDrawerSessionDB).order_by(CashDrawerSessionDB.opened_at.desc()).limit(limit).all()
    return [session_db_to_out(s) for s in sessions]
