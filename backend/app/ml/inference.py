import os
import joblib
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
import numpy as np
from sqlalchemy.orm import Session

from backend.app.core.config import settings
from backend.app.models.incident import Incident, IncidentStatus, IncidentCategory, IncidentSeverity
from backend.app.models.resource import EmergencyResource, ResourceCategory
from backend.app.utils.geo import haversine_distance


class RiskInferenceEngine:
    def __init__(self):
        self.model_bundle: Optional[dict] = None
        self._load_model()

    def _load_model(self):
        try:
            if os.path.exists(settings.ML_MODEL_PATH):
                self.model_bundle = joblib.load(settings.ML_MODEL_PATH)
        except Exception:
            self.model_bundle = None

    def assess_risk(
        self,
        db: Session,
        latitude: float,
        longitude: float,
        radius_km: float = 1.0
    ) -> Dict[str, Any]:
        now = datetime.now(timezone.utc)
        hour = now.hour
        is_night = 1 if (hour >= 21 or hour <= 5) else 0
        is_weekend = 1 if now.weekday() in [5, 6] else 0

        # Query verified incidents
        incidents = db.query(Incident).filter(Incident.status == IncidentStatus.VERIFIED).all()
        
        count_500m = 0
        count_1km = 0
        weighted_severity = 0.0
        harassment_count = 0
        lighting_count = 0
        contributing_factors: List[str] = []

        severity_weights = {
            IncidentSeverity.LOW: 1.0,
            IncidentSeverity.MEDIUM: 2.0,
            IncidentSeverity.HIGH: 3.5,
            IncidentSeverity.CRITICAL: 5.0
        }

        for inc in incidents:
            dist = haversine_distance(latitude, longitude, inc.latitude, inc.longitude)
            if dist <= 0.5:
                count_500m += 1
            if dist <= 1.0:
                count_1km += 1
                w = severity_weights.get(inc.severity, 2.0)
                weighted_severity += w
                if inc.category in [IncidentCategory.HARASSMENT, IncidentCategory.STALKING]:
                    harassment_count += 1
                if inc.category in [IncidentCategory.POOR_LIGHTING, IncidentCategory.UNSAFE_AREA]:
                    lighting_count += 1

        # Query emergency infrastructure distances
        resources = db.query(EmergencyResource).filter(EmergencyResource.is_verified == True).all()
        dist_police = 99.0
        dist_hospital = 99.0

        for r in resources:
            d = haversine_distance(latitude, longitude, r.latitude, r.longitude)
            if r.category == ResourceCategory.POLICE:
                if d < dist_police:
                    dist_police = d
            elif r.category == ResourceCategory.HOSPITAL:
                if d < dist_hospital:
                    dist_hospital = d

        # Construct contributing factors list
        if count_500m > 0:
            contributing_factors.append(f"{count_500m} verified report(s) within 500m")
        if count_1km > count_500m:
            contributing_factors.append(f"{count_1km} total verified report(s) within 1km")
        if harassment_count > 0:
            contributing_factors.append(f"{harassment_count} street harassment report(s) recorded in vicinity")
        if lighting_count > 0:
            contributing_factors.append(f"{lighting_count} poor street lighting report(s) logged")
        if dist_police <= 1.0:
            contributing_factors.append(f"Police assistance within {dist_police:.1f}km")
        elif dist_police > 3.0:
            contributing_factors.append(f"Nearest police facility is {dist_police:.1f}km away")
        if is_night:
            contributing_factors.append("Late night travel window (reduced public transit and foot traffic)")

        if not contributing_factors:
            contributing_factors.append("No adverse incidents reported within current radius")
            contributing_factors.append(f"Nearest police assistance within {dist_police:.1f}km")

        # Try ML Model prediction
        if self.model_bundle is None:
            self._load_model()

        risk_category = "lower_reported_risk"
        risk_score = 0.15
        confidence = 0.88
        model_version = "sakhi-heuristic-v1.0"

        if self.model_bundle and "model" in self.model_bundle:
            try:
                feature_row = np.array([[
                    count_500m,
                    count_1km,
                    weighted_severity,
                    harassment_count,
                    lighting_count,
                    min(dist_police, 15.0),
                    min(dist_hospital, 15.0),
                    hour,
                    is_night,
                    is_weekend
                ]])
                model = self.model_bundle["model"]
                pred = int(model.predict(feature_row)[0])
                probs = model.predict_proba(feature_row)[0]
                category_map = self.model_bundle.get("category_mapping", {
                    0: "lower_reported_risk",
                    1: "moderate_reported_risk",
                    2: "higher_reported_risk"
                })
                risk_category = category_map.get(pred, "lower_reported_risk")
                # Risk score normalized 0.0 to 1.0
                risk_score = round(float(probs[2] * 1.0 + probs[1] * 0.5 + probs[0] * 0.1), 3)
                confidence = round(float(np.max(probs)), 3)
                model_version = self.model_bundle.get("model_version", "sakhi-risk-xgb-v1.0")
            except Exception:
                pass
        else:
            # Contextual formula fallback
            if count_500m >= 3 or weighted_severity >= 8.0:
                risk_category = "higher_reported_risk"
                risk_score = 0.78
            elif count_1km >= 2 or lighting_count >= 1 or (is_night and dist_police > 2.0):
                risk_category = "moderate_reported_risk"
                risk_score = 0.45
            else:
                risk_category = "lower_reported_risk"
                risk_score = 0.18

        summary_map = {
            "lower_reported_risk": "Lower reported risk based on recent verified community reports.",
            "moderate_reported_risk": "Moderate reported-risk context based on available incident data.",
            "higher_reported_risk": "Higher reported-risk context based on recent incident reports in this area."
        }

        return {
            "latitude": latitude,
            "longitude": longitude,
            "risk_score": risk_score,
            "risk_category": risk_category,
            "confidence": confidence,
            "summary": summary_map.get(risk_category, "Contextual risk calculated."),
            "contributing_factors": contributing_factors,
            "nearby_incidents_count": count_1km,
            "nearest_police_km": round(dist_police, 2) if dist_police < 90 else None,
            "nearest_hospital_km": round(dist_hospital, 2) if dist_hospital < 90 else None,
            "model_version": model_version
        }


risk_engine = RiskInferenceEngine()
