					.public fadepal_complete
fadepal_complete	.byte 0

					.public fadepal_value
fadepal_value		.byte 0xff

fadepal_step		.equ 4

					.public nstable
nstable				.equ 0xc700

palette				.equ 0xe900

; ------------------------------------------------------------------------------------

		.public fadepal_init
fadepal_init:
		lda #0x00
		sta fadepal_complete
		rts

; ------------------------------------------------------------------------------------

		.public irq_fadeout
irq_fadeout:

		php
		pha
		phx
		phy
		phz

		jsr fadepal_decrease				; palette gets decreased by fadestep

		plz
		ply
		plx
		pla
		plp
		asl 0xd019
		rti

; ------------------------------------------------------------------------------------

fadepal_decrease:

		lda fadepal_complete
		beq fpd2$
		rts

fpd2$:	sec
		lda fadepal_value
		sbc #fadepal_step
		sta fadepal_value
		bcs fadepal_decrease_continue

fadepal_decrease_done:
		lda #0x00
		sta fadepal_value
		lda #0x01
		sta fadepal_complete 
		rts

fadepal_decrease_continue:

		ldx #0x01

fadepal_decrease_loop:
		lda 0xd100,x
		tay
		lda nstable,y
		sec
		sbc #fadepal_step
		bcs dpl2$
		lda #0x00
dpl2$:	tay
		lda nstable,y
		sta 0xd100,x

		lda 0xd200,x
		tay
		lda nstable,y
		sec
		sbc #fadepal_step
		bcs dpl3$
		lda #0x00
dpl3$:	tay
		lda nstable,y
		sta 0xd200,x

		lda 0xd300,x
		tay
		lda nstable,y
		sec
		sbc #fadepal_step
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

fpi2$:	clc
		lda fadepal_value
		adc #fadepal_step
		sta fadepal_value
		bcc fadepal_increase_continue

fadepal_increase_done:						; done increasing to $ff. set to full brightness
		lda #0xff
		sta fadepal_value
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

fadepal_increase_continue:
		
		sta 0xd770	; MULTINA0

		lda #0x00
		sta 0xd771
		sta 0xd772
		sta 0xd773
		sta 0xd775
		sta 0xd776
		sta 0xd777

		ldx #1

fadepal_increase_loop:

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
		bne fadepal_increase_loop

		rts

; ------------------------------------------------------------------------------------
