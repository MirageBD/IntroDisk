			.rtmodel cpu, "*"
			
			.extern modplay_play
			.extern keyboard_update
			.extern fontsys_clearscreen
			.extern program_update
			.extern _Zp

 ; ------------------------------------------------------------------------------------

			.public irq_main
irq_main:
			php
			pha
			phx
			phy
			phz

			;lda #0x01
			;sta 0xd020
			;sta 0xd021

			jsr modplay_play

			jsr fontsys_clearscreen
			jsr keyboard_update
			jsr program_update

			lda #0x0f
			sta 0xd020
			sta 0xd021

			lda #0x68
			sta 0xd04e						; VIC4.TEXTYPOSLSB

			lda #0x00						; VIC4.SCRNPTR		= (SCREEN & 0xffff);					// set screen pointer
			sta 0xd060						; VIC4.SCRNPTR		= (0xa000 & 0xffff);					// set screen pointer
			lda #0xa0
			sta 0xd061

			lda #0x00						; VIC4.COLPTR			= COLOR_RAM_OFFSET;						// set offset to colour ram, so we can use continuous memory
			sta 0xd064						; VIC4.COLPTR			= 0x0800;
			lda #0x08
			sta 0xd065

			lda #0x34 + 8
			sta 0xd012
			lda #.byte0 irq_main2
			sta 0xfffe
			lda #.byte1 irq_main2
			sta 0xffff

			plz
			ply
			plx
			pla
			plp
			asl 0xd019
			rti

; ------------------------------------------------------------------------------------

			.public textypos
textypos:	.byte 0x34*2+0x10
fietswait:	.byte 0

irq_main2:
			php
			pha
			phx
			phy
			phz

			inc fietswait
			lda fietswait
			cmp #0x02
			bne settextypos
			lda #0x00
			sta fietswait

			inc textypos
			lda textypos
			cmp #0x34*2+16+16
			bne settextypos
			lda #0x34*2+16
			sta textypos

settextypos:
			lda textypos
			sta 0xd04e						; VIC4.TEXTYPOSLSB

			lda #0x34 + 12*8
			sta 0xd012
			lda #.byte0 irq_main3
			sta 0xfffe
			lda #.byte1 irq_main3
			sta 0xffff

			plz
			ply
			plx
			pla
			plp
			asl 0xd019
			rti

; ------------------------------------------------------------------------------------

irq_main3:
			php
			pha
			phx
			phy
			phz

			clc
			lda 0xd012
			adc #0x08

			ldx #0xe2
			stx 0xd20f
			stx 0xd21f
			stx 0xd22f
			ldx #0xf4
			stx 0xd30f
			stx 0xd31f
			stx 0xd32f

waitr2$:	cmp 0xd012
			bne waitr2$

			ldx #0x00
			stx 0xd20f
			stx 0xd21f
			stx 0xd22f
			stx 0xd30f
			stx 0xd31f
			stx 0xd32f

			lda #0x34+23*8+2
			sta 0xd012

			lda #.byte0 irq_main4
			sta 0xfffe
			lda #.byte1 irq_main4
			sta 0xffff

			plz
			ply
			plx
			pla
			plp
			asl 0xd019
			rti

; ------------------------------------------------------------------------------------

irq_main4:
			php
			pha
			phx
			phy
			phz

			lda textypos
			sbc #0x68+0x10
			tax

			lda #0x68
			sta 0xd04e						; VIC4.TEXTYPOSLSB

			lda scroffsetlo,x				; VIC4.SCRNPTR		= (0xa000 & 0xffff);					// set screen pointer
			sta 0xd060
			lda scroffsethi,x
			sta 0xd061

			lda scroffsetlo,x				; VIC4.COLPTR			= 0x0800;
			sta 0xd064
			lda coloffsethi,x
			sta 0xd065

			lda #0xff
			sta 0xd012
			lda #.byte0 irq_main
			sta 0xfffe
			lda #.byte1 irq_main
			sta 0xffff

			plz
			ply
			plx
			pla
			plp
			asl 0xd019
			rti

; ------------------------------------------------------------------------------------

scroffsetlo	.byte 0x00, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40
scroffsethi	.byte 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa1, 0xa1, 0xa1, 0xa1, 0xa1, 0xa1, 0xa1
coloffsethi	.byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x09, 0x09, 0x09, 0x09, 0x09, 0x09, 0x09