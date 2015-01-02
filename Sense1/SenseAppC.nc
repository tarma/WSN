configuration SenseAppC {
}

implementation {
  components MainC, SenseC, LedsC;
  components ActiveMessageC as Radio;
  components new TimerMilliC() as Timer0;  

  MainC.Boot <- SenseC;

  SenseC.RadioControl -> Radio;

  SenseC.RadioSend -> Radio;
  SenseC.RadioReceive -> Radio.Receive;
  SenseC.RadioSnoop -> Radio.Snoop;
  SenseC.RadioPacket -> Radio;
  SenseC.RadioAMPacket -> Radio;
  
  SenseC.Leds -> LedsC;
  SenseC.Timer0 -> Timer0;
}

