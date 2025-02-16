#ifndef __PROGRAM_H
#define __PROGRAM_H

void program_loaddata();
void program_init();
void program_mainloop();
void program_update();

extern void program_reset();

extern void fadepal_init();
extern void fadepal_increase();

extern uint8_t textypos;
extern uint16_t verticalcenter;
extern uint16_t verticalcenterhalf;
extern uint8_t program_mainloopstate;

extern uint8_t prgfilename;
extern uint8_t mountname;
extern uint8_t wasautoboot;

#endif