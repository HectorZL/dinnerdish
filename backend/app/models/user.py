import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, JSON
from app.database import Base

class UserDB(Base):
    __tablename__ = "users"

    id = Column(String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    username = Column(String(64), unique=True, index=True, nullable=False)
    name = Column(String(128), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    email = Column(String(128), nullable=True)
    roles = Column(JSON, nullable=False, default=["mesero"])  # List of strings e.g. ["mesero", "admin"]
    is_active = Column(Boolean, default=True, nullable=False)
    last_login = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
