#include <M5_PbHub.h>
M5_PbHub myPbHub;


void setup() {
    Serial.begin(115200);
//    if (!pbhub.begin(&Wire, UNIT_PBHUB_I2C_ADDR, 21, 22, 400000U)) {
//        Serial.println("Couldn't find Pbhub");
//        while (1) delay(1);
//    }
  Wire.begin();
  myPbHub.begin();
}

void loop() {
    // ch: 0-5
    // index: 0-1
    // status: 0/1
//    for (uint8_t ch = 0; ch < 6; ch++) {
//        // only one pin supports analog reading each channel
//        Serial.printf("ch:%d adc:%d\r\n", ch, pbhub.analogRead(ch));
//        delay(500);
//    }
    int ch = 0;
    int a_value = myPbHub.digitalRead(ch);
    int d_value = myPbHub.analogRead(ch);
    Serial.printf("ch:%d adc:%d ddc:%d \r\n", ch, a_value, d_value);
    delay(500);
}