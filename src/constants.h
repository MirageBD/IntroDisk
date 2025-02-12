#ifndef __CONSTANTS_H
#define __CONSTANTS_H

#define SCREEN					0xa000
#define RRBSCREENWIDTH			80
#define RRBSCREENWIDTH2			(2*RRBSCREENWIDTH)
#define PALETTE					0xe000
#define LOGOSCREEN              0xe400
#define LOGOATTRIB              0xe800

#define ID4SCREEN               0xce00
#define ID4ATTRIB               0xcf00
#define ID4WIDTH                18
#define ID4HEIGHT               4

#define FONTCHARMEM				0x10000         // currently $4000 big. check bin/glacial_chars0.bin

#define COLOR_RAM				0xff80000
#define COLOR_RAM_OFFSET		0x0800
#define SAFE_COLOR_RAM			(COLOR_RAM + COLOR_RAM_OFFSET)
#define SAFE_COLOR_RAM_IN1MB	(SAFE_COLOR_RAM - $ff00000)	

#define MAPPEDCOLOURMEM			0x08000

#define SONGADDRESS             0x00030000

#endif
