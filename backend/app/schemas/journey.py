from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field
from backend.app.models.journey import JourneyStatus


class JourneyStart(BaseModel):
    destination_name: Optional[str] = Field(None, max_length=255)
    start_lat: float = Field(..., ge=-90.0, le=90.0)
    start_lon: float = Field(..., ge=-180.0, le=180.0)
    destination_lat: Optional[float] = Field(None, ge=-90.0, le=90.0)
    destination_lon: Optional[float] = Field(None, ge=-180.0, le=180.0)


class JourneyLocationPing(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    speed: Optional[float] = None
    accuracy: Optional[float] = None


class JourneyEnd(BaseModel):
    final_lat: Optional[float] = None
    final_lon: Optional[float] = None


class JourneyLocationOut(BaseModel):
    id: str
    latitude: float
    longitude: float
    speed: Optional[float]
    accuracy: Optional[float]
    timestamp: datetime

    class Config:
        from_attributes = True


class JourneyOut(BaseModel):
    id: str
    user_id: str
    status: JourneyStatus
    destination_name: Optional[str]
    start_lat: float
    start_lon: float
    current_lat: Optional[float]
    current_lon: Optional[float]
    destination_lat: Optional[float]
    destination_lon: Optional[float]
    start_time: datetime
    end_time: Optional[datetime]
    total_distance_km: float
    max_reported_risk_encountered: str
    created_at: datetime

    class Config:
        from_attributes = True


class JourneyShareCreate(BaseModel):
    duration_minutes: int = Field(30, ge=5, le=1440)  # 5 mins to 24 hours


class JourneyShareOut(BaseModel):
    id: str
    journey_id: str
    share_token: str
    expires_at: datetime
    is_revoked: bool
    views_count: int
    created_at: datetime
    share_url: Optional[str] = None

    class Config:
        from_attributes = True


class PublicShareAccessOut(BaseModel):
    journey_id: str
    status: JourneyStatus
    destination_name: Optional[str]
    current_lat: Optional[float]
    current_lon: Optional[float]
    start_time: datetime
    last_update_time: Optional[datetime]
    total_distance_km: float
    expires_at: datetime
    is_valid: bool
