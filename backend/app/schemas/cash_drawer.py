from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict

class CashDrawerStatusEnum(str, Enum):
    open = "open"
    closed = "closed"
    reconciled = "reconciled"

class OpenDrawerRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    cashierId: str = Field(alias="cashierId")
    startingBalanceCents: int = Field(default=0, alias="startingBalanceCents")

class CloseDrawerRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    sessionId: str = Field(alias="sessionId")
    actualBalanceCents: int = Field(alias="actualBalanceCents")

class ReconcileRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    sessionId: str = Field(alias="sessionId")
    actualBalanceCents: int = Field(alias="actualBalanceCents")

class CashDrawerSessionOut(BaseModel):
    model_config = ConfigDict(populate_by_name=True, from_attributes=True)

    id: str
    cashierId: str = Field(alias="cashierId")
    openedAt: str = Field(alias="openedAt")
    closedAt: Optional[str] = Field(default=None, alias="closedAt")
    startingBalanceCents: int = Field(default=0, alias="startingBalanceCents")
    expectedBalanceCents: int = Field(default=0, alias="expectedBalanceCents")
    actualBalanceCents: int = Field(default=0, alias="actualBalanceCents")
    differenceCents: int = Field(default=0, alias="differenceCents")
    status: CashDrawerStatusEnum
