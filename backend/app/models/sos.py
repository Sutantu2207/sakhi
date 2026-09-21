import uuid
from datetime import datetime, timezone
import enum
from sqlalchemy import Column, String, Float, DateTime, ForeignKey, Enum as SQLEnum, Integer, Text
from sqlalchemy.orm import relationship
from backend.app.db.session import Base


class SOSStatus(str, enum.Enum):
    CREATED = "CREATED"
    ACTIVE = "ACTIVE"
    ACKNOWLEDGED = "ACKNOWLEDGED"
    RESOLVED = "RESOLVED"
    CANCELLED = "CANCELLED"
    EXPIRED = "EXPIRED"


class SOSEvent(Base):
    __tablename__ = "sos_events"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    status = Column(SQLEnum(SOSStatus), default=SOSStatus.ACTIVE, nullable=False, index=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    address_approx = Column(String(255), nullable=True)
    triggered_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    resolved_at = Column(DateTime, nullable=True)
    contacts_notified_count = Column(Integer, default=0, nullable=False)
    notification_status = Column(String(100), default="SENT", nullable=False)  # SENT, FAILED, PARTIAL
    admin_notes = Column(Text, nullable=True)
    responder_id = Column(String(36), nullable=True)

    user = relationship("User", back_populates="sos_events")
