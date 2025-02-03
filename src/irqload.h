#ifndef _IRQLOAD_H
#define _IRQLOAD_H

extern void fl_init();
extern void fl_exit();
extern void fl_set_filename(char *filename);
extern void fl_waiting();

extern void fl_get_endofbasic();

extern uint8_t fl_mode;

//__attribute__((interrupt(0xfffe))) extern void fastload_irq_handler();

#endif