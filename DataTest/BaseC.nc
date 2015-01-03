#include <Timer.h>
#include "BaseMote.h"
#include "printf.h"

module BaseC
{
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli>;

    interface SplitControl as AMControl;
    interface Packet;
    interface AMPacket;
    interface AMSend;
    interface Receive;
  }
}
implementation
{
  DATA_MSG* data;
  ACK_MSG* ack;
  RESULT_MSG result;
  RESULT_MSG* ackpkt;
  message_t package;
  uint16_t count = 1;
  uint16_t max = 2000;
  uint16_t random_integer = 100;
  bool busy = FALSE;
  bool a_busy = FALSE;
  uint16_t Timer_Period = 10;
  uint8_t  id = 34;
   
  event void Boot.booted() {
    result.max = 200000;
    result.min = 100;
    result.sum = 200100000;
    result.average = 100050;
    result.median = 100050;
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err){
    
    if (err == SUCCESS) {            
      call Timer.startPeriodic(Timer_Period);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }
  
  event void Timer.fired(){
    data = (DATA_MSG*)(call Packet.getPayload(&package, sizeof(DATA_MSG)));
    if(!busy){
       if(data == NULL){
          return;
       }
       call Leds.led0Toggle();
       data->sequence_number = count;
       data->random_integer = random_integer;
       if(call AMSend.send(AM_BROADCAST_ADDR, &package, sizeof(DATA_MSG)) == SUCCESS) {
          busy = TRUE;
       }
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&package == msg) {
      if(count >= max){
        count = 0;
        random_integer = 0;
        printf("%ld %ld %ld\n",result.min,result.max,result.sum);
      printf("%u %u\n",data->sequence_number,random_integer);
      }
      printf("%u\n",data->sequence_number);
      count ++;
      random_integer += ;
      busy = FALSE;
    }
  }  

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    call Leds.led0Toggle();    
    atomic{     
      if (len == sizeof(RESULT_MSG)) {     
         ackpkt = (RESULT_MSG*)payload; 
         if(ackpkt->group_id == id)
         {
            if(result.max == ackpkt -> max && result.min == ackpkt -> min && result.sum == ackpkt -> sum && result.average == ackpkt -> average && result.median == ackpkt -> median){
              ack = (ACK_MSG*)(call Packet.getPayload(&package, sizeof(ACK_MSG)));
              ack -> group_id = ackpkt ->group_id;
              if(call AMSend.send(AM_BROADCAST_ADDR, &package, sizeof(ACK_MSG)) == SUCCESS) {
                 busy = TRUE;
              }    
            }
            call Leds.led2On();   
         }      
      }
    }
    return msg;
  }
}
