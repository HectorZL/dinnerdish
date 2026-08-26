import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime, Text
from app.database import Base

class PaymentTransactionDB(Base):
    __tablename__ = "payment_transactions"

    id = Column(String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    order_id = Column(String(64), index=True, nullable=False)
    processed_by = Column(String(64), nullable=False)
    amount_cents = Column(Integer, nullable=False, default=0)
    method = Column(String(32), nullable=False)  # cash, card, transfer, other
    status = Column(String(32), nullable=False, default="completed")  # pending, completed, refunded, failed
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    notes = Column(Text, nullable=True)
