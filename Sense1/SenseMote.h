#ifndef SENSEMOTE_H
#define SENSEMOTE_H
#define NODE0 0
#define NODE1 1
#define NODE2 2

enum {
  AM_RADIO_MSG = 6
};

typedef nx_struct RADIO_MSG {
  nx_uint16_t nodeid;
  nx_uint32_t counter;
  nx_uint16_t time_period;
  nx_uint16_t temperature;
  nx_uint16_t humidity;
  nx_uint16_t light;
  nx_uint32_t totel_time;
} RADIO_MSG;

typedef nx_struct ACK_MSG {
  nx_uint16_t nodeid;
  nx_uint32_t counter;
} ACK_MSG;

typedef nx_struct TIME_MSG {
  nx_uint16_t nodeid;
  nx_uint16_t time_period;
} TIME_MSG;

#endif
