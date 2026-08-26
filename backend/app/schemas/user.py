from enum import Enum
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict

class RoleEnum(str, Enum):
    mesero = "mesero"
    cajero = "cajero"
    cocinero = "cocinero"
    admin = "admin"

class UserBase(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    username: str
    name: str
    email: Optional[str] = None
    roles: List[RoleEnum] = Field(default_factory=lambda: [RoleEnum.mesero])
    isActive: bool = Field(default=True, alias="isActive")

class UserCreate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    username: str
    name: str
    password: str
    email: Optional[str] = None
    roles: List[RoleEnum] = Field(default_factory=lambda: [RoleEnum.mesero])
    isActive: bool = Field(default=True, alias="isActive")

class UserUpdate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    name: Optional[str] = None
    email: Optional[str] = None
    password: Optional[str] = None
    roles: Optional[List[RoleEnum]] = None
    isActive: Optional[bool] = Field(default=None, alias="isActive")

class UserOut(BaseModel):
    model_config = ConfigDict(populate_by_name=True, from_attributes=True)

    id: str
    username: str
    name: str
    email: Optional[str] = None
    role: str
    roles: List[str]
    token: Optional[str] = None
    lastLogin: Optional[str] = None
    isActive: bool = Field(default=True, alias="isActive")
