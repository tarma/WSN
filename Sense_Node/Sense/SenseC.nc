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
  uint16_t count;
  uint16_t Timer_Period = 1000;

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      s_message = (RADIO_MSG*)(call Packet.getPayload(&package, sizeof(RADIO_MSG)));
      s_message->totel_time = 0;
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
    count++;
    s_message->totel_time += Timer_Period;
    call ReadLight.read();
    call ReadTemperature.read();
    call ReadHumidity.read();
    if(!busy){         
      if (s_message == NULL) {
	return;
      }
      s_message->nodeid = NODE1;
      s_message->counter = count;
      s_message->time_period = Timer_Period;
      if (call AMSend.send(AM_BROADCAST_ADDR, &package, sizeof(RADIO_MSG)) == SUCCESS) {
          busy = TRUE;
      }
    }
  }
   
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(TIME_MSG)) {
      TIME_MSG* btrpkt = (TIME_MSG*)payload;
      if(btrpkt->nodeid == s_message->nodeid)
          Timer_Period = btrpkt -> time_period;      
    }

    if (len == sizeof(RADIO_MSG)){
      RADIO_MSG* btrpkt = (RADIO_MSG*)payload;
      if(btrpkt -> nodeid == NODE2)
      {
         btrpkt -> nodeid = NODE1;
         if (call AMSend.send(AM_BROADCAST_ADDR, &package, sizeof(RADIO_MSG)) == SUCCESS){
          busy = TRUE;
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
       call Leds.led1Toggle();
    }
  }
  
  event void ReadHumidity.readDone(error_t result, uint16_t data) 
  {
    if (result == SUCCESS){
       s_message->humidity = data;
       call Leds.led2Toggle();
    }
  }

  event void ReadLight.readDone(error_t result, uint16_t data) 
  {
    if (result == SUCCESS){
       s_message->light = data;
       call Leds.led0Toggle();
    }
  }
}
