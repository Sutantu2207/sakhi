from typing import List, Optional, Dict
from pydantic import BaseModel, Field


class AreaRiskRequest(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    radius_km: float = Field(1.0, ge=0.1, le=10.0)


class ContributingFactor(BaseModel):
    name: str
    impact: str  # e.g., "Increased reported night incidents in last 30 days" or "Nearby emergency station within 400m"


class AreaRiskResponse(BaseModel):
    latitude: float
    longitude: float
    risk_score: float = Field(..., ge=0.0, le=1.0)
    risk_category: str  # lower_reported_risk, moderate_reported_risk, higher_reported_risk
    confidence: float
    summary: str
    contributing_factors: List[str]
    nearby_incidents_count: int
    nearest_police_km: Optional[float] = None
    nearest_hospital_km: Optional[float] = None
    model_version: str


class RoutePoint(BaseModel):
    latitude: float
    longitude: float


class RouteOption(BaseModel):
    name: str
    distance_km: float
    estimated_minutes: int
    risk_category: str
    risk_score: float
    explanation: str


class RouteRiskRequest(BaseModel):
    origin_lat: float
    origin_lon: float
    destination_lat: float
    destination_lon: float


class RouteRiskResponse(BaseModel):
    routes: List[RouteOption]
