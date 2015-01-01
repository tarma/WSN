#include "SenseMote.h"

module BaseStationC {
  uses interface Boot;
  uses interface Leds;
  uses interface Packet;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
}

implementation {

  bool busy = FALSE;
  message_t pkt;

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

  event void AMSend.sendDone(message_t *msg, error_t err) {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }

  event message_t* Receive.receive(message_t *msg, void *payload, uint8_t len) {
    RADIO_MSG *btrpkt = (RADIO_MSG*)payload;
    call Leds.set(btrpkt->counter);
    return msg;
  }

}

