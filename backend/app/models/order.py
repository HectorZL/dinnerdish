import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime, JSON, Text
from app.database import Base

class OrderDB(Base):
    __tablename__ = "orders"

    id = Column(String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    table_id = Column(String(64), index=True, nullable=False)
    waiter_id = Column(String(64), index=True, nullable=False)
    status = Column(String(32), index=True, nullable=False, default="draft")
    # Statuses: draft, sentToKitchen, prepping, ready, billed, closed
    subtotal_cents = Column(Integer, nullable=False, default=0)
    tax_cents = Column(Integer, nullable=False, default=0)
    total_cents = Column(Integer, nullable=False, default=0)
    items = Column(JSON, nullable=False, default=list)  # List[OrderItem]
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    sent_to_kitchen_at = Column(DateTime, nullable=True)
    ready_at = Column(DateTime, nullable=True)
