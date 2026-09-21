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
        "address_approx": "Near Shivaji Stadium Metro"
    })
    assert res.status_code == 201
    sos_data = res.json()
    sos_id = sos_data["id"]
    assert sos_data["status"] == "ACTIVE"
    assert sos_data["contacts_notified_count"] >= 1
    assert sos_data["notification_status"] == "SENT"

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
