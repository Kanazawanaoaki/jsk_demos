#include <M5Stack.h>
#include <print.h>
#include "Adafruit_SGP30.h"
#include <Multichannel_Gas_GMXXX.h>
#include <M5_ENV.h>

Adafruit_SGP30 sgp;
int i = 15;
long last_millis = 0;

// if you use the software I2C to drive the sensor, you can uncommnet the define SOFTWAREWIRE which in Multichannel_Gas_GMXXX.h.
#ifdef SOFTWAREWIRE
    #include <SoftwareWire.h>
    SoftwareWire myWire(3, 2);
    GAS_GMXXX<SoftwareWire> gas;
#else
    #include <Wire.h>
    GAS_GMXXX<TwoWire> gas;
#endif

static uint8_t recv_cmd[8] = {};
uint32_t val_102B = 0;
uint32_t val_302B = 0;
uint32_t val_502B = 0;
uint32_t val_702B = 0;

SHT3X sht30;
QMP6988 qmp6988;

float tmp      = 0.0;
float hum      = 0.0;
float pressure = 0.0;


void header(const char *string, uint16_t color)
{
    M5.Lcd.fillScreen(color);
    M5.Lcd.setTextSize(1);
    M5.Lcd.setTextColor(TFT_WHITE, TFT_BLACK);
    M5.Lcd.fillRect(0, 0, 320, 30, TFT_BLACK);
    M5.Lcd.setTextDatum(TC_DATUM);
    M5.Lcd.drawString(string, 160, 3, 4);
}

void setupTVOCSGP30_GasV2_ENV() {
  // SPG
  header("SGP30 TEST",TFT_BLACK);
  PRINTLN("SGP30 test");
  if (! sgp.begin()){
    PRINTLN("Sensor not found :(");
    while (1);
  }

  M5.Lcd.drawString("TVOC:", 50, 40, 4);
  M5.Lcd.drawString("eCO2:", 50, 80, 4);
  PRINT("Found SGP30 serial #");
  PRINT(sgp.serialnumber[0], HEX);
  PRINT(sgp.serialnumber[1], HEX);
  PRINTLN(sgp.serialnumber[2], HEX);
  M5.Lcd.drawString("Initialization...", 140, 120, 4);

  // GasV2
  // If you have changed the I2C address of gas sensor, you must to be specify the address of I2C.
  //The default addrss is 0x08;
  gas.begin(Wire, 0x08); // use the hardware I2C
  //gas.begin(MyWire, 0x08); // use the software I2C
  //gas.setAddress(0x64); change thee I2C address

  // ENV
  M5.lcd.setTextSize(2);  // Set the text size to 2.  设置文字大小为2
  Wire.begin();  // Wire init, adding the I2C bus.  Wire初始化, 加入i2c总线
  qmp6988.init();
  M5.lcd.println(F("ENV Unit III test"));
}

void measureTVOCSGP30_GasV2_ENV() {
  // GasV2
  val_102B=gas.getGM102B();
  val_302B=gas.getGM302B();
  val_502B=gas.getGM502B();
  val_702B=gas.getGM702B();

  // ENV
  pressure = qmp6988.calcPressure();
  if (sht30.get() == 0) {  // Obtain the data of shT30.  获取sht30的数据
    tmp = sht30.cTemp;   // Store the temperature obtained from shT30.
                         // 将sht30获取到的温度存储
    hum = sht30.humidity;  // Store the humidity obtained from the SHT30.
                           // 将sht30获取到的湿度存储
  } else {
    tmp = 0, hum = 0;
  }
  M5.lcd.fillRect(0, 20, 100, 60,
                  BLACK);  // Fill the screen with black (to clear the
                             // screen).  将屏幕填充黑色(用来清屏)
  M5.lcd.setCursor(0, 20);
  char buffer[100];
  sprintf(buffer, "Temp: %2.1f  \r\nHumi: %2.0f%%  \r\nPressure:%2.0fPa\r\n",
          tmp, hum, pressure);
  M5.Lcd.printf(buffer);
  PRINTLN(buffer);

  // SGP
  while(i > 0) {
    if(millis()- last_millis > 1000) {
      last_millis = millis();
      i--;
      M5.Lcd.fillRect(198, 120, 40, 20, TFT_BLACK);
      M5.Lcd.drawNumber(i, 20, 120, 4);
    }
  }
  M5.Lcd.fillRect(0, 120, 300, 30, TFT_BLACK);

  if (! sgp.IAQmeasure()) {
    PRINTLN("Measurement failed");
    return;
  }
  M5.Lcd.fillRect(100, 40, 220, 90, TFT_BLACK);
  M5.Lcd.drawNumber(sgp.TVOC, 120, 40 , 4);
  M5.Lcd.drawString("ppb", 200, 40, 4);
  M5.Lcd.drawNumber(sgp.eCO2, 120, 80, 4);
  M5.Lcd.drawString("ppm", 200, 80, 4);
  PRINT("TVOC "); PRINT(sgp.TVOC); PRINTLN(" ppb");
  PRINT("eCO2 "); PRINT(sgp.eCO2); PRINTLN(" ppm");
  PRINTLN("");

  // GasV2
  M5.Lcd.setTextSize(2);
  M5.Lcd.setCursor(10, 10);
  M5.Lcd.printf("GM102B: %4u = %.2f V\n", val_102B, gas.calcVol(val_102B));
  M5.Lcd.printf(" GM302B: %4u = %.2f V\n", val_302B, gas.calcVol(val_302B));
  M5.Lcd.printf(" GM502B: %4u = %.2f V\n", val_502B, gas.calcVol(val_502B));
  M5.Lcd.printf(" GM702B: %4u = %.2f V\n", val_702B, gas.calcVol(val_702B));
}
