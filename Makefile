# -----------------------------------------------------------------------------

megabuild		= 0
attachdebugger	= 0
calypsiversion	= 5.6

# -----------------------------------------------------------------------------

MAKE			= make
RM				= rm -f

SRC_DIR			= ./src
EXE_DIR			= ./exe
BIN_DIR			= ./bin
PRG_DIR			= ./prg

AS6502			= D:\calypsi-6502-$(calypsiversion)\bin\as6502.exe
CC6502			= D:\calypsi-6502-$(calypsiversion)\bin\cc6502.exe
LN6502			= D:\calypsi-6502-$(calypsiversion)\bin\ln6502.exe
C1541			= c1541
CC1541			= cc1541
MC				= MegaConvert
MEGAADDRESS		= megatool -a
MEGACRUNCH		= megatool -c
MEGAIFFL		= megatool -i
EL				= etherload
MEGAFTP			= mega65_ftp -e

ifeq ($(lars), 1)
	XMEGA65			= D:\PCTOOLS\xemu\xmega65.exe
	CMD				= cmd.exe /c
	JAVA			= java
else
	XMEGA65			= /c/projs/xemu/build/bin/xmega65.native
	# XMEGA65		= /c/Progra~1/xemu/xmega65.exe
	CMD				=
	JAVA			= /usr/bin/java
	AS6502			= as6502.exe
	CC6502			= cc6502.exe
	LN6502			= ln6502.exe
endif

.SUFFIXES: .o .s .out .bin .pu .b2 .a

default: all

VPATH = src

# Common source files
ASM_SRCS = decruncher.s iffl.s irqload.s audio_asm.s program_asm.s irq_fadeout.s irq_fastload.s irq_main.s fontsys_asm.s startup.s
C_SRCS = main.c dma.c modplay.c keyboard.c fontsys.c dmajobs.c program.c

OBJS = $(ASM_SRCS:%.s=$(EXE_DIR)/%.o) $(C_SRCS:%.c=$(EXE_DIR)/%.o)
OBJS_DEBUG = $(ASM_SRCS:%.s=$(EXE_DIR)/%-debug.o) $(C_SRCS:%.c=$(EXE_DIR)/%-debug.o)

BINFILES  = $(BIN_DIR)/glacial_chars0.bin
BINFILES += $(BIN_DIR)/glacial_pal0.bin
BINFILES += $(BIN_DIR)/logo_chars0.bin
BINFILES += $(BIN_DIR)/logo_screen0.bin
BINFILES += $(BIN_DIR)/logo_attrib0.bin
BINFILES += $(BIN_DIR)/qranchors_sprites0.bin
BINFILES += $(BIN_DIR)/qranchors_sprites1.bin
BINFILES += $(BIN_DIR)/qranchors_sprites2.bin
BINFILES += $(BIN_DIR)/unicorn_sprites0.bin
BINFILES += $(BIN_DIR)/unicorn_sprites1.bin
BINFILES += $(BIN_DIR)/unicorn_sprites2.bin
BINFILES += $(BIN_DIR)/unicorn_sprites3.bin
BINFILES += $(BIN_DIR)/unicorn_sprites4.bin
BINFILES += $(BIN_DIR)/unicorn_sprites5.bin
BINFILES += $(BIN_DIR)/menu.bin
BINFILES += $(BIN_DIR)/menu2.bin
BINFILES += $(BIN_DIR)/song.mod
BINFILES += $(BIN_DIR)/qrspr.bin
BINFILES += $(BIN_DIR)/id4_chars0.bin
BINFILES += $(BIN_DIR)/id4_screen0.bin
BINFILES += $(BIN_DIR)/id4_attrib0.bin

BINFILESMC  = $(BIN_DIR)/glacial_chars0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/glacial_pal0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/logo_chars0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/logo_screen0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/logo_attrib0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/qranchors_sprites0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/qranchors_sprites1.bin.addr.mc
BINFILESMC += $(BIN_DIR)/qranchors_sprites2.bin.addr.mc
BINFILESMC += $(BIN_DIR)/unicorn_sprites0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/unicorn_sprites1.bin.addr.mc
BINFILESMC += $(BIN_DIR)/unicorn_sprites2.bin.addr.mc
BINFILESMC += $(BIN_DIR)/unicorn_sprites3.bin.addr.mc
BINFILESMC += $(BIN_DIR)/unicorn_sprites4.bin.addr.mc
BINFILESMC += $(BIN_DIR)/unicorn_sprites5.bin.addr.mc
BINFILESMC += $(BIN_DIR)/menu.bin.addr.mc
BINFILESMC += $(BIN_DIR)/menu2.bin.addr.mc
BINFILESMC += $(BIN_DIR)/song.mod.addr.mc
BINFILESMC += $(BIN_DIR)/qrspr.bin.addr.mc
BINFILESMC += $(BIN_DIR)/id4_chars0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/id4_screen0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/id4_attrib0.bin.addr.mc

# -----------------------------------------------------------------------------

$(BIN_DIR)/qranchors_sprites0.bin: $(BIN_DIR)/qranchors.bin
	$(MC) $< sm1:1 d1:0 cl1:20000 rc1:0

$(BIN_DIR)/unicorn_sprites0.bin: $(BIN_DIR)/unicorn.bin
	$(MC) $< sm1:1 d1:0 cl1:20000 rc1:0

$(BIN_DIR)/glacial_chars0.bin: $(BIN_DIR)/glacial.bin
	$(MC) $< cm1:2 d1:0 cl1:20000 rc1:0

$(BIN_DIR)/logo_chars0.bin: $(BIN_DIR)/logo.bin
	$(MC) $< cm1:2 d1:0 cl1:18000 rc1:1

$(BIN_DIR)/id4_chars0.bin: $(BIN_DIR)/id4.bin
	$(MC) $< cm1:2 d1:0 cl1:5e000 rc1:1

# currently, mod is 127kb ($20000, loaded at $30000) so $50000-$60000 is free for regular .prg loading!
# but we're not playing music when prg is loading, so safe to overwrite mod?

$(BIN_DIR)/alldata.bin: $(BINFILES)
	$(MEGAADDRESS) $(BIN_DIR)/glacial_pal0.bin        0000c800
	$(MEGAADDRESS) $(BIN_DIR)/logo_screen0.bin        0000ec00
	$(MEGAADDRESS) $(BIN_DIR)/logo_attrib0.bin        0000f100
	$(MEGAADDRESS) $(BIN_DIR)/glacial_chars0.bin      00010000
	$(MEGAADDRESS) $(BIN_DIR)/logo_chars0.bin         00018000
	$(MEGAADDRESS) $(BIN_DIR)/qranchors_sprites0.bin  0001e200
	$(MEGAADDRESS) $(BIN_DIR)/qranchors_sprites1.bin  0001e400
	$(MEGAADDRESS) $(BIN_DIR)/qranchors_sprites2.bin  0001e600
	$(MEGAADDRESS) $(BIN_DIR)/unicorn_sprites0.bin    0001e800
	$(MEGAADDRESS) $(BIN_DIR)/unicorn_sprites1.bin    0001ec00
	$(MEGAADDRESS) $(BIN_DIR)/unicorn_sprites2.bin    0001f000
	$(MEGAADDRESS) $(BIN_DIR)/unicorn_sprites3.bin    0001f400
	$(MEGAADDRESS) $(BIN_DIR)/unicorn_sprites4.bin    0001f800
	$(MEGAADDRESS) $(BIN_DIR)/unicorn_sprites5.bin    0001fc00
	$(MEGAADDRESS) $(BIN_DIR)/menu.bin                00020000
	$(MEGAADDRESS) $(BIN_DIR)/menu2.bin               00050000
	$(MEGAADDRESS) $(BIN_DIR)/song.mod                00030000
	$(MEGAADDRESS) $(BIN_DIR)/qrspr.bin               0000e000
	$(MEGAADDRESS) $(BIN_DIR)/id4_chars0.bin          0005e000
	$(MEGAADDRESS) $(BIN_DIR)/id4_screen0.bin         0000ce00
	$(MEGAADDRESS) $(BIN_DIR)/id4_attrib0.bin         0000cf00
	$(MEGACRUNCH) $(BIN_DIR)/glacial_chars0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/glacial_pal0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/logo_chars0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/logo_screen0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/logo_attrib0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/qranchors_sprites0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/qranchors_sprites1.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/qranchors_sprites2.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/unicorn_sprites0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/unicorn_sprites1.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/unicorn_sprites2.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/unicorn_sprites3.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/unicorn_sprites4.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/unicorn_sprites5.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/menu.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/menu2.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/song.mod.addr
	$(MEGACRUNCH) $(BIN_DIR)/qrspr.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/id4_chars0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/id4_screen0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/id4_attrib0.bin.addr
	$(MEGAIFFL) $(BINFILESMC) $(BIN_DIR)/alldata.bin

$(EXE_DIR)/%.o: %.s $(EXE_DIR)/c64run.prg
	$(AS6502) --target=mega65 --list-file=$(@:%.o=%.clst) -o $@ $<

$(EXE_DIR)/%.o: %.c
	$(CC6502) --target=mega65 -O2 --list-file=$(@:%.o=%.clst) -o $@ $<

$(EXE_DIR)/%-debug.o: %.s
	$(AS6502) --target=mega65 --debug --list-file=$(@:%.o=%.clst) -o $@ $<

$(EXE_DIR)/%-debug.o: %.c
	$(CC6502) --target=mega65 --debug --list-file=$(@:%.o=%.clst) -o $@ $<

# there are multiple places that need to be changed for the start address:
# ln6502 command line option --load-address 0x1000
# megacrunch start address -f 1000
# scm file   address (#x1000) section (programStart #x1000)

$(EXE_DIR)/intro5.prg: $(OBJS)
	$(LN6502) --target=mega65 mega65-custom.scm -o $@ $^ --load-address 0x1200 --raw-multiple-memories --cstartup=mystartup --rtattr printf=nofloat --rtattr exit=simplified --output-format=prg --verbose --list-file=$(EXE_DIR)/intro5.cmap

$(EXE_DIR)/intro5.prg.mc: $(EXE_DIR)/intro5.prg
	$(MEGACRUNCH) -f 1200 $(EXE_DIR)/intro5.prg

$(EXE_DIR)/c64run.prg: $(SRC_DIR)/c64run.asm
	$(JAVA) -jar KickAss65CE02-5.24f.jar -afo $<

# -----------------------------------------------------------------------------

# autoboot.c65

$(EXE_DIR)/intro5.d81: $(EXE_DIR)/intro5.prg.mc  $(BIN_DIR)/alldata.bin
	$(RM) $@
	$(CC1541) -n "intro disk 5" -i " 2026" -d 19 -v\
	 \
	 -f "autoboot.c65"     -w "$(EXE_DIR)/intro5.prg.mc"          \
	 -f "introdata"        -w "$(BIN_DIR)/alldata.bin"            \
	 -f "alpha maze"       -w "$(PRG_DIR)/alpha maze.prg"         \
	 -f "bugs"             -w "$(PRG_DIR)/bugs.prg"               \
	 -f "cribbage"         -w "$(PRG_DIR)/cribbage.prg"           \
	 -f "firework"         -w "$(PRG_DIR)/firework.prg"           \
	 -f "use1571as8"       -w "$(PRG_DIR)/use1571as8.prg"         \
	 -f "overlord"         -w "$(PRG_DIR)/overlord.prg"           \
	 -f "smoothscroll"     -w "$(PRG_DIR)/smoothscroll.prg"       \
	 -f "snowflake!"       -w "$(PRG_DIR)/snowflake!.prg"         \
	 -f "c128"             -w "$(PRG_DIR)/c128.prg"               \
	 -f "fcm"              -w "$(PRG_DIR)/fcm.prg"                \
	 -f "6502fb-mega65"    -w "$(PRG_DIR)/6502fb-mega65.prg"      \
	 -f "escape"           -w "$(PRG_DIR)/escape.prg"             \
	 -f "fifthwins"        -w "$(PRG_DIR)/fifthwins.prg"          \
	 -f "fullscreenscrool" -w "$(PRG_DIR)/fullscreenscrool.prg"   \
	 -f "megasweeperdemo"  -w "$(PRG_DIR)/megasweeperdemo.prg"    \
	 -f "bigscreen"        -w "$(PRG_DIR)/bigscreen.prg"          \
	 -f "haiku"            -w "$(PRG_DIR)/haiku.prg"              \
	 -f "hilbert"          -w "$(PRG_DIR)/hilbert.prg"            \
	 -f "mandelbr8"        -w "$(PRG_DIR)/mandelbr8.prg"          \
	 -f "matrix65"         -w "$(PRG_DIR)/matrix65.prg"           \
	 -f "maze"             -w "$(PRG_DIR)/maze.prg"               \
	 -f "siege"            -w "$(PRG_DIR)/siege.prg"              \
	 -f "tankvufo"         -w "$(PRG_DIR)/tankvufo.prg"           \
	 -f "game of life"     -w "$(PRG_DIR)/game of life.prg"       \
	 -f "gogo65"           -w "$(PRG_DIR)/gogo65.prg"             \
	 -f "iondrift"         -w "$(PRG_DIR)/iondrift.prg"           \
	 -f "megaqix"          -w "$(PRG_DIR)/megaqix.prg"            \
	$@

# -----------------------------------------------------------------------------

run: $(EXE_DIR)/intro5.d81

# test converting C file to asm
#	cc6502 --target=mega65 $(SRC_DIR)/skeleton.c --assembly-source=$(EXE_DIR)/skeleton.s

ifeq ($(megabuild), 1)
	$(MEGAFTP) -c "put .\exe\intro5.d81 intro5.d81" -c "quit"
	$(EL) -m "INTRO5.D81" -r "$(EXE_DIR)/intro5.prg.mc"
ifeq ($(attachdebugger), 1)
	m65dbg --device /dev/ttyS2
endif
else
ifeq ($(attachdebugger), 1)
	$(CMD) "$(XMEGA65) -uartmon :4510 -autoload -8 $(EXE_DIR)/intro5.d81" & m65dbg -l tcp 4510
else ifeq ($(lars), 1)
#	$(CMD) $(XMEGA65) -hickup HICKUP.M65 -autoload -8 $(EXE_DIR)/intro5.d81
	rm -f '/cygdrive/c/Users/larsv/AppData/Roaming/xemu-lgb/mega65/hdos/intro5.d81'
	cp $(EXE_DIR)/intro5.d81 'C:\Users\larsv\AppData\Roaming\xemu-lgb\mega65\hdos\'
	$(CMD) $(XMEGA65) -hdosvirt -uartmon :4510 -autoload -8 $(EXE_DIR)/intro5.d81
else
	cp $(EXE_DIR)/intro5.d81 'C:\Users\phuon\AppData\Roaming\xemu-lgb\mega65\hdos\INTRO5.D81'
	cp $(EXE_DIR)/intro5.d81 'C:\projs\mega65-release-prep\ALL_INTROS\sdcard-files\INTRO5.D81'
	cp $(EXE_DIR)/intro5.d81 'C:\projs\mega65-release-prep\disk5\final\INTRO5.D81'
	$(CMD) $(XMEGA65) -hickup c:/cygwin64/home/phuon/projs/mega65-core/bin/HICKUP.M65 -rom c:/projs/mega65-rom/newrom.bin -hdosvirt -emufhotkeys -uartmon :4510 -autoload -8 $(EXE_DIR)/INTRO5.D81
endif
endif

clean:
	-rm -f $(OBJS) $(OBJS:%.o=%.clst) $(OBJS_DEBUG) $(OBJS_DEBUG:%.o=%.clst) $(BIN_DIR)/*_*.bin
	-rm -f $(EXE_DIR)/INTRO5.D81 $(EXE_DIR)/intro5.d81 $(EXE_DIR)/intro5.elf $(EXE_DIR)/intro5.prg $(EXE_DIR)/intro5.prg.mc $(EXE_DIR)/*.clst $(EXE_DIR)/*.lst
