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

uint8_t				program_textbank;

__far uint8_t*		program_menubin_struct;
__far category*		program_categories;
__far catentry*		program_entries;
__far catentry*		program_current_entry;

uint8_t				current_cat_idx;
uint8_t				current_ent_idx;

uint8_t				c_textypos = 0x78;
int8_t				movedir = 0;

uint8_t				program_state = 0; // 0 = intro screen, 1 = browsing menu.bin

uint8_t				program_category_indices[256];
uint8_t				program_category_selectedrows[257]; // 257 because program_setcategory uses current_cat_idx+1 and current_cat_idx can be 0xff -> 0x0100

uint8_t sprwidth  = 64;
uint8_t sprheight = 48;
uint16_t sprptrs  = 0x0400;
uint16_t sprdata  = 0x0440;

uint8_t autobootstring[] = "AUTOBOOT.C65";

// LV TODO - Are these 0 terminated???
uint8_t introtext1[] = "\x80 THE mega65 COMMUNITY PRESENTS:";
uint8_t introtext2[] = "\x80 2025 - rom 920395 - pal mode";
uint8_t introtext3[] = "\x82  PRESS return TO BEGIN";
uint8_t introtext4[] = "\x80 this text is in the lower border";

uint8_t loadingtext[] = "\x80 loading...";

// forward function declarations
void program_drawtextscreen();

/*
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
*/

void program_settextbank(uint8_t bank)
{
	program_textbank = bank;
	poke(0x5e, bank);
}

void program_checkdrawQR()
{
	// don't check for QR if we're rendering categories
	if(current_ent_idx == 0xff)
	{
		VIC2.SE	= 0;
		return;
	}

	// is there a URL at this line?
	uint8_t urlsprindex = peek(&fnts_lineurlstart + program_selectedrow);
	if(urlsprindex != 255)
	{
		uint8_t urlsprsize = 4+(uint8_t)peek(&fnts_lineurlsize + program_selectedrow);

		VIC2.SE	= 0b00000011;
		poke(sprptrs+0, urlsprindex);
		poke(sprptrs+1, 0);
		VIC2.S0X =  88 - 2*urlsprsize;
		VIC2.S1X =  88 - 2*urlsprsize;
		VIC2.S0Y = 242 - 2*urlsprsize;
		VIC2.S1Y = 242 - 2*urlsprsize;

		VIC4.SPRHGHT = urlsprsize;
	}
	else
	{
		VIC2.SE	= 0;
	}
}

void program_drawline(uint16_t entry, uint8_t color, uint8_t row, uint8_t column)
{
	fnts_row = row;
	fnts_column = column;

	poke(&fnts_bottomlineadd1 + 1, 0x80);
	poke(&fnts_bottomlineadd2 + 1, 0);

	poke(&fnts_curpal + 1, color);

	poke(0x5c, entry & 0xff);
	poke(0x5d, (entry >> 8) & 0xff);

	fontsys_asm_setupscreenpos();
	fontsys_asm_render();
}

void program_drawintroscreen()
{
	fontsys_map();

	// draw ID4 logo
	for(uint8_t y=0; y<ID4HEIGHT; y++)
	{
		for(uint8_t x=0; x<2*ID4WIDTH; x++)
		{
			poke(SCREEN+(y+27)*RRBSCREENWIDTH2+(x+44), peek(ID4SCREEN + y*2*ID4WIDTH + x));
			poke(0x8000+(y+27)*RRBSCREENWIDTH2+(x+44), peek(ID4ATTRIB + y*2*ID4WIDTH + x));
		}
	}

	program_settextbank(0); // set current text bank to 0

	program_drawline((uint16_t)&introtext1, 0x00, 22, 2*26);
	program_drawline((uint16_t)&introtext2, 0x00, 34, 2*26);
	program_drawline((uint16_t)&introtext3, 0x20, 44, 2*30);

	// program_drawline(introtext4, 0x20, 48, 2*0);

	fontsys_unmap();

	program_settextbank(2); // set current text bank to 2 to read categories correctly
}

void program_drawprogramentry(uint16_t row, uint8_t index)
{
	fnts_row = 2*row;
	fnts_column = 0;

	poke(&fnts_bottomlineadd1 + 1, 0x80);
	poke(&fnts_bottomlineadd2 + 1, 0);

	poke(&fnts_curpal + 1, 0x0f);

	poke(0x5c, peek(&fnts_lineptrlistlo + index));
	poke(0x5d, peek(&fnts_lineptrlisthi + index));

	fontsys_asm_setupscreenpos();
	fontsys_asm_render();
}

void program_drawcategoryentry(uint16_t row, uint8_t index)
{
	if(current_cat_idx == 0xff)
	{
		// top level categories
		program_drawline(program_categories[program_category_indices[index]].name, 0x0f, 2 * row, 0 /* 40 */);
	}
	else
	{
		// below top level categories
		uint8_t color = 0x0f;
		if(program_entries[index].dir_flag != 0xff)
			color = 0x2f; // draw as yellow like original intro disk

		if(program_entries[index].full != 0)
			program_drawline(program_entries[index].full, color, 2 * row, 0 /* 40 */);
		else if(program_entries[index].title != 0)
			program_drawline(program_entries[index].title, color, 2 * row, 0 /* 40 */);
	}
}

void program_drawtopline()
{
	fontsys_map();
	
	dma_runjob((__far char *)&dma_cleartoplinecolorram1);
	dma_runjob((__far char *)&dma_cleartoplinecolorram2);
	dma_runjob((__far char *)&dma_cleartoplinescreenram1);
	dma_runjob((__far char *)&dma_cleartoplinescreenram2);

	if(program_selectedrow - 9 >= 0)
	{
		uint8_t index = program_selectedrow - 9;
		uint8_t row = 5;
		if(current_ent_idx != 0xff)
			program_drawprogramentry(row, index);
		else
			program_drawcategoryentry(row, index);
	}

	fontsys_unmap();
}

void program_drawbottomline()
{
	fontsys_map();

	dma_runjob((__far char *)&dma_clearbottomlinecolorram1);
	dma_runjob((__far char *)&dma_clearbottomlinecolorram2);
	dma_runjob((__far char *)&dma_clearbottomlinescreenram1);
	dma_runjob((__far char *)&dma_clearbottomlinescreenram2);

	if(program_selectedrow + 9 < program_numtxtentries)
	{
		uint8_t index = program_selectedrow + 9;
		uint8_t row = 24;
		if(current_ent_idx != 0xff)
			program_drawprogramentry(row, index);
		else
			program_drawcategoryentry(row, index);
	}

	fontsys_unmap();
}

void program_movescreenup()
{
	fontsys_map();
	dma_runjob((__far char *)&dma_copycolorramup);
	dma_runjob((__far char *)&dma_copyscreenramup);
	fontsys_unmap();
}

void program_movescreendown()
{
	fontsys_map();
	dma_runjob((__far char *)&dma_copycolorramdown);
	dma_runjob((__far char *)&dma_copyscreenramdown);
	fontsys_unmap();
}

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
	floppy_iffl_fast_load();										// menu2.bin
	floppy_iffl_fast_load();										// song.mod
	floppy_iffl_fast_load(); 										// QRspr
	floppy_iffl_fast_load();										// id4 chars     $1200
	floppy_iffl_fast_load();										// id4 screen    $0090
	floppy_iffl_fast_load();										// id4 attrib    $0090
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
	program_categories = (__far category*)(program_menubin_struct+1);

	program_numbasecategories = 0;
	for(uint8_t index = 0; index < program_numcategories; index++)
	{
		if(program_categories[index].parent_cat_idx == 0xff)
		{
			program_category_indices[program_numbasecategories] = index;
			program_numbasecategories++;
		}
	}

	current_cat_idx = 0xff;
	current_ent_idx = 0xff;
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

	for(uint16_t i=0; i<sprheight*(sprwidth/8); i++)	// fill QR background sprite
		poke(sprdata+i, 255);

	poke(&textypos, c_textypos);

	program_drawintroscreen();

	fadepal_init(); // init fadepal to start increasing in irq_main
}

void program_build_linelist(uint16_t entry)
{
	poke(0x5c, entry & 0xff);
	poke(0x5d, (entry >> 8) & 0xff);

	poke(&program_mainloopstate, 1);	// set state machine to build line ptr list
}

void program_drawtextscreen()
{
	VIC2.SE	= 0; // turn off sprites because there should be no QR codes here

	fontsys_clearscreen();

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
	if(current_ent_idx == 0xff)
	{
		for(uint16_t row = startrow; row < endrow; row++)
		{
			program_drawcategoryentry(row, index);
			index++;
		}
	}
	else
	{
		for(uint16_t row = startrow; row < endrow; row++)
		{
			program_drawprogramentry(row, index);
			index++;
		}
	}

	fontsys_unmap();
}

void program_setcategory(uint8_t index)
{
	program_category_selectedrows[current_cat_idx+1] = program_selectedrow;

	program_selectedrow = program_category_selectedrows[index+1];

	current_cat_idx = index;
	uint16_t cat_entry_offset = program_categories[current_cat_idx].cat_entry_offset;
	program_entries = (__far catentry*)(menubinaddr + program_menubin_struct_offset + cat_entry_offset + 1);
	program_numentries = lpeek(program_menubin_struct + cat_entry_offset);

	current_ent_idx = 0xff;

	if(current_cat_idx == 0xff)
		program_numtxtentries = program_numbasecategories;
	else
		program_numtxtentries = program_numentries;

	program_settextbank(2); // set text bank to 2 for all other sub-categories/entries

	if(current_cat_idx >= program_numcategories-2 && current_cat_idx < program_numcategories)
		program_settextbank(5); // set text bank to 5 for credits and news
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
				program_selectedrow--;
				program_movescreendown();
				program_checkdrawQR();
				c_textypos = (verticalcenter + 5 * 0x10);
				movedir = 0;
			}
		}

		if(movedir != 0)
			return;
	}

	if(keyboard_keypressed(KEYBOARD_CURSORDOWN) == 1)
	{
		if(program_state == 0)
			return;

		if(program_selectedrow == program_numtxtentries-1)
			return;

		program_selectedrow++;
		program_drawbottomline();
		program_movescreenup();
		program_checkdrawQR();
		c_textypos = verticalcenter + 6 * 0x10 - 2;
		movedir = 1;
	}
	else if(keyboard_keypressed(KEYBOARD_CURSORUP) == 1)
	{
		if(program_state == 0)
			return;

		if(program_selectedrow == 0)
			return;

		program_drawtopline();
		movedir = -1;
	}
	else if(keyboard_keyreleased(KEYBOARD_RETURN))
	{
		if(program_state == 0)
		{
			program_state = 1;
			program_drawtextscreen(); // draw initial list of categories
			return;
		}

		if(current_ent_idx != 0xff)
		{
			uint32_t titleaddr = (((uint32_t)program_textbank) << 16) + program_current_entry->title;

			// no mount or prg? must be credits or news or something, back out
			if(program_current_entry->mount == 0 && lpeek(titleaddr) == 0)
				return;

			// handle mounting/running of disk here

			uint8_t autoboot = 0;

			if(program_current_entry->title != 0)
			{
				uint32_t addroffset = 0;

				// grrr, some weird calypsi bug I think, have to store this in another var
				uint32_t secondcharaddr = titleaddr+1;

				// N.B. This simple check doesn't work any more for the silent enigma demo, because
				// it has this in the title: "-rom:999999.bin--boot-"
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
					titleaddr = (((uint32_t)program_textbank) << 16) + program_current_entry->title + addroffset;

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
				uint32_t mountaddr = (((uint32_t)program_textbank) << 16) + program_current_entry->mount;

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

			if(program_current_entry->title != 0)
			{
				poke(&wasautoboot, autoboot);
				poke(&program_mainloopstate, 10);

				dma_runjob((__far char *)&dma_clearfullcolorram1);
				dma_runjob((__far char *)&dma_clearfullcolorram2);
				dma_runjob((__far char *)&dma_clearfullscreen1);
				dma_runjob((__far char *)&dma_clearfullscreen2);

				fontsys_map();
				program_settextbank(0); // set current text bank to 0
				program_drawline((uint16_t)&loadingtext, 0x00, 25, 2*34); // draw loading text
				fontsys_unmap();
			
				return;
			}
		}

		if(current_cat_idx == 0xff)
		{
			// at top level? then show sub-category entries next
			program_setcategory(program_category_indices[program_selectedrow]);

			// Here is where we'll want to check if there's only one entry and skip to that straight away. I.E. credits page
			program_drawtextscreen();
		}
		else
		{
			// at sub-category level? then start to build linelist, but only if sub-category doesn't have even more sub-categories (check for 'dir' in gen.py for this)
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
				program_drawtextscreen();
			}
		}
	}
	else if(keyboard_keyreleased(KEYBOARD_ESC) || keyboard_keyreleased(KEYBOARD_SLASH))
	{
		if(current_ent_idx != 0xff)
		{
			// we were looking at an entry, so move back to sub-categories
			// don't change current_cat_idx, because that isn't changing

			// leave selected row at the entry we were just at
			program_selectedrow = current_ent_idx;
			// flag that we're not looking at an entry any more
			current_ent_idx = 0xff;
			if(current_cat_idx == 0xff)
				// if we're now at the top level, use basecategories
				program_numtxtentries = program_numbasecategories;
			else
				program_numtxtentries = program_numentries;
		}
		else if(current_cat_idx != 0xff)
		{
			// we were not looking at an entry, so we must have been looking at sub-categories, so just move up to base categories.
			program_setcategory(program_categories[current_cat_idx].parent_cat_idx);
		}

		program_drawtextscreen();
	}
	else if(keyboard_keyreleased(KEYBOARD_M))
	{
		modplay_toggleenable();
	}
	else
	{
		program_keydowndelay = 32;
		program_keydowncount = 0;
	}
}

void program_update()
{
	uint8_t program_loopstate = peek(&program_mainloopstate);

	if(program_loopstate == 2)
	{
		program_numtxtentries = fnts_numlineptrs;
		program_drawtextscreen();
		poke(&program_mainloopstate, 0);
	}

	if(program_loopstate == 0) // not waiting for anything, so do update
	{
		program_main_processkeyboard();
		poke(&textypos, c_textypos);
	}
}
