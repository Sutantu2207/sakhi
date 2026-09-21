from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field
from backend.app.models.user import UserRole


class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128)
    full_name: str = Field(..., min_length=2, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    email: str
    full_name: str
    role: UserRole


class UserOut(BaseModel):
    id: str
    email: str
    phone: Optional[str] = None
    full_name: str
    role: UserRole
    is_active: bool
    safety_network_opt_in: bool
    location_retention_days: int
    created_at: datetime

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None


class PrivacySettingsUpdate(BaseModel):
    safety_network_opt_in: Optional[bool] = None
    location_retention_days: Optional[int] = Field(None, ge=1, le=90)


class PasswordChange(BaseModel):
    old_password: str
    new_password: str = Field(..., min_length=6, max_length=128)
