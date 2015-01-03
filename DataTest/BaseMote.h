
#ifndef BASEMOTE_H
#define BASEMOTE_H
#define NODE0 1000
#define NODE1 34

enum {
  AM_RADIO_MSG = 6
};

typedef nx_struct DATA_MSG {
  nx_uint16_t sequence_number;
  nx_uint32_t random_integer;
} DATA_MSG;

typedef nx_struct RESULT_MSG{
  nx_uint8_t group_id;
  nx_uint32_t max;
  nx_uint32_t min;
  nx_uint32_t sum;
  nx_uint32_t average;
  nx_uint32_t median;
}RESULT_MSG;

typedef nx_struct ACK_MSG {
  nx_uint8_t group_id;
} ACK_MSG;

#endif
