					.public fadepal_complete
fadepal_complete	.byte 0
vblankcount			.byte 0

fadestep			.equ 4
nstable				.equ 0xc500

palette				.equ 0xe000

; ------------------------------------------------------------------------------------

		.public fadepal_init
fadepal_init:
		lda #0x00
		sta fadepal_complete
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

		lda fadepal_complete
		bne irq_fadeout_end

		jsr fadepal_decrease				; palette gets decreased by fadestep

		inc vblankcount
		lda vblankcount
		cmp #(256/fadestep)					; if fadestep is 4 then we need 256/4 = 64 frames to completely fadeout
		bne irq_fadeout_end

fadeout_done:
		lda #0x01
		sta fadepal_complete 

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

fadepal_decrease:
		ldx #0x00

fadepal_decrease_loop:
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
		bne fadepal_decrease_loop

		rts

; ------------------------------------------------------------------------------------

		.public fadepal_increase
fadepal_increase:

		lda fadepal_complete
		beq fpi2$
		rts

fpi2$:
		lda #0x00
		sta 0xd770	; MULTINA
		sta 0xd771
		sta 0xd772
		sta 0xd773
		sta 0xd774	; MULTINB
		sta 0xd775
		sta 0xd776
		sta 0xd777

		inc vblankcount
		lda vblankcount
		asl a		; assume fadestep of 4
		rol a
		bcc fadein_continue

fadein_done:
		lda #0x01
		sta fadepal_complete
		ldx #0
fpi3$:	lda palette+0*0x0100,x
		sta 0xd100,x
		lda palette+1*0x0100,x
		sta 0xd200,x
		lda palette+2*0x0100,x
		sta 0xd300,x
		inx
		bne fpi3$
		rts

fadein_continue:
		
		sta 0xd770	; MULTINA0

		ldx #0

increasepaletteloop:

		lda palette+0*0x0100,x
		tay
		lda nstable,y
		sta 0xd774
		ldy 0xd779
		lda nstable,y
		sta 0xd100,x

		lda palette+1*0x0100,x
		tay
		lda nstable,y
		sta 0xd774
		ldy 0xd779
		lda nstable,y
		sta 0xd200,x

		lda palette+2*0x0100,x
		tay
		lda nstable,y
		sta 0xd774
		ldy 0xd779
		lda nstable,y
		sta 0xd300,x

		inx
		bne increasepaletteloop

		rts

; ------------------------------------------------------------------------------------
