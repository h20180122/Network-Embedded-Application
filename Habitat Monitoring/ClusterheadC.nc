// $Id: BaseStationP.nc,v 1.12 2010-06-29 22:07:14 scipio Exp $


#include "AM.h"

#include "clusterhead.h"
#define NEW_PRINTF_SEMANTICS
#include "printf.h"

module ClusterheadC @safe() {
  uses {
    
    interface Boot;
    interface Timer<TMilli> as Timer0;

    interface Leds;
  }
}

implementation
{
 

  
  uint16_t node;

uint8_t Ynew, Xnew;
uint8_t Toprssi_node;
message_t pkt;
am_id_t id;

bool RadioBusy = FALSE;
 


  
  event void Boot.booted() {
  
   
    call Timer0.startPeriodic(TIMER_CYCLIC);
  }

event void Timer0.fired(){
			
     printf(" Timer0 fired....\n");
     call Leds.led2Toggle();
			

	}
}  
