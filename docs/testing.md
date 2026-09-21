# SAKHI — Testing Strategy & Verification Guide

SAKHI features automated test suites across the backend API, machine learning pipeline, and mobile client.

---

## 1. Backend Automated Tests (Pytest)

The backend test suite verifies authentication, journey lifecycle, emergency SOS, incident reporting and moderation, and spatial queries.

### Run tests:
```powershell
.\.venv\Scripts\pytest.exe backend\tests -v
```

### Coverage:
- `backend/tests/test_auth.py`: Registration, duplicate check, login, password verification, profile retrieval, privacy settings.
- `backend/tests/test_journeys.py`: Starting journey, location ping, distance calculation, temporary share token creation, public authorized access, token expiry/revocation, journey completion.
- `backend/tests/test_sos.py`: SOS trigger, emergency contacts notification recording, user cancellation, admin acknowledgment, admin resolution.
- `backend/tests/test_incidents.py`: Anonymous report submission, verification moderation, public nearby geospatial query.
- `backend/tests/test_spatial.py`: Emergency infrastructure distance filtering, ML area risk endpoint, route comparison.

---

## 2. Machine Learning Validation

### Run training & evaluation:
```powershell
.\.venv\Scripts\python.exe ml\training\train_model.py
```
- Trains XGBoost Multi-Class Classifier.
- Computes accuracy, confusion matrix, and feature importances.
- Verifies model export bundle integrity in `ml/models/sakhi_risk_model.joblib`.

---

## 3. Mobile Client Widget & Unit Tests

### Run Flutter tests:
```powershell
cd mobile
flutter test
```
- Verifies `RiskBadge` rendering for all risk categories.
- Verifies `SOSButton` rendering and tap responsiveness.
- Verifies `CountdownDialog` 5-second countdown mechanics and abort actions.
