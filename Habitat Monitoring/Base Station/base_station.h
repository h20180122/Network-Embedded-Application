#ifndef BASE_STATION_H
#define BASE_STATION_H
typedef nx_struct position
{
	nx_uint8_t Xpos;
	nx_uint8_t Ypos;
	nx_uint8_t node_id;
	nx_uint8_t top_rssi;
	
}position_t;
#endif /* BASE_STATION_H */
