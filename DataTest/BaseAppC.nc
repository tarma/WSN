#include <Timer.h>
#include "BaseMote.h"

configuration BaseAppC 
{ 
} 
implementation { 
  
  components BaseC, MainC, LedsC; 
  components new TimerMilliC() as Timer;
  components new AMSenderC(AM_RADIO_MSG);
  components ActiveMessageC;
  components new AMReceiverC(AM_RADIO_MSG);
   
  BaseC -> MainC.Boot;

  BaseC.Boot -> MainC;
  BaseC.Leds -> LedsC;
  BaseC.Timer -> Timer;

  BaseC.Packet -> AMSenderC;
  BaseC.AMPacket -> AMSenderC;
  BaseC.AMSend -> AMSenderC.AMSend;
  BaseC.AMControl -> ActiveMessageC;
  BaseC.Receive->AMReceiverC;
}
