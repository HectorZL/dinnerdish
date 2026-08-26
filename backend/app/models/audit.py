import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, JSON
from app.database import Base

class AuditEntryDB(Base):
    __tablename__ = "audit_entries"

    id = Column(String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    action = Column(String(128), index=True, nullable=False)
    user_id = Column(String(64), index=True, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False)
    metadata_json = Column(JSON, nullable=True)
