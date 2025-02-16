# -----------------------------------------------------------------------------

megabuild		= 0
attachdebugger	= 0

# -----------------------------------------------------------------------------

MAKE			= make
RM				= rm -f

SRC_DIR			= ./src
EXE_DIR			= ./exe
BIN_DIR			= ./bin

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
else
	XMEGA65			= /c/Progra~1/xemu/xmega65.exe
	CMD				=
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
BINFILESMC += $(BIN_DIR)/menu.bin.addr.mc
BINFILESMC += $(BIN_DIR)/menu2.bin.addr.mc
BINFILESMC += $(BIN_DIR)/song.mod.addr.mc
BINFILESMC += $(BIN_DIR)/qrspr.bin.addr.mc
BINFILESMC += $(BIN_DIR)/id4_chars0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/id4_screen0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/id4_attrib0.bin.addr.mc

# -----------------------------------------------------------------------------

$(BIN_DIR)/glacial_chars0.bin: $(BIN_DIR)/glacial.bin
	$(MC) $< cm1:2 d1:0 cl1:20000 rc1:0

$(BIN_DIR)/logo_chars0.bin: $(BIN_DIR)/logo.bin
	$(MC) $< cm1:2 d1:0 cl1:18000 rc1:1

$(BIN_DIR)/id4_chars0.bin: $(BIN_DIR)/id4.bin
	$(MC) $< cm1:2 d1:0 cl1:58000 rc1:1

# currently, mod is 127kb ($20000, loaded at $30000) so $50000-$60000 is free for regular .prg loading!
# but we're not playing music when prg is loading, so safe to overwrite mod?

$(BIN_DIR)/alldata.bin: $(BINFILES)
	$(MEGAADDRESS) $(BIN_DIR)/glacial_pal0.bin        0000e000
	$(MEGAADDRESS) $(BIN_DIR)/logo_screen0.bin        0000e400
	$(MEGAADDRESS) $(BIN_DIR)/logo_attrib0.bin        0000e800
	$(MEGAADDRESS) $(BIN_DIR)/glacial_chars0.bin      00010000
	$(MEGAADDRESS) $(BIN_DIR)/logo_chars0.bin         00018000
	$(MEGAADDRESS) $(BIN_DIR)/menu.bin                00020000
	$(MEGAADDRESS) $(BIN_DIR)/menu2.bin               00050000
	$(MEGAADDRESS) $(BIN_DIR)/song.mod                00030000
	$(MEGAADDRESS) $(BIN_DIR)/qrspr.bin               00007000
	$(MEGAADDRESS) $(BIN_DIR)/id4_chars0.bin          00058000
	$(MEGAADDRESS) $(BIN_DIR)/id4_screen0.bin         0000ce00
	$(MEGAADDRESS) $(BIN_DIR)/id4_attrib0.bin         0000cf00
	$(MEGACRUNCH) $(BIN_DIR)/glacial_chars0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/glacial_pal0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/logo_chars0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/logo_screen0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/logo_attrib0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/menu.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/menu2.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/song.mod.addr
	$(MEGACRUNCH) $(BIN_DIR)/qrspr.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/id4_chars0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/id4_screen0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/id4_attrib0.bin.addr
	$(MEGAIFFL) $(BINFILESMC) $(BIN_DIR)/alldata.bin

$(EXE_DIR)/%.o: %.s
	as6502 --target=mega65 --list-file=$(@:%.o=%.lst) -o $@ $<

$(EXE_DIR)/%.o: %.c
	cc6502 --target=mega65 --code-model=plain -O2 --list-file=$(@:%.o=%.lst) -o $@ $<

$(EXE_DIR)/%-debug.o: %.s
	as6502 --target=mega65 --debug --list-file=$(@:%.o=%.lst) -o $@ $<

$(EXE_DIR)/%-debug.o: %.c
	cc6502 --target=mega65 --debug --list-file=$(@:%.o=%.lst) -o $@ $<

# there are multiple places that need to be changed for the start address:
# ln6502 command line option --load-address 0x1000
# megacrunch start address -f 1000
# scm file   address (#x1000) section (programStart #x1000)

$(EXE_DIR)/intro4.prg: $(OBJS)
	ln6502 --target=mega65 mega65-custom.scm -o $@ $^ --load-address 0x1200 --raw-multiple-memories --cstartup=mystartup --rtattr printf=nofloat --rtattr exit=simplified --output-format=prg --verbose --list-file=$(EXE_DIR)/intro4.lst

$(EXE_DIR)/intro4.prg.mc: $(EXE_DIR)/intro4.prg
	$(MEGACRUNCH) -f 1200 $(EXE_DIR)/intro4.prg

# -----------------------------------------------------------------------------

# autoboot.c65

$(EXE_DIR)/intro4.d81: $(EXE_DIR)/intro4.prg.mc  $(BIN_DIR)/alldata.bin
	$(RM) $@
	$(CC1541) -n "intro4" -i " 2024" -d 19 -v\
	 \
	 -f "autoboot.c65"     -w "$(EXE_DIR)/intro4.prg.mc"    \
	 -f "introdata"        -w "$(BIN_DIR)/alldata.bin"      \
	 -f "3d functions"     -w "$(BIN_DIR)/3D FUNCTIONS.PRG" \
	 -f "3d 4-in-a-row"    -w "$(BIN_DIR)/3d4.prg"          \
	 -f "alpha burst"      -w "$(BIN_DIR)/alpha burst.prg"  \
	 -f "amiga theme"      -w "$(BIN_DIR)/Amiga Theme.prg"  \
	 -f "basictracker-1.1" -w "$(BIN_DIR)/basictracker-1.1.prg" \
	 -f "cal"              -w "$(BIN_DIR)/cal.prg"          \
	 -f "fireplace"        -w "$(BIN_DIR)/FIREPLACE.prg"    \
	 -f "hangthedj"        -w "$(BIN_DIR)/hangthedj.prg"    \
	 -f "joytest65"        -w "$(BIN_DIR)/joytest65.prg"    \
	 -f "megamod"          -w "$(BIN_DIR)/megamod.prg"      \
	 -f "mondrian_sim"     -w "$(BIN_DIR)/mondrian_sim.prg" \
	 -f "pattern v4"       -w "$(BIN_DIR)/pattern v4.prg"   \
	 -f "pelota"           -w "$(BIN_DIR)/pelota.prg"       \
	 -f "simple txt scrol" -w "$(BIN_DIR)/simple txt scrol.prg"  \
	 -f "snake65 1.0"      -w "$(BIN_DIR)/snake65 1.0.prg"  \
	 -f "soccer"           -w "$(BIN_DIR)/soccer.prg"       \
	 -f "unelite p1"       -w "$(BIN_DIR)/unelite p1.prg"   \
	 -f "romlister"        -w "$(BIN_DIR)/romlister.prg"    \
	$@

# -----------------------------------------------------------------------------

run: $(EXE_DIR)/intro4.d81

# test converting C file to asm
#	cc6502 --target=mega65 $(SRC_DIR)/skeleton.c --assembly-source=$(EXE_DIR)/skeleton.s

ifeq ($(megabuild), 1)
	$(MEGAFTP) -c "put .\exe\intro4.d81 intro4.d81" -c "quit"
	$(EL) -m "INTRO4.D81" -r "$(EXE_DIR)/intro4.prg.mc"
ifeq ($(attachdebugger), 1)
	m65dbg --device /dev/ttyS2
endif
else
ifeq ($(attachdebugger), 1)
	$(CMD) "$(XMEGA65) -uartmon :4510 -autoload -8 $(EXE_DIR)/intro4.d81" & m65dbg -l tcp 4510
else ifeq ($(lars), 1)
#	$(CMD) $(XMEGA65) -hickup HICKUP.M65 -autoload -8 $(EXE_DIR)/intro4.d81
	rm -f '/cygdrive/c/Users/larsv/AppData/Roaming/xemu-lgb/mega65/hdos/intro4.d81'
	cp $(EXE_DIR)/intro4.d81 '/cygdrive/c/Users/larsv/AppData/Roaming/xemu-lgb/mega65/hdos/'
	$(CMD) $(XMEGA65) -hdosvirt -uartmon :4510 -autoload -8 $(EXE_DIR)/intro4.d81
else
	cp $(EXE_DIR)/intro4.d81 'C:\Users\phuon\AppData\Roaming\xemu-lgb\mega65\hdos\'
	$(CMD) $(XMEGA65) -hdosvirt -uartmon :4510 -autoload -8 $(EXE_DIR)/intro4.d81 &
endif
endif

clean:
	-rm -f $(OBJS) $(OBJS:%.o=%.lst) $(OBJS_DEBUG) $(OBJS_DEBUG:%.o=%.lst)
	-rm -f $(EXE_DIR)/intro4.d81 $(EXE_DIR)/hello.elf $(EXE_DIR)/hello.prg $(EXE_DIR)/hello.prg.mc $(EXE_DIR)/hello.lst $(EXE_DIR)/hello-debug.lst
