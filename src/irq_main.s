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

			lda #0x0f
			sta 0xd020
			sta 0xd021

			jsr modplay_play

			jsr fontsys_clearscreen
			jsr keyboard_update
			jsr program_update

			lda #0x68
			sta 0xd04e						; VIC4.TEXTYPOSLSB

			lda #0x34-6
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

irq_main2:
			php
			pha
			phx
			phy
			phz

			lda #0xed
			sta 0xd020
			sta 0xd021

			lda #0x34 + 5*8
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

			.public textypos
textypos:	.byte 0x34*2+5*0x10

irq_main3:
			php
			pha
			phx
			phy
			phz

			lda textypos
			sta 0xd04e						; VIC4.TEXTYPOSLSB

			lda #0xed
			sta 0xd020
			sta 0xd021

			lda #0b00010000
			trb 0xd011

			clc
			lda 0xd012
			adc #0x08
blnkwait	cmp 0xd012
			bne blnkwait

			lda #0b00010000
			tsb 0xd011

			lda #0x0f
			sta 0xd020
			sta 0xd021

			lda #0x34 + 14*8
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

			lda #0xfc
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
