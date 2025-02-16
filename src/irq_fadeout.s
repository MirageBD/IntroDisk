				.public fadeoutcomplete
fadeoutcomplete .byte 0
vblankcount     .byte 0

fadestep		.equ 4
nstable         .equ 0xc500

; ------------------------------------------------------------------------------------

		.public fadeout_init
fadeout_init
		lda #0x00
		sta fadeoutcomplete
		sta vblankcount
		rts		

; ------------------------------------------------------------------------------------

		.public irq_fadeout
irq_fadeout:

		php
		pha
		txa
		pha
		tya
		pha

		lda fadeoutcomplete
		bne irq_fadeout_end

		jsr decreasepalette

		inc vblankcount
		lda vblankcount
		cmp #(256/fadestep)
		bne irq_fadeout_end

fadeout_done:
		lda #0x01
		sta fadeoutcomplete 

irq_fadeout_end:
		pla
		tay
		pla
		tax
		pla
		plp
		asl 0xd019
		rti

; ------------------------------------------------------------------------------------

decreasepalette:
		ldx #0x00

decreasepaletteloop:
		lda 0xd100,x
		tay
		lda nstable,y
		sec
		sbc #fadestep
		bcs dpl2$
		lda #0x00
dpl2$:	tay
		lda nstable,y
		sta 0xd100,x

		lda 0xd200,x
		tay
		lda nstable,y
		sec
		sbc #fadestep
		bcs dpl3$
		lda #0x00
dpl3$:	tay
		lda nstable,y
		sta 0xd200,x

		lda 0xd300,x
		tay
		lda nstable,y
		sec
		sbc #fadestep
		bcs dpl4$
		lda #0x00
dpl4$:	tay
		lda nstable,y
		sta 0xd300,x

		inx
		bne decreasepaletteloop

		rts

; ------------------------------------------------------------------------------------