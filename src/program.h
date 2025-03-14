#ifndef __PROGRAM_H
#define __PROGRAM_H

void program_loaddata();
void program_init();
void program_mainloop();
void program_update();

extern void program_reset();

extern void fadepal_init();
extern void fadepal_increase();

extern void program_renderqrbackground();

extern uint8_t id4bouncelo;
extern uint8_t id4bouncehi;

extern uint8_t textyposoffset;
extern uint8_t textypos;
extern uint16_t verticalcenter;
extern uint16_t verticalcenterhalf;
extern uint16_t palntscyoffset;
extern uint16_t palntscyoffsethalf;
extern uint8_t program_mainloopstate;
extern uint8_t program_nextmainloopstate;

extern uint8_t program_drawselectionline;
extern uint8_t program_bounceselectionline;
extern uint8_t program_selectionframe;

extern uint8_t mainlogoxposlo;
extern uint8_t mainlogoxposhi;
extern uint8_t maintextxposlo;
extern uint8_t maintextxposhi;
extern uint8_t headertextxposlo;
extern uint8_t headertextxposhi;
extern uint8_t footertextxposlo;
extern uint8_t footertextxposhi;

extern uint8_t romfilename;
extern uint8_t prgfilename;
extern uint8_t mountname;
extern uint8_t wasautoboot;
extern uint8_t wasgo64flag;
extern uint8_t wasntscflag;
extern uint8_t waspalflag;

extern uint8_t program_realhw;

#endif
