#ifndef DATA_MOTE_H
#define DATA_MOTE_H
#define GROUP_ID 12
#define NODE0 34
#define NODE1 35
#define NODE2 36
#define NODE_SOURCE 1000
#define NODE_DESTINATION 1000

typedef nx_struct DATA_MSG {
  nx_uint16_t sequence_number;
  nx_uint32_t random_integer;
} DATA_MSG;

typedef nx_struct RESULT_MSG {
  nx_uint8_t group_id;
  nx_uint32_t max;
  nx_uint32_t min;
  nx_uint32_t sum;
  nx_uint32_t average;
  nx_uint32_t median;
} RESULT_MSG;

typedef nx_struct ACK_MSG {
  nx_uint8_t group_id;
} ACK_MSG;

#endif

