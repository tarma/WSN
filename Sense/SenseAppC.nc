configuration SenseAppC {
}

implementation {
  components MainC, SenseC, LedsC;
  components ActiveMessageC as Radio;
  components new TimerMilliC() as Timer0;  
  components new HamamatsuS1087ParC() as LightSensor;
  components new SensirionSht11C() as TmpHumSensor;

  MainC.Boot <- SenseC;

  SenseC.RadioControl -> Radio;

  SenseC.RadioSend -> Radio;
  SenseC.RadioReceive -> Radio.Receive;
  SenseC.RadioSnoop -> Radio.Snoop;
  SenseC.RadioPacket -> Radio;
  SenseC.RadioAMPacket -> Radio;
  
  SenseC.Leds -> LedsC;
  SenseC.Timer0 -> Timer0;
  SenseC.ReadLight -> LightSensor.Read;
  SenseC.ReadTemperature->TmpHumSensor.Temperature;
  SenseC.ReadHumidity -> TmpHumSensor.Humidity;
}

