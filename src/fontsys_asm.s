; ----------------------------------------------------------------------------------------------------

			.extern _Zp

						.public fnts_lineptrlistlo
fnts_lineptrlistlo		.equ 0xc000
						.public fnts_lineptrlisthi
fnts_lineptrlisthi		.equ 0xc100
						.public fnts_lineurlstart	; 255 if no url present
fnts_lineurlstart		.equ 0xc200
						.public fnts_lineurlsize
fnts_lineurlsize		.equ 0xc300

						.public txturl
txturl					.equ 0xc400 ; 128 big

						.public fnts_chartrimshi
fnts_chartrimshi:		.equ 0xc500 ; 128 big
						.public fnts_chartrimslo
fnts_chartrimslo:		.equ 0xc580 ; 128 big

						.public fnts_screentablo
fnts_screentablo:		.equ 0xc600+0*64 ; 64 big		; .byte <(screen          + rrbscreenwidth2 * I)
						.public fnts_screentabhi
fnts_screentabhi:		.equ 0xc600+1*64 ; 64 big		; .byte >(screen          + rrbscreenwidth2 * I)
						.public fnts_attribtablo
fnts_attribtablo:		.equ 0xc600+2*64 ; 64 big		; .byte <(mappedcolourmem + rrbscreenwidth2 * I)
						.public fnts_attribtabhi
fnts_attribtabhi:		.equ 0xc600+3*64 ; 64 big		; .byte >(mappedcolourmem + rrbscreenwidth2 * I)

/*
	00 01 ptr to struct				; 04 a8

08
29 00 02 00 FF
A3 00 0E 00 07
C5 00 2D 00 FF	a804 + c5 = a8c9
				01
				02 00			""
				03 00			"cREDITS ENTRY"
				11 00			"cREDITS DESCRIPTION tHIS PROBABLY JUST WANTS TO BE ONE PAGE...
				E9 00
				00 00
				FF


*/

/*
	00 01 ptr to struct				; 73 a9

	a973:
			08						; number of categories

			; cat_entry_offset    name      parent_cat_idx;

			29 00	02 00	FF	aPPLICATION
								a973 + 0029 = a99c ->	0b						; number of subcategories
									5b 00											; title = "3D FUNCTIONS"
									68 00											; full = "3d functions"
									75 00											; desc = "tHIS IS A SHORT BASIC PROGRAM THAT DRA...
									df 01											; author = "ADORIGATTI"
									00 00											; mount = x
									ff												; dir_flag

									01 ea											; title = BASICTRACKER-1.1

			a3 00	0E 00	07	basic 65 sPRITE TO cHAR dETECT
								a973 + 00a3 = aa16 ->	03						; number of subcategories

			c5 00	2d 00	7F	cREDITS
								a973 + 00c5 = aa38 ->	01						; number of subcategories
									; 26CF should become 00 00?
									CF 26											; title = ""
									D0 26											; full = "cREDITS ENTRY"
									DE 26											; desc = "cREDITS DESCRIPTION. tHIS PROBABLY...
									B6 27											; author = ""
									00 00											; mount = x
									FF												; dir_flag

			d1 00	35 00	FF	dEMO
			6c 01	3a 00	FF	gAME
			3e 02	3f 00	FF	mEGAzINE iSSUE #1
			6b 02	51 00	FF	nEWS
			77 02	56 00	FF	tOOL

	; ADD $80 TO PARENT_CAT_IDX FOR CREDITS/NEWS???

*/



; ----------------------------------------------------------------------------------------------------

fnts_numchars			.equ (2048/16)				; IMPORTANT!!! KEEP IMAGE 2048 WIDE, SO THIS WILL BE $80
fontcharmem				.equ 0x10000

zpscrdst1:				.equlab _Zp + 80	; $52
zpscrdst2:				.equlab _Zp + 82	; $54
zpcoldst1:				.equlab _Zp + 84	; $56
zpcoldst2:				.equlab _Zp + 86	; $58

zptxtsrc1:				.equlab _Zp + 90	; $5c

; ----------------------------------------------------------------------------------------------------

						.public fnts_row
fnts_row				.byte 0
						.public fnts_column
fnts_column				.byte 0

						.public fnts_numlineptrs
fnts_numlineptrs		.byte 0

urlspriteindex			.byte 0
capturingurl			.byte 0
urlcaptured				.byte 0

						.public fnts_spacewidth
fnts_spacewidth			.byte 0

						.public fnts_gotoxpos
fnts_gotoxpos			.word 0

; ----------------------------------------------------------------------------------------------------

		.public fontsys_asm_init
fontsys_asm_init:

		ldx #0x00
fs_i0$:
		lda #0b00001000				; NCM bit, no 8-pixel trim
		sta fnts_chartrimshi,x
		sec
		lda #16
		sbc fnts_charwidths,x
		asl a						; upper 3 bits are trimlo
		asl a
		asl a
		asl a
		asl a
		sta fnts_chartrimslo,x
		bcc fs_il$
		lda #0b00001100				; overflowed, so we have a trimhi. ora with NCM bit and store
		sta fnts_chartrimshi,x
fs_il$:	inx
		cpx #128
		bne fs_i0$

		lda #0x02
		sta zp:zptxtsrc1+2
		lda #0x00
		sta zp:zptxtsrc1+3

		rts

; ----------------------------------------------------------------------------------------------------

		.public fontsys_asm_setupscreenpos
fontsys_asm_setupscreenpos:

fnts_readrow:
		ldy fnts_row

		lda fnts_screentablo+0,y
		sta zp:zpscrdst1+0
		lda fnts_screentabhi+0,y
		sta zp:zpscrdst1+1

		lda fnts_screentablo+1,y
		sta zp:zpscrdst2+0
		lda fnts_screentabhi+1,y
		sta zp:zpscrdst2+1

		lda fnts_attribtablo+0,y
		sta zp:zpcoldst1+0
		lda fnts_attribtabhi+0,y
		sta zp:zpcoldst1+1

		lda fnts_attribtablo+1,y
		sta zp:zpcoldst2+0
		lda fnts_attribtabhi+1,y
		sta zp:zpcoldst2+1

		rts

; ----------------------------------------------------------------------------------------------------

starturlcapture
		lda #1						; signal url capture
		sta capturingurl
		sta urlcaptured

		ldx #0
		lda #0x00
clearurl:
		sta txturl,x
		inx
		cpx #128
		bne clearurl

		ldx #0						; reset url capture counter
		lda urlspriteindex			; set index of sprite
		sta fnts_lineurlstart-1,y
		rts

; ----------------------------------------------------------------------------------------------------

generate_qrcode:
		; generate QR code here
		; From Goodwell:
		; The routine takes the bank of input-url from the accumulator (is used as the third byte for lda[] operation)
		; The location of the input-url is read from $FB/$FC
		; The sprite-index is read from $FD/$FE. This value is multiplied by 64 and the result will be written to that location (using sta[])

		lda #0x00
		lda #.byte0 txturl
		sta 0xfb
		lda #.byte1 txturl
		sta 0xfc

		lda urlspriteindex
		sta 0xfd
		lda #0x00
		sta 0xfe

		jsr 0xe000

		; done generating code. clear 2 lines garbage at the end because more of the QR code is rendered because there's an offset border behind it.

		clc
		lda zp:0xfe						; get size of generated QR code and compensate for border
		adc #0x02
		sta endofinsprite+0
		lda #0x00
		sta endofinsprite+1

		asl endofinsprite+0				; multiply by 8
		rol endofinsprite+1
		asl endofinsprite+0
		rol endofinsprite+1
		asl endofinsprite+0
		rol endofinsprite+1

		lda urlspriteindex				; get sprite index
		sta endofsprite+1
		lda #0x00
		sta endofsprite+2

		asl endofsprite+1				; multiply by 64
		rol endofsprite+2
		asl endofsprite+1
		rol endofsprite+2
		asl endofsprite+1
		rol endofsprite+2
		asl endofsprite+1
		rol endofsprite+2
		asl endofsprite+1
		rol endofsprite+2
		asl endofsprite+1
		rol endofsprite+2

		clc
		lda endofsprite+1
		adc endofinsprite+0
		sta endofsprite+1
		lda endofsprite+2
		adc endofinsprite+1
		sta endofsprite+2

		lda #0x00
		ldx #0x0f						; clear 2 lines of possible garbage
endofsprite:
		sta 0xbabe,x
		dex
		bpl endofsprite

		clc								; move to next URL sprite
		lda urlspriteindex
		adc #(0x180/64)					; sprheight * sprwidth/8 = 48 * (64/8) = 48 * 8 = $0x180
		sta urlspriteindex

		rts

endofinsprite
		.word 0

; ----------------------------------------------------------------------------------------------------

		.public fontsys_buildlineptrlist
fontsys_buildlineptrlist:

		; big list of text.
		; the only thing we'll find in here is normal text, 0x0a for returns and 0x00 for the end of the big list.

		lda #((0x0440+0x0180)/64)					; sprdata + sprheight * sprwidth/8 = 48 * (64/8) = 48 * 8 = $0x180
		sta urlspriteindex

		; store pointer to first line
		lda zp:zptxtsrc1+0
		sta fnts_lineptrlistlo
		lda zp:zptxtsrc1+1
		sta fnts_lineptrlisthi

		ldy #1	; line counter
fsbl0:	lda #0
		sta capturingurl
		sta urlcaptured
		ldz #0	; char counter
		ldx #0	; url char counter
		lda #255
		sta fnts_lineurlstart-1,y
		lda #0
		sta fnts_lineurlsize-1,y
fsbl1:	lda [zp:zptxtsrc1],z
		beq fontsys_buildlineptrlist_end ; 00

		cmp #0xb1		; skip over gotox control code
		bne fsbl6
		inz
		inz
		inz
		bra fsbl1

fsbl6:
		cmp #0x0a
		beq fontsys_buildlineptrlist_nextline

		cmp #0x96		; URL starts with 0x96 colour code
		bne fsbl2
		jsr starturlcapture
		bra fsbl5

fsbl2:	cmp #0x9b		; URL ends with 0x9B colour code
		bne fsbl3
		lda #0
		sta capturingurl
		bra fsbl5

fsbl3:	pha
		lda capturingurl
		beq fsbl4
		pla

		cpx #0x00
		bne fsbl3_good

		cmp #'-'		; skip '-' if it is first char of url (for hidden url)
		beq fsbl5

fsbl3_good:
		sta txturl,x
		inx
		bra fsbl5

fsbl4:	pla
fsbl5:	inz
		bra fsbl1

fontsys_buildlineptrlist_nextline

		lda #0x00
		sta txturl,x

		lda urlcaptured
		beq fsblplnl2

		phx
		phy
		phz
		jsr generate_qrcode
		plz
		ply
		plx

		lda zp:0xfe
		sta fnts_lineurlsize-1,y

fsblplnl2:
		inz	; skip over 0x0a
		tza
		clc
		adc zp:zptxtsrc1+0
		sta zp:zptxtsrc1+0
		sta fnts_lineptrlistlo,y
		lda zp:zptxtsrc1+1
		adc #0x00
		sta zp:zptxtsrc1+1
		sta fnts_lineptrlisthi,y

		iny
		jmp fsbl0

fontsys_buildlineptrlist_end
		sty fnts_numlineptrs

		lda urlcaptured
		beq fsblplnl3

		phx
		phy
		phz
		jsr generate_qrcode
		plz
		ply
		plx

		lda zp:0xfe
		sta fnts_lineurlsize-1,y

fsblplnl3:
		lda #0x00
		sta txturl,x

		rts

; ----------------------------------------------------------------------------------------------------

check_hide_url:
		pha
		inz
		lda [zp:zptxtsrc1],z
		cmp #'-'		; only hide urls that start with a '-' char
		beq do_hide
		dez
		pla
		rts

do_hide:
		inz
		lda [zp:zptxtsrc1],z
		cmp #0x9b
		bne do_hide

		tax
		pla
		txa
		rts

; ----------------------------------------------------------------------------------------------------

		.public fontsys_asm_render
fontsys_asm_render:

		ldy fnts_column

		ldz #0

fnts_readchar:
		lda [zp:zptxtsrc1],z
		bne fontsys_asmrender_notfinal	; 00 = end of text
		rts

fontsys_asmrender_notfinal
		bpl fnts_readchar3				; bigger than $00 and smaller than $80? render as normal

fnts_controlcode:
		sec
		sbc #0x80						; subtract $80 to bring control code into $00-$80 range
		cmp #0x20
		bpl fnts_nosetpal				; bigger than $a0/$20 so no colour code.

fnts_checkhideurl:
		cmp #0x16
		bne fnts_setpal
		jsr check_hide_url

fnts_setpal:
		tax
		lda palremap,x
		sta fnts_curpal+1
		inz
		bra fnts_readchar

fnts_nosetpal:
		cmp #0x21							; check for setunderline code						
		bne fnts_nosetunderline
fnts_setunderline:		
		lda #0*fnts_numchars
		sta fnts_bottomlineadd1+1
		lda #0x01
		sta fnts_bottomlineadd2+1
		inz
		bra fnts_readchar

fnts_nosetunderline:
		cmp #0x22							; check for resetunderline code
		bne fnts_noresetunderline
fnts_resetunderline:		
		lda #1*fnts_numchars
		sta fnts_bottomlineadd1+1
		lda #0x00
		sta fnts_bottomlineadd2+1
		inz
		bra fnts_readchar

fnts_noresetunderline:
		cmp #0x31
		bne fnts_nosetgotox
fnts_setgotox:		
		inz
		lda [zp:zptxtsrc1],z			; read 2 bytes for gotox value here, little endian.
		sta fnts_gotoxpos+0
		inz
		lda [zp:zptxtsrc1],z
		sta fnts_gotoxpos+1
		inz
		bra fnts_readchar

fnts_nosetgotox:
		cmp #0x32
		bne fnts_nogotogotox
fnts_gotogotox:
		lda #0b00010000
		sta (zp:zpcoldst1),y				; set top line gotox
		sta (zp:zpcoldst2),y				; set bottom line gotox
		lda fnts_gotoxpos+0
		sta (zp:zpscrdst1),y				; draw top line gotox lower 8 bits
		sta (zp:zpscrdst2),y				; draw bottom line gotox lower 8 bits
		iny
		lda fnts_gotoxpos+1
		sta (zp:zpscrdst1),y				; draw top line gotox lower 8 bits
		sta (zp:zpscrdst2),y				; draw bottom line gotox lower 8 bits
		iny

		inz
		bra fnts_readchar

fnts_nogotogotox:
		; no control codes - fall through to regular char reading





fnts_readchar3:
		cmp #0x0a				; EOL
		bne fnts_readchar3_notfinal
		rts

fnts_readchar3_notfinal:
		tax

		; draw top line
		sta (zp:zpscrdst1),y				; draw top line
		clc
		; draw bottom line
		.public fnts_bottomlineadd1
fnts_bottomlineadd1:
		adc #1*fnts_numchars				; fnts_numchars = 2048/16 = $0080
		sta (zp:zpscrdst2),y

		lda fnts_chartrimshi,x
		sta (zp:zpcoldst1),y
		sta (zp:zpcoldst2),y

		iny

		lda #.byte1 (fontcharmem / 64)
		ora fnts_chartrimslo,x
		sta (zp:zpscrdst1),y
		clc
		.public fnts_bottomlineadd2
fnts_bottomlineadd2:
		adc #0								; add 1 for underline
		sta (zp:zpscrdst2),y

		.public fnts_curpal
fnts_curpal:
		lda #0x0f ; palette 0 and colour 15 for transparent pixels
		sta (zp:zpcoldst1),y
		sta (zp:zpcoldst2),y

		iny
		inz
		jmp fnts_readchar

; ----------------------------------------------------------------------------------------------------

palremap
					.byte 0x0f, 0x1f, 0x2f, 0x3f, 0x4f, 0x5f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f
					.byte 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x3f, 0x3f, 0x3f, 0x3f, 0x1f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f

					.public fnts_charwidths
fnts_charwidths:

					.byte  4,4,7,4,4,4,4,7,4,4			; 0x02 = bullet point, 0x07 = tilde
					.byte  4,4,4,4,15,15,14,14,14,14,14	; 0x0e-0x14 = emojis
					.byte  16,16,16,16,16,16			; 0x15-0x1a = keys
					.byte  4,4,4,4,4

					;      .   !   "   #   $   %   &   '   (   )   *   +   ,   -   .   /   0   1   2   3
					.byte  4,  3,  7,  9,  9, 10,  9,  3,  5,  5,  8,  6,  4,  6,  4,  7,  9,  6,  7,  8
					;      4   5   6   7   8   9   :   ;   <   =   >   ?   @   a   b   c   d   e   f   g
					.byte  9,  8,  8,  9,  8,  9,  4,  4,  6,  7,  6,  8,  9,  8,  7,  8,  8,  8,  5,  8
					;      h   i   j   k   l   m   n   o   p   q   r   s   t   u   v   w   x   y   z   [
					.byte  7,  3,  4,  7,  3, 11,  7,  8,  8,  8,  5,  7,  4,  7,  7, 12,  8,  8,  7,  4
					;      £   ]   |   -   -   A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
					.byte  9,  4,  8,  8,  8, 10,  8, 10,  9,  7,  6, 10,  8,  3,  7,  8,  6, 13,  8, 10
					;      P   Q   R   S   T   U   V   W   X   Y   Z   _   c   a   e   u   .   .   .   .
					.byte  8, 11,  8,  9,  7,  9, 10, 14,  9,  9,  8,  8,  8,  8,  8,  7,  4,  4,  4,  4

					.byte  4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4

; ----------------------------------------------------------------------------------------------------
