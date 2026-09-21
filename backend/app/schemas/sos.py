from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
from backend.app.models.sos import SOSStatus


class SOSTrigger(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    accuracy_meters: Optional[float] = Field(10.0, ge=0.0, le=5000.0)
    address_approx: Optional[str] = Field(None, max_length=255)
    journey_id: Optional[str] = Field(None, max_length=36)


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
    accuracy_meters: float = 10.0
    address_approx: Optional[str] = None
    triggered_at: datetime
    resolved_at: Optional[datetime] = None
    contacts_notified_count: int = 0
    notification_status: str = "SENT"
    admin_notes: Optional[str] = None
    responder_id: Optional[str] = None
    journey_id: Optional[str] = None
    share_token: Optional[str] = None
    user_name: Optional[str] = None
    user_phone: Optional[str] = None
    destination_name: Optional[str] = None

    class Config:
        from_attributes = True
