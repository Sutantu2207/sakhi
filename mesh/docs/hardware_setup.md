# SAKHI Emergency Mesh — Hardware Setup, Security & Testing

## 1. Hardware Requirements & Board Selection
- **Relay Nodes**: ESP32-C3 / ESP32 DevKit v1 with integrated 2.4 GHz antenna.
- **Gateway Nodes**: ESP32-S3 or ESP32 dual-core with Wi-Fi/Ethernet.
- **Power**: 3.7V 18650 Li-ion battery or 5V USB power bank for relay nodes.

---

## 2. 10-Step Hardware Acceptance Test Plan

| Test # | Description | Expected Result | Pass Criteria |
| :--- | :--- | :--- | :--- |
| **Test 1** | ESP32 A ➔ ESP32 B over ESP-NOW | Direct packet reception on Channel 1 | RSSI > -85 dBm, 0% packet loss |
| **Test 2** | Mobile Phone ➔ BLE ➔ ESP32 Relay | GATT write to UUID `0xFA11` | ACK received on UUID `0xFA12` |
| **Test 3** | ESP32 A ➔ Relay ➔ ESP32 B | Hop count increments, TTL decrements | Forwarded packet captured on B |
| **Test 4** | Mobile ➔ BLE ➔ Relay A ➔ Relay B | End-to-end multi-hop transmission | Packet arrives at B with Hop=2 |
| **Test 5** | Relay ➔ Gateway ➔ Cloud API | Ingestion at `/api/v1/network/mesh-gateway` | HTTP 200 PROCESSED, SOS in DB |
| **Test 6** | Internet Disconnected on Mobile | App falls back to BLE relay search | App displays "Relay Available" |
| **Test 7** | Relay Node Disappears | Mesh re-routes through alternate relay | Secondary relay picks up broadcast |
| **Test 8** | Duplicate Packet Injection | Same `message_id` broadcasted twice | Gateway discards with DUPLICATE status |
| **Test 9** | Expired Packet (TTL = 0) | Packet arrives with TTL ≤ 1 | Node drops packet immediately |
| **Test 10**| Zero-PII Wireshark Sniffing | Packet payload analyzed with SDR/sniffer | Zero plaintext names or phone numbers |

---

## 3. Real-World Physical Constraints
- **Open-field range**: ~150–220 meters between ESP-NOW nodes.
- **Urban / indoor penetration**: ~30–50 meters through 2–3 reinforced concrete walls.
- **Latency**: Sub-50ms per hop.
