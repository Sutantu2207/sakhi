from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class EmergencyContactCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    phone: str = Field(..., min_length=5, max_length=25)
    relationship_label: Optional[str] = Field("Emergency Contact", max_length=50)
    notify_on_sos: bool = True
    priority_order: int = Field(1, ge=1, le=10)


class EmergencyContactUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    relationship_label: Optional[str] = None
    notify_on_sos: Optional[bool] = None
    priority_order: Optional[int] = None


class EmergencyContactOut(BaseModel):
    id: str
    user_id: str
    name: str
    phone: str
    relationship_label: Optional[str]
    notify_on_sos: bool
    priority_order: int
    created_at: datetime

    class Config:
        from_attributes = True
