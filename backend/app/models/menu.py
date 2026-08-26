import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, DateTime, JSON
from app.database import Base

class MenuItemDB(Base):
    __tablename__ = "menu_items"

    id = Column(String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(128), nullable=False)
    price_cents = Column(Integer, nullable=False, default=0)
    category = Column(String(64), index=True, nullable=False)
    available = Column(Boolean, default=True, nullable=False)
    stock = Column(Integer, default=99, nullable=False)
    modifiers = Column(JSON, default=list, nullable=False)  # List[{id, name, priceCents}]
    variations = Column(JSON, default=list, nullable=False)  # List[{id, name, priceCents, stock}]
    additional_ids = Column(JSON, default=list, nullable=False)  # List[str]
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

class GlobalAdditionalDB(Base):
    __tablename__ = "global_additionals"

    id = Column(String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(128), nullable=False)
    price_cents = Column(Integer, nullable=False, default=0)
    available = Column(Boolean, default=True, nullable=False)

class SpecialAdditionalDB(Base):
    __tablename__ = "special_additionals"

    id = Column(String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    menu_item_id = Column(String(64), index=True, nullable=False)
    name = Column(String(128), nullable=False)
    price_cents = Column(Integer, nullable=False, default=0)
    available = Column(Boolean, default=True, nullable=False)

class MenuAdditionalAssignmentDB(Base):
    __tablename__ = "menu_additional_assignments"

    id = Column(String(128), primary_key=True)
    menu_item_id = Column(String(64), index=True, nullable=False)
    source = Column(String(32), nullable=False)  # 'global' or 'special'
    additional_id = Column(String(64), index=True, nullable=False)
