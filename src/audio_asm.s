			.rtmodel cpu, "*"

; ------------------------------------------------------------------------------------

				.public audio_volume
audio_volume    .byte 0

; ------------------------------------------------------------------------------------

		.public audio_applyvolume
audio_applyvolume

		ldx #0x00							; reset audio xbar coefficients
raxbc:	stx 0xd6f4
		lda 0xd020
		sta 0xd021
		lda 0xd020
		sta 0xd021
		lda audio_volume
		sta 0xd6f5
		inx
		bne raxbc
		rts

; ------------------------------------------------------------------------------------		