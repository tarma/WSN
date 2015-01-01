#include "SenseMote.h"

configuration BaseStationAppC {
}

implementation {
  components MainC;
  components LedsC;
  components BaseStationC;
  components ActiveMessageC;
  components new AMSenderC(AM_RADIO_MSG);
  components new AMReceiverC(AM_RADIO_MSG);

  BaseStationC.Boot -> MainC;
  BaseStationC.Leds -> LedsC;
  BaseStationC.Packet -> AMSenderC;
  BaseStationC.AMSend -> AMSenderC;
  BaseStationC.Receive -> AMReceiverC;
  BaseStationC.AMControl -> ActiveMessageC;
}

