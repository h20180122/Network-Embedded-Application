
#ifndef NODEMESSAGE_H
#define NODEMESSAGE_H

typedef nx_struct NodeMessage {
	nx_uint8_t mode_type;
	nx_uint8_t msg_type;
	nx_float x;
	nx_float y;
} nodeMessage_t;

typedef struct coordinate {
  	float x;
  	float y;
} coord;



typedef nx_struct position{
	nx_uint8_t Xpos;
	nx_uint8_t Ypos;
	nx_uint8_t node_id;
	nx_uint8_t toprssi;
}position_t;
	
	

coord anchorCoord[32] = {
	{5,5},
	{10,5},
	{15,5},
	{20,5},
	{25,5},
	{30,5},
	{35,5},
	{40,5},
	
	
	{5,10},
	{10,10},
	{15,10},
	{20,10},
	{25,10},
	{30,10},
	{35,10},
	{40,10},
	
	{5,15},
	{10,15},
	{15,15},
	{20,15},
	{25,15},
	{30,15},
	{35,15},
	{40,15},
	
	
	{5,20},
	{10,20},
	{15,20},
	{20,20},
	{25,20},
	{30,20},
	{35,20},
	{40,20}
	
};


#define BEACON 1
#define SWITCHOFF 2
#define SYNCPACKET 3

#define MOVE_INTERVAL_MOBILE 1000
#define SEND_INTERVAL_ANCHOR 250
#define RECEIVE_INTERVAL_ANCHOR 180
#define AM_RSSIMSG 10

#endif
