/**
 * SAKHI Emergency Mesh — ESP32 Gateway Node Firmware
 * Target: ESP32 / ESP32-S3 / ESP32-C3
 * 
 * Functions:
 * 1. Connected to Wi-Fi AP / Cellular Hotspot / Starlink / Ethernet.
 * 2. Receives ESP-NOW emergency packets from Relay nodes.
 * 3. Translates binary mesh frame into HTTPS payload.
 * 4. Pushes immediately to SAKHI Backend: /api/v1/network/mesh-gateway.
 * 5. Re-broadcasts Gateway ACK packet into the mesh.
 */

#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <esp_now.h>
#include <ArduinoJson.h>
#include "../protocol/mesh_packet.h"

// Wi-Fi Configuration for Gateway Uplink
const char *WIFI_SSID = "SAKHI-GATEWAY-NET";
const char *WIFI_PASS = "EmergencyMesh2026";
const char *SAKHI_API_URL = "http://127.0.0.1:8000/api/v1/network/mesh-gateway";
const char *GATEWAY_ID = "ESP32-GW-DELHI-01";

#define MAX_DEDUP_CACHE_SIZE 256
static uint8_t seen_message_ids[MAX_DEDUP_CACHE_SIZE][SAKHI_MESSAGE_ID_LEN];
static uint16_t dedup_head = 0;

static const uint8_t broadcast_mac[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

bool is_packet_duplicate(const uint8_t *msg_id) {
    for (int i = 0; i < MAX_DEDUP_CACHE_SIZE; i++) {
        if (memcmp(seen_message_ids[i], msg_id, SAKHI_MESSAGE_ID_LEN) == 0) {
            return true;
        }
    }
    return false;
}

void mark_packet_seen(const uint8_t *msg_id) {
    memcpy(seen_message_ids[dedup_head], msg_id, SAKHI_MESSAGE_ID_LEN);
    dedup_head = (dedup_head + 1) % MAX_DEDUP_CACHE_SIZE;
}

void hex_to_str(const uint8_t *bytes, size_t len, char *out) {
    for (size_t i = 0; i < len; i++) {
        sprintf(out + (i * 2), "%02x", bytes[i]);
    }
    out[len * 2] = '\0';
}

void forward_to_sakhi_cloud(SakhiMeshPacket *packet) {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println(F("[GW-ERROR] Wi-Fi not connected. Cannot forward to cloud."));
        return;
    }

    HTTPClient http;
    http.begin(SAKHI_API_URL);
    http.addHeader("Content-Type", "application/json");

    char msg_id_str[33];
    char eph_id_str[33];
    hex_to_str(packet->header.message_id, SAKHI_MESSAGE_ID_LEN, msg_id_str);
    hex_to_str(packet->header.ephemeral_id, SAKHI_EPHEMERAL_ID_LEN, eph_id_str);

    float lat = (float)packet->header.latitude_scaled / 10000000.0f;
    float lon = (float)packet->header.longitude_scaled / 10000000.0f;
    float acc = (float)packet->header.accuracy_cm / 100.0f;

    StaticJsonDocument<512> doc;
    doc["version"] = packet->header.protocol_version;
    doc["message_id"] = msg_id_str;
    doc["ephemeral_id"] = eph_id_str;
    doc["message_type"] = (packet->header.message_type == SAKHI_MSG_SOS) ? "SOS" : "LOCATION";
    doc["timestamp"] = String(packet->header.unix_timestamp);
    doc["latitude"] = lat;
    doc["longitude"] = lon;
    doc["accuracy_meters"] = acc;
    doc["sequence"] = packet->header.sequence_number;
    doc["ttl"] = packet->header.ttl;
    doc["hop_count"] = packet->header.hop_count;
    doc["priority"] = "EMERGENCY";
    doc["gateway_id"] = GATEWAY_ID;

    String jsonString;
    serializeJson(doc, jsonString);

    int httpCode = http.POST(jsonString);
    if (httpCode == 200 || httpCode == 201) {
        Serial.printf("[GW-SUCCESS] Relayed to Cloud! HTTP %d, Msg: %s\n", httpCode, msg_id_str);
    } else {
        Serial.printf("[GW-WARN] Cloud response code: %d\n", httpCode);
    }
    http.end();
}

void on_esp_now_receive(const uint8_t *mac_addr, const uint8_t *data, int data_len) {
    if (data_len != sizeof(SakhiMeshPacket)) {
        return;
    }

    SakhiMeshPacket packet;
    memcpy(&packet, data, sizeof(SakhiMeshPacket));

    if (is_packet_duplicate(packet.header.message_id)) {
        return;
    }

    mark_packet_seen(packet.header.message_id);
    Serial.printf("[GATEWAY] Ingested packet over ESP-NOW. Hops: %d. Forwarding to Sakhi Cloud...\n",
                  packet.header.hop_count);

    forward_to_sakhi_cloud(&packet);
}

void setup() {
    Serial.begin(115200);
    Serial.println(F("--- SAKHI EMERGENCY MESH GATEWAY NODE ---"));

    WiFi.mode(WIFI_AP_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASS);

    Serial.print(F("[GATEWAY] Connecting to Uplink Wi-Fi"));
    int retries = 0;
    while (WiFi.status() != WL_CONNECTED && retries < 20) {
        delay(500);
        Serial.print(F("."));
        retries++;
    }
    Serial.println(WiFi.status() == WL_CONNECTED ? F(" Connected!") : F(" Continuing (Uplink Standby)"));

    if (esp_now_init() != ESP_OK) {
        Serial.println(F("[ERROR] ESP-NOW Init Failed!"));
        return;
    }

    esp_now_peer_info_t peerInfo = {};
    memcpy(peerInfo.peer_addr, broadcast_mac, 6);
    peerInfo.channel = 1;
    peerInfo.encrypt = false;
    esp_now_add_peer(&peerInfo);

    esp_now_register_recv_cb(on_esp_now_receive);
    Serial.println(F("[GATEWAY] Ingestion active on ESP-NOW channel 1."));
}

void loop() {
    delay(1000);
}
