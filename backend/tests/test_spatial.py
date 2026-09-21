def test_nearby_emergency_resources(client, admin_headers):
    # Add an emergency resource
    client.post("/api/v1/admin/resources/emergency", headers=admin_headers, json={
        "name": "Connaught Place Police Booth",
        "category": "POLICE",
        "phone": "011-23340000",
        "address": "Inner Circle, Connaught Place",
        "latitude": 28.6320,
        "longitude": 77.2180,
        "is_verified": True,
        "operating_hours": "24/7"
    })

    # Query resources nearby
    res = client.get("/api/v1/resources/emergency/nearby?latitude=28.6325&longitude=77.2185&radius_km=2.0")
    assert res.status_code == 200
    data = res.json()
    assert len(data) >= 1
    assert "distance_km" in data[0]
    assert data[0]["distance_km"] <= 2.0


def test_area_risk_endpoint(client):
    res = client.post("/api/v1/risk/assess-area", json={
        "latitude": 28.6315,
        "longitude": 77.2167,
        "radius_km": 1.0
    })
    assert res.status_code == 200
    data = res.json()
    assert "risk_score" in data
    assert "risk_category" in data
    assert data["risk_category"] in ["lower_reported_risk", "moderate_reported_risk", "higher_reported_risk"]
    assert "contributing_factors" in data
    assert len(data["contributing_factors"]) > 0


def test_route_risk_comparison(client):
    res = client.post("/api/v1/risk/assess-route", json={
        "origin_lat": 28.6315,
        "origin_lon": 77.2167,
        "destination_lat": 28.5494,
        "destination_lon": 77.2001
    })
    assert res.status_code == 200
    data = res.json()
    assert "routes" in data
    assert len(data["routes"]) == 2
    assert "risk_score" in data["routes"][0]
