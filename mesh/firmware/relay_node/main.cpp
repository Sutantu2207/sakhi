/**
 * SAKHI Emergency Mesh — ESP32 Relay Node Firmware
 * Target: ESP32-C3 / ESP32-S3 / ESP32 DevKit v1
 * 
 * Functions:
 * 1. BLE Server advertising SAKHI_EMERGENCY_SERVICE_UUID.
 * 2. Ingests encrypted emergency packets from mobile client.
 * 3. Decrements TTL, increments hop count.
 * 4. Deduplicates packets using an in-memory sliding ring buffer.
 * 5. Re-broadcasts via ESP-NOW to neighboring relays and gateways.
 * 6. Zero internet or SIM card required.
 */

#include <Arduino.h>
#include <WiFi.h>
#include <esp_now.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "../protocol/mesh_packet.h"

// UUIDs for Sakhi BLE Emergency Interface
#define SERVICE_UUID           "0000FA10-0000-1000-8000-00805F9B34FB"
#define CHAR_RX_PACKET_UUID    "0000FA11-0000-1000-8000-00805F9B34FB"
#define CHAR_TX_ACK_UUID       "0000FA12-0000-1000-8000-00805F9B34FB"

#define MAX_DEDUP_CACHE_SIZE   128

// Broadcast MAC address for ESP-NOW mesh relay
static const uint8_t broadcast_mac[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

// In-memory sliding deduplication ring buffer
static uint8_t seen_message_ids[MAX_DEDUP_CACHE_SIZE][SAKHI_MESSAGE_ID_LEN];
static uint16_t dedup_head = 0;

static BLECharacteristic *pTxAckCharacteristic = nullptr;

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

void forward_esp_now_mesh(SakhiMeshPacket *packet) {
    if (packet->header.ttl <= 1) {
        Serial.println(F("[RELAY] Discarding packet: TTL expired."));
        return;
    }

    packet->header.ttl--;
    packet->header.hop_count++;

    esp_err_t result = esp_now_send(broadcast_mac, (uint8_t *)packet, sizeof(SakhiMeshPacket));
    if (result == ESP_OK) {
        Serial.printf("[RELAY] Successfully relayed ESP-NOW packet. Hop: %d, TTL: %d\n",
                      packet->header.hop_count, packet->header.ttl);
    } else {
        Serial.printf("[RELAY] Failed to relay ESP-NOW packet: %d\n", result);
    }
}

// Callback for packets received over ESP-NOW from neighboring nodes
void on_esp_now_receive(const uint8_t *mac_addr, const uint8_t *data, int data_len) {
    if (data_len != sizeof(SakhiMeshPacket)) {
        return;
    }

    SakhiMeshPacket packet;
    memcpy(&packet, data, sizeof(SakhiMeshPacket));

    if (packet.header.protocol_version != SAKHI_PROTOCOL_VERSION) {
        return;
    }

    if (is_packet_duplicate(packet.header.message_id)) {
        return; // Suppress duplicate
    }

    mark_packet_seen(packet.header.message_id);
    Serial.printf("[RELAY] Received packet from neighbor node. Type: %02X, TTL: %d\n",
                  packet.header.message_type, packet.header.ttl);

    forward_esp_now_mesh(&packet);
}

// Callback for BLE packets sent from Sakhi Mobile Client
class BlePacketCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
        std::string value = pCharacteristic->getValue();
        if (value.length() == sizeof(SakhiMeshPacket)) {
            SakhiMeshPacket packet;
            memcpy(&packet, value.data(), sizeof(SakhiMeshPacket));

            if (!is_packet_duplicate(packet.header.message_id)) {
                mark_packet_seen(packet.header.message_id);
                Serial.println(F("[RELAY] Ingested new SOS packet from mobile phone via BLE!"));

                forward_esp_now_mesh(&packet);

                // Send BLE ACK back to mobile
                if (pTxAckCharacteristic) {
                    uint8_t ack_payload[4] = {'A', 'C', 'K', 0x01};
                    pTxAckCharacteristic->setValue(ack_payload, 4);
                    pTxAckCharacteristic->notify();
                }
            }
        }
    }
};

void setup() {
    Serial.begin(115200);
    Serial.println(F("--- SAKHI EMERGENCY MESH RELAY NODE ---"));

    // 1. Initialize Wi-Fi in Station mode for ESP-NOW (No connection to AP required)
    WiFi.mode(WIFI_STA);
    WiFi.disconnect();

    // 2. Initialize ESP-NOW
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

    // 3. Initialize BLE Peripheral Interface
    BLEDevice::init("SAKHI-RELAY-01");
    BLEServer *pServer = BLEDevice::createServer();
    BLEService *pService = pServer->createService(SERVICE_UUID);

    BLECharacteristic *pRxChar = pService->createCharacteristic(
        CHAR_RX_PACKET_UUID,
        BLECharacteristic::PROPERTY_WRITE
    );
    pRxChar->setCallbacks(new BlePacketCallbacks());

    pTxAckCharacteristic = pService->createCharacteristic(
        CHAR_TX_ACK_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );
    pTxAckCharacteristic->addDescriptor(new BLE2902());

    pService->start();
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->start();

    Serial.println(F("[RELAY] Node operational. BLE Advertising + ESP-NOW active."));
}

void loop() {
    delay(1000);
}
