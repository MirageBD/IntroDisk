#include <stdint.h>
#include "macros.h"
#include "registers.h"
#include "hyppo.h"
#include "constants.h"
#include "modplay.h"
#include "iffl.h"
#include "irqload.h"
#include "keyboard.h"
#include "sdc.h"
#include "dma.h"
#include "fontsys.h"
#include "dmajobs.h"
#include "program.h"

extern void irq_main();

/*
	FAT dir entry structure:

	Offset	Type		Description
	--------------------------------------------------------
	$00		asciiz		The long file name
	$40		byte		The length of long file name
	$41		ascii		The ”8.3” file name.
						The name part is padded with spaces to make it exactly 8 bytes. The 3 bytes of the extension follow. There is no . between the name and the extension. There is no NULL byte.
	$4e		dword		The cluster number where the file begins. For sub-directories, this is where the FAT dir entries start for that sub-directory.
	$52		dword		The length of file in bytes.
	$56		byte		The type and attribute bits.
	
						Attribute Bit		bit set
						0					Read only
						1					Hidden
						2					System
						3					Volume label
						4					Sub-directory
						5					Archive
						6					Undefined
						7					Undefined
*/

/*
	STORED FAT dir entry:

	$00		asciiz		The long file name
	$40		byte		The length of long file name
	$41		ascii		The ”8.3” file name.
						The name part is padded with spaces to make it exactly 8 bytes. The 3 bytes of the extension follow. There is no . between the name and the extension. There is no NULL byte.
	$4e		dword		The cluster number where the file begins. For sub-directories, this is where the FAT dir entries start for that sub-directory.
	$52		dword		The length of file in bytes.
	$56		byte		The type and attribute bits.

	$57		asciiz		converted file name (0x40 bytes)
	$97		10			10 bytes for filesize string
*/

uint32_t	program_rowoffset		= 0;
uint16_t	program_numtxtentries	= 50;
uint8_t		program_keydowncount	= 0;
uint8_t		program_keydowndelay	= 0;
int16_t		program_selectedrow		= 0;
uint8_t*	program_transbuf;

uint8_t		xemu_fudge = 8;

void program_loaddata()
{
	fl_init();
	fl_waiting();
	
	floppy_iffl_fast_load_init("INTRODATA");
	floppy_iffl_fast_load(); 										// chars
	floppy_iffl_fast_load();										// palette
	floppy_iffl_fast_load();										// menu.bin

	// chars are loaded to 0x08100000 in attic ram. copy it back to normal ram, location 0x10000
	dma_dmacopy(ATTICFONTCHARMEM, FONTCHARMEM, 0x8000);
}

void program_init()
{
	// TODO - bank in correct palette
	// TODO - create DMA job for this
	for(uint8_t i = 0; i < 255; i++)
	{
		poke(0xd100+i, ((uint8_t *)PALETTE)[0*256+i]);
		poke(0xd200+i, ((uint8_t *)PALETTE)[1*256+i]);
		poke(0xd300+i, ((uint8_t *)PALETTE)[2*256+i]);
	}
	// TODO - set correct palette

	VIC2.BORDERCOL = 0x0f;
	VIC2.SCREENCOL = 0x0f;

	modplay_init();
	fontsys_init();
	fontsys_clearscreen();

	VIC2.SCREENCOL = 0x00;
}

void program_drawstuff()
{
	fontsys_map();

	program_rowoffset = 0;
	
	int16_t startrow = 12 - program_selectedrow;
	if(startrow < 0)
	{
		program_rowoffset = -startrow;
		startrow = 0;
	}

	int16_t endrow = startrow + program_numtxtentries;
	if(endrow > 25)
		endrow = 25;

	uint8_t c = program_rowoffset + 10;
	for(uint16_t row = startrow; row < endrow; row++)
	{
		fnts_row = 2 * row;
		fnts_column = 0;

		poke(&fnts_tempbuf+0, c);
		poke(&fnts_tempbuf+1, 0);

		uint8_t color = 0x0f;
		poke(&fnts_curpal + 1, color);

		// read fnts_row and set up pointers to plot to
		fontsys_asm_setupscreenpos();
		// read fnts_column and start rendering from fnts_tempbuf
		fontsys_asm_render();

		c++;
	}

	fontsys_unmap();
}

void program_main_processkeyboard()
{
	if(xemu_fudge > 0)
	{
		xemu_fudge--;
		return;
	}

	if(keyboard_keypressed(KEYBOARD_CURSORDOWN) == 1)
	{
		program_keydowndelay--;
		if(program_keydowndelay == 0)
			program_keydowndelay = 1;

		if(program_keydowncount == 0)
			program_selectedrow++;

		if(program_selectedrow >= program_numtxtentries)
			program_selectedrow = program_numtxtentries - 1;

		program_keydowncount++;
		if(program_keydowncount > program_keydowndelay)
			program_keydowncount = 0;
	}
	else if(keyboard_keypressed(KEYBOARD_CURSORUP) == 1)
	{
		program_keydowndelay--;
		if(program_keydowndelay == 0)
			program_keydowndelay = 1;

		if(program_keydowncount == 0)
			program_selectedrow--;

		if(program_selectedrow < 0)
			program_selectedrow = 0;

		program_keydowncount++;
		if(program_keydowncount > program_keydowndelay)
			program_keydowncount = 0;
	}
	else if(keyboard_keyreleased(KEYBOARD_RETURN))
	{
	}
	else
	{
		program_keydowndelay = 32;
		program_keydowncount = 0;
	}
}

void program_update()
{
	program_drawstuff();
	program_main_processkeyboard();
}

void program_mainloop()
{
	while(1)
	{
		__asm
		(
			" lda 0xd020\n"
			" sta 0xd020\n"
			" lda 0xd020\n"
			" sta 0xd020\n"
			" lda 0xd020\n"
			" sta 0xd020\n"
			" lda 0xd020\n"
			" sta 0xd020\n"
		);
	}
}
