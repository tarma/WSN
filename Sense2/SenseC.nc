#include <Timer.h>
#include "SenseMote.h"
#include "printf.h"

module SenseC
{
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli>;
    interface Read<uint16_t> as ReadLight;
    interface Read<uint16_t> as ReadTemperature;
    interface Read<uint16_t> as ReadHumidity;

    interface SplitControl as AMControl;
    interface Packet;
    interface AMPacket;
    interface AMSend;
    interface Receive;
  }
}
implementation
{
  bool busy = FALSE;  
  message_t package;
  RADIO_MSG* s_message;
  uint16_t count = 0;
  uint16_t Timer_Period = 1000;
  uint16_t out_time = 2000;
  uint32_t waiting_time = 0,time = 0;
  bool ack_receive = TRUE;
  bool light_flag = FALSE;
  bool humidity_flag = FALSE;
  bool temperature_flag = FALSE;

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {            
      call Timer.startPeriodic(Timer_Period);
    }
    else {
      call AMControl.start();
    }
  }
  event void AMControl.stopDone(error_t err) {
  }

  task void send_message()
  {
    uint8_t len;
    am_addr_t addr;
    if(ack_receive){
       call Leds.led1Toggle();
       count++;              
       if(!busy){         
          if (s_message == NULL) {
	    return;
          }       
          len = call Packet.payloadLength(&package);
          addr = call AMPacket.destination(&package);     
          if (call AMSend.send(addr, &package, len) == SUCCESS) {
              busy = TRUE;
              waiting_time = 0;
              ack_receive = FALSE;
          }
       }     
    }
    else
    {       
       if(waiting_time >= out_time)
       {
          if(!busy){         
            if (s_message == NULL) {
	       return;
             }
            call Leds.led2Toggle();
            len = call Packet.payloadLength(&package);
            addr = call AMPacket.destination(&package); 
  printf("%u %u\n",len,addr);
            if (call AMSend.send(addr, &package, len) == SUCCESS) {
              busy = TRUE;
              waiting_time = 0;
            }
          }
       }
       else
         waiting_time += Timer_Period;   
    }
  }
  
  task void read_data()
  {
    call ReadLight.read();
    call ReadTemperature.read();
    call ReadHumidity.read();
  }

  event void Timer.fired() 
  {
    call Packet.setPayloadLength(&package, sizeof(RADIO_MSG));
    call AMPacket.setSource(&package, NODE2);
    call AMPacket.setDestination(&package, NODE1);
    s_message = (RADIO_MSG*)(call Packet.getPayload(&package, sizeof(RADIO_MSG)));
    time += Timer_Period;
    s_message->total_time = time;    
    s_message->nodeid = TOS_NODE_ID;     
    s_message->counter = count;
    s_message->time_period = Timer_Period;       
    post read_data();
    printf("%u %u %u %u\n",s_message->nodeid,s_message->counter,s_message->temperature,sizeof(RADIO_MSG));
    post send_message();
  }  
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    call Leds.led0Toggle();
    
    atomic{ 
      if (len == sizeof(TIME_MSG)) {
	  TIME_MSG* btrpkt = (TIME_MSG*)payload;
	  if(btrpkt->nodeid == s_message->nodeid)
	  {
             Timer_Period = btrpkt -> time_period;     
	     call Timer.stop();
             call Timer.startPeriodic(Timer_Period);
	  }    
      }  
    
      if (len == sizeof(ACK_MSG)) {     
         ACK_MSG* ackpkt = (ACK_MSG*)payload;  
         call Leds.led0Toggle();    
         if(ackpkt->nodeid == TOS_NODE_ID)
         {
            call Leds.led0Toggle();
            if(ackpkt->counter == count){
               ack_receive = TRUE;          
            }        
         }      
      }
    }
    return msg;
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&package == msg) {
      busy = FALSE;
    }
  }

  event void ReadTemperature.readDone(error_t result, uint16_t data) 
  {
    if (result == SUCCESS){
       s_message->temperature = data;
    }
  }
  
  event void ReadHumidity.readDone(error_t result, uint16_t data) 
  {
    if (result == SUCCESS){
       s_message->humidity = data;
    }
  }

  event void ReadLight.readDone(error_t result, uint16_t data) 
  {
    if (result == SUCCESS){
       s_message->light = data;
    }
  }
}
