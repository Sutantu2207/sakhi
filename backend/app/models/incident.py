import uuid
from datetime import datetime, timezone
import enum
from sqlalchemy import Column, String, Float, DateTime, ForeignKey, Enum as SQLEnum, Boolean, Text
from sqlalchemy.orm import relationship
from backend.app.db.session import Base


class IncidentCategory(str, enum.Enum):
    HARASSMENT = "HARASSMENT"
    STALKING = "STALKING"
    ASSAULT = "ASSAULT"
    THEFT = "THEFT"
    POOR_LIGHTING = "POOR_LIGHTING"
    UNSAFE_AREA = "UNSAFE_AREA"
    CYBERCRIME = "CYBERCRIME"
    OTHER = "OTHER"


class IncidentSeverity(str, enum.Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"


class IncidentStatus(str, enum.Enum):
    PENDING = "PENDING"
    VERIFIED = "VERIFIED"
    REJECTED = "REJECTED"
    RESOLVED = "RESOLVED"


class Incident(Base):
    __tablename__ = "incidents"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    reporter_id = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    is_anonymous = Column(Boolean, default=False, nullable=False)
    category = Column(SQLEnum(IncidentCategory), nullable=False, index=True)
    severity = Column(SQLEnum(IncidentSeverity), default=IncidentSeverity.MEDIUM, nullable=False)
    description = Column(Text, nullable=False)
    incident_time = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    latitude = Column(Float, nullable=False, index=True)
    longitude = Column(Float, nullable=False, index=True)
    status = Column(SQLEnum(IncidentStatus), default=IncidentStatus.PENDING, nullable=False, index=True)
    moderator_notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    reporter = relationship("User", back_populates="incidents")
