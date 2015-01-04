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
    interface Timer<TMilli> as Timer0;
  }
}

implementation
{
  RESULT_MSG node;
  message_t node_msg;
  uint16_t counter;
  uint32_t num[2001];
  bool finish;
  
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
    finish = FALSE;
  }

  event void Boot.booted() {
    reset();
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t error) {}
  event void RadioControl.stopDone(error_t error) {}

  void qsort(uint16_t x, uint16_t y)
  {
    uint16_t i = x, j = y;
    uint32_t k = num[((x + y) >> 1)], t;

    while (i < j)
    {
      while (num[i] < k) i++;
      while (num[j] > k) j--;
      if (i <= j)
      {
        t = num[i];
        num[i] = num[j];
        num[j] = t;
        i++;
        j--;
      }
    }

    if (x < j) qsort(x, j);
    if (y > i) qsort(i, y);
  }

  void count()
  {
    atomic
    {
      node.average = node.sum / 2000;
      qsort(1, 2000);
      node.median = ((num[1000] + num[1001]) >> 1);
      call Timer0.startPeriodic(100);
    }
  }

  event void Timer0.fired()
  {
    RESULT_MSG *btrpkt;
    atomic
    {
      if (finish)
      {
        call Timer0.stop();
        return;
      }
      btrpkt = (RESULT_MSG*)(call RadioPacket.getPayload(&node_msg, sizeof(RESULT_MSG)));
      btrpkt->group_id = node.group_id;
      btrpkt->max = node.max;
      btrpkt->min = node.min;
      btrpkt->sum = node.sum;
      btrpkt->average = node.average;
      btrpkt->median = node.median;
      call RadioPacket.setPayloadLength(&node_msg, sizeof(RESULT_MSG));
      call RadioAMPacket.setType(&node_msg, 6);
      call RadioAMPacket.setSource(&node_msg, TOS_NODE_ID);
      if (TOS_NODE_ID == NODE0)
      {
        call RadioAMPacket.setDestination(&node_msg, NODE_DESTINATION);
        if (call RadioSend.send[6](NODE_DESTINATION, &node_msg, sizeof(RESULT_MSG)) == SUCCESS)
          call Leds.led1Toggle();
      }
      else
      {
        call RadioAMPacket.setDestination(&node_msg, NODE0);
        if (call RadioSend.send[6](NODE0, &node_msg, sizeof(RESULT_MSG)) == SUCCESS)
          call Leds.led1Toggle();
      }
      printf("groud_id: %d\n", node.group_id);
      printf("max: %ld\n", node.max);
      printf("min: %ld\n", node.min);
      printf("sum: %ld\n", node.sum);
      printf("average: %ld\n", node.average);
      printf("median: %ld\n", node.median);
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
      if ((len == sizeof(ACK_MSG)) && ((call RadioAMPacket.source(msg)) == NODE_DESTINATION) && (TOS_NODE_ID == NODE0)) {
        ACK_MSG *btrpkt = (ACK_MSG*)payload;
        if (btrpkt->group_id == GROUP_ID)
        {
          call Leds.led2Toggle();
          finish = TRUE;
          call RadioPacket.setPayloadLength(msg, sizeof(ACK_MSG));
          call RadioAMPacket.setType(msg, 6);
          call RadioAMPacket.setSource(msg, TOS_NODE_ID);
          call RadioAMPacket.setDestination(msg, NODE1);
          call RadioSend.send[6](NODE1, msg, sizeof(ACK_MSG));
          call RadioAMPacket.setDestination(msg, NODE2);
          call RadioSend.send[6](NODE2, msg, sizeof(ACK_MSG));
        }
      }
      if ((len == sizeof(ACK_MSG)) && ((call RadioAMPacket.source(msg)) == NODE0) && (TOS_NODE_ID != NODE0)) {
        ACK_MSG *btrpkt = (ACK_MSG*)payload;
        if (btrpkt->group_id == GROUP_ID)
        {
          call Leds.led2Toggle();
          finish = TRUE;
        }
      }
      if ((len == sizeof(RESULT_MSG)) && (((call RadioAMPacket.source(msg)) == NODE1) || ((call RadioAMPacket.source(msg)) == NODE2)) && (TOS_NODE_ID == NODE0)) {
        RESULT_MSG *btrpkt = (RESULT_MSG*)payload;
        call RadioPacket.setPayloadLength(msg, sizeof(RESULT_MSG));
        call RadioAMPacket.setType(msg, 6);
        call RadioAMPacket.setSource(msg, TOS_NODE_ID);
        call RadioAMPacket.setDestination(msg, NODE_DESTINATION);
        if (call RadioSend.send[6](NODE_DESTINATION, msg, sizeof(RESULT_MSG)) == SUCCESS)
          call Leds.led1Toggle();
        printf("groud_id: %d\n", btrpkt->group_id);
        printf("max: %ld\n", btrpkt->max);
        printf("min: %ld\n", btrpkt->min);
        printf("sum: %ld\n", btrpkt->sum);
        printf("average: %ld\n", btrpkt->average);
        printf("median: %ld\n", btrpkt->median);
      }
    }
    return msg;
  }

  event void RadioSend.sendDone[am_id_t id](message_t* msg, error_t error) {
  }
}

