from enum import Enum
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict

class OrderStatusEnum(str, Enum):
    draft = "draft"
    sentToKitchen = "sentToKitchen"
    prepping = "prepping"
    ready = "ready"
    billed = "billed"
    closed = "closed"

class ItemOrderStatusEnum(str, Enum):
    pending = "pending"
    sent = "sent"
    preparing = "preparing"
    ready = "ready"
    served = "served"

class SelectedAdditionalSchema(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: str
    additionalId: str = Field(alias="additionalId")
    name: str
    priceCents: int = Field(default=0, alias="priceCents")
    source: str = "global"  # 'global' | 'special'

class OrderItemSchema(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: str
    menuItemId: str = Field(alias="menuItemId")
    quantity: int = 1
    notes: Optional[str] = None
    status: ItemOrderStatusEnum = ItemOrderStatusEnum.pending
    modifierIds: List[str] = Field(default_factory=list, alias="modifierIds")
    priceCents: int = Field(default=0, alias="priceCents")
    name: Optional[str] = None
    variationId: Optional[str] = Field(default=None, alias="variationId")
    selectedAdditionals: List[SelectedAdditionalSchema] = Field(
        default_factory=list, alias="selectedAdditionals"
    )

class OrderCreateDraft(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    waiterId: str = Field(alias="waiterId")
    tableId: Optional[str] = Field(default=None, alias="tableId")

class OrderUpdateTable(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    tableId: str = Field(alias="tableId")

class OrderAddItem(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    item: OrderItemSchema

class OrderAddCashierAdditional(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    additionalId: str = Field(alias="additionalId")
    quantity: int = 1
    byUserId: str = Field(alias="byUserId")

class OrderUpdateItem(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    item: OrderItemSchema
    byUserId: str = Field(alias="byUserId")

class OrderUpdateStatus(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    status: OrderStatusEnum
    byUserId: str = Field(alias="byUserId")

class OrderUpdateItemStatus(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    status: ItemOrderStatusEnum
    byUserId: str = Field(alias="byUserId")

class OrderOut(BaseModel):
    model_config = ConfigDict(populate_by_name=True, from_attributes=True)

    id: str
    tableId: str = Field(alias="tableId")
    waiterId: str = Field(alias="waiterId")
    items: List[OrderItemSchema] = Field(default_factory=list)
    status: OrderStatusEnum
    subtotalCents: int = Field(default=0, alias="subtotalCents")
    taxCents: int = Field(default=0, alias="taxCents")
    totalCents: int = Field(default=0, alias="totalCents")
    createdAt: str = Field(alias="createdAt")
    sentToKitchenAt: Optional[str] = Field(default=None, alias="sentToKitchenAt")
    readyAt: Optional[str] = Field(default=None, alias="readyAt")
    notes: Optional[str] = None
