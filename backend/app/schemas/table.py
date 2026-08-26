from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict

class TableStatusEnum(str, Enum):
    available = "available"
    occupied = "occupied"
    reserved = "reserved"

class TableBase(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    number: int
    seats: int = 4
    status: TableStatusEnum = TableStatusEnum.available
    section: Optional[str] = None

class TableCreate(TableBase):
    id: Optional[str] = None

class TableUpdate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    number: Optional[int] = None
    seats: Optional[int] = None
    status: Optional[TableStatusEnum] = None
    section: Optional[str] = None

class TableStatusUpdate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    status: TableStatusEnum

class TableOut(TableBase):
    model_config = ConfigDict(populate_by_name=True, from_attributes=True)

    id: str
