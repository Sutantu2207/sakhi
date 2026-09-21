from typing import Optional
from sqlalchemy.orm import Session
from backend.app.models.audit import AuditLog


def log_action(
    db: Session,
    action: str,
    resource_type: str,
    resource_id: Optional[str] = None,
    user_id: Optional[str] = None,
    details: Optional[str] = None,
    ip_address: Optional[str] = None
) -> AuditLog:
    log = AuditLog(
        action=action,
        resource_type=resource_type,
        resource_id=resource_id,
        user_id=user_id,
        details=details,
        ip_address=ip_address
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    return log
