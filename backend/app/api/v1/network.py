from fastapi import APIRouter, Depends
from backend.app.api.deps import get_current_user
from backend.app.models.user import User
from backend.app.schemas.network import PresencePing, NetworkStatusResponse
from backend.app.services.network_service import register_presence, leave_network

router = APIRouter(prefix="/network", tags=["Community Safety Network"])


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
