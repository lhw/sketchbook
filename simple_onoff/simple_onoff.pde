#include <RCSwitch.h>

RCSwitch mySwitch = RCSwitch();

byte receiveData[3];
byte index = 0;

void setup() {
  Serial.begin(9600);
  mySwitch.enableTransmit(11);
}

void loop() {
  while(Serial.available()) {
    receiveData[index++] = Serial.read();

    if(index == 3) {
      if(receiveData[0] == 1)
        mySwitch.switchOn(receiveData[1], receiveData[2] + 1);
      else
        mySwitch.switchOff(receiveData[1], receiveData[2] + 1);

      index = 0;
    }
  }
}


