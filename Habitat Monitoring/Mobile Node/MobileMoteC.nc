#include "NodeMessage.h"
#include "Timer.h"
#include "Leds.h"
#include "printf.h"
#include "math.h"

module MobileMoteC {
 
	uses {
		interface SplitControl as RadioControl;
		interface Boot;
		interface Leds;
		interface AMPacket;
		interface AMSend;
		interface Packet;
		interface Receive;
		interface Timer<TMilli> as TimeOut250;
		interface Timer<TMilli> as TimeOut180;
		interface Random;
		interface CC2420Packet;	
	}
}

implementation
{
	
	typedef struct rssiArrayElement
	{
		int nodeId;
		int16_t rssiVal;
	} nodeValue;

	nodeValue RSSIArray[32];
	nodeValue RSSISaved[32];
	
	bool RadioBusy = FALSE;
	message_t pkt;
	
	
	nodeValue topNode[3];
	
	float distArray[3];
	
	float posX, posY;
	float X = 0,Y = 0;
	
	int ts=3;
	int ap,tsap,ra,rb;
	
	int time = 0;
	uint16_t Xpos,Ypos;
	
	message_t packet;
	void findTopNode();
	void initNodeArray(nodeValue *array);
	void initTopArray(nodeValue *array);
	void initDistArray();
	void printfFloat(float toBePrinted);
	float getGaussian();
	float rand_gauss();
 
	//***************** Boot interface ********************//
	event void Boot.booted() {
		printf("[MOBILE] Mote booted.\n");
		initNodeArray(RSSIArray);
		initNodeArray(RSSISaved);
		initNodeArray(topNode);
		initDistArray();
		
		call RadioControl.start();
	}
 
	//***************** RadioControl interfaces ********************//
	event void RadioControl.startDone(error_t err){call Leds.led2On();
	call Leds.led0On();
	call Leds.led1On();
	}
	event void RadioControl.stopDone(error_t err){}

	//********************* AMSend interface ****************//
	event void AMSend.sendDone(message_t* buf,error_t err) { RadioBusy = FALSE;}

	event void TimeOut250.fired()
	{
		call TimeOut250.startOneShot(SEND_INTERVAL_ANCHOR);
	}

	event void TimeOut180.fired()
        {
			int j=0;
			printf("TimeOut180 fired\n");
			for(j=0;j<32;j++)
			{
				RSSISaved[j] = RSSIArray[j];
		        }
		
		printf("[MOBILE] Node current position (");
		
	
		findTopNode();
		initNodeArray(RSSISaved);
		initTopArray(topNode);
		initDistArray();
	}

	//***************************** Receive interface *****************//
	
	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len)
	{
		am_addr_t sourceNodeId = call AMPacket.source(buf);	
		nodeMessage_t* mess = (nodeMessage_t*) payload;
		printf("[MOBILE] Message received from anchor %d... type %d\n", sourceNodeId, mess->msg_type);
	
		if ( mess->msg_type == BEACON ) {
			printf("[MOBILE] RSSI Before: %d from %d\n",RSSIArray[sourceNodeId-1].rssiVal,sourceNodeId);
			RSSIArray[sourceNodeId-1].rssiVal = call CC2420Packet.getRssi(buf);
			RSSIArray[sourceNodeId-1].nodeId = sourceNodeId;
			printf("[MOBILE] RSSI Calculated: %d from %d\n",RSSIArray[sourceNodeId-1].rssiVal,sourceNodeId);
			
			//se gia non sto ricevendo, attivo il timer180
			if(!(call TimeOut180.isRunning())) {
				call TimeOut180.startOneShot(RECEIVE_INTERVAL_ANCHOR);
			}		
		} 
		else if(mess->msg_type == SYNCPACKET) {
			call TimeOut250.startOneShot(SEND_INTERVAL_ANCHOR);
		}
		return buf;
	}
 
	void initNodeArray(nodeValue *array) {
		int i;
		for(i=0;i<32;i++) {
			array[i].nodeId = -999;
			array[i].rssiVal = -999;
		}
	}
	
	void initTopArray(nodeValue *array) {
		int i;
		for(i=0;i<3;i++) {
			array[i].nodeId = -999;
			array[i].rssiVal = -999;
		}
	}

 
	void initDistArray() {
		int i;
		for(i=0;i<3;i++) {
			distArray[i] = -999;
		}
	}
	
	void findTopNode(){
		int j;
		for(j=0;j<32;j++) {
			printf("[MOBILE] Node = %d, RSSI = %d\n", RSSISaved[j].nodeId, RSSISaved[j].rssiVal);
		}
	
		for(j=0; j<32; ++j) {
			if(RSSISaved[j].rssiVal>topNode[0].rssiVal) {
				topNode[0] = RSSISaved[j];
			}
		}
		RSSISaved[topNode[0].nodeId-1].rssiVal = -999;
		for(j=0; j<32; ++j) {
			if(RSSISaved[j].rssiVal>topNode[1].rssiVal ) {
				topNode[1] = RSSISaved[j];
			}
		}
		RSSISaved[topNode[1].nodeId-1].rssiVal = -999;
		for(j=0; j<32 ; ++j) {
			if(RSSISaved[j].rssiVal>topNode[2].rssiVal) {
				topNode[2] = RSSISaved[j];
			}
		}
	
		printf("[MOBILE] First nodeID = %d with RSSI = %d\n",topNode[0].nodeId,topNode[0].rssiVal);
		printf("[MOBILE] Second nodeID = %d with RSSI = %d\n",topNode[1].nodeId,topNode[1].rssiVal);
		printf("[MOBILE] Third nodeID = %d with RSSI = %d\n",topNode[2].nodeId,topNode[2].rssiVal);
		
		
		ra = topNode[0].rssiVal-topNode[1].rssiVal;
		rb = topNode[0].rssiVal-topNode[2].rssiVal;
		
		if(ra==0)
		ap = 2.5;
		if(ra > 0 && ra < 5)
		ap=2;
		if(ra >= 5 && ra < 10)
		ap=1.5;
		if(ra >= 10 && ra < 15)
		ap=1;
		if(ra >= 15 && ra < 20)
		ap=0.75;
		if(ra >= 20 && ra < 25)
		ap=0.5;
		if(ra >= 25)
		ap=0.25;
		
		if(rb==0)
		tsap = 3;
		if(rb > 0 && rb < 5)
		tsap=2;
		if(rb >= 5 && rb < 10)
		tsap=1.5;
		if(rb >= 10 && rb < 15)
		tsap=1;
		if(rb >= 15 && rb < 20)
		tsap=0.75;
		if(rb >= 20 && rb < 25)
		tsap=0.5;
		if(rb >= 25)
		tsap=0.25;
		
		
		
		
		Xpos=ts*anchorCoord[topNode[0].nodeId-1].x+ap*anchorCoord[topNode[1].nodeId-1].x+tsap*anchorCoord[topNode[2].nodeId-1].x;
		Xpos=Xpos/(ts+ap+tsap);
		Ypos=ts*anchorCoord[topNode[0].nodeId-1].y+ap*anchorCoord[topNode[1].nodeId-1].y+tsap*anchorCoord[topNode[2].nodeId-1].y;
		Ypos=Ypos/(ts+ap+tsap);
		printf("X position %d\t",Xpos);
		printf("Y position %d\n",Ypos);	

		if (RadioBusy==FALSE)
			
				{
					position_t* pos=call Packet.getPayload(&pkt, sizeof(position_t));
					pos->Xpos=Xpos;
					pos->Ypos=Ypos;
					pos->node_id=TOS_NODE_ID;
					
					if(topNode[0].nodeId==1||topNode[0].nodeId== 2 ||topNode[0].nodeId== 3 || topNode[0].nodeId==4 ||topNode[0].nodeId== 9 ||topNode[0].nodeId== 10 ||topNode[0].nodeId== 11 ||topNode[0].nodeId== 12)
					pos->toprssi = 1;
				
					
					if(topNode[0].nodeId==5 || topNode[0].nodeId==6 ||topNode[0].nodeId== 7 || topNode[0].nodeId==8 ||topNode[0].nodeId== 13 || topNode[0].nodeId==14 || topNode[0].nodeId==15 || topNode[0].nodeId==16)
					pos->toprssi = 2;
					
					if(topNode[0].nodeId==17 || topNode[0].nodeId==18 || topNode[0].nodeId==19 ||topNode[0].nodeId== 20 ||topNode[0].nodeId== 25 ||topNode[0].nodeId== 26 ||topNode[0].nodeId== 27 ||topNode[0].nodeId== 28)
					pos->toprssi = 3;
					
					if(topNode[0].nodeId==21 ||topNode[0].nodeId== 22 ||topNode[0].nodeId== 23 ||topNode[0].nodeId== 24 ||topNode[0].nodeId== 29 ||topNode[0].nodeId== 30 ||topNode[0].nodeId== 31 ||topNode[0].nodeId== 32)
					pos->toprssi = 4;
					
					if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(position_t))==SUCCESS)
					{
						printf("Message broadcasted to cluster head \n");
						printf("toprssi is %d\n",pos->toprssi);
						
						RadioBusy=TRUE;
					}
				}	
	}
}
