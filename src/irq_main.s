			.rtmodel cpu, "*"
			
			.extern modplay_play
			.extern keyboard_update
			.extern fontsys_clearscreen
			.extern program_update
			.extern _Zp

; ------------------------------------------------------------------------------------

			.public nextrasterirqline
nextrasterirqline:
			.byte 0

			.public textypos
textypos:	.byte 0x34*2+5*0x10

; ------------------------------------------------------------------------------------

			.public irq_rti
irq_rti
			php
			pha
			phx
			phy
			phz

			asl 0xd019						; acknowledge raster IRQ and test if this was a timer IRQ or not using what's in carry now
			bcs rasterirq
			jmp timerirqimp					; IRQ was a timer IRQ

rasterirq:	
			ldx #0xff
			stx 0xd10f
			jsr waitawhile
			ldx #0x00
			stx 0xd10f

			lda #0xa0
			sta 0xd012
			sta nextrasterirqline
			lda #.byte0 irq_rti2
			sta 0xfffe
			sta 0x0314
			lda #.byte1 irq_rti2
			sta 0xffff
			sta 0x0315

			jmp endirq

; ------------------------------------------------------------------------------------

irq_rti2	php
			pha
			phx
			phy
			phz

			asl 0xd019
			bcs rasterirq2
			jmp timerirqimp

rasterirq2:
			ldx #0xff
			stx 0xd30f

			;jsr fontsys_clearscreen
			;jsr keyboard_update
			;jsr program_update

			jsr waitawhile2

			ldx #0x00
			stx 0xd30f

			;lda #0x68
			;sta 0xd04e						; VIC4.TEXTYPOSLSB

			lda #0x60
			sta 0xd012
			sta nextrasterirqline
			lda #.byte0 irq_rti
			sta 0xfffe
			lda #.byte1 irq_rti
			sta 0xffff

			jmp endirq

; ------------------------------------------------------------------------------------

timerirqimp:
			sec								; don't start MOD if there's less than 8 raster lines left to complete it
			lda nextrasterirqline
			sbc 0xd012
			cmp #0x08
			bpl timerirqimp_safe
			jmp endirq

timerirqimp_safe:
			ldx #0xff
			stx 0xd20f
			jsr modplay_play
			ldx #0x00
			stx 0xd20f

			bit 0xdc0d      				; aknowledge timer IRQ - If I don't aknowledge then the timer irq will trigger immediately again
			jmp endirq

; ------------------------------------------------------------------------------------



















/*
			.public irq_main
irq_main:
			php
			pha
			phx
			phy
			phz

			lda #0x03
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

			lda #0x0f
			sta 0xd020
			sta 0xd021

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

*/

			.public program_mainloop
program_mainloop:
			lda 0xc000
			sta 0xc000
			jmp program_mainloop

; ------------------------------------------------------------------------------------

verticalcenter	.word 0

			.public program_setuppalntsc
program_setuppalntsc:

		lda #.byte0 104						; 104 = pal y border start
		sta verticalcenter+0
		lda #.byte1 104
		sta verticalcenter+1

		bit 0xd06f
		bpl setpal

setntsc:
		lda #.byte0 55						; 55 = ntsc y border start
		sta verticalcenter+0
		lda #.byte1 55
		sta verticalcenter+1

setpal:
		lda verticalcenter+0
		sta 0xd048							; VIC4.TBDRPOSLSB
		sta 0xd04e							; VIC4.TEXTYPOSLSB
		lda #0b00001111
		trb 0xd049							; VIC4.TBDRPOSMSB
		lda verticalcenter+1
		tsb 0xd049			

		rts

; ------------------------------------------------------------------------------------

waitawhile:
			ldy #0x1f
			ldx #0x00
irtiw:		lda 0xd020
			dex
			bne irtiw
			dec 0xd10f
			dey
			bne irtiw
			rts

waitawhile2:
			ldy #0x1f
			ldx #0x00
irtiw2:		lda 0xd020
			dex
			bne irtiw2
			dec 0xd30f
			dey
			bne irtiw2
			rts

; ------------------------------------------------------------------------------------

endirq:		plz
			ply
			plx
			pla
			plp
			rti

; ------------------------------------------------------------------------------------
