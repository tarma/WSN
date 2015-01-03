#include "AM.h"
#include "DataMote.h"
#include "printf.h"
#define MAX_USHORT 65536

module DataC @safe() {
  uses {
    interface Boot;
    interface SplitControl as RadioControl;
    interface AMSend as RadioSend[am_id_t id];
    interface Receive as RadioReceive[am_id_t id];
    interface Receive as RadioSnoop[am_id_t id];
    interface Packet as RadioPacket;
    interface AMPacket as RadioAMPacket;
    interface Leds;
  }
}

implementation
{
  RESULT_MSG node;
  message_t node_msg;
  uint16_t counter;
  uint32_t num[2001];
  
  void reset()
  {
    uint16_t i;
    node.group_id = GROUP_ID;
    node.max = 0;
    node.min = MAX_USHORT;
    node.sum = 0;
    node.average = 0;
    node.median = 0;
    counter = 0;
    for (i = 1; i < 2001; i++)
      num[i] = MAX_USHORT;
  }

  event void Boot.booted() {
    reset();
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t error) {}
  event void RadioControl.stopDone(error_t error) {}

  void count()
  {
    RESULT_MSG *btrpkt;
    uint16_t i, j;

    atomic
    {
      node.average = node.sum / 2000;
      for (i = 1999; i >= 1; i--)
        for (j = 1; j <= i; j++)
          if (num[j] > num[j + 1])
          {
            num[j] = num[j] ^ num[j + 1];
            num[j + 1] = num[j + 1] ^ num[j];
            num[j] = num[j] & num[j + 1];
          }
      node.median = ((num[1000] + num[1001]) >> 1);
      btrpkt = (RESULT_MSG*)(call RadioPacket.getPayload(&node_msg, sizeof(RESULT_MSG)));
      btrpkt->group_id = node.group_id;
      btrpkt->max = node.max;
      btrpkt->min = node.min;
      btrpkt->sum = node.sum;
      btrpkt->average = node.average;
      btrpkt->median = node.median;
      call RadioPacket.setPayloadLength(&node_msg, sizeof(RESULT_MSG));
      call RadioAMPacket.setType(&node_msg, 6);
      call RadioAMPacket.setSource(&node_msg, NODE0);
      call RadioAMPacket.setDestination(&node_msg, NODE_DESTINATION);
      if (call RadioSend.send[6](NODE_DESTINATION, &node_msg, sizeof(RESULT_MSG)) == SUCCESS)
        call Leds.led1Toggle();
      printf("%d\n", node.group_id);
      printf("%ld\n", node.max);
      printf("%ld\n", node.min);
      printf("%ld\n", node.sum);
      printf("%ld\n", node.average);
      printf("%ld\n", node.median);
      printfflush();
    } 
  }

  message_t* ONE receive(message_t* ONE msg, void* payload, uint8_t len);

  event message_t *RadioSnoop.receive[am_id_t id](message_t *msg, void *payload, uint8_t len) {
    return receive(msg, payload, len);
  }
  
  event message_t *RadioReceive.receive[am_id_t id](message_t *msg, void *payload, uint8_t len) {
    return receive(msg, payload, len);
  }

  message_t* receive(message_t *msg, void *payload, uint8_t len) {
    atomic {
      if ((len == sizeof(DATA_MSG)) && ((call RadioAMPacket.source(msg)) == NODE_SOURCE)) {
        DATA_MSG *btrpkt = (DATA_MSG*)payload;
        if (num[btrpkt->sequence_number] == MAX_USHORT)
        {
          num[btrpkt->sequence_number] = btrpkt->random_integer;
          counter++;
          if (btrpkt->random_integer > node.max)
            node.max = btrpkt->random_integer;
          if (btrpkt->random_integer < node.min)
            node.min = btrpkt->random_integer;
          node.sum += btrpkt->random_integer;
          call Leds.led0Toggle();
          if (counter == 2000)
            count();
        }
      }
      if ((len == sizeof(ACK_MSG)) && ((call RadioAMPacket.source(msg)) == NODE_DESTINATION)) {
        ACK_MSG *btrpkt = (ACK_MSG*)payload;
        if (btrpkt->group_id == GROUP_ID)
          call Leds.led2Toggle();
      }
    }
    return msg;
  }

  event void RadioSend.sendDone[am_id_t id](message_t* msg, error_t error) {
  }
}

