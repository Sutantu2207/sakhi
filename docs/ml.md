# SAKHI — Machine Learning Contextual Risk Analysis Engine

## 1. Core Purpose & Non-Negotiable Ethical Principle

The machine learning subsystem in SAKHI calculates **contextual, environmental risk indicators based solely on verified community reports, spatial infrastructure proximity, and temporal patterns**.

### What the Model DOES:
- Evaluates density of verified reports (poor street lighting, past street harassment, dark alleys) within 500m and 1km radius.
- Weighs distance to nearest active emergency responder posts (police, hospitals).
- Accounts for temporal risk windows (e.g., late-night transit hours between 21:00 and 05:00).
- Categorizes contextual risk as:
  - `lower_reported_risk`
  - `moderate_reported_risk`
  - `higher_reported_risk`
- Returns plain-English contributing factors explaining the score.

### What the Model DOES NOT DO:
- **Never profiles individual persons** or demographic groups.
- **Never predicts whether a specific individual will commit a crime**.
- **Never claims an area is guaranteed "safe" or "dangerous"**.
- UI language is strictly descriptive:
  > *"Moderate reported-risk context based on available verified incident reports in this area."*

---

## 2. Feature Architecture

| Feature Name | Description | Gini Importance |
|---|---|---|
| `weighted_severity_score` | Sum of severity weights of verified reports in 1km | 46.8% |
| `incident_count_1km` | Total verified incidents reported within 1km | 19.3% |
| `incident_count_500m` | Immediate block incident density | 7.5% |
| `harassment_density` | Street harassment reports frequency in vicinity | 7.0% |
| `poor_lighting_density` | Street lighting and dark alley incident reports | 6.1% |
| `is_night` | Binary indicator (1 if 21:00-05:00, else 0) | 4.8% |
| `distance_to_hospital_km` | Proximity to nearest emergency medical facility | 2.2% |
| `hour_of_day` | Hour of the day (0-23) | 2.2% |
| `is_weekend` | Binary indicator (1 if Sat/Sun, else 0) | 2.1% |
| `distance_to_police_km` | Distance to nearest active police station | 2.0% |

---

## 3. Model Pipeline & Artifacts
- **Algorithm**: XGBoost Multi-Class Classifier (`objective='multi:softprob'`, `max_depth=4`, `n_estimators=100`).
- **Validation Accuracy**: 86.8% macro accuracy across 3 balanced risk tiers (no artificial inflation).
- **Artifact Location**: `ml/models/sakhi_risk_model.joblib`.
- **Training Script**: `ml/training/train_model.py`.
