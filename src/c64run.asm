.cpu _45gs02

.file [name="../exe/c64run.prg", type="bin", segments="Code"]
.segmentdef Code [start=$2000]

//-----------------------------------------------------------------------------

	// this routine resets all mappings and jumps into the c64 rom reset routine
	// (is copied to $334)
	.segment ResetCode [start=$0334]
reset_routine_dst:
	lda #$00
	tax
	tay
	taz
	map
	eom

	jmp ($fff6)

//-----------------------------------------------------------------------------

	.segment PostResetCode [start=$07e8]
	// this routine is installed after screen memory ($7e8) to survive a reset
post_reset_routine_dst:
	// map our code back again (from $42000 to $2000)
	lda #$00
	ldx #$24
	ldy #$00
	ldz #$00
	map      // MAPL: 2400  MAPH: 0000
	eom
	// we are back, now we can jump into our autostart routine
	jmp autostart

//-----------------------------------------------------------------------------

	.segment BackupData [startAfter="PostResetCode", virtual]
basic_cold_start_backup:
	.fill 2, 0
	.label irq_vector_backup = basic_cold_start_backup
	.label basic_main_vector_backup = basic_cold_start_backup
basic_text_top_backup:
	.fill 2, 0

//-----------------------------------------------------------------------------

	.segment AutostartExitCode [start=$0334]
// resets mappings and exits to basic
autostart_exit_dst:
	lda #$00
   	tax
	tay
	taz
	map
	eom

	// jump to original basic cold start
	jmp ($a000)

// this irq routine patches the basic main vector
autostart_irq:
	// vectors are written from back to front
	// if we detect $301 to be non-zero, we know
	// that $302/$303 contains the correct main vector
	lda $301
	bne !+
	jmp (irq_vector_backup)
!:
	// restore irq vector
	lda irq_vector_backup
	sta $314
	lda irq_vector_backup+1
	sta $315

	lda $302
	sta basic_main_vector_backup
	lda $303
	sta basic_main_vector_backup+1

	lda #<main
	sta $302
	lda #>main
	sta $303

	jmp ($314)

main:
	sei

	// 40 MHz
	lda #$41
	sta $00

	// set first basic byte
	lda #$00
	sta $0800

	// Enable mega65 I/O personality
	lda #$47
	sta $d02f
	lda #$53
	sta $d02f

	// dma program from $50000
	sta $d707
	.byte $00	// end of job options
	.byte $00 	// copy
	.word $f7f9 	// count (all the way up to the cpu vectors)
	.word $0002 	// src
	.byte $05 	// srcbank
	.word $0801     // dst
	.byte $00	// dstbank 
	.byte $00 	// cmdhi
	.word $0000	// modulo / ignored

	// bank in all ram
	lda #$34
	sta $01

	// find text_top pointer going back in memory finding the first
	// byte not $ff, start right before the cpu vectors
	ldz #$00
	lda #$fa
	sta $2d
	lda #$ff
	sta $2e
!:	dew $2d
	lda ($2d),z
	cmp #$ff
	beq !-

	// restore c64 banking
	lda #$37
	sta $01

	// reset I/O to C64 mode
	lda #$00
	sta $d02f

	// simulate RUN<cr>
	lda #$52
	sta $277
	lda #$55
	sta $278
	lda #$4e
	sta $279
	lda #$0d
	sta $27a
	lda #$04
	sta $c6

	// 1 MHz
	lda #$40
	sta $00
	
	cli

main_exit:
	// restore basic main vector
	lda basic_main_vector_backup
	sta $302
	lda basic_main_vector_backup+1
	sta $303

	jmp ($302)


//-----------------------------------------------------------------------------

	.segment Code
	sei

	// Disable C65 ROM write protection via Hypervisor trap
	lda #$02
	sta $d641
	clv

	// copy reset routine to $0334
	ldx #reset_size
!:	lda reset_routine_src-1,x
	sta reset_routine_dst-1,x
	dex
	bne !-

	// copy post reset routine to $7e8
	ldx #post_reset_size
!:	lda post_reset_routine_src-1,x
	sta post_reset_routine_dst-1,x
	dex
	bne !-

	// bank in basic rom to be able to write to it
	lda #$00
	ldx #$24
	ldy #$00
	ldz #$22
	map      // MAPL: 2400  MAPH: 2200
	eom

	// backup and patch basic cold start vector
	lda $a000
	sta basic_cold_start_backup
	lda $a001
	sta basic_cold_start_backup+1
	// set vector to post reset routine
	lda #<post_reset_routine_dst
	sta $a000
	lda #>post_reset_routine_dst
	sta $a001

	// unmap SD sector buffer
	lda #$82
	sta $d680

	// disable seam
	lda #$d7
	trb $d054

	// 40 column mode normal C64 screen
	lda #$00
	sta $d030
	sta $d031
	lda #%00000011
	tsb $dd00
	lda #$c0    // also enable raster delay to match rendering with interrupts more correctly
	sta $d05d
	lda #$1b
	sta $d011
	lda #$c8
	sta $d016
	lda #$14
	sta $d018

	// reset I/O to C64 mode
	lda #$00
	sta $d02f

	// default C64 banking
	lda #$3f
	sta $00
	sta $01

	// default stack location
	ldx #$ff
	ldy #$01
	txs
	tys

	// only use 8-bit stack
	see

	// 1 MHz
	lda #$40
	sta $00

	// jmp to reset_c64 routine
	jmp reset_routine_dst

	// this routine installs the irq vector and restores patched basic rom bytes
autostart:
	sei

	// Enable mega65 I/O personality
	lda #$47
	sta $d02f
	lda #$53
	sta $d02f

	// bank in basic rom to be able to write to it
	lda #$00
	ldx #$24
	ldy #$00
	ldz #$22
	map      // MAPL: 2400  MAPH: 2200
	eom

	// restore basic cold start vector
	lda basic_cold_start_backup
	sta $a000
	lda basic_cold_start_backup+1
	sta $a001


	// restore rom write protection
	lda #$00
	sta $d641
	clv

	// reset I/O to C64 mode
	lda #$00
	sta $d02f

	// copy exit and irq routine to tmpbuffer ($334)
	ldx #autostart_exit_size
!:	lda autostart_exit_src-1,x
	sta autostart_exit_dst-1,x
	dex
	bne !-

	// backup original irq vector
	lda $314
	sta irq_vector_backup
	lda $315
	sta irq_vector_backup+1

	// setup irq
	lda #<autostart_irq
	sta $314
	lda #>autostart_irq
	sta $315

	// we have patched the irq vector, so exit to basic
	jmp autostart_exit_dst

post_reset_routine_src:
	.segmentout [segments="PostResetCode"]
	.label post_reset_size = * - post_reset_routine_src

reset_routine_src:
	.segmentout [segments="ResetCode"]
	.label reset_size = * - reset_routine_src

autostart_exit_src:
	.segmentout [segments="AutostartExitCode"]
	.label autostart_exit_size = * - autostart_exit_src
