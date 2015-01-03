configuration DataAppC {
}

implementation {
  components MainC, DataC, LedsC;
  components ActiveMessageC as Radio;

  MainC.Boot <- DataC;
  DataC.RadioControl -> Radio;
  DataC.RadioSend -> Radio;
  DataC.RadioReceive -> Radio.Receive;
  DataC.RadioSnoop -> Radio.Snoop;
  DataC.RadioPacket -> Radio;
  DataC.RadioAMPacket -> Radio;
  DataC.Leds -> LedsC;
}

