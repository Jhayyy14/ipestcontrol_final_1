/*
 * IPESTCONTROL ESP32
 * Phase 5 – Pest (MDL) + Insect (Blue + HV) + Battery Monitoring
 */

#include <WiFi.h>
#include <WebServer.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <Adafruit_INA219.h>

// ================= WIFI =================
const char* ssid     = "IPESTCONTROL";
const char* password = "YOHANYOHAN";

// Raspberry Pi
const char* PI_IP   = "10.42.0.1";
const int   PI_PORT = 5000;

// Static IP (ESP32)
IPAddress local_IP(10, 42, 0, 50);
IPAddress gateway(10, 42, 0, 1);
IPAddress subnet(255, 255, 255, 0);

// ================= GPIO =================
// ACTIVE-LOW RELAYS
const int RELAY_PEST   = 25;  // IN1 – MDL
const int BLUE_LIGHT   = 26;  // MOSFET
const int ZAPPER_RELAY = 27;  // IN2 – HV
const int LED_PIN      = 2;

// ================= TIMING =================
const unsigned long STROBE_DELAY     = 120;     // ms
const unsigned long PEST_ACTIVE_TIME = 10000;   // 10s
const unsigned long HV_ON_TIME       = 10000;   // 10s
const unsigned long HV_OFF_TIME      = 10000;   // 10s
const unsigned long BATTERY_INTERVAL = 2000;    // 2s

// ================= STATE =================
bool pest_mode   = false;
bool insect_mode = false;

// ---- PEST STROBE ----
bool strobeActive = false;
int  strobeStep   = 0;
unsigned long lastStrobeChange = 0;
unsigned long strobeStartTime  = 0;

// ---- INSECT HV ----
bool hv_on = false;
unsigned long hv_timer = 0;

// ---- BATTERY ----
Adafruit_INA219 ina219;
bool battery_ok = false;
float batt_v = 0, batt_c = 0, batt_p = 0;
int batt_percent = 0;
unsigned long lastBatteryPush = 0;

// ================= SERVER =================
WebServer server(80);

// ================= SETUP =================
void setup() {
  Serial.begin(115200);
  delay(500);

  pinMode(RELAY_PEST, OUTPUT);
  pinMode(BLUE_LIGHT, OUTPUT);
  pinMode(ZAPPER_RELAY, OUTPUT);
  pinMode(LED_PIN, OUTPUT);

  // SAFE START
  digitalWrite(RELAY_PEST, HIGH);
  digitalWrite(BLUE_LIGHT, LOW);
  digitalWrite(ZAPPER_RELAY, HIGH);
  digitalWrite(LED_PIN, LOW);

  // INA219
  Wire.begin(21, 22);
  battery_ok = ina219.begin();
  if (battery_ok) {
    ina219.setCalibration_16V_400mA();
    Serial.println("🔋 INA219 OK");
  } else {
    Serial.println("❌ INA219 NOT FOUND");
  }

  // WiFi
  WiFi.mode(WIFI_STA);
  WiFi.config(local_IP, gateway, subnet);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    digitalWrite(LED_PIN, !digitalRead(LED_PIN));
    delay(300);
  }
  digitalWrite(LED_PIN, HIGH);

  // ROUTES
  server.on("/status", HTTP_GET, handleStatus);
  server.on("/update_mode", HTTP_POST, handleMode);
  server.on("/trigger", HTTP_GET, handleTrigger);

  server.begin();
  Serial.println("🌐 ESP32 READY");
  Serial.println(WiFi.localIP());
}

// ================= LOOP =================
void loop() {
  server.handleClient();
  unsigned long now = millis();

  // ===== PEST MODE =====
  if (strobeActive) {
    if (now - strobeStartTime >= PEST_ACTIVE_TIME) {
      digitalWrite(RELAY_PEST, HIGH);
      strobeActive = false;
      strobeStep = 0;
      Serial.println("🛑 MDL OFF");
    }
    else if (strobeStep < 7 && now - lastStrobeChange >= STROBE_DELAY) {
      lastStrobeChange = now;
      strobeStep++;
      digitalWrite(RELAY_PEST, (strobeStep % 2) ? LOW : HIGH);
      if (strobeStep == 7) {
        digitalWrite(RELAY_PEST, LOW);
        Serial.println("⚡ MDL STROBE ACTIVE");
      }
    }
  }

  // ===== INSECT MODE =====
  if (insect_mode) {
    digitalWrite(BLUE_LIGHT, HIGH);

    if (hv_on && now - hv_timer >= HV_ON_TIME) {
      hv_on = false;
      hv_timer = now;
      digitalWrite(ZAPPER_RELAY, HIGH);
      Serial.println("⚡ HV OFF");
    }
    else if (!hv_on && now - hv_timer >= HV_OFF_TIME) {
      hv_on = true;
      hv_timer = now;
      digitalWrite(ZAPPER_RELAY, LOW);
      Serial.println("⚡ HV ON");
    }
  } else {
    digitalWrite(BLUE_LIGHT, LOW);
    digitalWrite(ZAPPER_RELAY, HIGH);
    hv_on = false;
  }

  // ===== BATTERY PUSH =====
  if (battery_ok && now - lastBatteryPush >= BATTERY_INTERVAL) {
    lastBatteryPush = now;
    readBattery();
    pushBattery();
  }
}

// ================= HANDLERS =================
void handleTrigger() {
  if (!pest_mode || strobeActive) {
    server.send(403, "text/plain", "IGNORED");
    return;
  }

  strobeActive = true;
  strobeStep = 0;
  lastStrobeChange = millis();
  strobeStartTime  = millis();

  digitalWrite(RELAY_PEST, HIGH);
  Serial.println("🚨 PEST TRIGGERED");
  server.send(200, "text/plain", "Triggered");
}

void handleMode() {
  StaticJsonDocument<200> doc;
  deserializeJson(doc, server.arg("plain"));

  pest_mode   = doc["pest_mode"] | false;
  insect_mode = doc["insect_mode"] | false;

  if (!pest_mode) {
    strobeActive = false;
    digitalWrite(RELAY_PEST, HIGH);
  }
  if (!insect_mode) {
    hv_on = false;
    digitalWrite(BLUE_LIGHT, LOW);
    digitalWrite(ZAPPER_RELAY, HIGH);
  }

  server.send(200, "application/json", "{\"ok\":true}");
}

void handleStatus() {
  StaticJsonDocument<300> doc;
  doc["pest"] = pest_mode;
  doc["insect"] = insect_mode;
  doc["ip"] = WiFi.localIP().toString();

  JsonObject batt = doc.createNestedObject("battery");
  batt["voltage"] = batt_v;
  batt["current"] = batt_c;
  batt["power"]   = batt_p;
  batt["percent"] = batt_percent;
  batt["ok"]      = battery_ok;

  String out;
  serializeJson(doc, out);
  server.send(200, "application/json", out);
}

// ================= BATTERY =================
void readBattery() {
  batt_v = ina219.getBusVoltage_V();
  batt_c = ina219.getCurrent_mA() / 1000.0;
  batt_p = ina219.getPower_mW() / 1000.0;

  // Adjust these values to match your battery pack
  batt_percent = constrain(map((int)(batt_v * 100), 1050, 1260, 0, 100), 0, 100);
}

void pushBattery() {
  HTTPClient http;
  String url = String("http://") + PI_IP + ":" + PI_PORT + "/external_battery";

  StaticJsonDocument<200> doc;
  doc["voltage"] = batt_v;
  doc["current"] = batt_c;
  doc["power"]   = batt_p;
  doc["percent"] = batt_percent;

  String payload;
  serializeJson(doc, payload);

  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.POST(payload);
  http.end();
}
