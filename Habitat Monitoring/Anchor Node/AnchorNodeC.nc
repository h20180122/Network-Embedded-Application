
#include "NodeMessage.h" 
#include "Timer.h"
#include "Leds.h"
//#define NEW_PRINTF_SEMANTICS
#include "printf.h"

module AnchorNodeC {
  	uses {
  		interface SplitControl as RadioControl;
  		interface Boot;
  	    interface Leds;
	    interface AMPacket;
	    interface AMSend;
	    interface Receive;
	    interface Packet;
	    interface Timer<TMilli> as TimeOut;
	    interface Timer<TMilli> as Time10Sec;
	    interface Timer<TMilli> as Time10;
	    interface Timer<TMilli> as Timer0;
	}
}

implementation {
  message_t packet;
  void sendPacket();
  
  event void Boot.booted() {
	printf("[ANCHOR %d] Mote booted...\n", TOS_NODE_ID);
	call RadioControl.start();
	if(TOS_NODE_ID == 12) {
		call Time10Sec.startOneShot(WAIT_BEFORE_SYNC);
	}
  }
  
  event void RadioControl.startDone(error_t err){call Leds.led0On();
  call Timer0.startPeriodic(TIMER_CYCLIC);
  }
  
  event void RadioControl.stopDone(error_t err){
  	call Time10.stop();
  	call TimeOut.stop();	
  }
  
  event void TimeOut.fired() {
	call Time10.startOneShot(TIMESLOT*TOS_NODE_ID);
  }
  
  event void Time10.fired() {
  	sendPacket();
  }
  
  //************************Invia pacchetto al mobile node*********************************//
  void sendPacket() {
	nodeMessage_t* mess = (nodeMessage_t*) (call Packet.getPayload(&packet,sizeof(nodeMessage_t)));
	mess->msg_type = BEACON;
	mess->x = anchorCoord[TOS_NODE_ID-1].x;
	mess->y = anchorCoord[TOS_NODE_ID-1].y;
	 
	printf("[ANCHOR %d] Broadcasting beacon... \n", TOS_NODE_ID);
	call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(nodeMessage_t));
	
	call TimeOut.startOneShot(SEND_INTERVAL_ANCHOR);
	printf("[ANCHOR %d] Starting timer...\n", TOS_NODE_ID);

  }
 
 
 //************************Invia pacchetto di sync*********************************//
  void sendPacketSync() {
	nodeMessage_t* mess = (nodeMessage_t*) (call Packet.getPayload(&packet,sizeof(nodeMessage_t)));
	mess->msg_type = SYNCPACKET;
	
	printf("[ANCHOR %d] Broadcasting SYNC beacon... \n", TOS_NODE_ID);
	call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(nodeMessage_t));
  }
 
 
  //*********************AMSend interface****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
    if(&packet == buf && err == SUCCESS ) {}
  }

	event void Time10Sec.fired(){
			sendPacketSync();					
			//dopo avvio broadcast normale in TDMA per ancora 1
			printf(" Time10sec fired....\n");
			call Time10.startOneShot(TIMESLOT*TOS_NODE_ID);
			

	}
	
	event void Timer0.fired(){
			
			printf(" Timer0 fired....\n");
			call Leds.led2Toggle();
			

	}

	event message_t * Receive.receive(message_t* buf,void* payload, uint8_t len) {
		am_addr_t sourceNodeId = call AMPacket.source(buf);	
		nodeMessage_t* mess = (nodeMessage_t*) payload;
	
		if ( mess->msg_type == SYNCPACKET) {
			printf("[ANCHOR %d] SYNC Received from anchor %d...\n", TOS_NODE_ID, sourceNodeId);
			call Time10.startOneShot(TIMESLOT*TOS_NODE_ID);
		}
		/*else if( mess->msg_type == SWITCHOFF)  {
			printf("[ANCHOR %d] SWITCHOFF Received from anchor %d...\n", TOS_NODE_ID, sourceNodeId);
			printf("[ANCHOR %d] Radio switching off...\n", TOS_NODE_ID);
			call RadioControl.stop();
			call TimeOut.stop();
			call Time10.stop();
		}*/
		return buf;
	}
}
