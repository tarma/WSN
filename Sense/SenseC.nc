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

  RADIO_MSG  node;
  message_t node_msg;
  bool node_ack;

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

    node.nodeid = TOS_NODE_ID;
    node.counter = -1;
    node_ack = TRUE;
    node.time_period = 100;
    node.total_time = 0;
    call Timer0.startPeriodic(node.time_period);

    call RadioControl.start();
  }

  event void Timer0.fired()
  {
    message_t *ret;
    RADIO_MSG *btrpkt;

    atomic {
      if (node_ack)
      {
        call ReadLight.read();
        call ReadTemperature.read();
        call ReadHumidity.read();
        node.counter++;
        node_ack = FALSE;
      }
      node.total_time += node.time_period;
      btrpkt = (RADIO_MSG*)(call RadioPacket.getPayload(&node_msg, sizeof(RADIO_MSG)));
      btrpkt->nodeid = node.nodeid;
      btrpkt->counter = node.counter;
      btrpkt->temperature = node.temperature;
      btrpkt->humidity = node.humidity;
      btrpkt->light = node.light;
      btrpkt->time_period = node.time_period;
      btrpkt->total_time = node.total_time;
      call RadioPacket.setPayloadLength(&node_msg, sizeof(RADIO_MSG));
      call RadioAMPacket.setType(&node_msg, AM_RADIO_MSG);
      call RadioAMPacket.setSource(&node_msg, node.nodeid);
      if (node.nodeid == NODE1)
        call RadioAMPacket.setDestination(&node_msg, NODE0);
      else
        call RadioAMPacket.setDestination(&node_msg, NODE1);
      if (!radioFull)
	{
	  ret = radioQueue[radioIn];
	  *radioQueue[radioIn] = node_msg;

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
        if (btrpkt->nodeid == node.nodeid)
        {
          if (btrpkt->counter == node.counter)
            node_ack = TRUE;
        }
        else
          if (node.nodeid == NODE1)
          {
            call RadioPacket.setPayloadLength(msg, sizeof(ACK_MSG));
            call RadioAMPacket.setType(msg, AM_RADIO_MSG);
            call RadioAMPacket.setSource(msg, node.nodeid);
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
      if ((len == sizeof(RADIO_MSG)) && ((call RadioAMPacket.source(msg)) == NODE2)){
        call RadioPacket.setPayloadLength(msg, sizeof(RADIO_MSG));
        call RadioAMPacket.setType(msg, AM_RADIO_MSG);
        call RadioAMPacket.setSource(msg, node.nodeid);
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
      node.temperature = data;
  }

  event void ReadHumidity.readDone(error_t result, uint16_t data)
  {
    if (result == SUCCESS)
      node.humidity = data;
  }

  event void ReadLight.readDone(error_t result, uint16_t data)
  {
    if (result == SUCCESS)
      node.light = data;
  }
}

