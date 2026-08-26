from typing import Optional, Dict, Any
from pydantic import BaseModel, Field, ConfigDict

class AuditEntryCreate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    action: str
    userId: str = Field(alias="userId")
    metadata: Optional[Dict[str, Any]] = None
    timestamp: Optional[str] = None

class AuditEntryOut(BaseModel):
    model_config = ConfigDict(populate_by_name=True, from_attributes=True)

    id: str
    action: str
    userId: str = Field(alias="userId")
    timestamp: str
    metadata: Optional[Dict[str, Any]] = None
