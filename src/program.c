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

uint8_t				c_textyposstart = 6 * 0x10;
uint8_t				c_textyposoffset = 0;

uint8_t				c_textypos;
int8_t				movedir = 0;

uint8_t				program_state = 0; // 0 = intro screen, 1 = browsing menu.bin

uint8_t				program_category_indices[256];
uint8_t				program_category_selectedrows[257]; // 257 because program_setcategory uses current_cat_idx+1 and current_cat_idx can be 0xff -> 0x0100

uint8_t sprwidth  = 64;
uint8_t sprheight = 48;
uint16_t sprptrs  = 0x0400;
uint16_t sprdata  = 0x0440;

uint8_t autobootstring[] = "AUTOBOOT.C65";

uint8_t mega65d81string[] = "mega65.d81\x00";

// LV TODO - Are these 0 terminated???
uint8_t introtext1[] = "\x80 THE mega65 COMMUNITY PRESENTS\x00";
uint8_t introtext2[] = "\x80 2025 - rom 920412 - pal mode\x00";

uint8_t headercategorytext[] = "\x80 cURRENTLY BROWSING:\x00";
uint8_t headerentrytext[] = "\x80 cURRENTLY VIEWING:\x00";
uint8_t footertext0[] = "\x80PRESS\x82 return\x80 \x18\x19 TO\x82 begin\x00";
uint8_t footertext1[] = "\x80uSE cursor keys \x15 \x16 TO scroll, return \x18\x19 TO select AND escape \x17 TO go back\x00";
uint8_t footertext2[] = "\x80uSE cursor keys \x15 \x16 TO scroll, return \x18\x19 TO start AND escape \x17 TO go back\x00";

uint8_t loadingtext1[] = "\x82 mount:\x00";
uint8_t loadingtext2[] = "\x82 prg:\x00";
uint8_t loadingtext3[] = "\x80 loading...\x00";

uint8_t loadingntsc[] = "\x81 eNFORCING \x82ntsc\x81 MODE...\x00";
uint8_t loadingpal[] = "\x81 eNFORCING \x83pal\x81 MODE...\x00";

__far char *ptr;

// forward function declarations
void program_drawtextscreen();

#define NUM_SPECIAL_CATS 7
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

void program_setcategorytextbank()
{
	program_settextbank(2);
	if(current_cat_idx >= program_numcategories-NUM_SPECIAL_CATS && current_cat_idx < program_numcategories)
		program_settextbank(5);
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

void program_drawspace(uint8_t row, uint8_t column, uint8_t width)
{
	fnts_row = row;
	fnts_column = column;

	poke(&fnts_spacewidth, width);

	fontsys_asm_setupscreenpos();
	fontsys_asm_renderspace();
}


void program_clearheader()
{
	dma_runjob((__far char *)&dma_clearheaderlinecolorram1);
	dma_runjob((__far char *)&dma_clearheaderlinecolorram2);
	dma_runjob((__far char *)&dma_clearheaderlinescreenram1);
	dma_runjob((__far char *)&dma_clearheaderlinescreenram2);
}

void program_clearfooter()
{
	dma_runjob((__far char *)&dma_clearfooterlinecolorram1);
	dma_runjob((__far char *)&dma_clearfooterlinecolorram2);
	dma_runjob((__far char *)&dma_clearfooterlinescreenram1);
	dma_runjob((__far char *)&dma_clearfooterlinescreenram2);
}


void program_drawintrofooter()
{
	program_clearfooter();
	program_drawline((uint16_t)&footertext0, 0x00, 38, 29*2);
}

void program_drawcategoryheader()
{
	fontsys_map();
	program_clearheader();
	program_settextbank(0);
	program_drawline((uint16_t)&headercategorytext, 0x00, 0, 0);
	program_settextbank(2);
	program_drawline(program_categories[current_cat_idx].name, 0x1f, 0, 2*21);
	program_setcategorytextbank();
	fontsys_unmap();
}

void program_drawcategoryfooter()
{
	fontsys_map();
	program_clearfooter();
	program_settextbank(0);
	program_drawline((uint16_t)&footertext1, 0x00, 38, 5*2);
	program_setcategorytextbank();
	fontsys_unmap();
}

char str[128];

void program_genfilename_and_author(void)
{
	uint8_t idx = 0;

	if (program_entries[program_selectedrow].full != 0)
		ptr = (__far char*)(program_entries[program_selectedrow].full + ((long)program_textbank << 16));
	else
		ptr = (__far char*)(program_entries[program_selectedrow].title + ((long)program_textbank << 16));

	// strcpy(str, ptr) equivalent
	while (*ptr != 0) {
		str[idx] = *ptr;
		idx++;
		ptr++;
	}

	if (program_entries[program_selectedrow].author == 0) {
		str[idx] = '\0';
		return;
	}

	str[idx] = '\x80'; idx++;
	str[idx] = ' '; idx++;
	str[idx] = '-'; idx++;
	str[idx] = ' '; idx++;
	str[idx] = '\x81'; idx++;

	ptr = (__far char*)(program_entries[program_selectedrow].author + ((long)program_textbank << 16));

	// strcat(str, ptr); equivalent
	while (*ptr != 0) {
		str[idx] = *ptr;
		idx++;
		ptr++;
	}
	str[idx] = '\0';
}

void program_drawentryheader()
{
	fontsys_map();
	program_clearheader();
	program_settextbank(0);
	program_drawline((uint16_t)&headerentrytext, 0x00, 0, 0);
	program_setcategorytextbank();
	program_genfilename_and_author();
	program_settextbank(0);
	program_drawline((uint16_t)str, 0x2f, 0, 2*20);
	fontsys_unmap();
}

void program_drawentryfooter()
{
	fontsys_map();
	program_clearfooter();
	program_settextbank(0);
	program_drawline((uint16_t)&footertext2, 0x00, 38, 5*2);
	program_setcategorytextbank();
	fontsys_unmap();
}


void program_drawintroscreen()
{
	fontsys_map();

	// draw ID4 logo
	for(uint8_t y=0; y<ID4HEIGHT; y++)
	{
		for(uint8_t x=0; x<2*ID4WIDTH; x++)
		{
			poke(SCREEN+(y+17)*RRBSCREENWIDTH2+(x+44), peek(ID4SCREEN + y*2*ID4WIDTH + x));
			poke(0x8000+(y+17)*RRBSCREENWIDTH2+(x+44), peek(ID4ATTRIB + y*2*ID4WIDTH + x));
		}
	}

	program_settextbank(0); // set current text bank to 0

	program_clearheader();

	program_drawline((uint16_t)&introtext1, 0x00, 12, 2*26);
	program_drawline((uint16_t)&introtext2, 0x00, 24, 2*26);

	program_drawintrofooter();

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

		uint8_t curbank = program_textbank;

	if(current_cat_idx >= program_numcategories-NUM_SPECIAL_CATS && current_cat_idx < program_numcategories)
		program_settextbank(5); // set text bank to 5 for credits and news

		if(program_entries[index].dir_flag != 0xff)
			program_settextbank(2);	// force sub-directories text to bank 2

		ptr = (__far char *)
			(program_entries[index].title + ((long)program_textbank << 16));

		if (program_entries[index].title != 0 &&	// -(c)- items in red
				ptr[0] == '-' &&
				ptr[1] == '(')
			color = 0x1f;

		if(program_entries[index].full != 0)
			program_drawline(program_entries[index].full, color, 2 * row, 0 /* 40 */);
		else if(program_entries[index].title != 0)
			program_drawline(program_entries[index].title, color, 2 * row, 0 /* 40 */);

		program_settextbank(curbank);
	}
}

void program_drawtopline()
{
	fontsys_map();
	
	dma_runjob((__far char *)&dma_cleartoplinecolorram1);
	dma_runjob((__far char *)&dma_cleartoplinecolorram2);
	dma_runjob((__far char *)&dma_cleartoplinescreenram1);
	dma_runjob((__far char *)&dma_cleartoplinescreenram2);

	if(program_selectedrow - 8 >= 0)
	{
		uint8_t index = program_selectedrow - 8;
		uint8_t row = 1;
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
		uint8_t row = 18;
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
	for(uint8_t i = 0; i < 80; i++)
	{
		poke(LOGOFINALSCREEN+0*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+0*80+i));
		poke(LOGOFINALSCREEN+1*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+1*80+i));
		poke(LOGOFINALSCREEN+2*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+2*80+i));
		poke(LOGOFINALSCREEN+3*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+3*80+i));
		poke(LOGOFINALSCREEN+4*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+4*80+i));
		poke(LOGOFINALSCREEN+5*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+5*80+i));
		poke(LOGOFINALSCREEN+6*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+6*80+i));
		poke(LOGOFINALSCREEN+7*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+7*80+i));
		poke(LOGOFINALSCREEN+8*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+8*80+i));
		poke(LOGOFINALSCREEN+9*RRBSCREENWIDTH2+i, peek(LOGOSCREEN+9*80+i));

		lpoke(LOGO_COLOR_RAM+0*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+0*80+i));
		lpoke(LOGO_COLOR_RAM+1*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+1*80+i));
		lpoke(LOGO_COLOR_RAM+2*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+2*80+i));
		lpoke(LOGO_COLOR_RAM+3*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+3*80+i));
		lpoke(LOGO_COLOR_RAM+4*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+4*80+i));
		lpoke(LOGO_COLOR_RAM+5*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+5*80+i));
		lpoke(LOGO_COLOR_RAM+6*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+6*80+i));
		lpoke(LOGO_COLOR_RAM+7*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+7*80+i));
		lpoke(LOGO_COLOR_RAM+8*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+8*80+i));
		lpoke(LOGO_COLOR_RAM+9*RRBSCREENWIDTH2+i, peek(LOGOATTRIB+9*80+i));
	}
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

	dma_runjob((__far char *)&dma_clearentiresafecolorram);
	
	dma_runjob((__far char *)&dma_clearfullcolorram1);
	dma_runjob((__far char *)&dma_clearfullcolorram2);
	dma_runjob((__far char *)&dma_clearfullscreen1);
	dma_runjob((__far char *)&dma_clearfullscreen2);

	program_drawlogo();

	modplay_initmod(SONGADDRESS);

	modplay_enable();

	c_textypos = verticalcenter + c_textyposstart;

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

	fontsys_map();

	fontsys_clearscreen();

	program_rowoffset = 0;
	
	int16_t startrow = 9 - program_selectedrow;
	if(startrow < 1)
	{
		program_rowoffset = -startrow+1;
		startrow = 1;
	}

	int16_t endrow = startrow + program_numtxtentries;

	if(program_numtxtentries - program_selectedrow < 13)
		endrow = 9 + (program_numtxtentries - program_selectedrow);

	if(endrow > 19)
		endrow = 19;

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
}

int parse_custom_rom(uint32_t addr)
{
  uint8_t cnt = 0;
  char c;

  while ( (c = lpeek(addr)) != '-') // starts with '-'?
  {
    poke(&romfilename + cnt, c);
    addr++;
    cnt++;
  }
  poke(&romfilename + cnt, '\0');
  cnt++;

  return cnt;
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
			c_textyposoffset -= 2;
			c_textypos = verticalcenter + c_textyposstart + c_textyposoffset;
			if(c_textyposoffset <= 0)
			{
				c_textyposoffset = 0;
				c_textypos = (verticalcenter + c_textyposstart);
				movedir = 0;
			}
		}
		else if(movedir == -1) // moving up, text moves down
		{
			c_textyposoffset += 2;
			c_textypos = verticalcenter + c_textyposstart + c_textyposoffset;
			if(c_textyposoffset >= 1 * 0x10)
			{
				c_textyposoffset = 0;
				c_textypos = (verticalcenter + c_textyposstart);
				program_selectedrow--;
				program_movescreendown();
				program_checkdrawQR();
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

		c_textyposoffset = 1 * 0x10 - 2;
		c_textypos = verticalcenter + c_textyposstart + c_textyposoffset;
		program_selectedrow++;
		program_movescreenup();
		program_drawbottomline();
		program_checkdrawQR();
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
			program_drawcategoryfooter();
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
			uint8_t go64flag = 0;
			uint8_t palflag = 0;
			uint8_t ntscflag = 0;

			if(program_current_entry->title != 0)
			{
				uint32_t addroffset = 0;

				// grrr, some weird calypsi bug I think, have to store this in another var

				// N.B. This simple check doesn't work any more for the silent enigma demo, because
				// it has this in the title: "-rom:999999.bin--boot-"
				while (lpeek(titleaddr + addroffset) == 0x2d) // starts with '-'?
				{
					uint32_t secondcharaddr = titleaddr + addroffset + 1;

					if(lpeek(secondcharaddr) == 'R') // -Rom:xxx-?
					{
						addroffset += parse_custom_rom(secondcharaddr + 4) + 4 + 1;
					}
					else if(lpeek(secondcharaddr) == '(') // -(c)-?
					{
						addroffset += 5;
					}
					else if (lpeek(secondcharaddr) == 'G') // -Go64-?
					{
						go64flag = 1;
						addroffset += 6;
					}
					else if(lpeek(secondcharaddr) == 'N') // -Ntsc-?
					{
						ntscflag = 1;
						addroffset += 6;
					}
					else if(lpeek(secondcharaddr) == 0x50) // -Pal-?
					{
						palflag = 1;
						addroffset += 5;
					}
					else if(lpeek(secondcharaddr) == 0x42) // -Boot-?
					{
						// assume no prg file name and just boot
						for(uint8_t i = 0; i<16; i++)
							poke(&prgfilename+i, 0);

						autoboot = 1;
						addroffset += 6;
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
				poke(&wasgo64flag, go64flag);
				poke(&wasntscflag, ntscflag);
				poke(&waspalflag, palflag);

				dma_runjob((__far char *)&dma_clearfullcolorram1);
				dma_runjob((__far char *)&dma_clearfullcolorram2);
				dma_runjob((__far char *)&dma_clearfullscreen1);
				dma_runjob((__far char *)&dma_clearfullscreen2);

				fontsys_map();

				program_settextbank(0); // set current text bank to 0

				// draw loading text
				program_drawline((uint16_t)&loadingtext1, 0x00, 0, 2*0);
				program_drawspace(0, 2*9, 13);
				program_drawline((uint16_t)&mountname,    0x00, 0, 2*10);
				
				program_drawline((uint16_t)&loadingtext2, 0x00, 3, 2*0);
				program_drawspace(3, 2*9, 8);
				program_drawline((uint16_t)&prgfilename,  0x00, 3, 2*10);
				
				program_drawline((uint16_t)&loadingtext3, 0x00, 25, 2*34);

				if (wasntscflag)
					program_drawline((uint16_t)&loadingntsc, 0x00, 6, 2*0);

				if (waspalflag)
					program_drawline((uint16_t)&loadingpal, 0x00, 6, 2*0);

				fontsys_unmap();

				poke(&program_mainloopstate, 10);

				return;
			}
		}

		if(current_cat_idx == 0xff)
		{
			program_setcategory(program_category_indices[program_selectedrow]);
			program_drawcategoryheader();
			program_drawcategoryfooter();

			// Here is where we'll want to check if there's only one entry and skip to that straight away. I.E. credits page
			program_drawtextscreen();
		}
		else
		{
			program_drawentryheader();
			program_drawentryfooter();

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
				program_setcategorytextbank();
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
			{
				// if we're now at the top level, use basecategories
				// TODO - this doesn't work for 'parented' categories. Can I get a name from somewhere?
				program_clearheader();
				program_drawcategoryfooter();
				program_numtxtentries = program_numbasecategories;
			}
			else
			{
				program_drawcategoryheader();
				program_drawcategoryfooter();
				program_numtxtentries = program_numentries;
			}
		}
		else if(current_cat_idx != 0xff)
		{
			// we were not looking at an entry, so we must have been looking at sub-categories, so just move up to base categories.
			program_clearheader();
			program_drawcategoryfooter();
			program_setcategory(program_categories[current_cat_idx].parent_cat_idx);
			program_setcategorytextbank();
		}
		else
		{
			// move to intro disk selection menu
			for(uint8_t i = 0; i<16; i++)
			{
				poke(&prgfilename+i, peek(autobootstring + i));
				poke(&mountname+i, peek(mega65d81string + i));
			}

			poke(&wasautoboot, 1);

			dma_runjob((__far char *)&dma_clearfullcolorram1);
			dma_runjob((__far char *)&dma_clearfullcolorram2);
			dma_runjob((__far char *)&dma_clearfullscreen1);
			dma_runjob((__far char *)&dma_clearfullscreen2);

			poke(&program_mainloopstate, 10);

			return;
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
		poke(&textyposoffset, c_textyposoffset);
		poke(&textypos, c_textypos);
	}
}
