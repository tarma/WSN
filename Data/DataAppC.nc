configuration DataAppC {
}

implementation {
  components MainC, DataC, LedsC;
  components ActiveMessageC as Radio;
  components new TimerMilliC() as Timer0;

  MainC.Boot <- DataC;
  DataC.RadioControl -> Radio;
  DataC.RadioSend -> Radio;
  DataC.RadioReceive -> Radio.Receive;
  DataC.RadioSnoop -> Radio.Snoop;
  DataC.RadioPacket -> Radio;
  DataC.RadioAMPacket -> Radio;
  DataC.Leds -> LedsC;
  DataC.Timer0 -> Timer0;
}

