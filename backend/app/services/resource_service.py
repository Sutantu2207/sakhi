from typing import Optional, List
from sqlalchemy.orm import Session
from backend.app.models.resource import EmergencyResource, SupportResource, ResourceCategory, SupportCategory
from backend.app.schemas.resource import EmergencyResourceCreate, SupportResourceCreate
from backend.app.utils.geo import haversine_distance


def get_nearby_emergency_resources(
    db: Session,
    latitude: float,
    longitude: float,
    radius_km: float = 10.0,
    category: Optional[ResourceCategory] = None
) -> List[dict]:
    query = db.query(EmergencyResource).filter(EmergencyResource.is_verified == True)
    if category:
        query = query.filter(EmergencyResource.category == category)

    resources = query.all()
    results = []
    for res in resources:
        dist = haversine_distance(latitude, longitude, res.latitude, res.longitude)
        if dist <= radius_km:
            results.append({
                "id": res.id,
                "name": res.name,
                "category": res.category,
                "phone": res.phone,
                "address": res.address,
                "latitude": res.latitude,
                "longitude": res.longitude,
                "is_verified": res.is_verified,
                "operating_hours": res.operating_hours,
                "distance_km": dist,
                "created_at": res.created_at
            })

    # Sort by nearest
    results.sort(key=lambda x: x["distance_km"])
    return results


def get_support_resources(
    db: Session,
    category: Optional[SupportCategory] = None
) -> List[SupportResource]:
    query = db.query(SupportResource)
    if category:
        query = query.filter(SupportResource.category == category)
    return query.order_by(SupportResource.title.asc()).all()


def create_emergency_resource(db: Session, data: EmergencyResourceCreate) -> EmergencyResource:
    res = EmergencyResource(
        name=data.name,
        category=data.category,
        phone=data.phone,
        address=data.address,
        latitude=data.latitude,
        longitude=data.longitude,
        is_verified=data.is_verified,
        operating_hours=data.operating_hours
    )
    db.add(res)
    db.commit()
    db.refresh(res)
    return res


def create_support_resource(db: Session, data: SupportResourceCreate) -> SupportResource:
    res = SupportResource(
        category=data.category,
        title=data.title,
        organization=data.organization,
        phone=data.phone,
        website=data.website,
        description=data.description,
        jurisdiction=data.jurisdiction,
        actionable_steps=data.actionable_steps
    )
    db.add(res)
    db.commit()
    db.refresh(res)
    return res
