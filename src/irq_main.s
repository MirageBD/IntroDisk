			.rtmodel cpu, "*"
			
			.extern modplay_play
			.extern keyboard_update
			.extern program_update
			.extern _Zp
			.extern fadepal_increase

; ------------------------------------------------------------------------------------

			.public nextrasterirqlinelo
nextrasterirqlinelo:
			.byte 0

			.public nextrasterirqlinehi
nextrasterirqlinehi:
			.byte 0

			.public textypos
textypos:	.byte 0x34*2+5*0x10

			.public verticalcenter
verticalcenter
			.word 0

			.public verticalcenterhalf
verticalcenterhalf
			.word 0

program_framelo
			.byte 0

program_framehi
			.byte 0

; ------------------------------------------------------------------------------------

			.public irq_main
irq_main									; IRQ that starts at lower border
			php
			pha
			phx
			phy
			phz

			lda nextrasterirqlinelo			; if we're on the raster IRQ line then we should defo be a raster IRQ
			cmp 0xd012
			beq irq_main_raster
			asl 0xd019						; acknowledge raster IRQ and test if this was a timer IRQ or not using what's in carry now
			bcs irq_main_raster
			jmp timerirqimp					; IRQ was a timer IRQ

irq_main_raster:
			asl 0xd019						; make sure that raster IRQ is aknowledged

			lda #0b00010000					; disable screen
			trb 0xd011

			lda #0x00
			sta 0xd020
			sta 0xd021

			lda #0x00
			sta 0xd100
			sta 0xd200
			sta 0xd300

			jsr fadepal_increase

			;lda #0x36 ; green
			;sta 0xd020
			jsr program_setuppalntsc
			;lda #0x26 ; orange
			;sta 0xd020
			jsr keyboard_update
			;lda #0x16 ; blue
			;sta 0xd020
			jsr program_update
			;lda #0x0f
			;sta 0xd020

			; reset textypos for top logo
			lda verticalcenter+0
			sta 0xd04e						; VIC4.TEXTYPOSLSB
			lda #0x00
			sta 0xd04f						; VIC4.TEXTYPOSMSB

			lda #0b10000000
			trb 0xd011
			lda verticalcenterhalf+0
			sec
			sbc #0x06
			sta 0xd012
			sta nextrasterirqlinelo
			lda #0
			sta nextrasterirqlinehi
			lda #.byte0 irq_main2
			sta 0xfffe
			sta 0x0314
			lda #.byte1 irq_main2
			sta 0xffff
			sta 0x0315

			jmp endirq

; ------------------------------------------------------------------------------------

irq_main2									; IRQ just above logo
			php
			pha
			phx
			phy
			phz

waitlowerborder:							; TEMP TEMP FIX FOR THIS RASTER IRQ STARTING IN LOWER BORDER INSTEAD OF UPPER
			bit 0xd011
			bmi waitlowerborder

			lda nextrasterirqlinelo			; if we're on the raster IRQ line then we should defo be a raster IRQ
			cmp 0xd012
			beq irq_main2_raster
			asl 0xd019						; acknowledge raster IRQ and test if this was a timer IRQ or not using what's in carry now
			bcs irq_main2_raster
			jmp timerirqimp					; IRQ was a timer IRQ

irq_main2_raster:
			asl 0xd019						; make sure that raster IRQ is aknowledged

			lda 0xd012
stableraster1:
			cmp 0xd012
			beq stableraster1

			lda #0b00010000					; enable screen
			tsb 0xd011

			inc program_framelo

			ldx #00
rasterloop			
			lda colbars_r,x
			sta 0xd100
			lda colbars_g,x
			sta 0xd200
			lda colbars_b,x
			sta 0xd300
			lda 0xd012
			clc
			adc #01
waitras		cmp 0xd012
			bne waitras
			inx
			cpx #0x2c
			bne rasterloop


			clc
			lda verticalcenterhalf+0
			adc #5*8
			sta 0xd012
			sta nextrasterirqlinelo
			lda #0
			sta nextrasterirqlinehi
			lda #.byte0 irq_main3
			sta 0xfffe
			sta 0x0314
			lda #.byte1 irq_main3
			sta 0xffff
			sta 0x0315

			jmp endirq

; ------------------------------------------------------------------------------------

irq_main3									; IRQ for smooth scrolling of text underneath logo
			php
			pha
			phx
			phy
			phz

			lda nextrasterirqlinelo			; if we're on the raster IRQ line then we should defo be a raster IRQ
			cmp 0xd012
			beq irq_main3_raster
			asl 0xd019
			bcs irq_main3_raster
			jmp timerirqimp

irq_main3_raster:
			asl 0xd019						; make sure that raster IRQ is aknowledged

			lda #0b00010000					; disable screen
			trb 0xd011

			lda textypos
			sta 0xd04e						; VIC4.TEXTYPOSLSB

			clc
			lda 0xd012
			adc #0x08
blnkwait	cmp 0xd012
			bne blnkwait

			lda #0b00010000					; enable screen
			tsb 0xd011

			lda #0x02
			sta 0xd100
			sta 0xd200
			sta 0xd300

			clc
			lda verticalcenterhalf
			adc #14*8-1
			sta 0xd012
			sta nextrasterirqlinelo
			lda #0
			sta nextrasterirqlinehi
			lda #.byte0 irq_main4
			sta 0xfffe
			lda #.byte1 irq_main4
			sta 0xffff

			jmp endirq

; ------------------------------------------------------------------------------------

irq_main4									; IRQ to draw selection line
			php
			pha
			phx
			phy
			phz

			lda nextrasterirqlinelo			; if we're on the raster IRQ line then we should defo be a raster IRQ
			cmp 0xd012
			beq irq_main4_raster
			asl 0xd019
			bcs irq_main4_raster
			jmp timerirqimp

irq_main4_raster:
			asl 0xd019						; make sure that raster IRQ is aknowledged

			lda 0xd012
stableraster2:
			cmp 0xd012
			beq stableraster2

			clc								; get rasterline at which we should turn off the selection line again
			lda 0xd012
			adc #0x08

			ldx #0x04
			stx 0xd100
			stx 0xd200
			stx 0xd300

waitr2$:	cmp 0xd012
			bne waitr2$

			lda #0x02
			sta 0xd100
			sta 0xd200
			sta 0xd300

			jsr fillrasters					; stick filling of rasters here for now

			clc
			lda verticalcenterhalf
			adc #24*8
			sta 0xd012
			sta nextrasterirqlinelo
			lda #0
			sta nextrasterirqlinehi
			lda #.byte0 irq_main
			sta 0xfffe
			lda #.byte1 irq_main
			sta 0xffff

			jmp endirq

; ------------------------------------------------------------------------------------

timerirqimp:
			sec								; don't start MOD if there's less than 8 raster lines left to complete it
			lda nextrasterirqlinelo
			sbc 0xd012
			cmp #0x10
			bpl timerirqimp_safe

timerirqimp_notsafe:
			jmp endirq

timerirqimp_safe:
			bit 0xdc0d      				; aknowledge timer IRQ - If I don't aknowledge then the timer irq will trigger immediately again

			;lda #0xff
			;sta 0xd20f
			jsr modplay_play
			;lda #0x00
			;sta 0xd20f

			jmp endirq

; ------------------------------------------------------------------------------------

		.public program_setuppalntsc
program_setuppalntsc:

		lda #.byte0 0x0068					; $68 = #104 = pal y border start
		sta verticalcenter+0
		lda #.byte1 0x0068
		sta verticalcenter+1
		lda verticalcenter+1
		lsr a
		sta verticalcenterhalf+1
		lda verticalcenter+0
		ror a
		sta verticalcenterhalf+0

		bit 0xd06f
		bpl setborders

setntsc:
		lda #.byte0 0x002a					; $37 = #55 = ntsc y border start
		sta verticalcenter+0
		lda #.byte1 0x002a
		sta verticalcenter+1
		lda verticalcenter+1
		lsr a
		sta verticalcenterhalf+1
		lda verticalcenter+0
		ror a
		sta verticalcenterhalf+0

		lda 0xd60f
		and #0b00100000
		beq skiprealHWfudge					; if 0 (=NOT REALHW, then skip fudge)

		clc
		lda verticalcenterhalf+0
		adc #0x07							; have to add 7 for things to work on real HW
		sta verticalcenterhalf+0
		lda verticalcenterhalf+1
		adc #0x00
		sta verticalcenterhalf+1

skiprealHWfudge:

setborders:
		lda verticalcenter+0
		sta 0xd048							; VIC4.TBDRPOSLSB
		sta 0xd04e							; VIC4.TEXTYPOSLSB
		lda #0b00001111
		trb 0xd049							; VIC4.TBDRPOSMSB
		lda verticalcenter+1
		tsb 0xd049

		lda #0b00001111
		trb 0xd04b							; VIC4.BBDRPOSMSB
		clc
		lda verticalcenter+0
		adc #0xc0							; add $0180 (#400 - 16) for bottom border
		sta 0xd04a							; VIC4.BBDRPOSLSB
		lda verticalcenter+1
		adc #0x01
		tsb 0xd04b

		rts

; ------------------------------------------------------------------------------------

endirq:		plz
			ply
			plx
			pla
			plp
			rti

; ------------------------------------------------------------------------------------

fillrasters:

			ldx #0x2c
			lda #0x00
frc$:		sta colbars_r,x
			sta colbars_g,x
			sta colbars_b,x
			dex
			bpl frc$

			ldy #0x00
			lda #4+0*10
			jsr drawbar

			ldy #0x01
			lda #4+1*10
			jsr drawbar

			ldy #0x02
			lda #4+2*10
			jsr drawbar

			ldy #0x03
			lda #4+3*10
			jsr drawbar

			rts

; ------------------------------------------------------------------------------------

drawbar:
			sta dbr+1
			sta dbg+1
			sta dbb+1

			ldx #0x00
frcr:		lda colr,y
dbr:		sta colbars_r,x
			lda colg,y
dbg:		sta colbars_g,x
			lda colb,y
dbb:		sta colbars_b,x
			inx
			cpx #0x08
			bne frcr
			rts

; ------------------------------------------------------------------------------------

colr		.byte 0x00, 0x00, 0x08, 0x07
colg		.byte 0x02, 0x04, 0x05, 0x00
colb		.byte 0x04, 0x00, 0x00, 0x00

			.public colbars_r
			.align 256
colbars_r
			.space 44

			.public colbars_g
			.align 256
colbars_g
			.space 44

			.public colbars_b
			.align 256
colbars_b
			.space 44
