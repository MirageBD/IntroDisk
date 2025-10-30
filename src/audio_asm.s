			.rtmodel cpu, "*"

; ------------------------------------------------------------------------------------

				.public audio_volume
audio_volume    .byte 0
master_vols			.space 8	; stores 16-bit values for HDMI-left/right and headphones-left/right

; ------------------------------------------------------------------------------------

transform_x_to_master_coeff_idx:
		txa
		clc
		; multiply by 32 (so either 0x00, 0x20, 0x40, 0x60, 0x80, 0xA0, 0xC0, 0xE0)
		;   (the start index of each output channel's co-efficient group)
		rol a
		rol a
		rol a
		rol a
		rol a

		; skip to row 15 of group (the master control for this output group)
		clc
		adc #0x1e
		tax

		rts

; ------------------------------------------------------------------------------------

dummy_delay:
		lda 0xd020
		sta 0xd021
		lda 0xd020
		sta 0xd021
		rts

; ------------------------------------------------------------------------------------

audio_applyvolume_to_output_channel:
; input:
; - X = output channel (0 - 7)
; - 'audio_volume' stores the volume we want to set it to
;   (the value is set for both the low and high byte of the full 16-bit co-efficient)

		jsr transform_x_to_master_coeff_idx

		; apply desired volume level to co-efficient

		; high byte
		stx 0xd6f4
		jsr dummy_delay
		lda audio_volume
		sta 0xd6f5

		; low byte
		inx
		stx 0xd6f4
		jsr dummy_delay
		lda audio_volume
		sta 0xd6f5
		rts

; ------------------------------------------------------------------------------------

audio_save_output_channel_master_volume:
; input:
; - X = output channel (0 - 7)
; - Y = index into master_vols

		jsr transform_x_to_master_coeff_idx

		; high byte
		stx 0xd6f4
		jsr dummy_delay
		lda 0xd6f5
		sta master_vols,y

		; low byte
		inx
		stx 0xd6f4
		jsr dummy_delay
		lda 0xd6f5
		iny
		sta master_vols,y

		iny
		rts

; ------------------------------------------------------------------------------------

		.public audio_save_master_volumes
audio_save_master_volumes:
; call this prior to fiddling with any mixer audio settings, to preserve user's preference for HDMI and headphone audio levels

			ldy #0x00	; index to write into master_vols array

			; HDMI-LEFT
			ldx #0x00
			jsr audio_save_output_channel_master_volume

			; HDMI-RIGHT
			ldx #0x01
			jsr audio_save_output_channel_master_volume

			; HEADPHONES-LEFT
			ldx #0x06
			jsr audio_save_output_channel_master_volume

			; HEADPHONES-RIGHT
			ldx #0x07
			jsr audio_save_output_channel_master_volume

			rts

; ------------------------------------------------------------------------------------

audio_restore_output_channel_master_volume:
; input:
; - X = output channel (0 - 7)
; - Y = index into master_vols

		jsr transform_x_to_master_coeff_idx

		; high byte
		stx 0xd6f4
		jsr dummy_delay
		lda master_vols,y
		sta 0xd6f5

		; low byte
		inx
		stx 0xd6f4
		jsr dummy_delay
		iny
		lda master_vols,y
		sta 0xd6f5

		iny
		rts

; ------------------------------------------------------------------------------------

		.public audio_restore_master_volumes
audio_restore_master_volumes:
; call this after program ends, to restore user's preferred audio levels for HDMI + headphones

			ldy #0x00	; index to read from master_vols array

			; HDMI-LEFT
			ldx #0x00
			jsr audio_restore_output_channel_master_volume

			; HDMI-RIGHT
			ldx #0x01
			jsr audio_restore_output_channel_master_volume

			; HEADPHONES-LEFT
			ldx #0x06
			jsr audio_restore_output_channel_master_volume

			; HEADPHONES-RIGHT
			ldx #0x07
			jsr audio_restore_output_channel_master_volume

			rts


; ------------------------------------------------------------------------------------

		.public audio_applyvolume
audio_applyvolume:
		; This reference explains the layout of the mixer co-efficients
		; - https://gurce.net/mega65_logs/day504

		; set HDMI-LEFT master volume
		ldx #0x00
		jsr audio_applyvolume_to_output_channel

		; set HDMI-RIGHT master volume
		ldx #0x01
		jsr audio_applyvolume_to_output_channel

		; set HEADPHONE-LEFT master volume
		ldx #0x06
		jsr audio_applyvolume_to_output_channel

		; set HEADPHONE-RIGHT master volume
		ldx #0x07
		jsr audio_applyvolume_to_output_channel
		
		rts

; ------------------------------------------------------------------------------------		
