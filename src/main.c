#include "macros.h"
#include "registers.h"
#include "constants.h"
#include "dmajobs.h"
#include "program.h"

extern void irq_fastload();
extern void irq_main();
extern void program_mainloop();
extern void program_setuppalntsc();

extern uint8_t nextrasterirqlinelo;
extern uint8_t nextrasterirqlinehi;

void main()
{
	SEI

	VIC2.DEN = 0;
	poke(0xd020, 0x00);
	poke(0xd021, 0x00);

	// VIC4.PALNTSC = 1;											// 0 = PAL, 1 = NTSC

	CPU.PORT = 0b00110101;										// 0x35 = I/O area visible at $D000-$DFFF, RAM visible at $A000-$BFFF and $E000-$FFFF.
	VIC4.HOTREG = 0;											// disable hot registers
	UNMAP_ALL													// unmap any mappings
	CPU.PORTDDR = 65;											// enable 40Hz
	VIC3.KEY = 0x47;											// Enable the VIC4
	VIC3.KEY = 0x53;											// do I need an eom after this?
	EOM

	dma_init();

	CIA1.ICR = 0b01111111;										// disable interrupts
	CIA2.ICR = 0b01111111;
	CIA1.ICR;
	CIA2.ICR;
	poke(0xd01a,0x00);											// disable IRQ raster interrupts because C65 uses raster interrupts in the ROM
	VIC2.RC = 0x08;												// d012 = 0
	VIC2.RC8 = 0x00;											// d011
	IRQ_VECTORS.IRQ = (volatile uint16_t)&irq_fastload;			// set irq vector
	poke(0xd01a,0x01);											// ACK!

	CLI

	program_loaddata();

	SEI

	CPU.PORT			= 0b00110101;							// 0x35 = I/O area visible at $D000-$DFFF, RAM visible at $A000-$BFFF and $E000-$FFFF.
	
	VIC3.ROM8			= 0;									// map I/O (Mega65 memory mapping)
	VIC3.ROMA			= 0;
	VIC3.ROMC			= 0;
	VIC3.CROM9			= 0;
	VIC3.ROME			= 0;

	VIC4.FNRST			= 0;									// disable raster interrupts
	VIC4.FNRSTCMP		= 0;
	VIC4.CHR16			= 1;									// use wide character lookup (i.e. character data anywhere in memory)

	VIC4.TEXTXPOSLSB	= 80;									// set TEXTXPOS to same as SDBDRWDLSB
	VIC4.SDBDRWDLSB		= 80;
	
	VIC2.MCM			= 1;									// set multicolor mode
	VIC4.FCLRLO			= 1;									// lower block, i.e. 0-255		// use NCM and FCM for all characters
	VIC4.FCLRHI			= 1;									// everything above 255
	VIC4.NORRDEL		= 0;									// enable rrb double buffering
	VIC4.DBLRR			= 0;									// disable double-height rrb
	
	VIC3.H640			= 1;									// enable 640 horizontal width
	VIC3.V400			= 1;									// enable 400 vertical height
	VIC4.CHRYSCL		= 0;
	VIC4.CHRXSCL		= 0x78;

	VIC4.DISPROWS		= 47;									// display 47 rows of text (50 - extra for scrolling)

	VIC4.SCRNPTR		= (SCREEN & 0xffff);					// set screen pointer
	VIC4.SCRNPTRBNK		= (SCREEN & 0xf0000) >> 16;
	VIC4.SCRNPTRMB		= 0;

	VIC4.CHRCOUNTLSB	= RRBSCREENWIDTH;						// set RRB screenwidth and linestep
	VIC4.CHRCOUNTMSB	= RRBSCREENWIDTH >> 8;
	VIC4.LINESTEP		= RRBSCREENWIDTH2;

	VIC4.COLPTR			= COLOR_RAM_OFFSET;						// set offset to colour ram, so we can use continuous memory

	program_setuppalntsc();										// set up pal/ntsc values before calling program_init
	program_init();

	CIA1.ICR = 0b01111111;										// disable CIA timer interrupts
	CIA2.ICR = 0b01111111;
	CIA1.ICR;													// and clear any pending ones
	CIA2.ICR;

	while((peek(0xd011) & 0b10000000) == 0b10000000) ;			// wait until we're out of the lower border
	while((peek(0xd011) & 0b10000000) == 0b00000000) ;			// wait until we're out of the upper border
	while((peek(0xd011) & 0b10000000) == 0b10000000) ;			// wait until we're out of the lower border again
	while(peek(0xd012) != 250) ;

	poke(0xd01a,0x00);											// disable IRQ raster interrupts because C65 uses raster interrupts in the ROM

	// set up CIA TIMER IRQ for MOD playback
	CIA1.ICR = 0b10000001;										// enable CIA timer interrupts
	uint8_t realhw = ((peek(0xd60f) >> 5) & 0x01);
	if(realhw)
	{
		poke(0xdc04, 0xa7);			// set timer to $4ca7 cycles for PAL which should be 50Hz, which is good for MODs
		poke(0xdc05, 0x4c);			// $40b8 for NTSC
	}
	else
	{
		poke(0xdc04, 0x00);			// FFS! STUDID XEMU - set timer to $4e00 for xemu
		poke(0xdc05, 0x4e);
	}
	CIA1.CRA = 0b00010001;			// $dc0e Load start value into timer and start timer
	CIA1.ICR;

	VIC2.DEN = 1;

	VIC2.RC = 0xfc;												// d012 = fc
	poke(&nextrasterirqlinelo, 0xfc);
	VIC2.RC8 = 0x00;											// d011
	poke(&nextrasterirqlinehi, 0);
	IRQ_VECTORS.IRQ = (volatile uint16_t)&irq_main;
	poke(0x0314, (volatile uint16_t)&irq_main & 0xff);
	poke(0x0315, ((volatile uint16_t)&irq_main >> 8) & 0xff);

	poke(0xd01a,0x01);											// enable raster interrupts again

	CLI

	program_mainloop();
}
