#ifndef __FONTSYS_H
#define __FONTSYS_H

void fontsys_init();
void fontsys_map();
void fontsys_unmap();
void fontsys_clearscreen();

extern void fontsys_asm_init();
extern void fontsys_asm_setupscreenpos();
extern void fontsys_asm_render();
extern void fontsys_asm_renderspace();

extern void fontsys_convertfilesizetostring();

extern uint8_t fnts_bin;
extern uint8_t fnts_bcd;
extern uint8_t fnts_binstring;

extern uint8_t fnts_screentablo;
extern uint8_t fnts_screentabhi;
extern uint8_t fnts_attribtablo;
extern uint8_t fnts_attribtabhi;

extern uint8_t fnts_row;
extern uint8_t fnts_column;
extern uint8_t fnts_curpal;

extern uint8_t fnts_numlineptrs;
extern uint8_t fnts_lineptrlistlo;
extern uint8_t fnts_lineptrlisthi;
extern uint8_t fnts_lineurlstart;
extern uint8_t fnts_lineurlsize;

extern uint8_t fnts_bottomlineadd1;
extern uint8_t fnts_bottomlineadd2;

extern uint8_t fnts_spacewidth;

#endif