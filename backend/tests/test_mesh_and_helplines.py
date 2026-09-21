def test_get_emergency_helplines(client):
    res = client.get("/api/v1/network/helplines")
    assert res.status_code == 200
    helplines = res.json()
    numbers = [h["number"] for h in helplines]
    assert "112" in numbers
    assert "181" in numbers
    assert "1930" in numbers
    assert "1098" in numbers


def test_mesh_gateway_packet_ingestion_and_deduplication(client):
    packet = {
        "version": 1,
        "message_id": "pkt-test-unique-001",
        "ephemeral_id": "eph-node-998877",
        "message_type": "SOS",
        "timestamp": "2026-09-21T10:00:00Z",
        "latitude": 28.6140,
        "longitude": 77.2095,
        "accuracy_meters": 12.0,
        "sequence": 1,
        "ttl": 5,
        "hop_count": 2,
        "priority": "EMERGENCY",
        "gateway_id": "ESP32-GW-DELHI-01"
    }

    # 1. First transmission -> PROCESSED
    res1 = client.post("/api/v1/network/mesh-gateway", json=packet)
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["status"] == "PROCESSED"
    assert data1["sos_id"] is not None
    assert data1["deduplicated"] is False

    # 2. Duplicate transmission of same message_id -> DUPLICATE
    res2 = client.post("/api/v1/network/mesh-gateway", json=packet)
    assert res2.status_code == 200
    data2 = res2.json()
    assert data2["status"] == "DUPLICATE"
    assert data2["deduplicated"] is True

    # 3. Check Mesh Status
    status_res = client.get("/api/v1/network/mesh-status")
    assert status_res.status_code == 200
    m_status = status_res.json()
    assert m_status["status"] == "OPERATIONAL"
    assert m_status["total_packets_relayed"] >= 1
    assert m_status["emergency_sos_packets_count"] >= 1
