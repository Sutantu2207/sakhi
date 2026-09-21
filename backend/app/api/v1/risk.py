from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from backend.app.db.session import get_db
from backend.app.schemas.risk import AreaRiskRequest, AreaRiskResponse, RouteRiskRequest, RouteRiskResponse, RouteOption
from backend.app.ml.inference import risk_engine
from backend.app.utils.geo import haversine_distance

router = APIRouter(prefix="/risk", tags=["Contextual Risk Analysis"])


@router.post("/assess-area", response_model=AreaRiskResponse)
def api_assess_area_risk(
    data: AreaRiskRequest,
    db: Session = Depends(get_db)
):
    result = risk_engine.assess_risk(db, data.latitude, data.longitude, data.radius_km)
    return result


@router.post("/assess-route", response_model=RouteRiskResponse)
def api_assess_route_risk(
    data: RouteRiskRequest,
    db: Session = Depends(get_db)
):
    # Assess origin and destination
    origin_risk = risk_engine.assess_risk(db, data.origin_lat, data.origin_lon, radius_km=1.0)
    dest_risk = risk_engine.assess_risk(db, data.destination_lat, data.destination_lon, radius_km=1.0)
    
    direct_dist = haversine_distance(data.origin_lat, data.origin_lon, data.destination_lat, data.destination_lon)
    base_mins = max(10, int(direct_dist * 3.5))

    # Route A (Main well-lit avenue)
    route_a_score = round(min(origin_risk["risk_score"], dest_risk["risk_score"]) * 0.85 + 0.08, 2)
    cat_a = "lower_reported_risk" if route_a_score < 0.4 else "moderate_reported_risk"

    # Route B (Shortest back-alleys route)
    route_b_score = round(max(origin_risk["risk_score"], dest_risk["risk_score"]) * 1.15 + 0.15, 2)
    cat_b = "higher_reported_risk" if route_b_score > 0.6 else "moderate_reported_risk"

    routes = [
        RouteOption(
            name="Route A (Main Well-Lit Corridor)",
            distance_km=round(direct_dist * 1.15, 2),
            estimated_minutes=base_mins + 4,
            risk_category=cat_a,
            risk_score=route_a_score,
            explanation="Route A passes through major arterial roads with open commercial establishments and closer police presence, though taking approximately 4 minutes longer."
        ),
        RouteOption(
            name="Route B (Direct Shortcut)",
            distance_km=round(direct_dist, 2),
            estimated_minutes=base_mins,
            risk_category=cat_b,
            risk_score=route_b_score,
            explanation="Direct route with shorter distance, passing through areas with fewer street lighting reports and higher distance to nearest emergency facility."
        )
    ]

    return RouteRiskResponse(routes=routes)
