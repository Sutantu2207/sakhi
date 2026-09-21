from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.app.db.session import get_db
from backend.app.api.deps import get_current_user
from backend.app.models.user import User
from backend.app.models.sos import SOSEvent, SOSStatus
from backend.app.schemas.sos import SOSTrigger, SOSCancel, SOSOut
from backend.app.services.sos_service import trigger_sos, cancel_sos

router = APIRouter(prefix="/sos", tags=["Emergency SOS"])


@router.post("/trigger", response_model=SOSOut, status_code=status.HTTP_201_CREATED)
def api_trigger_sos(
    data: SOSTrigger,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return trigger_sos(db, current_user, data)


@router.post("/{sos_id}/cancel", response_model=SOSOut)
def api_cancel_sos(
    sos_id: str,
    data: Optional[SOSCancel] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return cancel_sos(db, current_user, sos_id, data)


@router.get("/active", response_model=Optional[SOSOut])
def api_get_active_sos(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(SOSEvent).filter(
        SOSEvent.user_id == current_user.id,
        SOSEvent.status.in_([SOSStatus.CREATED, SOSStatus.ACTIVE, SOSStatus.ACKNOWLEDGED])
    ).first()


@router.get("/history", response_model=List[SOSOut])
def api_get_sos_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(SOSEvent).filter(
        SOSEvent.user_id == current_user.id
    ).order_by(SOSEvent.triggered_at.desc()).limit(20).all()
