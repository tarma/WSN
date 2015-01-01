configuration BaseStationAppC {
}

implementation {
  components MainC, BaseStationC, LedsC;
  components ActiveMessageC as Radio, SerialActiveMessageC as Serial;
  
  MainC.Boot <- BaseStationC;

  BaseStationC.RadioControl -> Radio;
  BaseStationC.SerialControl -> Serial;
  
  BaseStationC.SerialSend -> Serial;
  BaseStationC.SerialReceive -> Serial.Receive;
  BaseStationC.SerialPacket -> Serial;
  BaseStationC.SerialAMPacket -> Serial;
  
  BaseStationC.RadioSend -> Radio;
  BaseStationC.RadioReceive -> Radio.Receive;
  BaseStationC.RadioSnoop -> Radio.Snoop;
  BaseStationC.RadioPacket -> Radio;
  BaseStationC.RadioAMPacket -> Radio;
  
  BaseStationC.Leds -> LedsC;
}
