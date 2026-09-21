import os
import numpy as np
import pandas as pd

def generate_synthetic_geospatial_safety_data(n_samples: int = 2500, random_state: int = 42) -> pd.DataFrame:
    """
    Generate realistic dataset representing reported environmental and incident factors.
    Features:
      - incident_count_500m: Verified incidents reported within 500 meters in last 90 days.
      - incident_count_1km: Verified incidents reported within 1 kilometer.
      - weighted_severity_score: Weighted sum of reported incidents by severity.
      - harassment_density: Density of harassment / stalking reports.
      - poor_lighting_density: Density of poor lighting / dark alley reports.
      - distance_to_police_km: Distance to nearest verified police post / station.
      - distance_to_hospital_km: Distance to nearest medical emergency facility.
      - hour_of_day: 0 to 23.
      - is_night: 1 if between 20:00 and 05:00, else 0.
      - is_weekend: 1 if Saturday or Sunday, else 0.
    
    Target:
      - risk_category: 0 = lower_reported_risk, 1 = moderate_reported_risk, 2 = higher_reported_risk
    """
    np.random.seed(random_state)

    incident_500m = np.random.poisson(lam=1.5, size=n_samples)
    incident_1km = incident_500m + np.random.poisson(lam=2.5, size=n_samples)
    
    # Severity weighting
    weighted_severity = incident_500m * np.random.uniform(1.0, 3.0, size=n_samples) + \
                        (incident_1km - incident_500m) * np.random.uniform(0.5, 1.5, size=n_samples)

    harassment_density = np.random.binomial(n=incident_1km + 1, p=0.35)
    poor_lighting_density = np.random.binomial(n=incident_1km + 1, p=0.45)

    distance_to_police = np.random.exponential(scale=1.8, size=n_samples) + 0.1
    distance_to_hospital = np.random.exponential(scale=2.5, size=n_samples) + 0.2

    hour_of_day = np.random.randint(0, 24, size=n_samples)
    is_night = np.where((hour_of_day >= 21) | (hour_of_day <= 5), 1, 0)
    is_weekend = np.random.binomial(1, 2/7, size=n_samples)

    # Composite environmental indicator score
    raw_risk_score = (
        0.28 * incident_500m +
        0.18 * incident_1km +
        0.25 * weighted_severity +
        0.20 * harassment_density +
        0.15 * poor_lighting_density +
        0.12 * (distance_to_police > 2.5).astype(int) +
        0.22 * is_night +
        0.08 * is_weekend +
        np.random.normal(0, 0.4, size=n_samples)
    )

    # Convert to 3 categories based on quantiles
    q1, q2 = np.percentile(raw_risk_score, [45, 80])
    risk_category = np.zeros(n_samples, dtype=int)
    risk_category[raw_risk_score > q1] = 1
    risk_category[raw_risk_score > q2] = 2

    df = pd.DataFrame({
        "incident_count_500m": incident_500m,
        "incident_count_1km": incident_1km,
        "weighted_severity_score": np.round(weighted_severity, 2),
        "harassment_density": harassment_density,
        "poor_lighting_density": poor_lighting_density,
        "distance_to_police_km": np.round(distance_to_police, 2),
        "distance_to_hospital_km": np.round(distance_to_hospital, 2),
        "hour_of_day": hour_of_day,
        "is_night": is_night,
        "is_weekend": is_weekend,
        "risk_category": risk_category
    })

    return df


if __name__ == "__main__":
    out_dir = os.path.dirname(os.path.abspath(__file__))
    data_path = os.path.join(out_dir, "geospatial_risk_dataset.csv")
    df = generate_synthetic_geospatial_safety_data(n_samples=3000)
    df.to_csv(data_path, index=False)
    print(f"Generated {len(df)} samples and saved to {data_path}")
    print("Class distribution:")
    print(df["risk_category"].value_counts(normalize=True))
