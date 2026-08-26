from typing import Optional, List
from pydantic import BaseModel

class LoginRequest(BaseModel):
    username: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserOut"

from app.schemas.user import UserOut
TokenResponse.model_rebuild()
