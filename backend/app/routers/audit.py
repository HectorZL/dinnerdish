import uuid
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.audit import AuditEntryDB
from app.schemas.audit import AuditEntryCreate, AuditEntryOut
from app.models.user import UserDB
from app.core.dependencies import get_current_user

router = APIRouter(prefix="/api/audit", tags=["audit"])

@router.post("", response_model=AuditEntryOut)
def record_audit(
    req: AuditEntryCreate,
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    timestamp_val = datetime.utcnow()
    if req.timestamp:
        try:
            timestamp_val = datetime.fromisoformat(req.timestamp)
        except Exception:
            pass

    entry = AuditEntryDB(
        id=str(uuid.uuid4()),
        action=req.action,
        user_id=req.userId,
        timestamp=timestamp_val,
        metadata_json=req.metadata,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return AuditEntryOut(
        id=entry.id,
        action=entry.action,
        userId=entry.user_id,
        timestamp=entry.timestamp.isoformat(),
        metadata=entry.metadata_json,
    )

@router.get("", response_model=List[AuditEntryOut])
def list_audit(
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    entries = db.query(AuditEntryDB).order_by(AuditEntryDB.timestamp.desc()).offset(offset).limit(limit).all()
    return [
        AuditEntryOut(
            id=e.id,
            action=e.action,
            userId=e.user_id,
            timestamp=e.timestamp.isoformat() if e.timestamp else datetime.utcnow().isoformat(),
            metadata=e.metadata_json,
        )
        for e in entries
    ]
