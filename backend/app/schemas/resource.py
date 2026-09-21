from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field
from backend.app.models.resource import ResourceCategory, SupportCategory


class EmergencyResourceCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=255)
    category: ResourceCategory
    phone: str = Field(..., min_length=3, max_length=50)
    address: str = Field(..., min_length=5, max_length=255)
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    is_verified: bool = True
    operating_hours: str = "24/7"


class EmergencyResourceOut(BaseModel):
    id: str
    name: str
    category: ResourceCategory
    phone: str
    address: str
    latitude: float
    longitude: float
    is_verified: bool
    operating_hours: str
    distance_km: Optional[float] = None
    created_at: datetime

    class Config:
        from_attributes = True


class SupportResourceCreate(BaseModel):
    category: SupportCategory
    title: str = Field(..., min_length=2, max_length=255)
    organization: str = Field(..., min_length=2, max_length=255)
    phone: Optional[str] = None
    website: Optional[str] = None
    description: str
    jurisdiction: str = "National / Regional"
    actionable_steps: Optional[str] = None


class SupportResourceOut(BaseModel):
    id: str
    category: SupportCategory
    title: str
    organization: str
    phone: Optional[str]
    website: Optional[str]
    description: str
    jurisdiction: str
    actionable_steps: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True
