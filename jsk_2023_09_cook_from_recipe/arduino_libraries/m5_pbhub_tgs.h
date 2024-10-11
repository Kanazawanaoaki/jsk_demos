#include <M5Stack.h>
#include <print.h>
#include <M5_PbHub.h>
M5_PbHub myPbHub;

int ch_2600 = 0;
int ch_2602 = 1;
int ch_2603 = 2;

uint16_t a_value_2600;
uint16_t d_value_2600;
uint16_t a_value_2602;
uint16_t d_value_2602;
uint16_t a_value_2603;
uint16_t d_value_2603;

void setupPbHubTGSSensors()
{
  Wire.begin();
  myPbHub.begin();
}

void measurePbHubTGSSensors()
{
  a_value_2600 = myPbHub.analogRead(ch_2600);
  d_value_2600 = myPbHub.digitalRead(ch_2600);
  a_value_2602 = myPbHub.analogRead(ch_2602);
  d_value_2602 = myPbHub.digitalRead(ch_2602);
  a_value_2603 = myPbHub.analogRead(ch_2603);
  d_value_2603 = myPbHub.digitalRead(ch_2603);
}

void displayPbHubTGSSensors()
{
  M5.Lcd.setTextSize(2);
  M5.Lcd.setCursor(10, 10);
  M5.Lcd.printf("2600_analog_value: %04d\n", a_value_2600);
  M5.Lcd.printf(" 2600_digital_value: %01d\n", d_value_2600);
  M5.Lcd.printf(" 2602_analog_value: %04d\n", a_value_2602);
  M5.Lcd.printf(" 2602_digital_value: %01d\n", d_value_2602);
  M5.Lcd.printf(" 2603_analog_value: %04d\n", a_value_2603);
  M5.Lcd.printf(" 2603_digital_value: %01d\n", d_value_2603);
}

