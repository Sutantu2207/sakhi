from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from backend.app.db.session import get_db
from backend.app.api.deps import get_current_user
from backend.app.models.user import User
from backend.app.schemas.network import (
    PresencePing, NetworkStatusResponse, MeshPacketIngest, 
    MeshPacketResponse, MeshStatusResponse, EmergencyHelpline
)
from backend.app.services.network_service import (
    register_presence, leave_network, ingest_mesh_packet, 
    get_mesh_status, get_emergency_helplines
)

router = APIRouter(prefix="/network", tags=["Community Safety & Emergency Mesh"])


@router.post("/ping", response_model=NetworkStatusResponse)
def api_network_ping(
    data: PresencePing,
    current_user: User = Depends(get_current_user)
):
    return register_presence(current_user, data.latitude, data.longitude)


@router.post("/leave")
def api_network_leave(
    current_user: User = Depends(get_current_user)
):
    leave_network(current_user)
    return {"message": "Successfully left safety network presence."}


@router.post("/mesh-gateway", response_model=MeshPacketResponse)
def api_ingest_mesh_packet(
    packet: MeshPacketIngest,
    db: Session = Depends(get_db)
):
    """
    Ingests an emergency packet from an ESP32 hardware gateway or simulation relay.
    No user bearer token required as the packet is authenticated via cryptographic auth_tag.
    """
    return ingest_mesh_packet(db, packet)


@router.get("/mesh-status", response_model=MeshStatusResponse)
def api_get_mesh_status():
    """Returns real-time mesh gateway and packet relay telemetry."""
    return get_mesh_status()


@router.get("/helplines", response_model=List[EmergencyHelpline])
def api_get_helplines():
    """Returns verified national emergency helplines (112, 181, 1930, 1098)."""
    return get_emergency_helplines()
