from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
from backend.app.models.incident import IncidentCategory, IncidentSeverity, IncidentStatus


class IncidentCreate(BaseModel):
    category: IncidentCategory
    severity: IncidentSeverity = IncidentSeverity.MEDIUM
    description: str = Field(..., min_length=5, max_length=2000)
    incident_time: Optional[datetime] = None
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    is_anonymous: bool = False


class IncidentModeration(BaseModel):
    status: IncidentStatus
    moderator_notes: Optional[str] = Field(None, max_length=500)


class IncidentOut(BaseModel):
    id: str
    reporter_id: Optional[str]
    is_anonymous: bool
    category: IncidentCategory
    severity: IncidentSeverity
    description: str
    incident_time: datetime
    latitude: float
    longitude: float
    status: IncidentStatus
    moderator_notes: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True
