def test_journey_lifecycle_and_sharing(client, user_headers):
    # 1. Start journey
    res = client.post("/api/v1/journeys/start", headers=user_headers, json={
        "destination_name": "Metro Central Station",
        "start_lat": 28.6300,
        "start_lon": 77.2150,
        "destination_lat": 28.6400,
        "destination_lon": 77.2250
    })
    assert res.status_code == 201
    journey = res.json()
    journey_id = journey["id"]
    assert journey["status"] == "ACTIVE"
    assert journey["destination_name"] == "Metro Central Station"

    # 2. Location Ping
    ping_res = client.post(f"/api/v1/journeys/{journey_id}/location", headers=user_headers, json={
        "latitude": 28.6350,
        "longitude": 77.2200,
        "speed": 22.5,
        "accuracy": 4.0
    })
    assert ping_res.status_code == 200
    updated = ping_res.json()
    assert updated["total_distance_km"] > 0

    # 3. Create Share Token (30 minutes)
    share_res = client.post(f"/api/v1/journeys/{journey_id}/share", headers=user_headers, json={
        "duration_minutes": 30
    })
    assert share_res.status_code == 200
    share_data = share_res.json()
    share_token = share_data["share_token"]
    share_id = share_data["id"]

    # 4. Access Public Shared Journey (Read-only token view)
    public_res = client.get(f"/api/v1/public/share/{share_token}")
    assert public_res.status_code == 200
    public_view = public_res.json()
    assert public_view["journey_id"] == journey_id
    assert public_view["current_lat"] == 28.6350
    assert public_view["is_valid"] is True

    # 5. Revoke Share
    revoke_res = client.delete(f"/api/v1/journeys/shares/{share_id}", headers=user_headers)
    assert revoke_res.status_code == 204

    # 6. Verify Revoked Share Returns 410 Gone
    expired_res = client.get(f"/api/v1/public/share/{share_token}")
    assert expired_res.status_code == 410

    # 7. End Journey
    end_res = client.post(f"/api/v1/journeys/{journey_id}/end", headers=user_headers, json={
        "final_lat": 28.6400,
        "final_lon": 77.2250
    })
    assert end_res.status_code == 200
    assert end_res.json()["status"] == "COMPLETED"
