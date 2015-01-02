#include <Timer.h>
#include "SenseMote.h"

configuration SenseAppC 
{ 
} 
implementation { 
  
  components SenseC, MainC, LedsC; 
  components new TimerMilliC() as Timer;
  components new HamamatsuS1087ParC() as LightSensor;
  components new SensirionSht11C() as TmpHumSensor;
  components new AMSenderC(AM_RADIO_MSG);
  components ActiveMessageC;
  components new AMReceiverC(AM_RADIO_MSG);
   
  SenseC -> MainC.Boot;
  SenseC.ReadLight -> LightSensor.Read;
  SenseC.ReadTemperature->TmpHumSensor.Temperature;
  SenseC.ReadHumidity -> TmpHumSensor.Humidity;
  SenseC.Boot -> MainC;
  SenseC.Leds -> LedsC;
  SenseC.Timer -> Timer;
  SenseC.Packet -> AMSenderC;
  SenseC.AMPacket -> AMSenderC;
  SenseC.AMSend -> AMSenderC.AMSend;
  SenseC.AMControl -> ActiveMessageC;
}
