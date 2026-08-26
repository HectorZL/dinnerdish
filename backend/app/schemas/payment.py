from enum import Enum
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict

class PaymentMethodEnum(str, Enum):
    cash = "cash"
    card = "card"
    transfer = "transfer"
    other = "other"

class PaymentStatusEnum(str, Enum):
    pending = "pending"
    completed = "completed"
    refunded = "refunded"
    failed = "failed"

class PaymentRequestCreate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    orderId: str = Field(alias="orderId")
    requestedBy: str = Field(alias="requestedBy")
    reason: Optional[str] = None

class PaymentProcessRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    orderId: str = Field(alias="orderId")
    amountCents: int = Field(alias="amountCents")
    method: PaymentMethodEnum
    processedBy: str = Field(alias="processedBy")

class SplitPaymentRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    orderId: str = Field(alias="orderId")
    splitAmountsCents: List[int] = Field(alias="splitAmountsCents")
    processedBy: str = Field(alias="processedBy")

class PaymentTransactionOut(BaseModel):
    model_config = ConfigDict(populate_by_name=True, from_attributes=True)

    id: str
    orderId: str = Field(alias="orderId")
    processedBy: str = Field(alias="processedBy")
    amountCents: int = Field(alias="amountCents")
    method: PaymentMethodEnum
    status: PaymentStatusEnum
    createdAt: str = Field(alias="createdAt")
    notes: Optional[str] = None

class PaymentSummaryOut(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    method: PaymentMethodEnum
    totalAmountCents: int = Field(alias="totalAmountCents")
    transactionCount: int = Field(alias="transactionCount")
