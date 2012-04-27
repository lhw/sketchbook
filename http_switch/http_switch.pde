// EtherShield webserver demo
#include <etherShield.h>
#include <RCSwitch.h>

#define WWWPORT 80
#define TXPORT 8
#define DEVICE_OFFSET 1
#define BUFFER_SIZE 200 // ATMEGA 168 smaller ~> no http return; bigger ~> no space for operations


#define DEVICE(a) (a+DEVICE_OFFSET)
#define FAIL PSTR("{\"result\":false}")
#define SUCCESS PSTR("{\"result\":true}")

static uint8_t mymac[6] = {
  0x54,0x55,0x58,0x10,0x00,0x24}; 
static uint8_t myip[4] = {
  192,168,1,11};
static uint8_t buf[BUFFER_SIZE+1];

EtherShield es=EtherShield();
RCSwitch swt = RCSwitch();

int c, d, s;
uint16_t es_len;
char *request;

uint16_t httpOK() {
  return es.ES_fill_tcp_data_p(buf, 0, PSTR("HTTP/1.0 200 OK\r\nContent-Type: application/json\r\nPragma: no-cache\r\n\r\n"));
}

void setup(){
  Serial.begin(9600);

  es.ES_enc28j60Init(mymac);
  es.ES_init_ip_arp_udp_tcp(mymac, myip, WWWPORT);

  swt.enableTransmit(TXPORT);
}

void loop() {
  // read packet, handle ping and wait for a tcp packet:
  es_len = es.ES_packetloop_icmp_tcp(buf, es.ES_enc28j60PacketReceive(BUFFER_SIZE, buf));

  /* no data? - nothing to do here */
  if(es_len == 0)
    return;

  request = (char *)&(buf[es_len]);

  if(strncmp("GET", request, 4) != 0) {
    c = d = s = -1;
    char *f = strchr(request, '?');
    do {
      if(*(f+1) == 'c') {
        sscanf(f+1, "c=%d", &c);
      } 
      else if(*(f+1) == 'd') {
        sscanf(f+1, "d=%d", &d);
      }
      else if(*(f+1) == 's') {
        if(strncmp(f+3, "on", 2) == 0)
          s = 1;
        else
          s = 0;
      }
    } 
    while((f = strchr(f+1, '&')) != NULL);

    if(c != -1 && d != -1 && s != -1) {
      if(s == 1)
        swt.switchOn(c, DEVICE(d));
      else
        swt.switchOff(c, DEVICE(d));

      es_len = httpOK();
      es_len = es.ES_fill_tcp_data_p(buf, es_len, SUCCESS);
      es.ES_www_server_reply(buf, es_len);
      return;
    }
  }
  
  es_len = httpOK();
  es_len = es.ES_fill_tcp_data_p(buf, es_len, FAIL);
  es.ES_www_server_reply(buf, es_len);
}











