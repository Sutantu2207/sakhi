import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Integer
from sqlalchemy.orm import relationship
from backend.app.db.session import Base


class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    phone = Column(String(30), nullable=False)
    relationship_label = Column(String(100), nullable=True)  # e.g., Mother, Partner, Friend
    notify_on_sos = Column(Boolean, default=True, nullable=False)
    priority_order = Column(Integer, default=1, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", back_populates="emergency_contacts")
