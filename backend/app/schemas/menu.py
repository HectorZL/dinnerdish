from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict

class ModifierSchema(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: str
    name: str
    priceCents: int = Field(default=0, alias="priceCents")

class MenuItemVariationSchema(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: str
    name: str
    priceCents: int = Field(default=0, alias="priceCents")
    stock: int = 99

class MenuItemBase(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    name: str
    priceCents: int = Field(default=0, alias="priceCents")
    category: str
    available: bool = True
    stock: int = 99
    modifiers: List[ModifierSchema] = Field(default_factory=list)
    variations: List[MenuItemVariationSchema] = Field(default_factory=list)
    additionalIds: List[str] = Field(default_factory=list, alias="additionalIds")

class MenuItemCreate(MenuItemBase):
    id: Optional[str] = None

class MenuItemUpdate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    name: Optional[str] = None
    priceCents: Optional[int] = Field(default=None, alias="priceCents")
    category: Optional[str] = None
    available: Optional[bool] = None
    stock: Optional[int] = None
    modifiers: Optional[List[ModifierSchema]] = None
    variations: Optional[List[MenuItemVariationSchema]] = None
    additionalIds: Optional[List[str]] = Field(default=None, alias="additionalIds")

class MenuItemOut(MenuItemBase):
    model_config = ConfigDict(populate_by_name=True, from_attributes=True)

    id: str

class StockAdjustRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    quantityChange: int = Field(alias="quantityChange")
    variationId: Optional[str] = Field(default=None, alias="variationId")

# Global Additionals
class GlobalAdditionalBase(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    name: str
    priceCents: int = Field(default=0, alias="priceCents")
    available: bool = True

class GlobalAdditionalCreate(GlobalAdditionalBase):
    id: Optional[str] = None

class GlobalAdditionalUpdate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    name: Optional[str] = None
    priceCents: Optional[int] = Field(default=None, alias="priceCents")
    available: Optional[bool] = None

class GlobalAdditionalOut(GlobalAdditionalBase):
    model_config = ConfigDict(populate_by_name=True, from_attributes=True)

    id: str

# Special Additionals
class SpecialAdditionalBase(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    menuItemId: str = Field(alias="menuItemId")
    name: str
    priceCents: int = Field(default=0, alias="priceCents")
    available: bool = True

class SpecialAdditionalCreate(SpecialAdditionalBase):
    id: Optional[str] = None

class SpecialAdditionalOut(SpecialAdditionalBase):
    model_config = ConfigDict(populate_by_name=True, from_attributes=True)

    id: str

# Assignments
class MenuAdditionalAssignmentBase(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    menuItemId: str = Field(alias="menuItemId")
    source: str  # 'global' | 'special'
    additionalId: str = Field(alias="additionalId")

class MenuAdditionalAssignmentCreate(MenuAdditionalAssignmentBase):
    id: Optional[str] = None

class MenuAdditionalAssignmentOut(MenuAdditionalAssignmentBase):
    model_config = ConfigDict(populate_by_name=True, from_attributes=True)

    id: str

class AssignedAdditionalOut(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    assignmentId: str = Field(alias="assignmentId")
    additionalId: str = Field(alias="additionalId")
    source: str
    name: str
    priceCents: int = Field(alias="priceCents")
    available: bool
