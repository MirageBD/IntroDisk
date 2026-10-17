		.rtmodel cpu, "*"
		
		.extern _Zp
		.extern fl_set_filename
		.extern fastload_request
		.extern fl_waiting
		.extern fl_iffl_currentfile
		.extern fastload_iffl_start_address_and_size
		.extern fastload_address
		.extern fl_iffl_sizeremaining
		.extern decrunch

fastload_address_ptr:		.equlab _Zp+1			; LV TODO - this overlaps the second byte of fastload_filename_ptr, is that OK. Probably because the filename is only set once?
													; I really need a better way to show which base/zero page addresses are being used

;------------------------------------------------------------------------------

; IFFL header format:

;    number of files 1 byte     (256/8 = max 32 entries)
;
;    Load address    4 bytes    00 08 00 00
;    File size       4 bytes    00 20 00 00
;
;    EXTRA INFO NEEDED:
;
;    Start track     1 byte     28 (track   40)
;    Start sector    1 byte     03 (sector   3)
;    Start offset    1 byte     7A (offset 122)

;------------------------------------------------------------------------------

		.section code,text
		.public floppy_iffl_fast_load_init
floppy_iffl_fast_load_init:
		jsr fl_set_filename

		lda #0x01										; Request fastload job
		sta fastload_request
		jsr fl_waiting
		rts

;------------------------------------------------------------------------------

		.section code,text
		.public floppy_fast_load_init
floppy_fast_load_init:
		lda #0x00										; set fastload address. hardcoded to 0x00050000 for now
		sta fastload_address+0
		sta fastload_address+1
		sta fastload_address+3
		lda #0x05
		sta fastload_address+2

		lda #0x01										; Request fastload job
		sta fastload_request
		jsr fl_waiting

		rts

;------------------------------------------------------------------------------

		.section code,text
		.public floppy_fast_load
floppy_fast_load:

		lda #0x03
		sta fastload_request
		jsr fl_waiting
		rts

;------------------------------------------------------------------------------

		.section code,text
		.public floppy_iffl_fast_load
floppy_iffl_fast_load:
		lda fl_iffl_currentfile
		asl a
		asl a
		asl a
		tax
		lda fastload_iffl_start_address_and_size+0,x
		sta fastload_address+0
		sta zp:fastload_address_ptr+0
		lda fastload_iffl_start_address_and_size+1,x
		sta fastload_address+1
		sta zp:fastload_address_ptr+1
		lda fastload_iffl_start_address_and_size+2,x
		sta fastload_address+2
		sta zp:fastload_address_ptr+2
		lda fastload_iffl_start_address_and_size+3,x
		sta fastload_address+3
		sta zp:fastload_address_ptr+3

		lda fastload_iffl_start_address_and_size+4,x
		sta fl_iffl_sizeremaining+0
		lda fastload_iffl_start_address_and_size+5,x
		sta fl_iffl_sizeremaining+1
		lda fastload_iffl_start_address_and_size+6,x
		sta fl_iffl_sizeremaining+2
		lda fastload_iffl_start_address_and_size+7,x
		sta fl_iffl_sizeremaining+3

		lda #0x07
		sta fastload_request
		inc fl_iffl_currentfile
		jsr fl_waiting

		jsr decrunch
		rts

;------------------------------------------------------------------------------
