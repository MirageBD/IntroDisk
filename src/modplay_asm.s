			.rtmodel cpu, "*"

			.extern portdiff 	; int16_t
			.extern portdiffabs ; uint16_t

; ------------------------------------------------------------------------------------

			.public mp_calc_portdiffabs
mp_calc_portdiffabs:

			lda portdiff+0
			sta portdiffabs+0
			lda portdiff+1
			sta portdiffabs+1

			lda portdiff+1					; Load the high byte
			bpl mp_calc_portdiffabs_done	; If bit 7 is clear (positive), we're done
	
											; Negate the number (NOT + 1)
			sec								; Set carry for two's complement subtraction
			lda #0x00						; 0 minus the low byte
			sbc portdiffabs+0
			sta portdiffabs+0
			lda #0x00						; 0 minus the high byte (accounting for borrow)
			sbc portdiffabs+1
			sta portdiffabs+1

mp_calc_portdiffabs_done:
			rts

; ------------------------------------------------------------------------------------
