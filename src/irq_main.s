			.rtmodel cpu, "*"
			
			.extern modplay_play
			.extern keyboard_update
			.extern fontsys_clearscreen
			.extern fontsys_buildlineptrlist
			.extern program_update
			.extern fl_mode
			.extern fl_waiting
			.extern fl_set_filename
			.extern fastload_request
			.extern floppy_fast_load
			.extern _Zp

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

			.public program_mainloopstate
program_mainloopstate
			.byte 0

program_framelo
			.byte 0

program_framehi
			.byte 0

; ------------------------------------------------------------------------------------

			.public irq_main
irq_main
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

			;lda #0x23
			;sta 0xd020

			jsr program_setuppalntsc
			jsr fontsys_clearscreen
			jsr keyboard_update
			jsr program_update

			;lda #0x0f
			;sta 0xd020

			lda verticalcenter+0
			sta 0xd04e						; VIC4.TEXTYPOSLSB

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

irq_main2
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

			lda #0xed
			sta 0xd020
			sta 0xd021

			inc program_framelo

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

irq_main3	php
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

			lda #0xed
			sta 0xd020
			sta 0xd021

			lda #0b00010000
			trb 0xd011

			lda textypos
			sta 0xd04e						; VIC4.TEXTYPOSLSB

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

irq_main4	php
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

			clc
			lda 0xd012
			adc #0x08

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

			clc
			lda verticalcenterhalf
			adc #25*8
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
		bpl setpal

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
		clc
		lda verticalcenterhalf+0
		adc #0x07
		sta verticalcenterhalf+0
		lda verticalcenterhalf+1
		adc #0x00
		sta verticalcenterhalf+1

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

endirq:		plz
			ply
			plx
			pla
			plp
			rti

; ------------------------------------------------------------------------------------

			.public program_mainloop
program_mainloop:
			lda program_mainloopstate
			beq program_mainloop
			cmp #1
			bne pml2
			jsr fontsys_buildlineptrlist
			lda #0
			sta program_mainloopstate
pml2:		cmp #2	; reset
			bne pml3
			jmp program_reset
pml3:		jmp program_mainloop

; ------------------------------------------------------------------------------------

romfilename:	.asciz "MEGA65.ROM"
prgfilename:	.asciz "YAMP65"
mountname:		.asciz "YAMP65.D81"

		.public program_reset
program_reset:

		lda #0x42							; unmount current images
		sta 0xd640
		clv
		
		lda mountname						; set d81 mount name if there is one
		beq skip_mount

		ldx #0x3f
mntlp:	lda mountname,x
		sta 0x0200,x
		dex
		bpl mntlp
		
		ldy #0x02							; set d81 filename from 0x0200
		lda #0x2e							; hyppo_setname
		sta 0xd640
		clv
		
		lda #0x40							; hyppo_d81attach0 - attach d81 image
		sta 0xd640
		clv

skip_mount:

		lda #0x01							; Set fileload mode to non-IFFL
		sta fl_mode

		lda #.byte0 prgfilename
		sta _Zp+0
		lda #.byte1 prgfilename
		sta _Zp+1

		jsr fl_set_filename

		lda #0x01							; Request fastload job
		sta fastload_request
		jsr fl_waiting

		jsr floppy_fast_load

		sei

		lda #0x37
		sta 0x01

		lda #0x00							; unmap upper 8 bits
		ldx #0x0f
		ldy #0x00
		ldz #0x0f
		map

		lda #0x00							; unmap lower 20 bits
		ldx #0x00
		ldy #0x00
		ldz #0x00
		map
		eom

		lda #0x00							; clear INTRO4.D81 string
		sta 0x11b2

		lda #0x02							; Disable C65 ROM write protection via Hypervisor trap
		sta 0xd641
		clv
		
		ldx #0x0b							; copy rom filename to bank 0
prsfn$:	lda romfilename,x
		sta 0x0200,x
		dex
		bpl prsfn$
		
		ldy #0x02							; set rom filename
		lda #0x2e
		sta 0xd640
		clv
		
		lda #0x00							; load rom file to $20000
		tax
		tay
	    ldz #0x02
	    lda #0x36
	    sta 0xd640
	    clv

		lda #0b00100000						; Disable $c000 mapping via $d030 as we want to write to interface rom.
		trb 0xd030							; Writing to rom is not possible via $d030. We'll use map for writing instead.

		lda #0xff							; unmap maphmb, while keeping maplmb
		ldx #0x0f
		ldy #0x00
		ldz #0x0f
		map

		lda #0x00							; mapping of interface rom $2c000 at $c000
		ldx #0x00							; (enables writing to rom, but also hides i/o for now as a side effect)
		ldy #0x00
		ldz #0x42
		map
		eom
		
		ldx #0x00							; copy autostart routine to $c700. in xemu check: d 2c700
carc700:	lda runmeafterreset,x
		sta 0xc700,x
		inx
		bne carc700

		lda #0x07							; patch basic IRQ vector. in xemu : d 32007
		sta 0x80
		lda #0x20
		sta 0x81
		lda #0x03
		sta 0x82
		lda #0x00
		sta 0x83

		ldz #0x00
		lda #.byte0 0xc700
		sta [0x80],z
		inz
		lda #.byte1 0xc700
		sta [0x80],z

		lda #0x00							; unmap $c000 rom to make I/O available again
		ldx #0x8d
		ldy #0x00
		ldz #0x00
		map
		eom

		lda #0b00100000						; activate $c000 rom read-only again via $d030
		tsb 0xd030
		
		lda #0x00							; restore rom write protection
		sta 0xd641
		clv

		lda #0x00							; set basepage to zeropage
		tab

		lda #0x82							; unmap SD sector buffer
		sta 0xd680

		lda #0b10000000						; Set bit 7 - HOTREG
		tsb 0xd05d
		
		lda #0x00
		sta 0xd070							; restore palette
		sta 0xd076							; disable SPRENV400
		sta 0xd711							; disable audio DMA
		sta 0xd720							; stop audio playback
		sta 0xd730
		sta 0xd740
		sta 0xd750

		lda #0b11010111
		trb 0xd054							; disable Super-Extended Attribute Mode

		lda #0x00							; do final unmap and perform reset
		ldx #0x0f
		ldy #0x00
		ldz #0x0f
		map

		lda #0x00
		ldx #0x00
		ldy #0x00
		ldz #0x00
		map
		eom

		jmp (0xfffc)

runmeafterreset:
		sei

		sta 0xd707							; inline DMA copy
		.byte 0x80, (0x00050000 >> 20)		; sourcemb
		.byte 0x81, (0x00000000 >> 20)		; destmb
		.byte 0x00							; end of job options
		.byte 0x00							; copy
		.word 0xa700						; count
		.word 0x0002						; src
		.byte (0x00050000 >> 16)			; src bank
		.word 0x2001						; dst
		.byte (0x00000000 >> 16)			; dst bank
		.byte 0x00							; cmd hi
		.word 0x0000						; modulo, ignored

		lda #0x52	; R
		sta 0x2b0
		lda #0x55	; U
		sta 0x2b1
		lda #0x4e	; N
		sta 0x2b2
		lda #0x0d	; <cr>
		sta 0x2b3
		lda #0x04
		sta 0xd0

		lda #0x49							; revert INTRO4.D81 string
		sta 0x11b2

		cli
		rts

		;jmp 0x2006

; ------------------------------------------------------------------------------------
