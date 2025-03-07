			.rtmodel cpu, "*"
			
			.extern modplay_play
			.extern keyboard_update
			.extern program_update
			.extern _Zp
			.extern fadepal_increase

			.extern nstable
			.extern fadepal_value

			.extern program_realhw

; ------------------------------------------------------------------------------------

			.public nextrasterirqlinelo
nextrasterirqlinelo:
			.byte 0

			.public nextrasterirqlinehi
nextrasterirqlinehi:
			.byte 0

			.public textypos
textypos:	.byte 0x34*2+5*0x10

			.public textyposoffset
textyposoffset:	.byte 0

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

fnts_screentablo:		.equ 0xc600+0*64 ; 64 big		; .byte <(screen          + rrbscreenwidth2 * I)

			.public colbars_r
colbars_r:	.equ 0xcb00

			.public colbars_g
colbars_g:	.equ 0xcc00

			.public colbars_b
colbars_b:	.equ 0xcd00

palette		.equ 0xe900

; ------------------------------------------------------------------------------------

waituntilbackporchstart:
wubps1:		lda 0xd051
			and #0x0f
			cmp #.byte1 720
			bne wubps1
wubps2:		lda 0xd050
			cmp #.byte0 720
			bcs wubps2
			rts

setcol0:	jsr waituntilbackporchstart
			lda #0x00
			sta 0xd100
			sta 0xd200
			sta 0xd300
			rts

setcol4:	jsr waituntilbackporchstart
			lda colrfaded+4
			sta 0xd100
			lda colgfaded+4
			sta 0xd200
			lda colbfaded+4
			sta 0xd300
			rts

setcol5:	jsr waituntilbackporchstart
			lda colrfaded+5
			sta 0xd100
			lda colgfaded+5
			sta 0xd200
			lda colbfaded+5
			sta 0xd300
			rts

; ------------------------------------------------------------------------------------

setbordercolour:
			ldx #0x40
sbc01:		dex
			bne sbc01
			sta 0xd021
			ldy #0x02
sbc02:		ldx #0xe0
sbc03:		dex
			bne sbc03
			dey
			bne sbc02
			sta 0xd020
			rts

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

			lda #0b00010000					; enable screen
			tsb 0xd011

			lda #0x00
			sta 0xd020
			sta 0xd021

			jsr fadepal_increase
			jsr faderastercolors
			jsr fillrasters					; stick filling of rasters here for now
			
			;lda #0x36 ; green
			;sta 0xd020
			;lda #0x26 ; orange
			;sta 0xd020
			jsr keyboard_update
			;lda #0x16 ; blue
			;sta 0xd020
			jsr program_update
			;lda #0x0f
			;sta 0xd020

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

			jsr program_setuppalntsc

			; reset textypos for top logo
			lda verticalcenter+0
			sta 0xd04e						; VIC4.TEXTYPOSLSB
			lda #0x00
			sta 0xd04f						; VIC4.TEXTYPOSMSB

			lda 0xd012
stableraster1:
			cmp 0xd012
			beq stableraster1

			lda #0b00010000					; enable screen
			tsb 0xd011

			lda #.byte0 0x3000				; LOGO_COLOR_RAM_OFFSET
			sta 0xd064
			lda #.byte1 0x3000
			sta 0xd065

			lda #.byte0 0xf800				; LOGOFINALSCREEN
			sta 0xd060
			lda #.byte1 0xf800
			sta 0xd061

			inc program_framelo

			ldx #00
rasterloop:	lda colbars_r,x
			sta 0xd100
			lda colbars_g,x
			sta 0xd200
			lda colbars_b,x
			sta 0xd300
			lda 0xd012
			clc
			adc #01
waitras:	cmp 0xd012
			bne waitras
			inx
			cpx #0x2a
			bne rasterloop

			lda #0x00
			sta 0xd100
			sta 0xd200
			sta 0xd300

			clc
			lda verticalcenterhalf+0
			adc #5*8-1
			;sec								; sub -1 for realHW because we want to change the screenptr before the next char starts rendering
			;sbc program_realhw				; BECAUSE XEMU IS STUPID AND NOTHING GETS FIXED
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

			lda #.byte0 (0x0800-10*160)		; COLOR_RAM_OFFSET
			sta 0xd064
			lda #.byte1 (0x0800-10*160)
			sta 0xd065

			lda #.byte0 (0xa000-10*160)		; SCREEN RRBSCREENWIDTH2
			sta 0xd060
			lda #.byte1 (0xa000-10*160)
			sta 0xd061

			clc
			lda 0xd012
			adc #0x09
waitforme:	cmp 0xd012
			bne waitforme

			lda #0b00010000					; disable screen
			trb 0xd011

			lda textypos
			sta 0xd04e						; VIC4.TEXTYPOSLSB

			clc
			lda 0xd012
			adc #0x08
blnkwait	cmp 0xd012
			bne blnkwait

			jsr setcol4

			lda #0b00010000					; enable screen
			tsb 0xd011

			clc
			lda verticalcenterhalf
			adc #14*8
			sta 0xd012
			sta nextrasterirqlinelo
			lda #0
			sta nextrasterirqlinehi
			lda #.byte0 irq_main4
			sta 0xfffe
			sta 0x0314
			lda #.byte1 irq_main4
			sta 0xffff
			sta 0x0315

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

			jsr setcol5

			clc								; get rasterline at which we should turn off the selection line again
			lda 0xd012
			adc #0x08

waitr2$:	cmp 0xd012
			bne waitr2$

			jsr setcol4

			lda #0xf3						; TODO - Calculate using screenoffset and stuff
			sta 0xd012
			sta nextrasterirqlinelo
			lda #0
			sta nextrasterirqlinehi
			lda #.byte0 irq_main5
			sta 0xfffe
			sta 0x0314
			lda #.byte1 irq_main5
			sta 0xffff
			sta 0x0315

			jmp endirq

; ------------------------------------------------------------------------------------

irq_main5									; IRQ before bottom border
			php
			pha
			phx
			phy
			phz

			lda nextrasterirqlinelo			; if we're on the raster IRQ line then we should defo be a raster IRQ
			cmp 0xd012
			beq irq_main5_raster
			asl 0xd019
			bcs irq_main5_raster
			jmp timerirqimp

irq_main5_raster:
			asl 0xd019						; make sure that raster IRQ is aknowledged

			lda #0b00010000					; disable screen
			trb 0xd011

			jsr setcol0

			clc
			lda textyposoffset
			lsr a
			adc #0xf5
			sta 0xd012
			sta nextrasterirqlinelo
			lda #0
			sta nextrasterirqlinehi
			lda #.byte0 irq_main6
			sta 0xfffe
			lda #.byte1 irq_main6
			sta 0xffff

			jmp endirq

; ------------------------------------------------------------------------------------

irq_main6									; IRQ before bottom border
			php
			pha
			phx
			phy
			phz

			lda nextrasterirqlinelo			; if we're on the raster IRQ line then we should defo be a raster IRQ
			cmp 0xd012
			beq irq_main6_raster
			asl 0xd019
			bcs irq_main6_raster
			jmp timerirqimp

irq_main6_raster:
			asl 0xd019						; make sure that raster IRQ is aknowledged

			lda #0xfc
			sta 0xd04e
			lda #0x01
			sta 0xd04f

			lda #0b00010000					; enable screen
			tsb 0xd011

			clc
			lda #0xfe
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

		lda program_realhw
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

			lda program_framelo
			asl a
			sta sinframe

			ldy #0x00
			clc
			ldx program_framelo
			lda id4sine+0*20,x
			lsr a
			lsr a
			lsr a
			lsr a
			adc #0x06
			sta barheight+1
			ldx sinframe
			lda id4sine+0*40,x
			lsr a
			lsr a
			lsr a
			lsr a
			adc #0x05
			jsr drawbar

			ldy #0x01
			clc
			ldx program_framelo
			lda id4sine+1*20,x
			lsr a
			lsr a
			lsr a
			lsr a
			adc #0x06
			sta barheight+1
			ldx sinframe
			lda id4sine+1*40,x
			lsr a
			lsr a
			lsr a
			lsr a
			adc #0x05
			jsr drawbar

			ldy #0x02
			clc
			ldx program_framelo
			lda id4sine+2*20,x
			lsr a
			lsr a
			lsr a
			lsr a
			adc #0x06
			sta barheight+1
			ldx sinframe
			lda id4sine+2*40,x
			lsr a
			lsr a
			lsr a
			lsr a
			adc #0x05
			jsr drawbar

			ldy #0x03
			clc
			ldx program_framelo
			lda id4sine+3*20,x
			lsr a
			lsr a
			lsr a
			lsr a
			adc #0x06
			sta barheight+1
			ldx sinframe
			lda id4sine+3*40,x
			lsr a
			lsr a
			lsr a
			lsr a
			adc #0x05
			jsr drawbar

			rts

sinframe	.byte 0

; ------------------------------------------------------------------------------------

drawbar:
			sta dbr1+1
			sta dbg1+1
			sta dbb1+1
			sta dbr2+1
			sta dbg2+1
			sta dbb2+1

			ldx #0x00
frcr:
			clc
dbr1:		lda colbars_r,x
			adc colrfaded,y
dbr2:		sta colbars_r,x

			clc
dbg1:		lda colbars_g,x
			adc colgfaded,y
dbg2:		sta colbars_g,x

			clc
dbb1:		lda colbars_b,x
			adc colbfaded,y
dbb2:		sta colbars_b,x

			inx
barheight:	cpx #0x0a
			bne frcr
			rts

; ------------------------------------------------------------------------------------

fadecolor:
			tay
			lda nstable,y
			sta 0xd774
			ldy 0xd779
			lda nstable,y
			rts

faderastercolors:

			lda #0x00
			sta 0xd771
			sta 0xd772
			sta 0xd773
			sta 0xd775
			sta 0xd776
			sta 0xd777

			lda fadepal_value
			sta 0xd770	; MULTINA0

			ldx #0x00
frcloop:	lda colr,x
			jsr fadecolor
			sta colrfaded,x

			lda colg,x
			jsr fadecolor
			sta colgfaded,x

			lda colb,x
			jsr fadecolor
			sta colbfaded,x

			lda colrfaded,x
			sta 0xd100+0xd0,x
			lda colgfaded,x
			sta 0xd200+0xd0,x
			lda colbfaded,x
			sta 0xd300+0xd0,x

			inx
			cpx #0x06
			bne frcloop

			rts

; ------------------------------------------------------------------------------------

colr		.byte 0x00, 0x00, 0x08, 0x07, 0x81, 0x82
colg		.byte 0x02, 0x07, 0x05, 0x00, 0x81, 0x82
colb		.byte 0x07, 0x02, 0x00, 0x00, 0x81, 0x82

colrfaded	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
colgfaded	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
colbfaded	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

			.align 256
id4sine:
    .byte  128, 131, 134, 137, 140, 143, 146, 149, 152, 156, 159, 162, 165, 168, 171, 174
    .byte  176, 179, 182, 185, 188, 191, 193, 196, 199, 201, 204, 206, 209, 211, 213, 216
    .byte  218, 220, 222, 224, 226, 228, 230, 232, 234, 236, 237, 239, 240, 242, 243, 245
    .byte  246, 247, 248, 249, 250, 251, 252, 252, 253, 254, 254, 255, 255, 255, 255, 255
    .byte  255, 255, 255, 255, 255, 255, 254, 254, 253, 252, 252, 251, 250, 249, 248, 247
    .byte  246, 245, 243, 242, 240, 239, 237, 236, 234, 232, 230, 228, 226, 224, 222, 220
    .byte  218, 216, 213, 211, 209, 206, 204, 201, 199, 196, 193, 191, 188, 185, 182, 179
    .byte  176, 174, 171, 168, 165, 162, 159, 156, 152, 149, 146, 143, 140, 137, 134, 131
    .byte  128, 124, 121, 118, 115, 112, 109, 106, 103,  99,  96,  93,  90,  87,  84,  81
    .byte   79,  76,  73,  70,  67,  64,  62,  59,  56,  54,  51,  49,  46,  44,  42,  39
    .byte   37,  35,  33,  31,  29,  27,  25,  23,  21,  19,  18,  16,  15,  13,  12,  10
    .byte    9,   8,   7,   6,   5,   4,   3,   3,   2,   1,   1,   0,   0,   0,   0,   0
    .byte    0,   0,   0,   0,   0,   0,   1,   1,   2,   3,   3,   4,   5,   6,   7,   8
    .byte    9,  10,  12,  13,  15,  16,  18,  19,  21,  23,  25,  27,  29,  31,  33,  35
    .byte   37,  39,  42,  44,  46,  49,  51,  54,  56,  59,  62,  64,  67,  70,  73,  76
    .byte   79,  81,  84,  87,  90,  93,  96,  99, 103, 106, 109, 112, 115, 118, 121, 124

    .byte  128, 131, 134, 137, 140, 143, 146, 149, 152, 156, 159, 162, 165, 168, 171, 174
    .byte  176, 179, 182, 185, 188, 191, 193, 196, 199, 201, 204, 206, 209, 211, 213, 216
    .byte  218, 220, 222, 224, 226, 228, 230, 232, 234, 236, 237, 239, 240, 242, 243, 245
    .byte  246, 247, 248, 249, 250, 251, 252, 252, 253, 254, 254, 255, 255, 255, 255, 255
    .byte  255, 255, 255, 255, 255, 255, 254, 254, 253, 252, 252, 251, 250, 249, 248, 247
    .byte  246, 245, 243, 242, 240, 239, 237, 236, 234, 232, 230, 228, 226, 224, 222, 220
    .byte  218, 216, 213, 211, 209, 206, 204, 201, 199, 196, 193, 191, 188, 185, 182, 179
    .byte  176, 174, 171, 168, 165, 162, 159, 156, 152, 149, 146, 143, 140, 137, 134, 131
    .byte  128, 124, 121, 118, 115, 112, 109, 106, 103,  99,  96,  93,  90,  87,  84,  81
    .byte   79,  76,  73,  70,  67,  64,  62,  59,  56,  54,  51,  49,  46,  44,  42,  39
    .byte   37,  35,  33,  31,  29,  27,  25,  23,  21,  19,  18,  16,  15,  13,  12,  10
    .byte    9,   8,   7,   6,   5,   4,   3,   3,   2,   1,   1,   0,   0,   0,   0,   0
    .byte    0,   0,   0,   0,   0,   0,   1,   1,   2,   3,   3,   4,   5,   6,   7,   8
    .byte    9,  10,  12,  13,  15,  16,  18,  19,  21,  23,  25,  27,  29,  31,  33,  35
    .byte   37,  39,  42,  44,  46,  49,  51,  54,  56,  59,  62,  64,  67,  70,  73,  76
    .byte   79,  81,  84,  87,  90,  93,  96,  99, 103, 106, 109, 112, 115, 118, 121, 124