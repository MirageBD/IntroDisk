; ----------------------------------------------------------------------------------------------------

			.extern _Zp

; This is a test.
; 54 68 69 73 20 69 73 20 61 20 74 65 73 74 2E 0D 0A

; Let's see how much I can write.
; 4C 65 74 27 73 20 73 65 65 20 68 6F 77 20 6D 75 63 68 20 49 20 63 61 6E 20 77 72 69 74 65 2E 0D 0A

/*
num_categories				06
cat[0].cat_entry_offset		1F 00	; ptr to cat[0].entries_count
cat[0].name					02 00	; bAD aPPLE
cat[0].parent_cat_idx		01
cat[1].cat_entry_offset		41 00	; ptr to cat[1].entries_count
cat[1].name					0C 00	; dEMO
cat[1].parent_cat_idx		FF
cat[2].cat_entry_offset		08 01	; ptr to cat[2].entries_count
cat[2].name					11 00	; gAMES
cat[2].parent_cat_idx		FF
cat[3].cat_entry_offset		DA 01	; ptr to cat[3].entries_count
cat[3].name					17 00	; mEGA aSSEMBLER
cat[3].parent_cat_idx		05
cat[4].cat_entry_offset		FC 01	; ptr to cat[4].entries_count
cat[4].name					26 00	; tcc 1.5
cat[4].parent_cat_idx		05
cat[5].cat_entry_offset		3F 02	; ptr to cat[5].entries_count
cat[5].name					2E 00	; tOOLS
cat[5].parent_cat_idx		FF

cat[0].entries_count		03
cat[0].entries[0].title		34 00	; BADBASIC65APPLE
cat[0].entries[0].full		44 00	; bAD bASIC65 aPPLE dEMO V0.65BETA
cat[0].entries[0].desc		65 00	;	bAD bASIC65 aPPLE dEMO v0.65 BETA (fILEHOST vERSION 1.2)
										cHANGES TO THE PREVIOUS VERSION:
										* sWITCHING TO pal-mODE WHEN IN ntsc-mODE ADDED
										(rEFRESHED UPLOAD. vERSION 0.65BETA SHOULD NOW BE ON THE FILE HOST.)

										bAD bASIC65 aPPLE dEMO v0.6 BETA (fILEHOST vERSION 1.1)
										important note:
										tHIS DEMO RUNS ONLY IN pal MODE. sWITCH TO pal MODE IN mega65 CONFIGURATION BEFORE.
										rEMINDER: PRESSING alt-KEY WHILE POWER ON AND THEN PRESS 1 FOR mEGA65 CONFIGURATION MENU).
										cHANGES TO THE PREVIOUS VERSION:
										* nOW WITH MUSIC, AS GOOD AS i MANAGED WITH basic65.
										* bETTER COMPRESSION OF VIDEO DATA AT THE EXPENSE OF DECOMPRESSION TIME, BUT CONSTANT FRAME RATE OF VIDEO SEQUENCE
										* wAITING SCREEN DURING COMPRESSION SHOWS AN ai GENERATED IMAGE CREATED WITH sTABLE dIFFUSION 1.5 ON kRITA
										* sELECTION MENU TO OFFER OPTIONS FOR LOADING THE VIDEO DATA
										* tHE MODIFIED pYTHON SCRIPTS ARE NOT INCLUDED. sORRY, WILL BE DELIVERED LATER (OR ON REQUEST).
										* sPECIAL BONUS: tHE lITTLE bAD bASIC65 aPPLE DEMO IS INCLUDED



										bAD bASIC65 aPPLE dEMO PRE1 (fILEHOST vERSION 1.0):

										hERE IS ANOTHER DEMO OF tOHOU bAD aPPLE. tHIS TIME WRITTEN IN basic65. oKAY, THE DATA OF THE VIDEO WAS PREPARED WITH pYTHON. bUT ONLY basic65 COMMANDS ARE USED TO PLAY THE VIDEO.
										tHE zip FILE ALSO CONTAINS THE pYTHON SCRIPTS i USED TO PREPARE THE DATA. eVERYTHING ELSE IS DESCRIBED IN THE readme FILE INSIDE THE zip FILE. tHE pYTHON SCRIPTS ALSO CONTAIN MANY USEFUL HINTS.
										uNFORTUNATELY i'M NOT THE MUSIC TYPE, SO THERE IS NO MUSIC YET. i'M STILL THINKING ABOUT WHAT TO DO NEXT. sOME OPTIMIZATIONS ARE STILL POSSIBLE (FRAME RATE!). i HAVE THE FOLLOWING RESTRICTIONS: tHE ACTUAL PROGRAM SHOULD BE WRITTEN IN PURE basic. pEEK AND pOKES ARE ALLOWED AS LONG AS THEY DON'T WRITE MACHINE CODE.
										hELP IS OF COURSE WELCOME, ESPECIALLY FOR THE INTEGRATION OF MUSIC.
cat[0].entries[0].author	68 07	; nOBATO
cat[0].entries[0].mount		6F 07	; B65APPL1.D81
cat[0].entries[0].dir_flag	FF		; (is this a directory entry? and which cat-idx if points to)

cat[0].entries[1].title		7C 07	; LITTLEBADDEMO
cat[0].entries[1].full		8A 07	; lITTLE bAD dEMO
cat[0].entries[1].desc		9A 07	;	sPECIAL BONUS bAD aPPLE DEMO BY nOBATO!
										note: iF SPRITES SEEM OUT OF PLACE, PRESS space bar TO RESET POSITIONS.
cat[0].entries[1].author	0B 08	; nOBATO
cat[0].entries[1].mount		12 08	; LITTLBAD.D81
cat[0].entries[1].dir_flag	FF		; (is this a directory entry? and which cat-idx if points to)

cat[0].entries[2].title		1F 08	; MEGAPPLE
cat[0].entries[2].full		28 08	; megaPPLE
cat[0].entries[2].desc		31 08	; mega65 VERSION OF bAD aPPLE.
										note: iF YOU EXPERIENCE AUDIO-PLAYBACK ISSUES, TRY RUNNING FROM A FASTER SD-CARD (CLASS 10).
cat[0].entries[2].author	C9 0D	; mIRAGEäbd
cat[0].entries[2].mount		00 00
cat[0].entries[2].dir_flag	FF		; (is this a directory entry? and which cat-idx if points to)

cat[1].entries_count		12
cat[1].entries[0].title		D3 0D	; bAD aPPLE
cat[1].entries[0].full		00 00
cat[1].entries[0].desc		00 00
cat[1].entries[0].author	00 00
cat[1].entries[0].mount		00 00
cat[1].entries[0].dir_flag	00		; (is this a directory entry? and which cat-idx if points to)

cat[1].entries[1].title		DD 0D	; CUBE-SPIN
cat[1].entries[1].full		E7 0D	; 3d cUBE sPIN
cat[1].entries[1].desc		F4 0D	; aNIMATED 3d CUBE SPINNING. cODED IN basic. oRIGINAL CODE BY rETRO rAMBLINGS FOR c64. tRANSLATED TO basic 65
cat[1].entries[1].author	60 0E	; HEATHäMAN
cat[1].entries[1].mount		00 00
cat[1].entries[1].dir_flag	FF		; (is this a directory entry? and which cat-idx if points to)

cat[1].entries[2].title		6A 0E	; AUTOMATA
cat[1].entries[2].full		00 00
cat[1].entries[2].desc		73 0E	;	jUST A SMALL TEXT-MODE SCREENSAVER WRITTEN IN bASIC. lOOPS THROUGH SEVERAL RULESETS OF wOLFRAM'S eLEMENTARY cELLULAR aUTOMATA [1], AND PRINTS THEM OUT IN 80X50 MODE.

										tHANKS TO nATURE OF cODE [2] FOR HELPING ME UNDERSTAND HOW THIS WORKS.

										[1] –HTTPS://MATHWORLD.WOLFRAM.COM/eLEMENTARYcELLULARaUTOMATON.HTML›
										[2] –HTTPS://NATUREOFCODE.COM/CELLULAR-AUTOMATA/›

cat[1].entries[2].author	D9 0F	; BISGEDI
cat[1].entries[2].mount		00 00
cat[1].entries[2].dir_flag	FF		; (is this a directory entry? and which cat-idx if points to)



*/

; ----------------------------------------------------------------------------------------------------

fnts_numchars			.equ (2048/16)
fontcharmem				.equ 0x10000

zpscrdst1:				.equlab _Zp + 80
zpscrdst2:				.equlab _Zp + 82
zpcoldst1:				.equlab _Zp + 84
zpcoldst2:				.equlab _Zp + 86

zptxtsrc1:				.equlab _Zp + 90	; $5c

; ----------------------------------------------------------------------------------------------------

						.public fnts_row
fnts_row				.byte 0
						.public fnts_column
fnts_column				.byte 0

						.public fnts_tempbuf
fnts_tempbuf			.space 0xff

						.public fnts_numlineptrs
fnts_numlineptrs		.byte 0
						.public fnts_lineptrlistlo
fnts_lineptrlistlo		.space 256
						.public fnts_lineptrlisthi
fnts_lineptrlisthi		.space 256

						.public fnts_lineurlstart	; 255 if no url present
fnts_lineurlstart		.space 256

capturingurl			.byte 0

txturl					.space 256

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

		.public fontsys_buildlineptrlist
fontsys_buildlineptrlist

		; big list of text.
		; the only thing we'll find in here is normal text, 0x0a for returns and 0x00 for the end of the big list.

		lda #0
		sta capturingurl

		; store pointer to first line
		lda zp:zptxtsrc1+0
		sta fnts_lineptrlistlo
		lda zp:zptxtsrc1+1
		sta fnts_lineptrlisthi

		ldy #1	; line counter
fsbl0:	ldz #0	; char counter
		ldx #0	; url char counter
		lda #255
		sta fnts_lineurlstart-1,y
fsbl1:	lda [zp:zptxtsrc1],z
		beq fontsys_buildlineptrlist_end ; 00

		cmp #0x0a
		beq fontsys_buildlineptrlist_nextline

		cmp #0x96	; URL starts with 0x96 colour code
		bne fsbl2
		lda #1		; signal url capture
		sta capturingurl
		ldx #0		; reset url capture counter
		lda #1
		sta fnts_lineurlstart-1,y
		bra fsbl5

fsbl2:	cmp #0x9b	; URL starts with 0x96 colour code
		bne fsbl3
		lda #0
		sta capturingurl
		bra fsbl5

fsbl3:	pha
		lda capturingurl
		beq fsbl4
		pla
		sta txturl,x
		inx
		bra fsbl5

fsbl4:	pla
fsbl5:	inz
		bra fsbl1

fontsys_buildlineptrlist_nextline

		lda #0x00
		sta txturl,x

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

		lda #0x00
		sta txturl,x

		rts

; ----------------------------------------------------------------------------------------------------

		.public fontsys_asm_render
fontsys_asm_render:

		ldy fnts_column

		ldz #0
		ldx #0

fnts_readchar:
		lda [zp:zptxtsrc1],z
		beq fontsys_asmrender_finalize	; 00 = end of text

		bpl fnts_readchar3$		; 0x80-0xa0 = set color. $9a = red, $9b = white?
		cmp #0xa0
		bpl fnts_readchar3$

		phx
		sec
		sbc #0x80
		tax
		lda palremap,x
		sta fnts_curpal+1
		inz
		plx
		inx
		bra fnts_readchar

fnts_readchar3$:
		cmp #0x0a				; EOL
		beq fontsys_asmrender_finalize

		phx
		tax

		sta (zp:zpscrdst1),y
		clc
		adc #.byte0 (fontcharmem / 64 + 1 * fnts_numchars) ; 64
		sta (zp:zpscrdst2),y

		lda fnts_chartrimshi,x
		sta (zp:zpcoldst1),y
		sta (zp:zpcoldst2),y

		iny

		lda #.byte1 (fontcharmem / 64)
		ora fnts_chartrimslo,x
		sta (zp:zpscrdst1),y
		sta (zp:zpscrdst2),y

		.public fnts_curpal
fnts_curpal:
		lda #0x0f ; palette 0 and colour 15 for transparent pixels
		sta (zp:zpcoldst1),y
		sta (zp:zpcoldst2),y

		iny
		plx

		inz
		inx
		bra fnts_readchar

fontsys_asmrender_finalize:

		rts

; ----------------------------------------------------------------------------------------------------

palremap
					.byte 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f
					.byte 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x3f, 0x3f, 0x3f, 0x3f, 0x1f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f

					.public fnts_charwidths
fnts_charwidths:

					.byte  4,4,4,4,4,4,4,4,4,4
					.byte  4,4,4,4,4,4,4,4,4,4
					.byte  4,4,4,4,4,4,4,4,4,4
					.byte  4,4

					;      .   !   "   #   $   %   &   '   (   )   *   +   ,   -   .   /   0   1   2   3
					.byte  4,  3,  7,  9,  9, 10,  9,  3,  5,  5,  8,  6,  4,  6,  4,  7,  9,  6,  7,  8
					;      4   5   6   7   8   9   :   ;   <   =   >   ?   @   a   b   c   d   e   f   g
					.byte  9,  8,  8,  9,  8,  9,  4,  4,  6,  7,  6,  8,  9,  8,  7,  8,  8,  8,  5,  8
					;      h   i   j   k   l   m   n   o   p   q   r   s   t   u   v   w   x   y   z   [
					.byte  7,  3,  4,  7,  3, 11,  7,  8,  8,  8,  5,  7,  4,  7,  7, 12,  8,  8,  7,  4
					;      £   ]   |   -   -   A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
					.byte  9,  4,  8,  8,  8, 10,  8, 10,  9,  7,  6, 10,  8,  3,  7,  8,  6, 13,  8, 10
					;      P   Q   R   S   T   U   V   W   X   Y   Z   =   =   =   -   o   .   .   ~   .
					.byte  8, 11,  8,  9,  7,  9, 10, 14,  9,  9,  8, 10,  8, 16, 16,  8,  4,  4,  8,  4

					.byte  4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4

					.public fnts_chartrimshi
fnts_chartrimshi:	.space 128
					.public fnts_chartrimslo
fnts_chartrimslo:	.space 128

					.public fnts_screentablo
fnts_screentablo:	.space 50		; .byte <(screen          + rrbscreenwidth2 * I)
					.public fnts_screentabhi
fnts_screentabhi:	.space 50		; .byte >(screen          + rrbscreenwidth2 * I)
					.public fnts_attribtablo
fnts_attribtablo:	.space 50		; .byte <(mappedcolourmem + rrbscreenwidth2 * I)
					.public fnts_attribtabhi
fnts_attribtabhi:	.space 50		; .byte >(mappedcolourmem + rrbscreenwidth2 * I)

; ----------------------------------------------------------------------------------------------------

			.public fnts_bin
fnts_bin	.long  0x00ffffff	; A test value to convert (LSB first)
			.public fnts_bcd
fnts_bcd	.space 5			; Should end up as $45,$23,$01

			.public fnts_binstring
fnts_binstring
			.space 10

			.public fontsys_convertfilesizetostring
fontsys_convertfilesizetostring:

			sed					; Switch to decimal mode
			lda #0				; Ensure the result is clear
			sta fnts_bcd+0
			sta fnts_bcd+1
			sta fnts_bcd+2
			sta fnts_bcd+3
			sta fnts_bcd+4

			ldx #32				; The number of source bits
       
cnvbit:		asl fnts_bin+0		; Shift out one bit
			rol fnts_bin+1
			rol fnts_bin+2
			rol fnts_bin+3

			lda fnts_bcd+0		; And add into result
			adc fnts_bcd+0
			sta fnts_bcd+0
			lda fnts_bcd+1		; propagating any carry
			adc fnts_bcd+1
			sta fnts_bcd+1
			lda fnts_bcd+2		; ... thru whole result
			adc fnts_bcd+2
			sta fnts_bcd+2
			lda fnts_bcd+3		; ... thru whole result
			adc fnts_bcd+3
			sta fnts_bcd+3
			lda fnts_bcd+4		; ... thru whole result
			adc fnts_bcd+4
			sta fnts_bcd+4

			dex					; And repeat for next bit
			bne cnvbit
			
			cld					; Back to binary

			ldy #0
			ldx #4

tostr:		lda fnts_bcd,x
			lsr a
			lsr a
			lsr a
			lsr a
			sta fnts_binstring,y

			lda fnts_bcd,x
			and #0x0f
			sta fnts_binstring+1,y
			iny
			iny
			dex
			bpl tostr

			ldx #0x00
trimstart:	lda fnts_binstring,x
			beq trimstart2
			bra trimstart3
trimstart2:	lda #0x63
			sta fnts_binstring,x
			inx
			cpx #10
			bne trimstart
			bra trimstartend

trimstart3:	lda fnts_binstring,x
			clc
			adc #0x10
			sta fnts_binstring,x
			inx
			cpx #10
			bne trimstart3

trimstartend:
			rts

; ----------------------------------------------------------------------------------------------------
