def test_sos_lifecycle_flow(client, user_headers, admin_headers):
    # Add an emergency contact first
    client.post("/api/v1/contacts/", headers=user_headers, json={
        "name": "Trusted Guardian",
        "phone": "+919888877777",
        "relationship_label": "Guardian",
        "notify_on_sos": True,
        "priority_order": 1
    })

    # 1. Trigger SOS
    res = client.post("/api/v1/sos/trigger", headers=user_headers, json={
        "latitude": 28.6250,
        "longitude": 77.2100,
        "accuracy_meters": 8.5,
        "address_approx": "Near Shivaji Stadium Metro"
    })
    assert res.status_code == 201
    sos_data = res.json()
    sos_id = sos_data["id"]
    assert sos_data["status"] == "ACTIVE"
    assert sos_data["contacts_notified_count"] >= 1
    assert sos_data["notification_status"] == "SENT"
    assert sos_data["accuracy_meters"] == 8.5
    assert sos_data["user_name"] is not None

    # 2. Admin acknowledges SOS
    ack_res = client.put(f"/api/v1/admin/sos/{sos_id}/acknowledge", headers=admin_headers)
    assert ack_res.status_code == 200
    assert ack_res.json()["status"] == "ACKNOWLEDGED"

    # 3. Admin resolves SOS with dispatch notes
    resolve_res = client.put(f"/api/v1/admin/sos/{sos_id}/resolve", headers=admin_headers, json={
        "admin_notes": "Local patrol dispatched and verified victim safe."
    })
    assert resolve_res.status_code == 200
    resolved = resolve_res.json()
    assert resolved["status"] == "RESOLVED"
    assert "patrol dispatched" in resolved["admin_notes"]


def test_user_cancel_sos(client, user_headers):
    trigger_res = client.post("/api/v1/sos/trigger", headers=user_headers, json={
        "latitude": 28.6250,
        "longitude": 77.2100
    })
    sos_id = trigger_res.json()["id"]

    cancel_res = client.post(f"/api/v1/sos/{sos_id}/cancel", headers=user_headers, json={
        "reason": "False alarm triggered accidentally"
    })
    assert cancel_res.status_code == 200
    assert cancel_res.json()["status"] == "CANCELLED"


def test_sos_linked_to_active_journey(client, user_headers, admin_headers):
    # Start a journey first
    journey_res = client.post("/api/v1/journeys/start", headers=user_headers, json={
        "destination_name": "Saket District Court",
        "start_lat": 28.5244,
        "start_lon": 77.2167,
        "destination_lat": 28.5200,
        "destination_lon": 77.2100
    })
    assert journey_res.status_code == 201
    journey_id = journey_res.json()["id"]

    # Trigger SOS while journey is active
    sos_res = client.post("/api/v1/sos/trigger", headers=user_headers, json={
        "latitude": 28.5220,
        "longitude": 77.2130,
        "accuracy_meters": 5.0
    })
    assert sos_res.status_code == 201
    sos_data = sos_res.json()
    assert sos_data["journey_id"] == journey_id
    assert sos_data["destination_name"] == "Saket District Court"
    assert sos_data["share_token"] is not None

    # Verify admin gets the enriched SOS event
    admin_sos = client.get("/api/v1/admin/sos", headers=admin_headers)
    assert admin_sos.status_code == 200
    active_events = [e for e in admin_sos.json() if e["id"] == sos_data["id"]]
    assert len(active_events) == 1
    assert active_events[0]["destination_name"] == "Saket District Court"
    assert active_events[0]["user_name"] is not None

    # Clean up by cancelling SOS and ending journey
    client.post(f"/api/v1/sos/{sos_data['id']}/cancel", headers=user_headers)
    client.post(f"/api/v1/journeys/{journey_id}/end", headers=user_headers)


def test_sos_duplicate_suppression_and_update(client, user_headers):
    # Trigger first SOS
    res1 = client.post("/api/v1/sos/trigger", headers=user_headers, json={
        "latitude": 28.6100,
        "longitude": 77.2000,
        "accuracy_meters": 15.0
    })
    sos_id1 = res1.json()["id"]

    # Trigger second SOS while first is active -> should update coordinates, not create a duplicate
    res2 = client.post("/api/v1/sos/trigger", headers=user_headers, json={
        "latitude": 28.6150,
        "longitude": 77.2050,
        "accuracy_meters": 6.0
    })
    sos_data2 = res2.json()
    assert sos_data2["id"] == sos_id1
    assert sos_data2["latitude"] == 28.6150
    assert sos_data2["longitude"] == 77.2050
    assert sos_data2["accuracy_meters"] == 6.0

    # Cancel
    client.post(f"/api/v1/sos/{sos_id1}/cancel", headers=user_headers)
