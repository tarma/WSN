/*
 * Copyright (c) 2006, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2006/12/12 18:22:49 $
 * @author: Jan Hauer
 * ========================================================================
 */

/**
 * 
 * Sensing demo application. See README.txt file in this directory for usage
 * instructions and have a look at tinyos-2.x/doc/html/tutorial/lesson5.html
 * for a general tutorial on sensing in TinyOS.
 *
 * @author Jan Hauer
 */

#include <Timer.h>
#include "SenseMote.h"
#define NODE1 288
#define NODE2 299

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
    interface AMSend;
    interface Receive;
  }
}
implementation
{
  bool busy = FALSE;  
  message_t package;
  RADIO_MSG* s_message;
  uint16_t count = -1;
  uint16_t Timer_Period = 1000;
  uint16_t out_time = 2000;
  uint16_t waiting_time = 0;
  bool ack_receive = TRUE;
  bool light_flag = FALSE;
  bool humidity_flag = FALSE;
  bool temperature_flag = FALSE;

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      s_message = (RADIO_MSG*)(call Packet.getPayload(&package, sizeof(RADIO_MSG)));
      s_message->total_time = 0;      
      call Timer.startPeriodic(Timer_Period);
    }
    else {
      call AMControl.start();
    }
  }
  event void AMControl.stopDone(error_t err) {
  }

  event void Timer.fired() 
  {
    s_message->total_time += Timer_Period;
    call ReadLight.read();
    call ReadTemperature.read();
    call ReadHumidity.read();
    
  }
  
  void send_message()
  {
    if(ack_receive){
       call Leds.led1Off();
       count++;              
       if(!busy){         
          if (s_message == NULL) {
	    return;
          }
          s_message->nodeid = TOS_NODE_ID;
          s_message->counter = count;
          s_message->time_period = Timer_Period;
          if (call AMSend.send(NODE1, &package, sizeof(RADIO_MSG)) == SUCCESS) {
              busy = TRUE;
              waiting_time = 0;
              ack_receive = FALSE;
              call Leds.led1On();
          }
       }     
    }
    else
    {
       call Leds.led2Off();
       if(waiting_time >= out_time)
       {
          if(!busy){         
            if (s_message == NULL) {
	       return;
             }
            if (call AMSend.send(NODE1, &package, sizeof(RADIO_MSG)) == SUCCESS) {
              busy = TRUE;
              waiting_time = 0;
              call Leds.led2On();
            }
          }
       }
       else
         waiting_time += Timer_Period;   
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
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
      call Leds.led0Off();
      if(ackpkt->nodeid == s_message->nodeid)
      {
         call Leds.led0On();
         if(ackpkt->counter == s_message->counter){
            ack_receive = TRUE;          
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
       temperature_flag = TRUE;
       if(light_flag && humidity_flag && temperature_flag)
       {
          light_flag = FALSE;
          humidity_flag = FALSE;
          temperature_flag = FALSE;
          send_message();
       }
       //call Leds.led0Toggle();
    }
    else
    {
       call Leds.led0Off();
    }
  }
  
  event void ReadHumidity.readDone(error_t result, uint16_t data) 
  {
    if (result == SUCCESS){
       s_message->humidity = data;
       humidity_flag = TRUE;
       if(light_flag && humidity_flag && temperature_flag)
       {
          light_flag = FALSE;
          humidity_flag = FALSE;
          temperature_flag = FALSE;
          send_message();
       }
       //call Leds.led0Toggle();
    }
    else
    {
       call Leds.led0Off();
    }
  }

  event void ReadLight.readDone(error_t result, uint16_t data) 
  {
    if (result == SUCCESS){
       s_message->light = data;
       light_flag = TRUE;
       //call Leds.led0Toggle();
       if(light_flag && humidity_flag && temperature_flag)
       {
          light_flag = FALSE;
          humidity_flag = FALSE;
          temperature_flag = FALSE;
          send_message();
       }
    }
    else
    {
       call Leds.led0Off();
    }
  }
}
