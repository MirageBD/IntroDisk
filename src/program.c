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

uint32_t			program_rowoffset			= 0;
uint16_t			program_numtxtentries		= 0;
uint8_t				program_keydowncount		= 0;
uint8_t				program_keydowndelay		= 0;
int16_t				program_selectedrow			= 0;

uint8_t				xemu_fudge = 8;

uint32_t			menubinaddr = 0x20000;
uint16_t			program_menubin_struct_offset;
uint8_t				program_numcategories;
uint8_t				program_numbasecategories;
uint8_t				program_numentries;

__far uint8_t*		program_menubin_struct;
__far category*		program_categories;
__far catentry*		program_entries;
__far catentry*		program_current_entry;

uint8_t				current_cat_idx = 0xff;
uint8_t				current_ent_idx = 0xff;

uint8_t				program_category_indices[256];
uint8_t				program_category_selectedrows[256];

uint8_t				header[54] = {	'm', 'e', 'g', 'a', 0x7c, ' ', '6', '5', ' ',
									0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d,
									0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d,
									0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d,
									0x7d, 0x7d, 0x7d,
									' ', 'i', 'N', 'T', 'R', 'O', ' ', 'd', 'I', 'S', 'K', ' ', '#', '4',
									0 };

uint8_t				footer[64] = {	0x6d, 0x65, 0x67, 0x61, 0x7c, 0x20, 0x36, 0x35, 0x20,
									0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d,
									0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d, 0x7d,
									0x7d, 0x7d, 0x7d, 0x7d, 0x7d,
									' ', 'u', 'S', 'E', ' ', 'C', 'U', 'R', 'S', 'O', 'R',
									' ', 'K', 'E', 'Y', 'S', ',', ' ', 'r', 'e', 't', 'u', 'r', 'n',
									' ', 'A', 'N', 'D', ' ', 0x5f,
									0 };

void program_loaddata()
{
	fl_init();
	fl_waiting();
	
	floppy_iffl_fast_load_init("INTRODATA");
	floppy_iffl_fast_load(); 										// chars
	floppy_iffl_fast_load();										// palette
	floppy_iffl_fast_load();										// QR chars
	floppy_iffl_fast_load();										// menu.bin
	floppy_iffl_fast_load();										// song.mod

	// chars and QR chars are loaded to 0x08100000 in attic ram. copy it back to normal ram, location 0x10000
	// dma_dmacopy(ATTICFONTCHARMEM, FONTCHARMEM, 0x8000);
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

	modplay_initmod(SONGADDRESS);

	modplay_enable();

	program_menubin_struct_offset = lpeek(menubinaddr+0) + (lpeek(menubinaddr+1) << 8);

	program_menubin_struct = (__far uint8_t*)(menubinaddr + program_menubin_struct_offset);
	program_numcategories = lpeek(program_menubin_struct);
	program_categories = program_menubin_struct+1;

	program_numbasecategories = 0;
	for(uint8_t index = 0; index < program_numcategories; index++)
	{
		if(program_categories[index].parent_cat_idx == 0xff)
		{
			program_category_indices[program_numbasecategories] = index;
			program_numbasecategories++;
		}
	}

	program_numtxtentries = program_numcategories;

	VIC2.SCREENCOL = 0x00;
}

void program_draw_entry(uint16_t entry, uint8_t color, uint8_t row, uint8_t column)
{
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

void program_draw_header()
{
	fnts_row = 0;
	fnts_column = 0;

	poke(&fnts_curpal + 1, 0x0f);

	uint32_t headerptr = &header;

	poke(0x5c, (headerptr >>  0) & 0xff);
	poke(0x5d, (headerptr >>  8) & 0xff);
	poke(0x5e, (headerptr >> 16) & 0xff);
	poke(0x5f, (headerptr >> 24) & 0xff);

	fontsys_asm_setupscreenpos();
	fontsys_asm_render();
}

void program_draw_footer()
{
	fnts_row = 48;
	fnts_column = 0;

	poke(&fnts_curpal + 1, 0x0f);

	uint32_t footerptr = &footer;

	poke(0x5c, (footerptr >>  0) & 0xff);
	poke(0x5d, (footerptr >>  8) & 0xff);
	poke(0x5e, (footerptr >> 16) & 0xff);
	poke(0x5f, (footerptr >> 24) & 0xff);

	fontsys_asm_setupscreenpos();
	fontsys_asm_render();
}

void program_drawentry()
{
	fontsys_map();

	program_draw_header();

	if(program_current_entry->full != 0)
		program_draw_entry(program_current_entry->full,   0x2f, 4, 0);
	else if(program_current_entry->title != 0)
		program_draw_entry(program_current_entry->title,   0x2f, 4, 0);

	if(program_current_entry->author != 0)
		program_draw_entry(program_current_entry->author, 0x3f, 6, 0);

	if(program_current_entry->mount != 0)
		program_draw_entry(program_current_entry->mount,  0x4f, 8, 0);

	if(program_current_entry->desc != 0)
		program_draw_entry(program_current_entry->desc,   0x0f, 12, 0);

	program_draw_footer();

	fontsys_unmap();
}

void program_drawlist()
{
	fontsys_map();

	program_draw_header();

	program_rowoffset = 0;
	
	int16_t startrow = 12 - program_selectedrow;
	if(startrow < 2)
	{
		program_rowoffset = -startrow+2;
		startrow = 2;
	}

	int16_t endrow = startrow + program_numtxtentries;

	if(program_numtxtentries - program_selectedrow < 13)
		endrow = 12 + (program_numtxtentries - program_selectedrow);

	if(endrow > 23)
		endrow = 23;

	uint8_t index = program_rowoffset;
	uint8_t skipped = 0;
	for(uint16_t row = startrow; row < endrow; row++)
	{
		if(current_cat_idx == 0xff)
		{
			if(program_categories[index].parent_cat_idx == 0xff)
				program_draw_entry(program_categories[index].name, 0x0f, 2 * (row-skipped), 0);
			else
				skipped++;
		}
		else
		{
			uint8_t color = 0x0f;
			if(program_entries[index].dir_flag != 0xff)
				color = 0x1f;

			if(program_entries[index].full != 0)
				program_draw_entry(program_entries[index].full, color, 2 * row, 0);
			else if(program_entries[index].title != 0)
				program_draw_entry(program_entries[index].title, color, 2 * row, 0);
		}

		index++;
	}

	program_draw_footer();

	fontsys_unmap();
}

void program_setcategory(uint8_t index)
{
	program_category_selectedrows[current_cat_idx+1] = program_selectedrow;

	program_selectedrow = program_category_selectedrows[index+1];

	current_cat_idx = index;
	uint16_t cat_entry_offset = program_categories[current_cat_idx].cat_entry_offset;
	program_entries = menubinaddr + program_menubin_struct_offset + cat_entry_offset + 1;
	program_numentries = lpeek(program_menubin_struct + cat_entry_offset);

	current_ent_idx = 0xff;

	if(current_cat_idx == 0xff)
		program_numtxtentries = program_numcategories;
	else
		program_numtxtentries = program_numentries;
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
		if(current_cat_idx == 0xff)
		{
			program_setcategory(program_category_indices[program_selectedrow]);
		}
		else
		{
			uint8_t dirflag = program_entries[program_selectedrow].dir_flag;
			if(dirflag == 0xff)
			{
				current_ent_idx = program_selectedrow;
				program_current_entry = &(program_entries[current_ent_idx]);
			}
			else
			{
				program_setcategory(dirflag);
			}
		}
	}
	else if(keyboard_keyreleased(KEYBOARD_ESC))
	{
		if(current_ent_idx != 0xff)
		{
			program_selectedrow = current_ent_idx;
			current_ent_idx = 0xff;
		}
		else if(current_cat_idx != 0xff)
		{
			program_setcategory(program_categories[current_cat_idx].parent_cat_idx);
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
	if(current_ent_idx != 0xff)
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
