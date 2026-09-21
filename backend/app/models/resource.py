import uuid
from datetime import datetime, timezone
import enum
from sqlalchemy import Column, String, Float, DateTime, Enum as SQLEnum, Boolean, Text
from backend.app.db.session import Base


class ResourceCategory(str, enum.Enum):
    POLICE = "POLICE"
    HOSPITAL = "HOSPITAL"
    FIRE_STATION = "FIRE_STATION"
    SAFE_PLACE = "SAFE_PLACE"
    WOMEN_SHELTER = "WOMEN_SHELTER"


class SupportCategory(str, enum.Enum):
    LEGAL = "LEGAL"
    DOMESTIC_ABUSE = "DOMESTIC_ABUSE"
    CYBERCRIME = "CYBERCRIME"
    PSYCHOLOGICAL = "PSYCHOLOGICAL"
    HELPLINE = "HELPLINE"
    POSH = "POSH"


class EmergencyResource(Base):
    __tablename__ = "emergency_resources"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(255), nullable=False)
    category = Column(SQLEnum(ResourceCategory), nullable=False, index=True)
    phone = Column(String(50), nullable=False)
    address = Column(String(255), nullable=False)
    latitude = Column(Float, nullable=False, index=True)
    longitude = Column(Float, nullable=False, index=True)
    is_verified = Column(Boolean, default=True, nullable=False)
    operating_hours = Column(String(100), default="24/7", nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)


class SupportResource(Base):
    __tablename__ = "support_resources"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    category = Column(SQLEnum(SupportCategory), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    organization = Column(String(255), nullable=False)
    phone = Column(String(100), nullable=True)
    website = Column(String(255), nullable=True)
    description = Column(Text, nullable=False)
    jurisdiction = Column(String(100), default="National / Regional", nullable=False)
    actionable_steps = Column(Text, nullable=True)  # JSON or newline-separated actionable guidance
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
