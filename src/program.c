#include <stdint.h>
#include "macros.h"
#include "registers.h"
#include "hyppo.h"
#include "constants.h"
#include "modplay.h"
#include "iffl.h"
#include "irqload.h"
#include "keyboard.h"
#include "dma.h"
#include "fontsys.h"
#include "dmajobs.h"
#include "program.h"

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

uint8_t				c_textypos = 0x78;
int8_t				movedir = 0;

uint8_t				program_category_indices[256];
uint8_t				program_category_selectedrows[257]; // 257 because program_setcategory uses current_cat_idx+1 and current_cat_idx can be 0xff -> 0x0100

uint8_t sprwidth  = 64;
uint8_t sprheight = 48;
uint16_t sprptrs  = 0x0400;
uint16_t sprdata  = 0x0440;

uint8_t *autobootstring = "AUTOBOOT.C65";

uint8_t QRBitmask[8] =
{
	0b00000000,
	0b10000000,
	0b11000000,
	0b11100000,
	0b11110000,
	0b11111000,
	0b11111100,
	0b11111110,
};

void program_loaddata()
{
	fl_init();
	fl_waiting();
	
	poke(&fl_mode, 0);												// set mode to IFFL loading
	floppy_iffl_fast_load_init("INTRODATA");
	floppy_iffl_fast_load(); 										// chars
	floppy_iffl_fast_load();										// palette
	floppy_iffl_fast_load();										// logo chars
	floppy_iffl_fast_load();										// logo screen
	floppy_iffl_fast_load();										// logo attrib
	floppy_iffl_fast_load();										// menu.bin
	floppy_iffl_fast_load();										// song.mod
	floppy_iffl_fast_load(); 										// QRspr
}

void program_drawlogo()
{
	fontsys_map();

	for(uint8_t i = 0; i < 80; i++)
	{
		poke(SCREEN+0*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+0*80+i));
		poke(SCREEN+1*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+1*80+i));
		poke(SCREEN+2*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+2*80+i));
		poke(SCREEN+3*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+3*80+i));
		poke(SCREEN+4*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+4*80+i));
		poke(SCREEN+5*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+5*80+i));
		poke(SCREEN+6*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+6*80+i));
		poke(SCREEN+7*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+7*80+i));
		poke(SCREEN+8*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+8*80+i));
		poke(SCREEN+9*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+9*80+i));

		poke(0x8000+0*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+0*80+i));
		poke(0x8000+1*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+1*80+i));
		poke(0x8000+2*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+2*80+i));
		poke(0x8000+3*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+3*80+i));
		poke(0x8000+4*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+4*80+i));
		poke(0x8000+5*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+5*80+i));
		poke(0x8000+6*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+6*80+i));
		poke(0x8000+7*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+7*80+i));
		poke(0x8000+8*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+8*80+i));
		poke(0x8000+9*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+9*80+i));
	}

	fontsys_unmap();
}

void program_init()
{
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

	program_numtxtentries = program_numbasecategories;

	modplay_init();
	fontsys_init();

	dma_runjob((__far char *)&dma_clearfullcolorram1);
	dma_runjob((__far char *)&dma_clearfullcolorram2);
	dma_runjob((__far char *)&dma_clearfullscreen1);
	dma_runjob((__far char *)&dma_clearfullscreen2);

	program_drawlogo();

	modplay_initmod(SONGADDRESS);

	modplay_enable();

	// TODO - bank in correct palette
	// TODO - create DMA job for this
	for(uint8_t i = 0; i < 255; i++)
	{
		poke(0xd100+i, ((uint8_t *)PALETTE)[0*256+i]);
		poke(0xd200+i, ((uint8_t *)PALETTE)[1*256+i]);
		poke(0xd300+i, ((uint8_t *)PALETTE)[2*256+i]);
	}

	c_textypos = verticalcenter + 0x10;

	VIC2.BORDERCOL = 0x0f;
	VIC2.SCREENCOL = 0x0f;

	// VIC4.PALEMU		= 1;			// $d054 - turn on PALEMU

	VIC2.SE			= 0;			// 0b00000011;	// $d015 - enable the sprites
	VIC4.SPRPTRADR	= sprptrs;		// $d06c - location of sprite pointers
	VIC4.SPRPTR16	= 1;			// $d06e - 16 bit sprite pointers
	VIC2.BSP		= 0;			// $d01b - sprite background priority
	VIC4.SPRX64EN	= 0b00000011;	// $d057 - 64 pixel wide sprites
	VIC4.SPR16EN	= 0;			// $d06b - turn off Full Colour Mode
	VIC4.SPRHGTEN	= 0b00000011;	// $d055 - enable setting of sprite height
	VIC4.SPR640		= 0;			// $d054 - disable SPR640 for all sprites
	VIC4.SPRHGHT	= sprheight;	// $d056 - set sprite height to 64 pixels for sprites that have SPRHGTEN enabled
	VIC2.SEXX		= 0b00000011;	// $d01d - enable x stretch
	VIC2.SEXY		= 0b00000011;	// $d017 - enable y stretch
	VIC2.SXMSB		= 0b00000011;	// $d010 - set x MSB bits
	VIC2.S0X		= 0;			// $d000 - sprite 0 x position QR
	VIC2.S0Y		= 180;			// $d001 - sprite 0 y position QR
	VIC2.S1X		= 0;			// $d000 - sprite 1 x position QR background
	VIC2.S1Y		= 180;			// $d001 - sprite 1 y position QR background
	VIC2.SPR0COL	= 0x0f;			// $d027 - sprite 0 colour - QR
	VIC2.SPR1COL	= 6;			// $d028 - sprite 1 colour - QR background

	poke(sprptrs+2, ( (sprdata+0x000)/64) & 0xff);
	poke(sprptrs+3, (((sprdata+0x000)/64) >> 8) & 0xff);
	poke(sprptrs+0, ( (sprdata+(sprwidth/8)*sprheight)/64) & 0xff);
	poke(sprptrs+1, (((sprdata+(sprwidth/8)*sprheight)/64) >> 8) & 0xff);
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

void program_build_linelist(uint16_t entry)
{
	// clear 5 URL sprites
	//for(uint16_t i = (sprdata+0x180); i<(sprdata+0x180+5*0x180); i++)
	//	poke(i,0);

	poke(0x5c, entry & 0xff);
	poke(0x5d, (entry >> 8) & 0xff);
	poke(0x5e, 0x02);
	poke(0x5f, 0x00);

	// fontsys_buildlineptrlist();
	poke(&program_mainloopstate, 1);	// set state machine to build line ptr list
}

void program_draw_disk()
{
	program_numtxtentries = fnts_numlineptrs;

	fontsys_map();

	program_rowoffset = 0;

	int16_t startrow = 14 - program_selectedrow;
	if(startrow < 5)
	{
		program_rowoffset = -startrow+5;
		startrow = 5;
	}

	int16_t endrow = startrow + program_numtxtentries;

	if(program_numtxtentries - program_selectedrow < 13)
		endrow = 14 + (program_numtxtentries - program_selectedrow);

	if(endrow > 25)
		endrow = 25;

//	if(program_current_entry->full != 0)
//		program_draw_entry(program_current_entry->full,   0x2f, row, 0);
//	else if(program_current_entry->title != 0)
//		program_draw_entry(program_current_entry->title,   0x2f, row, 0);

//	row += 2;
//	if(program_current_entry->author != 0)
//		program_draw_entry(program_current_entry->author, 0x3f, row, 0);

//	row += 2;
//	if(program_current_entry->mount != 0)
//		program_draw_entry(program_current_entry->mount,  0x4f, row, 0);

	if(program_current_entry->desc != 0)
	{
		uint8_t index = program_rowoffset;
		for(uint16_t row = startrow; row < endrow; row++)
		{
			fnts_row = 2*row;
			fnts_column = 0;

			poke(&fnts_curpal + 1, 0x0f);

			poke(0x5c, peek(&fnts_lineptrlistlo + index));
			poke(0x5d, peek(&fnts_lineptrlisthi + index));
			poke(0x5e, 0x02);
			poke(0x5f, 0x00);

			if(index == program_selectedrow)
			{
				uint8_t urlsprindex = peek(&fnts_lineurlstart + index);
				uint16_t urlsprsize = 4+(uint16_t)peek(&fnts_lineurlsize + index);

				if(urlsprindex != 255)
				{
					VIC2.SE	= 0b00000011;
					poke(sprptrs+0, urlsprindex);
					poke(sprptrs+1, 0);
					VIC2.S0X =  48 - urlsprsize;
					VIC2.S1X =  48 - urlsprsize;
					VIC2.S0Y = 50+200-42 - urlsprsize;	// LV TODO - fix weird xemu 7 pixel offset?
					VIC2.S1Y = 50+200-42 - urlsprsize;

					VIC4.SPRHGHT = urlsprsize;

					for(uint16_t i=0; i<urlsprsize; i++)
					{
						int16_t urlsprsize2 = urlsprsize;

						for(uint16_t j=0; j<8; j++)
						{
							uint8_t foo = 255;
							if(urlsprsize2 < 8)
								foo = QRBitmask[(uint8_t)urlsprsize2];

							poke(sprdata+i*8+j, foo);

							urlsprsize2 -= 8;
							if(urlsprsize2 < 0)
								urlsprsize2 = 0;
						}
					}
				}
				else
					VIC2.SE	= 0;
			}

			fontsys_asm_setupscreenpos();
			fontsys_asm_render();

			index++;
		}
	}

	fontsys_unmap();
}

void program_drawlist()
{
	VIC2.SE	= 0; // turn off sprites because there should be no QR codes here

	fontsys_map();

	program_rowoffset = 0;
	
	int16_t startrow = 14 - program_selectedrow;
	if(startrow < 5)
	{
		program_rowoffset = -startrow+5;
		startrow = 5;
	}

	int16_t endrow = startrow + program_numtxtentries;

	if(program_numtxtentries - program_selectedrow < 13)
		endrow = 14 + (program_numtxtentries - program_selectedrow);

	if(endrow > 25)
		endrow = 25;

	uint8_t index = program_rowoffset;
	for(uint16_t row = startrow; row < endrow; row++)
	{
		if(current_cat_idx == 0xff)
		{
			// top level categories
			if(program_categories[index].parent_cat_idx == 0xff)
				program_draw_entry(program_categories[index].name, 0x0f, 2 * row, 0 /* 40 */);
			else
				row--;
		}
		else
		{
			// below top level categories
			uint8_t color = 0x0f;
			if(program_entries[index].dir_flag != 0xff)
				color = 0x2f; // draw as yellow like original intro disk

			if(program_entries[index].full != 0)
				program_draw_entry(program_entries[index].full, color, 2 * row, 0 /* 40 */);
			else if(program_entries[index].title != 0)
				program_draw_entry(program_entries[index].title, color, 2 * row, 0 /* 40 */);
		}

		index++;
	}

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
		program_numtxtentries = program_numbasecategories;
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

	if(movedir != 0)
	{
		if(movedir == 1) // moving down - text moves up
		{
			c_textypos -= 2;
			if(c_textypos < (verticalcenter + 5 * 0x10))
			{
				c_textypos = (verticalcenter + 5 * 0x10);
				movedir = 0;
			}
		}
		else if(movedir == -1) // moving up, text moves down
		{
			c_textypos += 2;
			if(c_textypos >= (verticalcenter + 6 * 0x10))
			{
				c_textypos = (verticalcenter + 5 * 0x10);
				program_selectedrow--;
				movedir = 0;
			}
		}

		if(movedir != 0)
			return;
	}

	if(keyboard_keypressed(KEYBOARD_CURSORDOWN) == 1)
	{
		//if(current_ent_idx != 0xff)
		//	return;

		program_selectedrow++;

		if(program_selectedrow >= program_numtxtentries)
		{
			program_selectedrow = program_numtxtentries - 1;
			return;
		}

		c_textypos = verticalcenter + 6 * 0x10 - 2;
		movedir = 1;
	}
	else if(keyboard_keypressed(KEYBOARD_CURSORUP) == 1)
	{
		//if(current_ent_idx != 0xff)
		//	return;

		if(program_selectedrow == 0)
			return;

		movedir = -1;
	}
	else if(keyboard_keyreleased(KEYBOARD_RETURN))
	{
		if(current_ent_idx != 0xff)
		{
			// handle mounting/running of disk here

			uint8_t autoboot = 0;

			if(program_current_entry->title != 0)
			{
				uint32_t titleaddr = 0x20000 + program_current_entry->title;
				uint32_t addroffset = 0;

				// grrr, some weird calypsi bug I think, have to store this in another var
				uint32_t secondcharaddr = titleaddr+1;

				if(lpeek(titleaddr) == 0x2d) // starts with '-'?
				{
					if(lpeek(secondcharaddr) == 0x42) // -Boot-?
					{
						// assume no prg file name and just boot
						for(uint8_t i = 0; i<16; i++)
							poke(&prgfilename+i, peek(autobootstring + i));

						autoboot = 1;
					}
					else if(lpeek(secondcharaddr) == 0x3d) // -Ntsc-?
					{
						 addroffset = 6;
					}
					else if(lpeek(secondcharaddr) == 0x50) // -Pal-?
					{
						 addroffset = 5;
					}
				}

				if(autoboot == 0)
				{
					// TODO - figure out why LPEEK is changing titleaddr
					titleaddr = 0x20000 + program_current_entry->title + addroffset;

					uint8_t i = 0;
					for(; i<16; i++)
					{
						uint8_t b = lpeek(titleaddr + i);
						poke(&prgfilename+i, b);
						if(b == 0)
							break;
					}
					for(; i<16; i++)
					{
						poke(&prgfilename+i, 0);
					}
				}
			}
			else
			{
				for(uint8_t i = 0; i<16; i++)
					poke(&prgfilename+i, 0);
			}

			if(program_current_entry->mount != 0)
			{
				uint32_t mountaddr = 0x20000 + program_current_entry->mount;

				uint8_t i = 0;
				for(; i<64; i++)
				{
					uint8_t b = lpeek(mountaddr + i);
					poke(&mountname+i, b);
					if(b == 0)
						break;
				}
				for(; i<64; i++)
				{
					poke(&mountname+i, 0);
				}
			}
			else
			{
				for(uint8_t i = 0; i<64; i++)
					poke(&mountname+i, 0);
			}

			// while(1) {}

			if(program_current_entry->title != 0)
			{
				poke(&wasautoboot, autoboot);
				poke(&program_mainloopstate, 2);
				return;
			}
		}

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
				program_selectedrow = 0;
				if(program_current_entry->desc != 0)
					program_build_linelist(program_current_entry->desc);
			}
			else
			{
				program_setcategory(dirflag);
			}
		}
	}
	else if(keyboard_keyreleased(KEYBOARD_ESC) || keyboard_keyreleased(KEYBOARD_SLASH))
	{
		if(current_ent_idx != 0xff)
		{
			program_selectedrow = current_ent_idx;
			current_ent_idx = 0xff;
			if(current_cat_idx == 0xff)
				program_numtxtentries = program_numbasecategories;
			else
				program_numtxtentries = program_numentries;
		}
		else if(current_cat_idx != 0xff)
		{
			program_setcategory(program_categories[current_cat_idx].parent_cat_idx);
		}
	}
	else if(keyboard_keyreleased(KEYBOARD_M))
	{
		modplay_toggleenable();
	}
	else if(keyboard_keyreleased(KEYBOARD_F7))
	{
		poke(&program_mainloopstate, 2);
	}
	else
	{
		program_keydowndelay = 32;
		program_keydowncount = 0;
	}
}

void program_update()
{
	uint8_t busy = peek(&program_mainloopstate);

	if(!busy)
	{
		poke(&textypos, c_textypos);

		if(current_ent_idx != 0xff)
			program_draw_disk();
		else
			program_drawlist();

		program_main_processkeyboard();
	}
}
