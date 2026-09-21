def test_incident_reporting_and_moderation(client, user_headers, admin_headers):
    # 1. Report an anonymous incident
    rep_res = client.post("/api/v1/incidents/report", json={
        "category": "POOR_LIGHTING",
        "severity": "HIGH",
        "description": "Streetlights off for 300 meters near the park entrance.",
        "latitude": 28.6310,
        "longitude": 77.2170,
        "is_anonymous": True
    })
    assert rep_res.status_code == 201
    inc = rep_res.json()
    inc_id = inc["id"]
    assert inc["is_anonymous"] is True
    assert inc["status"] == "PENDING"

    # 2. Verify it does NOT appear in public nearby incidents yet (only verified appear)
    nearby_res = client.get("/api/v1/incidents/nearby?latitude=28.6310&longitude=77.2170&radius_km=2.0")
    assert nearby_res.status_code == 200
    ids = [i["id"] for i in nearby_res.json()]
    assert inc_id not in ids

    # 3. Admin moderates and verifies the incident
    mod_res = client.put(f"/api/v1/admin/incidents/{inc_id}/moderate", headers=admin_headers, json={
        "status": "VERIFIED",
        "moderator_notes": "Ground inspection confirmed lighting fault."
    })
    assert mod_res.status_code == 200
    assert mod_res.json()["status"] == "VERIFIED"

    # 4. Now verify it appears in nearby incidents
    nearby_after = client.get("/api/v1/incidents/nearby?latitude=28.6310&longitude=77.2170&radius_km=2.0")
    assert nearby_after.status_code == 200
    ids_after = [i["id"] for i in nearby_after.json()]
    assert inc_id in ids_after
