		.rtmodel cpu, "*"
	
		.extern _Zp
		.extern prg_failed

fastload_sector_buffer	.equ 0x0200

fastload_filename_ptr:		.equlab _Zp+0

; 0. fastload_request = 1 (fl_new_request)
; 1. fastload_request = 2 (fl_directory_scan)
; 2. fastload_request = 3 (fl_read_file_block)
; 3. jump to 2

; ----------------------------------------------------------------------------------------------------

; IMPORTANT: A PHYSICAL 1581 SECTOR (AND THE BUFFER) IS 512 BYTES AND CONTAINS TWO CONSECUTIVE 256-BYTE LOGICAL SECTORS

; Disk Layout and 1581 Logical Sectors
; The 1581 disk format is unusual in that the physical sectors on the disk are a different
; size of the size of the data blocks that it presents to the user. Specifically, the disks
; use 512 byte sectors, while the 1581 (and C65) DOS present 256 byte data blocks.

; 2 BLOCKS ARE STORED IN EACH PHYSICAL SECTOR

; Also, the physical track numbers are from 0 to 79, while the logical track numbers of the DOS are 1 to 80.
; Physical sectors are also numbered from 1 to 10, while logical block numbers begin are 0 to 39.
; This means that if you want to find a 1581 logical sector, you need to know which
; physical sector it will be found in. To determine the physical sector that contains a
; block, you first subtract one from the track number, and then divide the sector number
; by two.

; LOGICAL SECTORS  0 TO 19 OF EACH TRACK ARE LOCATED IN PHYSICAL SECTORS 1 TO 10 ON SIDE 0
; LOGICAL SECTORS 20 TO 39 OF EACH TRACK ARE LOCATED IN PHYSICAL SECTORS 1 TO 10 ON SIDE 1


; Thus we can map a some logical track and sector to the physical track, side and sector as follows:

; physical track = logical track - 1
; if logical sector < 20
;     side = 0
; else
;     side = 1
; physical sector = (logical sector - (side * 20)) / 2 + 1


; It is also worth noting that the 45IO27 is capable of reading from tracks beyond track
; 80, provided that the disk drive is capable of this. Almost all 3.5 inch floppy drives
; are capable of reading at least one extra track, as historically manufacturers of floppy
; disks stored information about the disk on the 81st track. In our experience almost all
; drives will also be able to access an 82nd track.


; ----------------------------------------------------------------------------------------------------

; Commodore 1581 disk format
; The Commodore 1581 is the 3.5-inch floppy drive for the Commodore 64/128 family. Its most important characteristic, especially if you're writing low-level disk code,
; is that the logical disk layout is different from the physical layout on the diskette. The drive's DOS normally hides that difference from the computer.

; ----------------------------------------------------------------------------------------------------

; 1. Physical vs. logical geometry
;
;    Physical disk format
;        Disk sides:                                    2
;        Cylinders:                                    80
;        Sectors per side, per cylinder:               10
;        Bytes per physical sector:                   512
;
;    Logical disk format (DOS)
;        Logical tracks:                               80
;        Logical sectors per track:                    40
;        Bytes per logical sector / block:            256
;        Total logical blocks:                      3,200
;
; Each physical track on one side contains ten 512-byte sectors. Each of those physical sectors holds two 256-byte logical blocks, so the drive exposes 40 logical sectors per cylinder across both sides.
;
; The resulting capacities are:
;    Measurement                                 Capacity
;    Physical data sectors                           1600
;    Bytes per physical sector                        512
;    Total raw sector-data bytes                  819,200
;    Logical blocks                                 3,200
;    Bytes per logical block                          256
;    Formatted disk capacity                      808,960 bytes
;    Free blocks on a standard formatted disk       3,160
;
;    The difference between raw sector-data capacity and formatted capacity comes from formatting overhead and the reserved/structural areas of the DOS filesystem. 

; ----------------------------------------------------------------------------------------------------

; 2. How logical blocks map to physical sectors
;    The 1581 uses one-based physical sector numbers (1–10) but zero-based logical sector numbers (0–39).
;
;    The mapping is:
;    Physical side        Physical sector    Logical sectors       Byte offsets within physical sector
;    -------------------------------------------------------------------------------------------------
;    Side 0	                            1    0, 1                  0–255, 256–511
;    Side 0	                            2    2, 3                  0–255, 256–511
;    Side 0                             3    4, 5                  0–255, 256–511
;    …                                  …    …                     …
;    Side 0                            10    18, 19                0–255, 256–511
;    Side 1                             1    20, 21                0–255, 256–511
;    Side 1                             2    22, 23                0–255, 256–511
;    …                                  …    …                     …
;    Side 1	                           10    38, 39                0–255, 256–511
;
;    So, for example, logical sector 7 is the second half of physical sector 4 on side 0. Logical sector 20 is the first half of physical sector 1 on side 1.

; ----------------------------------------------------------------------------------------------------

; 3. Tracks, cylinders and sides
;    These terms are worth distinguishing when accessing the drive controller directly.
;    - Cylinder: One of the 80 head positions, numbered 0–79 physically.
;    - Physical track: The circular recording path under one head on one side of the disk.
;    - Side: Side 0 or side 1.
;    - Physical sector: One of ten 512-byte sectors on a physical track.
;    - Logical track: One of 80 DOS tracks, numbered 1–80.
;    - Logical sector/block: One of 40 DOS sectors on a logical track, numbered 0–39, each 256 bytes.
;    A logical track spans both sides of the same cylinder. For example, logical track 1 corresponds to physical cylinder 0; logical track 80 corresponds to physical cylinder 79. 

; ----------------------------------------------------------------------------------------------------

; 4. Directory, BAM and reserved blocks
;    The standard 1581 filesystem reserves part of the logical disk for filesystem metadata.
;
;    Logical track/sector    Purpose
;    --------------------------------------------------------------
;    40/0                    Disk header
;    40/1                    First block availability map (BAM)
;    40/2                    Second BAM block
;    40/3                    First directory sector
;    40/4 onward             Additional directory sectors as needed
;
;    The directory can grow across the remaining sectors of logical track 40. The BAM records which logical blocks are allocated or free.

; ----------------------------------------------------------------------------------------------------

; 5. What matters for direct disk access
;    If you're working with raw physical sectors rather than the DOS block interface, keep these rules in mind:
;    - A physical sector contains 512 bytes, not 256.
;    - Physical sector numbers start at 1, not 0.
;    - There are 10 physical sectors per track per side.
;    - A physical sector holds two logical blocks.
;    - The DOS filesystem's logical track/sector numbering cannot be passed directly to a physical disk controller without translation.
;    One important caveat: the physical geometry describes the standard 1581 format. If you're accessing the drive's WD1770/WD1772 controller or using a disk image, the exact interface determines whether you receive raw physical sectors, logical blocks, or a translated representation. The controller also deals with sector headers, CRCs and inter-sector gaps; those aren't part of the 512-byte payload.
;    The primary reference for the low-level details is the Commodore 1581 User's Guide, Chapter 10.
;    (https://s3.amazonaws.com/com.c64os.resources/weblog/sd2iecdocumentation/manuals/1581_Users_Guide.pdf?utm_source=chatgpt.com)

; ----------------------------------------------------------------------------------------------------

; 6. On the Commodore 1581, the first two bytes of a 256-byte logical sector are normally a forward pointer to the next sector in a chain.
;
; Offset    Meaning
; --------------------------------------------------
; $00       Track number of the next sector
; $01       Sector number of the next sector
; $02–$FF   Data, depending on the sector's purpose
;
; The track and sector values are stored as individual bytes, not as a combined 16-bit number.
; The DOS follows the pointer to find the next block, so a file can occupy non-contiguous sectors
;
; How the last sector is marked
; When byte $00 is zero, it indicates that there is no next sector. Byte $01 then has a different meaning: it indicates the position immediately after the final valid data byte.
; For example:
; - $00 = $00
; - $01 = $40
; This means the sector contains valid data up to offset $3F in the sector's data area, depending on the file format's conventions.
; For ordinary sequential files, the data area begins at offset $02; the second byte is a count/position marker, not a sector number. 
;
; One important distinction: this convention applies to file-data blocks and chained directory/BAM blocks,
; but the meaning of the data following the pointer depends on the block type. A PRG file's first data block also contains its load address at offsets $02–$03.

; ----------------------------------------------------------------------------------------------------

; D080        IRQ     LED     MOTOR   SWAP    SIDE    DS      DS      DS      
;
; IRQ         The floppy controller has generated an interrupt (read only). Note that interrupts are not currently implemented on the 45GS27
; LED         Drive LED blinks when set
; MOTOR       Activates drive motor and LED (unless LED signal is also set, causing the drive LED to blink)
; SWAP        Swap upper and lower halves of data buffer (i.e. invert bit 8 of the sector buffer)
; DS          Drive select (0 to 7). Internal drive is 0. Second floppy drive on internal cable is 1. Other values reserved for C1565 external drive interface

; ----------------------------------------------------------------------------------------------------

; D081        WRCMD   RDCMD   FREE    STEP    DIR     ALGO    ALT     NOBUF   
;
; WRCMD       Command is a write operation if set
; RDCMD       Command is a read operation if set
; FREE        Command is a free-format (low level) operation
; STEP        Writing 1 causes the head to step in the indicated direction
; DIR         Sets the stepping direction (inward vs
; ALGO        Selects reading and writing algorithm (currently ignored)
; ALT         Selects alternate DPLL read recovery method (not implemented)
; NOBUF       Reset the sector buffer read/write pointers

; ----------------------------------------------------------------------------------------------------

; D082        BUSY    DRQ     EQ      RNF     CRC     LOST    PROT    TK0     
;
; BUSY        F011 FDC busy flag (command is being executed) (read only)
; DRQ         F011 FDC DRQ flag (one or more bytes of data are ready) (read only)
; EQ          F011 FDC CPU and disk pointers to sector buffer are equal, indicating that the sector buffer is either full or empty. (read only)
; RNF         F011 FDC Request Not Found (RNF), i.e., a sector read or write operation did not find the requested sector (read only)
; CRC         F011 FDC CRC check failure flag (read only)
; LOST        F011 LOST flag (data was lost during transfer, i.e., CPU did not read data fast enough) (read only)
; PROT        F011 Disk write protect flag (read only)
; TK0         F011 Head is over track 0 flag (read only)

; ----------------------------------------------------------------------------------------------------

; D083        RDREQ   WTREQ   RUN     WGATE   DISKIN  INDEX   IRQ     DSKCHG  
; 
; RDREQ       F011 Read Request flag, i.e., the requested sector was found during a read operation (read only)
; WTREQ       F011 Write Request flag, i.e., the requested sector was found during a write operation (read only
; RUN         F011 Successive match. A synonym of RDREQ on the 45IO47 (read only)
; WGATE       F011 write gate flag. Indicates that the drive is currently writing to media. Bad things may happen if a write transaction is aborted (read only)
; DISKIN      F011 Disk sense (read only)
; INDEX       F011 Index hole sense (read only)
; IRQ         The floppy controller has generated an interrupt (read only). Note that interrupts are not currently implemented on the 45GS27.
; DSKCHG      G F011 disk change sense (read only)

; ----------------------------------------------------------------------------------------------------

; D084        TRACK
; D085        SECTOR
; D086        SIDE
; D087        DATA
; D088        CLOCK
; D089        STEP
; D08A        PCODE

; ----------------------------------------------------------------------------------------------------

;.feature pc_assignment
;.feature labels_without_colons
;.feature c_comments

; ----------------------------------------------------------------------------------------------------

IFFL_DEBUG_BREAK	.macro
				lda fl_iffl_debug
				beq fl_iffl_skip_debug
iffldbgloop:	inc 0xc000
				jmp iffldbgloop
fl_iffl_skip_debug:
				.endm

; ----------------------------------------------------------------------------------------------------

		.public fl_mode									; loading mode. 0 = iffl, 1 = regular
fl_mode	.byte 0

; ----------------------------------------------------------------------------------------------------

		.section code,text
		.public fl_init
fl_init:
		lda #0x60										; Start motor
		sta 0xd080

		rts

; ----------------------------------------------------------------------------------------------------

		.section code,text
		.public fl_exit
fl_exit:
		lda #0x00										; Stop motor
		sta 0xd080

		rts

; ----------------------------------------------------------------------------------------------------

		.section code,text
		.public fl_set_filename
fl_set_filename:
		ldx zp:fastload_filename_ptr+0
		ldy zp:fastload_filename_ptr+1
		stx fl_fnptr+1
		sty fl_fnptr+2

		ldx #0x0f
		lda #0xa0										; pad name with 0xa0
loop$:	
		sta fastload_filename,x
		dex
		bpl loop$

		ldx #0xff
filenamecopyloop:
		inx
		cpx #0x10
		beq endofname
fl_fnptr:
		lda 0xbabe,x
		beq endofname
		sta fastload_filename,x
		bne filenamecopyloop

endofname:
		rts


; ----------------------------------------------------------------------------------------------------

		.section code,text
		.public fl_waiting
fl_waiting:
		jsr fastload_irq
		lda fastload_request							; Then just wait for the request byte to
		bmi fl_error									; go back to 0x00, or to report an error by having the MSB
		bne fl_waiting									; set. The request value will continually update based on the
		beq fl_waiting_done								; state of the loading.

fl_error:
		jsr prg_failed
		lda #0x02
		sta 0xd020
		lda #0x07
		sta 0xd020
		jmp fl_error

fl_waiting_done:
		rts

; ------------------------------------------------------------------------------------------------------------------------------
; Actual fast-loader code
; ------------------------------------------------------------------------------------------------------------------------------

		.public fastload_filename
fastload_filename:
		.space 16 , 0

		.public fastload_address
fastload_address:
		.long 0

		.public fastload_request
fastload_request:
		.byte 4											; Start with seeking to track 0

		; 0x00 = fl_idle								; idle
		; 0x01 = fl_new_request							; requested
		; 0x02 = fl_directory_scan						; scan directory
		; 0x03 = fl_read_file_block						; read file block
		; 0x04 = fl_seek_track_0						; seek to track 0
		; 0x05 = fl_reading_sector						; track stepping/sector reading state
		; 0x06 = fl_iffl_read_file_block_init
		; 0x07 = fl_iffl_read_file_block
		; 0x80 = File not found							; file not found

fastload_request_stashed:								; Remember the state that requested a sector read
		.byte 0

		; Variables for the logical track and sector of the next 256 byte block of the file.
		; These have to get translated into the physical track and sector of the drive, which like the 1581,
		; stores two blocks in each physical sector.

		.public fl_current_track
fl_current_track:
		.byte 0
		.public fl_file_next_track
fl_file_next_track:
		.byte 0
		.public fl_file_next_sector
fl_file_next_sector:
		.byte 0

		.public fl_current_half
fl_current_half:
		.byte 0											; 0 = first half, 1 = second half

fl_prev_track:
		.byte 0
fl_prev_sector:
		.byte 0
fl_prev_side:
		.byte 0

		.align 256
		.public fastload_sector_buffer

		.public fastload_iffl_header
fastload_iffl_header:

fl_iffl_numfiles:
		.byte 0

		.public fastload_iffl_start_address_and_size
fastload_iffl_start_address_and_size:
fastload_directory_entries:
		.space 32*(4+4), 0

		.public fastload_iffl_tracksectoroffset
fastload_iffl_tracksectoroffset
		.space 32*3			; 3 bytes - track, sector, offset


		.public fl_iffl_currentfile
fl_iffl_currentfile:
		.byte 0

		.public fl_iffl_sizeremaining
fl_iffl_sizeremaining:
		.long 0

		.public fl_iffl_bytecounter
fl_iffl_bytecounter:
		.byte 0

		.public fl_iffl_debug
fl_iffl_debug:
		.byte 0		

fastload_irq:
		lda fastload_request							; are we in idle state?
		bne todo										; nope, go and check if the FDC is busy
		rts												; yep, back out

todo:	
		lda 0xd082										; is the FDC busy?
		bpl fl_fdc_not_busy								; nope, continue with request
		rts												; yep, back out

fl_fdc_not_busy:
		lda fastload_request							; are we in error state?
		bpl fl_not_in_error_state						; nope, continue
		rts												; yep, back out

fl_not_in_error_state:
		cmp #8											; is the request smaller than 8?
		bcc fl_job_ok									; yep, continue
		rts												; nope, something must have gone wrong (0x80 (file not found) is bigger than 8)

fl_job_ok:
		asl a											; shift state left one bit, so that we can use it as a lookup
		tax												; into a jump table. Everything else is handled by the jump table
		jmp (fl_jumptable,x)

fl_jumptable:
		.word fl_idle									; 0
		.word fl_new_request							; 1
		.word fl_directory_scan							; 2
		.word fl_read_file_block						; 3
		.word fl_seek_track_0							; 4
		.word fl_reading_sector							; 5
		.word fl_iffl_read_file_block_init				; 6
		.word fl_iffl_read_file_block					; 7

		; order for iffl load:
		; calling floppy_iffl_fast_load_init() sets the state to 1 (fl_new_request) - this increases the state to 2 (fl_directory_scan)
		; when entry is found we call fl_got_iffl_file_track_and_sector which will set the state to 6 (fl_iffl_read_file_block_init) which will read the IFFL header

		; calling floppy_iffl_fast_load() sets the state to 7 (fl_iffl_read_file_block) which will load the next file from the IFFL file and then
		; set the state back to 0

fl_idle:
		rts

fl_seek_track_0:
		lda 0xd082
		and #0x01										; TK0 - F011 Head is over track 0 flag (read only)
		beq fl_not_on_track_0
		lda #0x00
		sta fastload_request
		sta fl_current_track
		rts

fl_not_on_track_0:
		lda #0x10										; Step back towards track 0
		sta 0xd081
		rts

fl_select_side1:
		lda #0x01
		sta 0xd086										; requested side
		lda #0x60										; Sides are inverted on the 1581
		sta 0xd080										; physical side selected of mechanical drive
		rts

fl_select_side0:
		lda #0x00
		sta 0xd086										; requested side
		lda #0x68										; Sides are inverted on the 1581
		sta 0xd080										; physical side selected of mechanical drive
		rts

fl_new_request:
		lda #2											; Acknowledge fastload request
		sta fastload_request

		lda #40-1										; Request Track 40 Sector 3 to start directory scan
		sta 0xd084										; (remember we have to do silly translation to real sectors)
		lda #(3/2)+1
		sta 0xd085
		jsr fl_select_side0

		jsr fl_read_sector								; Request read
		rts
	
; ------------------------------------------------------------------------------------------------------------------------------

fl_directory_scan:

		jsr fl_copy_sector_to_buffer					; Check if our filename we want is in this sector

														; (XXX we scan the last BAM sector as well, to keep the code simple.)
														; filenames are at offset 4 in each 32-byte directory entry, padded at
														; the end with 0xA0
		lda #.byte0 fastload_sector_buffer
		sta fl_buffaddr+1
		lda #.byte1 fastload_sector_buffer
		sta fl_buffaddr+2

fl_check_logical_sector:
		ldx #0x05
fl_filenamecheckloop:
		ldy #0x00

fl_check_loop_inner:

fl_buffaddr:
		lda fastload_sector_buffer+0x100,x

		cmp fastload_filename,y	
		bne fl_filename_differs
		inx
		iny
		cpy #0x10
		bne fl_check_loop_inner

fl_found_file:											; Filename matches

		txa
		sec
		sbc #0x12
		tax
		lda fl_buffaddr+2
		cmp #.byte1 fastload_sector_buffer
		bne fl_file_in_2nd_logical_sector

		lda fastload_sector_buffer,x					; Y=Track, A=Sector
		tay
		lda fastload_sector_buffer+1,x
		ldz fl_mode
		cpz #0x00
		beq fl_found_iffl_file
		jmp fl_got_file_track_and_sector
fl_found_iffl_file	
		jmp fl_got_iffl_file_track_and_sector

fl_file_in_2nd_logical_sector:

		lda fastload_sector_buffer+0x100,x				; Y=Track, A=Sector
		tay
		lda fastload_sector_buffer+0x101,x
		ldz fl_mode
		cpz #0x00
		beq fl_got_iffl_file_track_and_sector
		jmp fl_got_file_track_and_sector

fl_got_iffl_file_track_and_sector:
		sty fl_file_next_track							; Store track and sector of file
		sta fl_file_next_sector
		lda #6											; Advance to next state (6=fl_iffl_read_file_block_init)
		sta fastload_request
		jsr fl_read_next_sector							; Request reading of next track and sector
		rts

fl_got_file_track_and_sector
		sty fl_file_next_track							; Store track and sector of file
		sta fl_file_next_sector
		lda #3											; Advance to next state (3=fl_read_file_block)
		sta fastload_request
		jsr fl_read_next_sector							; Request reading of next track and sector
		rts

fl_filename_differs:
		cpy #0x10										; Skip same number of chars as though we had matched
		beq fl_end_of_name
		inx
		iny
		jmp fl_filename_differs
		.public fl_end_of_name
fl_end_of_name:
		txa												; Advance to next directory entry
		clc
		adc #0x10
		tax
		bcc fl_filenamecheckloop
		inc fl_buffaddr+2
		lda fl_buffaddr+2
		cmp #.byte1 (fastload_sector_buffer+0x100)
		bne fl_checked_both_halves
		jmp fl_check_logical_sector

fl_checked_both_halves:
		inc 0xd085										; No matching name in this 512 byte sector.
		lda 0xd085										; Load the next one, or give up the search
		cmp #11
		bne fl_load_next_dir_sector
														; Ran out of sectors in directory track
														; (XXX only checks side 0, and assumes DD disk)

		lda #0x80 										; Mark load as failed. 0x80 = File not found
		sta fastload_request
		rts

fl_load_next_dir_sector:
		jsr fl_read_sector								; Request read. No need to change state
		rts

; ------------------------------------------------------------------------------------------------------------------------------

fl_read_sector:

		; this function does a check to see if the next track/sector is already in the buffer or not
		; and skips loading if so

		lda fastload_request							; Remember the state that we need to return to
		sta fastload_request_stashed

		lda #5											; and then set ourselves to the track stepping/sector reading state
		sta fastload_request
														; FALLTHROUGH

	; ----------------------------------------------------------------------------------------------------------------------

fl_reading_sector:
		lda 0xd084										; Check if we are already on the correct track/side
		cmp fl_current_track							; and if not, select/step as required
		beq fl_on_correct_track
		bcc fl_step_in

fl_step_out:
		lda #0x18										; We need to step first
		sta 0xd081
		inc fl_current_track
		rts

fl_step_in:
		lda #0x10										; We need to step first
		sta 0xd081
		dec fl_current_track
		rts

fl_on_correct_track:
		lda 0xd084
		cmp fl_prev_track
		bne fl_not_prev_sector
		lda 0xd086
		cmp fl_prev_side
		bne fl_not_prev_sector
		lda 0xd085
		cmp fl_prev_sector
		bne fl_not_prev_sector

		lda fastload_request_stashed					; We are being asked to read the sector we already have in the buffer
		sta fastload_request							; Jump immediately to the correct routine
		jmp fl_fdc_not_busy

fl_not_prev_sector:
		lda #0x40										; ISSUE ACTUAL READ COMMAND
		sta 0xd081

		lda fastload_request_stashed					; Now that we are finally reading the sector,
		sta fastload_request							; restore the stashed state ID

		rts

fl_step_track:
		lda #3											; advance to next state (3=fl_read_file_block)
		sta fastload_request
														; FALL THROUGH

fl_read_next_sector:
		lda fl_file_next_track							; Check if we reached the end of the file first
		bne fl_not_end_of_file
		rts

fl_not_end_of_file:
		jsr fl_logical_to_physical_sector				; Read next sector of file	
		jsr fl_read_sector
		rts

fl_logical_to_physical_sector:
		lda 0xd084										; Remember current loaded sector, so that we can optimise when asked
		sta fl_prev_track								; to read other half of same physical sector
		lda 0xd085
		sta fl_prev_sector
		lda 0xd086
		sta fl_prev_side
														; Convert 1581 sector numbers to physical ones on the disk.
		jsr fl_select_side0								; Side = 0
		lda fl_file_next_track
		dec	a											; Physical Track = Logical Track - 1
		sta 0xd084

		; if logical sector < 20
		;     side = 0
		; else
		;     side = 1
		; physical sector = (logical sector - (side * 20)) / 2 + 1

		lda fl_file_next_sector							; Physical Sector = (Logical Sector/2) + 1
		lsr a
		inc a
		cmp #11											; If physical sector > 10, then sector=sector-10, side=1
		bcs fl_on_second_side							; but sides are inverted
		sta 0xd085

		rts

fl_on_second_side:
		sec
		sbc #10
		sta 0xd085
		jsr fl_select_side1
		rts

; ------------------------------------------------------------------------------------------------------------------------------

fl_iffl_read_file_block_init:

		; use simulated file loading to get IFFL header, which contains all load addresses and file sizes

		jsr fl_copy_sector_to_buffer					; copy sector to buffer (only to get number of files)

		lda fl_file_next_sector							; Work out which half we care about
		and #0x01
		bne fl_iffl_init_read_from_second_half			; odd next sector number, so second half

fl_iffl_init_read_from_first_half:
		lda fastload_sector_buffer+0x002				; read number of file entries in iffl from first sector (and skip 2 bytes for next_track/next_sector)
		sta fl_iffl_numfiles
		jmp fl_iffl_read_file_block_init_end

fl_iffl_init_read_from_second_half:
		lda fastload_sector_buffer+0x102				; read number of file entries in iffl from second sector (and skip 2 bytes for next_track/next_sector)
		sta fl_iffl_numfiles

fl_iffl_read_file_block_init_end

		lda #.byte0 fastload_iffl_header
		sta fastload_address+0
		lda #.byte1 fastload_iffl_header
		sta fastload_address+1
		lda #.byte2 fastload_iffl_header
		sta fastload_address+2
		lda #.byte3 fastload_iffl_header
		sta fastload_address+3

		clc
		lda fl_iffl_numfiles							; set sizeremaing to numfiles*8 + 1
		asl a
		asl a
		asl a
		inc a
		sta fl_iffl_sizeremaining+0
		lda #0x00
		sta fl_iffl_sizeremaining+1
		sta fl_iffl_sizeremaining+2
		sta fl_iffl_sizeremaining+3

		lda #0x02										; skip next-track, next-sector and numfiles
		sta fl_iffl_bytecounter
		lda #0x00
		sta fl_iffl_currentfile

		lda #0x07										; load and relocated the IFFL like any other file (but not calling decrunch)
		sta fastload_request
		jsr fl_waiting

		rts

; ------------------------------------------------------------------------------------------------------------------------------

fl_iffl_read_file_block:

		; fl_iffl_bytecounter is always in the $02-$ff range, because the first two bytes in the first and second half
		; of the SDC buffer always contain the nexttrack/nextsector, so are skipped.

		; this also means that the maximum number of bytes we ever have to copy is $fe ($100-2)
		; so we can always assume a 'full copy' if any of the upper 3 bytes of sizeremaining are not 0.
		; (and then figure out if (256 - counter) > sizeremaining to do a partial copy)

		jsr fl_copy_sector_to_buffer					; Get sector from FDC
														; TODO - check if there was actually a read or not, because
														; the correct buffer might already be here?

		lda fl_iffl_bytecounter							; set offset for DMA copy
		sta fl_read_address+0

		lda fl_file_next_sector							; Work out which half we care about
		and #0x01
		sta fl_current_half
		bne fl_iffl_read_from_second_half				; odd next sector number, so second half

fl_iffl_partial_read_from_first_half:
		lda #.byte1 fastload_sector_buffer
		sta fl_read_address+1
		bra fl_iffl_read_file_block_continue

fl_iffl_read_from_second_half:
		lda #.byte1 (fastload_sector_buffer+0x100)
		sta fl_read_address+1
		;bra fl_iffl_read_file_block_continue

fl_iffl_read_file_block_continue:

		lda fl_iffl_sizeremaining+3
		bne fl_iffl_fullcopy
		lda fl_iffl_sizeremaining+2
		bne fl_iffl_fullcopy
		lda fl_iffl_sizeremaining+1
		bne fl_iffl_fullcopy

		sec
		lda #0											; (256 - counter) > sizeremaining?
		sbc fl_iffl_bytecounter
		sec
		sbc fl_iffl_sizeremaining+0
		bcc fl_iffl_fullcopy							; yes, copy remaining buffer

fl_iffl_partialcopy:									; no, copy until remaining size

		lda fl_iffl_sizeremaining+0						; set bytes to copy
		sta fl_bytes_to_copy+0

		jsr fl_iffl_performcopy

		clc
		lda fl_iffl_bytecounter							; update bytecounter
		adc fl_bytes_to_copy+0
		sta fl_iffl_bytecounter

		; if the copy is 'partial' then do an extra check to see if the remaining file size was EXACTLY
		; the size of bytes left in the SDC buffer, otherwise fl_iffl_bytecounter ends up being 0.
		; in that case, reset fl_iffl_bytecounter to 0x02 and read the next block from disk
		; (by calling fl_iffl_read_file_block_advance_to_next)

		lda #0x00										; Mark end of loading
		sta fastload_request

		;IFFL_DEBUG_BREAK

		lda fl_iffl_bytecounter
		bne fl_iffl_partialcopy_finalise
		jsr fl_iffl_read_file_block_advance_to_next

fl_iffl_partialcopy_finalise:
		rts

fl_iffl_fullcopy:

		sec
		lda #0											; set bytes to copy
		sbc fl_iffl_bytecounter
		sta fl_bytes_to_copy+0

		jsr fl_iffl_performcopy

		jmp fl_iffl_read_file_block_advance_to_next

; ------------------------------------------------------------------------------------------------------------------------------

fl_iffl_read_file_block_advance_to_next:

		lda #0x02										; update bytecounter
		sta fl_iffl_bytecounter							; this is a full copy, so fl_iffl_bytecounter will always end up at #0x02

		lda fl_current_half
		bne fl_iffl_full_read_from_second_half			; odd next sector number, so second half

fl_iffl_full_read_from_first_half
		lda fastload_sector_buffer+0					; get nexttrack byte from first half
		sta fl_file_next_track
		lda fastload_sector_buffer+1					; get nextsector byte from first half
		sta fl_file_next_sector
		bra fl_iffl_dma_read_bytes

fl_iffl_full_read_from_second_half:
		lda fastload_sector_buffer+0x100				; get nexttrack byte from second half
		sta fl_file_next_track
		lda fastload_sector_buffer+0x101				; get nextsector byte from second half
		sta fl_file_next_sector
		;bra fl_iffl_dma_read_bytes

fl_iffl_dma_read_bytes:

		sec												; update sizeremaining and read next block
		lda fl_iffl_sizeremaining+0
		sbc fl_bytes_to_copy+0
		sta fl_iffl_sizeremaining+0
		lda fl_iffl_sizeremaining+1
		sbc #0
		sta fl_iffl_sizeremaining+1
		lda fl_iffl_sizeremaining+2
		sbc #0
		sta fl_iffl_sizeremaining+2
		lda fl_iffl_sizeremaining+3
		sbc #0
		sta fl_iffl_sizeremaining+3
		jsr fl_read_next_sector							; Schedule reading of next block

		rts

; ------------------------------------------------------------------------------------------------------------------------------

fl_iffl_performcopy:

		lda fastload_address+3							; Update destination address
		asl a
		asl a
		asl a
		asl a
		sta fl_data_read_dmalist+2						; update destination MB
		lda fastload_address+2
		lsr a
		lsr a
		lsr a
		lsr a
		ora fl_data_read_dmalist+2
		sta fl_data_read_dmalist+2						; update destination MB
		lda fastload_address+2
		and #0x0f
		sta fl_write_address+2							; update Dest bank
		lda fastload_address+1
		sta fl_write_address+1							; update Dest Address high
		lda fastload_address+0
		sta fl_write_address+0							; update Dest Address low

		lda #0x00										; Copy sector buffer data to final address
		sta 0xd704
		lda #.byte1 fl_data_read_dmalist
		sta 0xd701
		lda #.byte0 fl_data_read_dmalist
		sta 0xd705

		clc
		lda fastload_address+0							; Update load address
		adc fl_bytes_to_copy+0
		sta fastload_address+0
		lda fastload_address+1
		adc #0
		sta fastload_address+1
		lda fastload_address+2
		adc #0
		sta fastload_address+2
		lda fastload_address+3
		adc #0
		sta fastload_address+3

		rts

; ------------------------------------------------------------------------------------------------------------------------------

fl_read_file_block:
														; We have a sector from the floppy drive.
														; Work out which half and how many bytes, and copy them into place.

		jsr fl_copy_sector_to_buffer					; Get sector from FDC

		; LV - TODO - CHECK IF I CAN DO THIS SAFELY HERE. PROBABLY NEEDS MOVING UP!!!
		lda #0x02										; reset low byte of DMA src
		sta fl_read_address+0

		sec
		lda #0x00										; Assume full sector initially (256 bytes)
		sbc #0x02										; subtract 2 for track and sector bytes
		sta fl_bytes_to_copy+0

		lda fl_file_next_sector							; Work out which half we care about
		and #0x01
		bne fl_read_from_second_half					; odd next sector number, so second half

		lda #.byte1 fastload_sector_buffer				; fl_read_from_first_half
		sta fl_read_address+1
		lda fastload_sector_buffer+1
		sta fl_file_next_sector
		lda fastload_sector_buffer+0
		sta fl_file_next_track
		bne fl_dma_read_bytes							; if next track is 0 then this is a partial sector and 'sector' now becomes the number of bytes left in this sector

		lda fastload_sector_buffer+1					; fl_1st_half_partial_sector. track is 0, so sector contains number of bytes left
		sec												; subtract 1, because the byte that contains the size is included
		sbc #0x01
		sta fl_bytes_to_copy+0	
		lda #0x00										; Mark end of loading
		sta fastload_request
		jmp fl_dma_read_bytes

fl_read_from_second_half:
		lda #.byte1 (fastload_sector_buffer+0x100)
		sta fl_read_address+1
		lda fastload_sector_buffer+0x101
		sta fl_file_next_sector
		lda fastload_sector_buffer+0x100
		sta fl_file_next_track
		bne fl_dma_read_bytes							; if next track is 0 then this is a partial sector and 'sector' now becomes the number of bytes left in this sector

		lda fastload_sector_buffer+0x101				; fl_2nd_half_partial_sector. track is 0, so sector contains number of bytes left
		sec												; subtract 1, because the byte that contains the size is included
		sbc #0x01
		sta fl_bytes_to_copy+0
		lda #0x00										; Mark end of loading
		sta fastload_request
		jmp fl_dma_read_bytes

; ------------------------------------------------------------------------------------------------------------------------------

fl_dma_read_bytes:
		lda fastload_address+3							; Update destination address
		asl a
		asl a
		asl a
		asl a
		sta fl_data_read_dmalist+2						; update destination MB
		lda fastload_address+2
		lsr a
		lsr a
		lsr a
		lsr a
		ora fl_data_read_dmalist+2
		sta fl_data_read_dmalist+2						; update destination MB
		lda fastload_address+2
		and #0x0f
		sta fl_write_address+2							; update Dest bank
		lda fastload_address+1
		sta fl_write_address+1							; update Dest Address high
		lda fastload_address+0
		sta fl_write_address+0							; update Dest Address low

		lda #0x00										; Copy sector buffer data to final address
		sta 0xd704
		lda #.byte1 fl_data_read_dmalist
		sta 0xd701
		lda #.byte0 fl_data_read_dmalist
		sta 0xd705

		clc
		lda fastload_address+0							; Update load address
		adc fl_bytes_to_copy+0
		sta fastload_address+0
		lda fastload_address+1
		adc #0
		sta fastload_address+1
		lda fastload_address+2
		adc #0
		sta fastload_address+2
		lda fastload_address+3
		adc #0
		sta fastload_address+3

		jsr fl_read_next_sector							; Schedule reading of next block

		rts

; ------------------------------------------------------------------------------------------------------------------------------
		.public fl_get_endofbasic
fl_get_endofbasic

		clc
		lda fl_write_address+0							; last known copy position + $2001 - 2 (for start address)
		adc #0xff
		tax
		lda fl_write_address+1
		adc #0x1f
		tay
		rts

; ------------------------------------------------------------------------------------------------------------------------------

		.public fl_data_read_dmalist
fl_data_read_dmalist:
		.byte 0x0b										; F011A type list
		.byte 0x81,0x00									; Destination MB
		.byte 0											; no more options
		.byte 0											; copy
		.public fl_bytes_to_copy
fl_bytes_to_copy:
		.word 0											; size of copy. SECOND BYTE IS ALWAYS 0 BECAUSE WE'RE ALWAYS COPYING $FE AT MOST
		.public fl_read_address
fl_read_address:
		.word fastload_sector_buffer+2					; Source address. +2 is to skip track/header link
		.byte 0x00										; Source bank
		.public fl_write_address
fl_write_address:		
		.word 0											; Dest address
		.byte 0x00										; Dest bank
		.byte 0x00										; sub-command
		.word 0											; modulo (unused)

; ------------------------------------------------------------------------------------------------------------------------------

fl_copy_sector_to_buffer:
		lda #0x80										; Make sure FDC sector buffer is selected
		trb 0xd689
		lda #0x00										; Copy FDC data to our buffer
		sta 0xd704
		lda #.byte1 fl_sector_read_dmalist
		sta 0xd701
		lda #.byte0 fl_sector_read_dmalist
		sta 0xd705
		rts

fl_sector_read_dmalist:
		.byte 0x0b	 									; F011A type list
		.byte 0x80,0xff									; MB of FDC sector buffer address (0xFFD6C00)
		.byte 0											; no more options
		.byte 0											; copy
		.word 512										; size of copy
		.word 0x6c00									; low 16 bits of FDC sector buffer address (0xFFD6C00)
		.byte 0x0d										; next 4 bits of FDC sector buffer address (0xFFD6C00)
		.word fastload_sector_buffer					; Dest address	
		.byte 0x00										; Dest bank
		.byte 0x00										; sub-command
		.word 0											; modulo (unused)

; ------------------------------------------------------------------------------------------------------------------------------
