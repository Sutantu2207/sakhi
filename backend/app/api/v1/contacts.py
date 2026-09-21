from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.app.db.session import get_db
from backend.app.api.deps import get_current_user
from backend.app.models.user import User
from backend.app.models.contact import EmergencyContact
from backend.app.schemas.contact import EmergencyContactCreate, EmergencyContactUpdate, EmergencyContactOut

router = APIRouter(prefix="/contacts", tags=["Emergency Contacts"])


@router.get("/", response_model=List[EmergencyContactOut])
def get_contacts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(EmergencyContact).filter(
        EmergencyContact.user_id == current_user.id
    ).order_by(EmergencyContact.priority_order.asc()).all()


@router.post("/", response_model=EmergencyContactOut, status_code=status.HTTP_201_CREATED)
def add_contact(
    data: EmergencyContactCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    count = db.query(EmergencyContact).filter(EmergencyContact.user_id == current_user.id).count()
    if count >= 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximum of 10 emergency contacts reached."
        )

    contact = EmergencyContact(
        user_id=current_user.id,
        name=data.name,
        phone=data.phone,
        relationship_label=data.relationship_label,
        notify_on_sos=data.notify_on_sos,
        priority_order=data.priority_order
    )
    db.add(contact)
    db.commit()
    db.refresh(contact)
    return contact


@router.put("/{contact_id}", response_model=EmergencyContactOut)
def update_contact(
    contact_id: str,
    data: EmergencyContactUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    contact = db.query(EmergencyContact).filter(
        EmergencyContact.id == contact_id,
        EmergencyContact.user_id == current_user.id
    ).first()
    if not contact:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Emergency contact not found.")

    if data.name is not None:
        contact.name = data.name
    if data.phone is not None:
        contact.phone = data.phone
    if data.relationship_label is not None:
        contact.relationship_label = data.relationship_label
    if data.notify_on_sos is not None:
        contact.notify_on_sos = data.notify_on_sos
    if data.priority_order is not None:
        contact.priority_order = data.priority_order

    db.commit()
    db.refresh(contact)
    return contact


@router.delete("/{contact_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_contact(
    contact_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    contact = db.query(EmergencyContact).filter(
        EmergencyContact.id == contact_id,
        EmergencyContact.user_id == current_user.id
    ).first()
    if not contact:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Emergency contact not found.")

    db.delete(contact)
    db.commit()
    return None
