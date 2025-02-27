#ifndef __CONSTANTS_H
#define __CONSTANTS_H

#define SCREEN					0xa000
#define RRBSCREENWIDTH			80
#define RRBSCREENWIDTH2			(2*RRBSCREENWIDTH)
#define PALETTE					0xe000
#define LOGOSCREEN              0xe400
#define LOGOATTRIB              0xe800

// fontsys_asm uses this memory:
// fnts_lineptrlistlo		.equ 0xc000
// fnts_lineptrlisthi		.equ 0xc100
// fnts_lineurlstart		.equ 0xc200
// fnts_lineurlsize		    .equ 0xc300
// txturl					.equ 0xc400 ; 128 big
// fnts_chartrimshi:		.equ 0xc500 ; 128 big
// fnts_chartrimslo:		.equ 0xc580 ; 128 big
// fnts_screentablo:		.equ 0xc600+0*64 ; 64 big
// fnts_screentabhi:		.equ 0xc600+1*64 ; 64 big
// fnts_attribtablo:		.equ 0xc600+2*64 ; 64 big
// fnts_attribtabhi:		.equ 0xc600+3*64 ; 64 big

#define NSTABLE					0xc700

#define ID4SCREEN               0xce00
#define ID4ATTRIB               0xcf00
#define ID4WIDTH                18
#define ID4HEIGHT               4

#define FONTCHARMEM				0x10000         // currently $4000 big. check bin/glacial_chars0.bin

#define COLOR_RAM				0xff80000
#define COLOR_RAM_OFFSET		0x0800
#define SAFE_COLOR_RAM			(COLOR_RAM + COLOR_RAM_OFFSET)
#define SAFE_COLOR_RAM_IN1MB	(SAFE_COLOR_RAM - $ff00000)	

#define LOGO_COLOR_RAM_OFFSET   0x0800
#define LOGO_COLOR_RAM          (COLOR_RAM + LOGO_COLOR_RAM_OFFSET)

#define MAPPEDCOLOURMEM			0x08000

#define SONGADDRESS             0x00030000

#endif
