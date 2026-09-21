import os
import json
import joblib
import numpy as np
import pandas as pd
from datetime import datetime, timezone
import xgboost as xgb
import sys

root_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if root_dir not in sys.path:
    sys.path.append(root_dir)

from ml.dataset.generate_dataset import generate_synthetic_geospatial_safety_data


def train_and_export_model():
    dataset_dir = os.path.join(root_dir, "ml", "dataset")
    models_dir = os.path.join(root_dir, "ml", "models")
    os.makedirs(models_dir, exist_ok=True)
    os.makedirs(dataset_dir, exist_ok=True)

    csv_path = os.path.join(dataset_dir, "geospatial_risk_dataset.csv")
    if os.path.exists(csv_path):
        print(f"Loading existing dataset from {csv_path}")
        df = pd.read_csv(csv_path)
    else:
        print("Generating dataset...")
        df = generate_synthetic_geospatial_safety_data(n_samples=3000)
        df.to_csv(csv_path, index=False)

    feature_cols = [
        "incident_count_500m",
        "incident_count_1km",
        "weighted_severity_score",
        "harassment_density",
        "poor_lighting_density",
        "distance_to_police_km",
        "distance_to_hospital_km",
        "hour_of_day",
        "is_night",
        "is_weekend"
    ]

    X = df[feature_cols].values
    y = df["risk_category"].values

    # Train / Test split using pure numpy
    np.random.seed(42)
    indices = np.arange(len(X))
    np.random.shuffle(indices)
    split_idx = int(len(X) * 0.8)
    train_idx, test_idx = indices[:split_idx], indices[split_idx:]

    X_train, X_test = X[train_idx], X[test_idx]
    y_train, y_test = y[train_idx], y[test_idx]

    print("Training XGBoost Multi-Class Classifier...")
    model = xgb.XGBClassifier(
        n_estimators=100,
        learning_rate=0.08,
        max_depth=4,
        objective="multi:softprob",
        num_class=3,
        random_state=42,
        eval_metric="mlogloss"
    )
    model.fit(X_train, y_train)

    # Evaluate
    y_pred = model.predict(X_test)
    accuracy = float(np.mean(y_pred == y_test))
    print(f"Model Test Accuracy: {accuracy:.4f}")

    # Compute confusion matrix
    classes = [0, 1, 2]
    conf_matrix = [[int(np.sum((y_test == r) & (y_pred == c))) for c in classes] for r in classes]
    print("Confusion Matrix:")
    for r in conf_matrix:
        print(" ", r)

    # Feature importances
    importances = {feature_cols[i]: round(float(model.feature_importances_[i]), 4) for i in range(len(feature_cols))}
    print("\nFeature Importances:")
    for k, v in sorted(importances.items(), key=lambda x: x[1], reverse=True):
        print(f"  {k}: {v}")

    # Export bundle
    bundle = {
        "model": model,
        "feature_names": feature_cols,
        "category_mapping": {
            0: "lower_reported_risk",
            1: "moderate_reported_risk",
            2: "higher_reported_risk"
        },
        "metrics": {
            "test_accuracy": accuracy,
            "confusion_matrix": conf_matrix
        },
        "feature_importances": importances,
        "trained_at": datetime.now(timezone.utc).isoformat(),
        "model_version": "sakhi-risk-xgb-v1.0"
    }

    model_path = os.path.join(models_dir, "sakhi_risk_model.joblib")
    joblib.dump(bundle, model_path)
    print(f"\nModel bundle successfully saved to {model_path}")
    return bundle


if __name__ == "__main__":
    train_and_export_model()
