#include "AM.h"
#include "SenseMote.h"
#include "Timer.h"

module SenseC @safe() {
  uses {
    interface Boot;
    interface SplitControl as RadioControl;

    interface AMSend as RadioSend[am_id_t id];
    interface Receive as RadioReceive[am_id_t id];
    interface Receive as RadioSnoop[am_id_t id];
    interface Packet as RadioPacket;
    interface AMPacket as RadioAMPacket;

    interface Leds;
    interface Timer<TMilli> as Timer0;
    interface Read<uint16_t> as ReadLight;
    interface Read<uint16_t> as ReadTemperature;
    interface Read<uint16_t> as ReadHumidity;
  }
}

implementation
{
  enum {
    RADIO_QUEUE_LEN = 12,
  };

  message_t  radioQueueBufs[RADIO_QUEUE_LEN];
  message_t  * ONE_NOK radioQueue[RADIO_QUEUE_LEN];
  uint8_t    radioIn, radioOut;
  bool       radioBusy, radioFull;

  RADIO_MSG  node1;
  message_t node1_msg;
  bool node1_ack;

  task void radioSendTask();

  void dropBlink() {
    call Leds.led2Toggle();
  }

  void failBlink() {
    call Leds.led2Toggle();
  }

  event void Boot.booted() {
    uint8_t i;

    for (i = 0; i < RADIO_QUEUE_LEN; i++)
      radioQueue[i] = &radioQueueBufs[i];
    radioIn = radioOut = 0;
    radioBusy = FALSE;
    radioFull = TRUE;

    node1.nodeid = NODE1;
    node1.counter = -1;
    node1_ack = TRUE;
    node1.time_period = 500;
    node1.total_time = 0;
    call Timer0.startPeriodic(node1.time_period);

    call RadioControl.start();
  }

  event void Timer0.fired()
  {
    message_t *ret;
    RADIO_MSG *btrpkt;

    atomic {
      if (node1_ack)
      {
        call ReadLight.read();
        call ReadTemperature.read();
        call ReadHumidity.read();
        node1.counter++;
        node1_ack = FALSE;
      }
      node1.total_time += node1.time_period;
      btrpkt = (RADIO_MSG*)(call RadioPacket.getPayload(&node1_msg, sizeof(RADIO_MSG)));
      btrpkt->nodeid = node1.nodeid;
      btrpkt->counter = node1.counter;
      btrpkt->temperature = node1.temperature;
      btrpkt->humidity = node1.humidity;
      btrpkt->light = node1.light;
      btrpkt->time_period = node1.time_period;
      btrpkt->total_time = node1.total_time;
      call RadioPacket.setPayloadLength(&node1_msg, sizeof(RADIO_MSG));
      call RadioAMPacket.setType(&node1_msg, AM_RADIO_MSG);
      call RadioAMPacket.setSource(&node1_msg, NODE1);
      call RadioAMPacket.setDestination(&node1_msg, NODE0);
      if (!radioFull)
	{
	  ret = radioQueue[radioIn];
	  *radioQueue[radioIn] = node1_msg;

	  radioIn = (radioIn + 1) % RADIO_QUEUE_LEN;
	
	  if (radioIn == radioOut)
	    radioFull = TRUE;

	  if (!radioBusy)
	    {
	      post radioSendTask();
	      radioBusy = TRUE;
	    }
	}
      else
	dropBlink();

    }

  }

  event void RadioControl.startDone(error_t error) {
    if (error == SUCCESS) {
      radioFull = FALSE;
    }
  }

  event void RadioControl.stopDone(error_t error) {}

  message_t* ONE receive(message_t* ONE msg, void* payload, uint8_t len);
  
  event message_t *RadioSnoop.receive[am_id_t id](message_t *msg,
						    void *payload,
						    uint8_t len) {
    return receive(msg, payload, len);
  }
  
  event message_t *RadioReceive.receive[am_id_t id](message_t *msg,
						    void *payload,
						    uint8_t len) {
    return receive(msg, payload, len);
  }

  message_t* receive(message_t *msg, void *payload, uint8_t len) {
    message_t *ret = msg;

    atomic {
      if (len == sizeof(ACK_MSG)) {
        ACK_MSG *btrpkt = (ACK_MSG*)payload;
        if (btrpkt->nodeid == node1.nodeid)
        {
          if (btrpkt->counter == node1.counter)
            node1_ack = TRUE;
        }
        else
        {
          call RadioPacket.setPayloadLength(msg, sizeof(ACK_MSG));
          call RadioAMPacket.setType(msg, AM_RADIO_MSG);
          call RadioAMPacket.setSource(msg, NODE1);
          call RadioAMPacket.setDestination(msg, NODE2);
          if (!radioFull)
  	  {
	    ret = radioQueue[radioIn];
	    *radioQueue[radioIn] = *msg;
	    radioIn = (radioIn + 1) % RADIO_QUEUE_LEN;
	    if (radioIn == radioOut)
	      radioFull = TRUE;
	    if (!radioBusy)
	    {
	      post radioSendTask();
	      radioBusy = TRUE;
	    }
            call Leds.led2Toggle();
	  }
          else
	    dropBlink();
        }
      }
      if (len == sizeof(RADIO_MSG)) {
        call RadioPacket.setPayloadLength(msg, sizeof(RADIO_MSG));
        call RadioAMPacket.setType(msg, AM_RADIO_MSG);
        call RadioAMPacket.setSource(msg, NODE1);
        call RadioAMPacket.setDestination(msg, NODE0);
        if (!radioFull)
	  {
	    ret = radioQueue[radioIn];
	    *radioQueue[radioIn] = *msg;
	    radioIn = (radioIn + 1) % RADIO_QUEUE_LEN;
	    if (radioIn == radioOut)
	      radioFull = TRUE;
	    if (!radioBusy)
	    {
	      post radioSendTask();
	      radioBusy = TRUE;
	    }
            call Leds.led1Toggle();
	  }
          else
	    dropBlink();
      }
    }
    
    return ret;
  }

  task void radioSendTask() {
    uint8_t len;
    am_id_t id;
    am_addr_t addr,source;
    message_t* msg;
    
    atomic
      if (radioIn == radioOut && !radioFull)
	{
	  radioBusy = FALSE;
	  return;
	}

    msg = radioQueue[radioOut];
    len = call RadioPacket.payloadLength(msg);
    addr = call RadioAMPacket.destination(msg);
    source = call RadioAMPacket.source(msg);
    id = call RadioAMPacket.type(msg);

    if (call RadioSend.send[id](addr, msg, len) == SUCCESS)
      call Leds.led0Toggle();
    else
      {
	failBlink();
	post radioSendTask();
      }
  }

  event void RadioSend.sendDone[am_id_t id](message_t* msg, error_t error) {
    if (error != SUCCESS)
      failBlink();
    else
      atomic
	if (msg == radioQueue[radioOut])
	  {
	    if (++radioOut >= RADIO_QUEUE_LEN)
	      radioOut = 0;
	    if (radioFull)
	      radioFull = FALSE;
	  }
    
    post radioSendTask();
  }

  event void ReadTemperature.readDone(error_t result, uint16_t data)
  {
    if (result == SUCCESS)
      node1.temperature = data;
  }

  event void ReadHumidity.readDone(error_t result, uint16_t data)
  {
    if (result == SUCCESS)
      node1.humidity = data;
  }

  event void ReadLight.readDone(error_t result, uint16_t data)
  {
    if (result == SUCCESS)
      node1.light = data;
  }
}

