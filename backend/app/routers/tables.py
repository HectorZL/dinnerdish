import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.table import TableDB
from app.models.user import UserDB
from app.schemas.table import TableCreate, TableUpdate, TableStatusUpdate, TableOut, TableStatusEnum
from app.core.dependencies import get_current_user, require_role
from app.core.websocket_manager import ws_manager

router = APIRouter(prefix="/api/tables", tags=["tables"])

def table_db_to_out(t: TableDB) -> TableOut:
    return TableOut(
        id=t.id,
        number=t.number,
        seats=t.seats,
        status=TableStatusEnum(t.status) if t.status in TableStatusEnum._value2member_map_ else TableStatusEnum.available,
        section=t.section,
    )

@router.get("", response_model=List[TableOut])
def get_tables(db: Session = Depends(get_db)):
    tables = db.query(TableDB).order_by(TableDB.number).all()
    return [table_db_to_out(t) for t in tables]

@router.get("/{table_id}", response_model=TableOut)
def get_table(table_id: str, db: Session = Depends(get_db)):
    table = db.query(TableDB).filter(TableDB.id == table_id).first()
    if not table:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Mesa no encontrada")
    return table_db_to_out(table)

@router.post("", response_model=TableOut)
async def create_table(
    req: TableCreate,
    db: Session = Depends(get_db),
    _: UserDB = Depends(require_role(["admin", "mesero"])),
):
    existing = db.query(TableDB).filter(TableDB.number == req.number).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"La mesa número {req.number} ya existe")
    
    table_id = req.id if req.id else str(uuid.uuid4())
    table = TableDB(
        id=table_id,
        number=req.number,
        seats=req.seats,
        status=req.status.value,
        section=req.section,
    )
    db.add(table)
    db.commit()
    db.refresh(table)
    out = table_db_to_out(table)
    await ws_manager.broadcast("table_created", out.model_dump(by_alias=True))
    return out

@router.put("/{table_id}", response_model=TableOut)
async def update_table(
    table_id: str,
    req: TableUpdate,
    db: Session = Depends(get_db),
    _: UserDB = Depends(require_role(["admin", "mesero"])),
):
    table = db.query(TableDB).filter(TableDB.id == table_id).first()
    if not table:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Mesa no encontrada")
    
    if req.number is not None:
        conflict = db.query(TableDB).filter(TableDB.number == req.number, TableDB.id != table_id).first()
        if conflict:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"La mesa número {req.number} ya existe")
        table.number = req.number
    if req.seats is not None:
        table.seats = req.seats
    if req.status is not None:
        table.status = req.status.value
    if req.section is not None:
        table.section = req.section

    db.commit()
    db.refresh(table)
    out = table_db_to_out(table)
    await ws_manager.broadcast("table_updated", out.model_dump(by_alias=True))
    return out

@router.put("/{table_id}/status", response_model=TableOut)
async def update_table_status(
    table_id: str,
    req: TableStatusUpdate,
    db: Session = Depends(get_db),
    _: UserDB = Depends(get_current_user),
):
    table = db.query(TableDB).filter(TableDB.id == table_id).first()
    if not table:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Mesa no encontrada")
    
    table.status = req.status.value
    db.commit()
    db.refresh(table)
    out = table_db_to_out(table)
    await ws_manager.broadcast("table_updated", out.model_dump(by_alias=True))
    return out
