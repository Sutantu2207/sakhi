from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
from backend.app.models.sos import SOSStatus


class SOSTrigger(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    address_approx: Optional[str] = Field(None, max_length=255)


class SOSCancel(BaseModel):
    reason: Optional[str] = Field("Accidental trigger", max_length=255)


class SOSResolve(BaseModel):
    admin_notes: Optional[str] = Field(None, max_length=500)


class SOSOut(BaseModel):
    id: str
    user_id: str
    status: SOSStatus
    latitude: float
    longitude: float
    address_approx: Optional[str]
    triggered_at: datetime
    resolved_at: Optional[datetime]
    contacts_notified_count: int
    notification_status: str
    admin_notes: Optional[str]
    responder_id: Optional[str]

    class Config:
        from_attributes = True
