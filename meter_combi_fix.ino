// Include the libraries we need
#include <OneWire.h>
#include <DallasTemperature.h>
#include "AiEsp32RotaryEncoder.h"
#include <Wire.h>
#include <Adafruit_INA219.h>
#include <DFRobot_HX711.h>

#define ONE_WIRE_BUS 4
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature tempSensor(&oneWire);

#define TRIG_PIN 20 // ESP32 pin GPIO20 connected to Ultrasonic Sensor's TRIG pin
#define ECHO_PIN 19 // ESP32 pin GPIO19 connected to Ultrasonic Sensor's ECHO pin

#define ROTARY_ENCODER_A_PIN 22
#define ROTARY_ENCODER_B_PIN 21
#define ROTARY_ENCODER_BUTTON_PIN 23
#define ROTARY_ENCODER_VCC_PIN -1
#define ROTARY_ENCODER_STEPS 4
#define MAX_ROTARY_VALUE 100
AiEsp32RotaryEncoder rotaryEncoder = AiEsp32RotaryEncoder(ROTARY_ENCODER_A_PIN, ROTARY_ENCODER_B_PIN, ROTARY_ENCODER_BUTTON_PIN, -1, ROTARY_ENCODER_STEPS);
void IRAM_ATTR readEncoderISR()
{
    rotaryEncoder.readEncoder_ISR();
}
unsigned long rpmPeriod = 0;

Adafruit_INA219 ina219;

DFRobot_HX711 MyScale(9, 18);

#define BREAK_PIN 10
#define ABS_PIN 11
#define AIRBAG_PIN 2
#define SEATBELT_PIN 8
void setup(void)
{
    // start serial port
    Serial.begin(115200);
    // Start up the library
    tempSensor.begin();

    pinMode(TRIG_PIN, OUTPUT);
    pinMode(ECHO_PIN, INPUT);

    rotaryEncoder.begin();
    rotaryEncoder.setup(readEncoderISR);
    rotaryEncoder.setBoundaries(0, MAX_ROTARY_VALUE, true); 
    rotaryEncoder.disableAcceleration();

    Wire.begin(5, 6);
    if (! ina219.begin()) {
      Serial.println("Failed to find INA219 chip");
      while (1) { delay(10); }
    }
    ina219.setCalibration_16V_400mA();

    pinMode(BREAK_PIN, INPUT_PULLUP);
    pinMode(ABS_PIN, INPUT_PULLUP);
    pinMode(AIRBAG_PIN, INPUT_PULLUP);
    pinMode(SEATBELT_PIN, INPUT_PULLUP);
    
}
unsigned long lastMillis = 0;
unsigned long period = 1000;
void loop(void)
{ 
    if(millis() - lastMillis >= period){
        lastMillis = millis();
        tempSensor.requestTemperatures(); // Send the command to get temperatures
        float tempC = tempSensor.getTempCByIndex(0);

        digitalWrite(TRIG_PIN, HIGH);
        delayMicroseconds(10);
        digitalWrite(TRIG_PIN, LOW);
        float duration_us = pulseIn(ECHO_PIN, HIGH);
        float distance_cm = 0.017 * duration_us;
        distance_cm = constrain(distance_cm, 0, 100);
        distance_cm = map(distance_cm, 0, 100, 100, 0);
        
        float shuntvoltage = ina219.getShuntVoltage_mV();
        float busvoltage = ina219.getBusVoltage_V();
        float current_mA = ina219.getCurrent_mA();
        float power_mW = ina219.getPower_mW();
        float loadvoltage = busvoltage + shuntvoltage;
        loadvoltage = constrain(loadvoltage, 0.00, 4.75);
        loadvoltage = (loadvoltage - 0.00)/(4.75 - 0.00) * 100;
        
        float weight = MyScale.readWeight();
        weight = constrain(weight, 0, 100);

        bool breakVal = !digitalRead(BREAK_PIN);
        bool absVal = !digitalRead(ABS_PIN);
        bool airbagVal = !digitalRead(AIRBAG_PIN);
        bool seatbeltVal = !digitalRead(SEATBELT_PIN);

        float step = rotaryEncoder.readEncoder();
        float rpm = (step * 60)/MAX_ROTARY_VALUE;
        rotaryEncoder.setEncoderValue(0);
        //Serial.printf("{\"speed\":%.2f,\"temperature\":%.2f,\"level\":%.2f,\"pressure\":%.2f,\"voltage\":%.2f,\"break\":%d,\"abs\":%d,\"airbag\":%d,\"seatbelt\":%d}\n", rpm, tempC, distance_cm, weight, loadvoltage, breakVal, absVal, airbagVal, seatbeltVal);
        Serial.printf("Speed:%.0f\n", rpm); // Mengirim "Speed:nilai_rpm"
        Serial.printf("Temperature:%.1f\n", tempC); // Key "Temperature"
        Serial.printf("Level:%.0f\n", distance_cm);   // Key "Level"
        Serial.printf("Pressure:%.1f\n", weight);    // Key "Pressure"
        Serial.printf("Voltage:%.2f\n", loadvoltage);  // Key "Voltage" (menggunakan busvoltage)
        Serial.printf("Brake:%d\n", breakVal);      // Key "Brake" (0/1)
        Serial.printf("ABS:%d\n", absVal);          // Key "ABS"
        Serial.printf("Airbag:%d\n", airbagVal);    // Key "Airbag"
        Serial.printf("Seatbelt:%d\n", seatbeltVal); // Key "Seatbelt"
    }
}
