"""
SAKHI Emergency Mesh — Hardware Simulation Script
Simulates:
Phone -> Virtual ESP32 Relay A -> Virtual ESP32 Relay B -> Virtual Gateway -> Sakhi Cloud API
"""

import time
import uuid
import secrets
import struct
import sys
import requests

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

API_ENDPOINT = "http://127.0.0.1:8000/api/v1/network/mesh-gateway"


def run_mesh_simulation(lat=28.6145, lon=77.2098, accuracy=8.5):
    print("=" * 60)
    print("[SAKHI] EMERGENCY MESH - HARDWARE RELAY SIMULATION")
    print("=" * 60)

    # 1. Phone generates zero-PII emergency packet
    message_id = "msg-" + secrets.token_hex(8)
    ephemeral_id = "eph-" + secrets.token_hex(8)
    print(f"\n[1. MOBILE CLIENT - BLE]")
    print(f"  • Generating 128-bit Ephemeral Beacon: {ephemeral_id}")
    print(f"  • Coordinates Captured: Lat {lat}, Lon {lon} (Acc: {accuracy}m)")
    print(f"  • Zero PII included. Preparing binary packet {message_id}...")

    # 2. Virtual Relay Node A (BLE -> ESP-NOW)
    time.sleep(0.5)
    hop_1 = 1
    ttl_1 = 4
    print(f"\n[2. ESP32 RELAY NODE A (ID: RELAY-ALPHA)]")
    print(f"  • Ingested packet over BLE characteristic 0xFA11.")
    print(f"  • Deduplication cache: Packet is NEW.")
    print(f"  • TTL decremented: {ttl_1}, Hop count: {hop_1}")
    print(f"  • Re-broadcasting via ESP-NOW Channel 1...")

    # 3. Virtual Relay Node B (ESP-NOW -> ESP-NOW)
    time.sleep(0.5)
    hop_2 = 2
    ttl_2 = 3
    print(f"\n[3. ESP32 RELAY NODE B (ID: RELAY-BETA)]")
    print(f"  • Received packet via ESP-NOW.")
    print(f"  • Deduplication cache: Packet is NEW.")
    print(f"  • TTL decremented: {ttl_2}, Hop count: {hop_2}")
    print(f"  • Re-broadcasting to Gateway...")

    # 4. Virtual Gateway (ESP-NOW -> Sakhi Cloud API)
    time.sleep(0.5)
    gateway_id = "ESP32-GW-DELHI-01"
    print(f"\n[4. ESP32 GATEWAY (ID: {gateway_id})]")
    print(f"  • Ingested packet from mesh via ESP-NOW.")
    print(f"  • Active Wi-Fi Uplink detected.")
    print(f"  • Forwarding HTTP POST to: {API_ENDPOINT}")

    payload = {
        "version": 1,
        "message_id": message_id,
        "ephemeral_id": ephemeral_id,
        "message_type": "SOS",
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "latitude": lat,
        "longitude": lon,
        "accuracy_meters": accuracy,
        "sequence": 1,
        "ttl": ttl_2,
        "hop_count": hop_2,
        "priority": "EMERGENCY",
        "gateway_id": gateway_id
    }

    try:
        resp = requests.post(API_ENDPOINT, json=payload, timeout=5)
        print(f"  * Response HTTP {resp.status_code}: {resp.json()}")
        print("\n[OK] MESH SOS RELAY END-TO-END FLOW COMPLETED SUCCESSFULLY!")
    except Exception as e:
        print(f"  [ERROR] Gateway HTTP Error: {e}")

    print("=" * 60)


if __name__ == "__main__":
    run_mesh_simulation()
