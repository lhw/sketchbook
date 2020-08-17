#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

#define wifi_ssid "XXXXXXXXXXXXXXXXXXXXXXX"
#define wifi_password "XXXXXXXXXXXXXXXX"

#define mqtt_server "XXXXXXXXXXXXXXX"
#define mqtt_client_id "irrigation"
#define mqtt_topic_command "irrigation/command"
//#define mqtt_topic_battery "irrigation/battery"

#define esp_max_runtime 10e3
#define esp_deep_sleep 300e6

WiFiClient esp_client;
PubSubClient mqtt_client(esp_client);
long wait_before_sleep = millis();

void setup() {
    Serial.begin(115200);
    setup_wifi();
    setup_mqtt();
}

void callback(char* topic, uint8_t* payload, unsigned int length) {
  const size_t capacity = JSON_OBJECT_SIZE(1) + 10;
  DynamicJsonDocument doc(capacity);
  deserializeJson(doc, payload);
  int run_time = doc["run_time"]; // 300

  irrigation(run_time);

  mqtt_client.unsubscribe(mqtt_topic_command);
  mqtt_client.publish(mqtt_topic_command, NULL, 0, true);
}

void setup_wifi() {
  delay(10);
  WiFi.begin(wifi_ssid, wifi_password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
}

void setup_mqtt() {
  mqtt_client.setServer(mqtt_server, 1883);
  while (!mqtt_client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (mqtt_client.connect(mqtt_client_id)) {
      Serial.println("connected");
      mqtt_client.subscribe(mqtt_topic_command);
      mqtt_client.setCallback(callback);
    } else {
      Serial.print("failed, rc=");
      Serial.print(mqtt_client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void irrigation(int runtime_in_sec) {

}

void loop() {
  mqtt_client.loop();
  if (millis() - wait_before_sleep > mqtt_max_runtime) {
    Serial.println("Going to sleep");
    ESP.deepSleep(esp_deep_sleep);
  }
}
