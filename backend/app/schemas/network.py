from pydantic import BaseModel, Field


class PresencePing(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)


class NetworkStatusResponse(BaseModel):
    opted_in: bool
    nearby_participants_count: int
    approximate_cell: str
    message: str
