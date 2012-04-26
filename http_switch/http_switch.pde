// EtherShield webserver demo
#include <etherShield.h>
#include <RCSwitch.h>

#define WWWPORT 80
#define BUFFER_SIZE 550

static uint8_t mymac[6] = {
  0x54,0x55,0x58,0x10,0x00,0x24}; 
static uint8_t myip[4] = {
  192,168,1,100};
static uint8_t buf[BUFFER_SIZE+1];

EtherShield es=EtherShield();
RCSwitch ok = RCSwitch();

uint16_t httpOK() {
  return es.ES_fill_tcp_data_p(buf, 0, PSTR("HTTP/1.0 200 OK\r\nContent-Type: text/html\r\nPragma: no-cache\r\n\r\n"));
}

void setup(){
  Serial.begin(9600);

  es.ES_enc28j60Init(mymac);
  es.ES_init_ip_arp_udp_tcp(mymac, myip, WWWPORT);

  mySwitch.enableTransmit(11);
}

void loop() {
  uint16_t len;
  byte c, d, s;
  char *request;

  while(1) {
    // read packet, handle ping and wait for a tcp packet:
    len = es.ES_packetloop_icmp_tcp(buf, es.ES_enc28j60PacketReceive(BUFFER_SIZE, buf));

    /* no data? - nothing to do here */
    if(len == 0)
      continue;

    request = (char *)&(buf[len]);
    Serial.println(request);

    if(strncmp("GET", request, 3) != 0) {
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

      len = httpOK();
      if(c != -1 && d != -1 && s != -1) {
        if(s == 1)
          ok.switchOn(c, d + 1);
        else
          ok.switchOff(c, d + 1);
        len = es.ES_fill_tcp_data_p(buf, len, PSTR("{\"result\":true}"));
      }
      else
        len = es.ES_fill_tcp_data_p(buf, len, PSTR("{\"result\":false}"));

    }
    es.ES_www_server_reply(buf, len);
  }
}



