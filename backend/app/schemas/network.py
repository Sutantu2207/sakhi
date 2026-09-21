from typing import Optional, List
from pydantic import BaseModel, Field


class PresencePing(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)


class NetworkStatusResponse(BaseModel):
    opted_in: bool
    nearby_participants_count: int
    approximate_cell: str
    message: str


class MeshPacketIngest(BaseModel):
    version: int = 1
    message_id: str = Field(..., min_length=6, max_length=64)
    ephemeral_id: str = Field(..., min_length=6, max_length=64)
    message_type: str = Field("SOS", max_length=20)
    timestamp: str
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    accuracy_meters: Optional[float] = 15.0
    sequence: int = 1
    ttl: int = Field(5, ge=0, le=16)
    hop_count: int = Field(1, ge=0, le=16)
    priority: str = Field("EMERGENCY", max_length=20)
    gateway_id: Optional[str] = Field("ESP32-GW-01", max_length=64)
    auth_tag: Optional[str] = Field(None, max_length=64)


class MeshPacketResponse(BaseModel):
    status: str
    message_id: str
    sos_id: Optional[str] = None
    ack_timestamp: str
    relayed_by_gateway: str
    deduplicated: bool = False


class MeshStatusResponse(BaseModel):
    status: str
    active_gateways_count: int
    total_packets_relayed: int
    emergency_sos_packets_count: int
    last_packet_received_at: Optional[str] = None
    simulation_mode: bool = False


class EmergencyHelpline(BaseModel):
    number: str
    name: str
    category: str
    badge_color: str
    description: str
    priority: int
