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

typedef struct _category
{
	uint16_t cat_entry_offset;
	uint16_t name;
	uint8_t  parent_cat_idx;
} category;

typedef struct _catentry
{
	uint16_t title;
	uint16_t full;
	uint16_t desc;
	uint16_t author;
	uint16_t mount;
	uint8_t  dir_flag;
} catentry;

uint32_t			program_rowoffset		= 0;
uint16_t			program_numtxtentries	= 50;
uint8_t				program_keydowncount	= 0;
uint8_t				program_keydowndelay	= 0;
int16_t				program_selectedrow		= 0;
uint8_t*			program_transbuf;

uint8_t				xemu_fudge = 8;

uint32_t			menubinaddr = 0x20000;
uint16_t			program_menubin_struct_offset;
uint8_t				program_numcategories;
uint8_t				program_numentries;

__far uint8_t*		program_menubin_struct;
__far category*		program_categories;
__far catentry*		program_entries;
__far catentry*		program_current_entry;
__far uint8_t*		program_txt;
__far uint8_t*		program_categoryname;
__far uint8_t*		program_entryfull;

uint8_t				program_rendermode = 0;	// 0 = categories, 1 = entries, 2 = full entry

void program_loaddata()
{
	fl_init();
	fl_waiting();
	
	floppy_iffl_fast_load_init("INTRODATA");
	floppy_iffl_fast_load(); 										// chars
	floppy_iffl_fast_load();										// palette
	floppy_iffl_fast_load();										// menu.bin
	floppy_iffl_fast_load();										// song.mod

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

	modplay_initmod(ATTICADDRESS, SAMPLEADRESS);

	modplay_enable();

	program_menubin_struct_offset = lpeek(menubinaddr+0) + (lpeek(menubinaddr+1) << 8);

	program_txt = (__far uint8_t*)(menubinaddr+2);
	program_menubin_struct = (__far uint8_t*)(menubinaddr + program_menubin_struct_offset);
	program_numcategories = lpeek(program_menubin_struct);
	program_numtxtentries = program_numcategories;
	program_categories = program_menubin_struct+1;

	VIC2.SCREENCOL = 0x00;
}

void program_draw_entry(uint16_t entry, uint8_t color, uint8_t row, uint8_t column)
{
	if(entry == 0)
		return;

	fnts_row = row;
	fnts_column = column;

	poke(&fnts_curpal + 1, color);

	poke(0x5c, entry & 0xff);
	poke(0x5d, (entry >> 8) & 0xff);
	poke(0x5e, 0x02);
	poke(0x5f, 0x00);

	// read fnts_row and set up pointers to plot to
	fontsys_asm_setupscreenpos();
	// read fnts_column and start rendering
	fontsys_asm_render();
}

void program_drawentry()
{
	fontsys_map();

	program_draw_entry(program_current_entry->full, 0x0f, 0, 0);
	program_draw_entry(program_current_entry->author, 0x0f, 2, 0);
	program_draw_entry(program_current_entry->mount, 0x0f, 4, 0);

	program_draw_entry(program_current_entry->desc, 0x0f, 8, 0);

	fontsys_unmap();
}

void program_drawlist()
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

	if(program_numtxtentries - program_selectedrow < 13)
	{
		endrow = 12 + (program_numtxtentries - program_selectedrow);
	}
	
	uint8_t index = program_rowoffset;
	for(uint16_t row = startrow; row < endrow; row++)
	{
		if(program_rendermode == 0)
			program_draw_entry(program_categories[index].name, 0x0f, 2 * row, 0);
		else if(program_rendermode == 1)
			program_draw_entry(program_entries[index].full, 0x0f, 2 * row, 0);
		index++;
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
		if(program_rendermode < 2)
		{
			program_rendermode++;

			if(program_rendermode == 1)
			{
				uint16_t cat_entry_offset = program_categories[program_selectedrow].cat_entry_offset;
				program_entries = menubinaddr + program_menubin_struct_offset + cat_entry_offset + 1;
				program_numentries = lpeek(program_menubin_struct + cat_entry_offset);

				program_numtxtentries = program_numentries;
				program_selectedrow = 0;
			}
			else if(program_rendermode == 2)
			{
				program_current_entry = &(program_entries[program_selectedrow]);
				program_numtxtentries = 1;
				program_selectedrow = 0;
			}
		}
	}
	else if(keyboard_keyreleased(KEYBOARD_ESC))
	{
		if(program_rendermode > 0)
		{
			program_rendermode--;
			program_selectedrow = 0;

			if(program_rendermode == 0)
				program_numtxtentries = program_numcategories;
			if(program_rendermode == 1)
				program_numtxtentries = program_numentries;
		}
	}
	else
	{
		program_keydowndelay = 32;
		program_keydowncount = 0;
	}
}

void program_update()
{
	if(program_rendermode == 2)
		program_drawentry();
	else
		program_drawlist();

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
