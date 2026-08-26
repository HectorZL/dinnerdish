import uuid
from sqlalchemy import Column, String, Integer
from app.database import Base

class TableDB(Base):
    __tablename__ = "tables"

    id = Column(String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    number = Column(Integer, unique=True, index=True, nullable=False)
    seats = Column(Integer, nullable=False, default=4)
    status = Column(String(32), nullable=False, default="available")  # available, occupied, reserved
    section = Column(String(64), nullable=True)
