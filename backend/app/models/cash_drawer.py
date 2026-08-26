import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime
from app.database import Base

class CashDrawerSessionDB(Base):
    __tablename__ = "cash_drawer_sessions"

    id = Column(String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    cashier_id = Column(String(64), index=True, nullable=False)
    opened_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    closed_at = Column(DateTime, nullable=True)
    starting_balance_cents = Column(Integer, default=0, nullable=False)
    expected_balance_cents = Column(Integer, default=0, nullable=False)
    actual_balance_cents = Column(Integer, default=0, nullable=False)
    difference_cents = Column(Integer, default=0, nullable=False)
    status = Column(String(32), default="open", nullable=False)  # open, closed, reconciled
