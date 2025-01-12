# -----------------------------------------------------------------------------

megabuild		= 1
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
XMEGA65			= D:\PCTOOLS\xemu\xmega65.exe
MEGAFTP			= mega65_ftp -e

.SUFFIXES: .o .s .out .bin .pu .b2 .a

default: all

VPATH = src

# Common source files
ASM_SRCS = decruncher.s iffl.s irqload.s irq_fastload.s irq_main.s sdc_asm.s fontsys_asm.s startup.s
C_SRCS = main.c dma.c modplay.c keyboard.c sdc.c fontsys.c dmajobs.c program.c

OBJS = $(ASM_SRCS:%.s=$(EXE_DIR)/%.o) $(C_SRCS:%.c=$(EXE_DIR)/%.o)
OBJS_DEBUG = $(ASM_SRCS:%.s=$(EXE_DIR)/%-debug.o) $(C_SRCS:%.c=$(EXE_DIR)/%-debug.o)

BINFILES  = $(BIN_DIR)/glacial_chars0.bin
BINFILES += $(BIN_DIR)/glacial_pal0.bin
BINFILES += $(BIN_DIR)/logo_chars0.bin
BINFILES += $(BIN_DIR)/logo_screen0.bin
BINFILES += $(BIN_DIR)/logo_attrib0.bin
BINFILES += $(BIN_DIR)/menu.bin
BINFILES += $(BIN_DIR)/song.mod
BINFILES += $(BIN_DIR)/qrspr.bin

BINFILESMC  = $(BIN_DIR)/glacial_chars0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/glacial_pal0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/logo_chars0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/logo_screen0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/logo_attrib0.bin.addr.mc
BINFILESMC += $(BIN_DIR)/menu.bin.addr.mc
BINFILESMC += $(BIN_DIR)/song.mod.addr.mc
BINFILESMC += $(BIN_DIR)/qrspr.bin.addr.mc

# -----------------------------------------------------------------------------

$(BIN_DIR)/glacial_chars0.bin: $(BIN_DIR)/glacial.bin
	$(MC) $< cm1:2 d1:0 cl1:20000 rc1:0

$(BIN_DIR)/logo_chars0.bin: $(BIN_DIR)/logo.bin
	$(MC) $< cm1:2 d1:0 cl1:14000 rc1:1

# currently, mod is 127kb ($20000, loaded at $30000) so $50000-$60000 is free for regular .prg loading!

$(BIN_DIR)/alldata.bin: $(BINFILES)
	$(MEGAADDRESS) $(BIN_DIR)/glacial_pal0.bin        0000c000
	$(MEGAADDRESS) $(BIN_DIR)/logo_screen0.bin        0000c400
	$(MEGAADDRESS) $(BIN_DIR)/logo_attrib0.bin        0000c800
	$(MEGAADDRESS) $(BIN_DIR)/glacial_chars0.bin      00010000
	$(MEGAADDRESS) $(BIN_DIR)/logo_chars0.bin         00014000
	$(MEGAADDRESS) $(BIN_DIR)/menu.bin                00020000
	$(MEGAADDRESS) $(BIN_DIR)/song.mod                00030000
	$(MEGAADDRESS) $(BIN_DIR)/qrspr.bin               00007000
	$(MEGACRUNCH) $(BIN_DIR)/glacial_chars0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/glacial_pal0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/logo_chars0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/logo_screen0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/logo_attrib0.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/menu.bin.addr
	$(MEGACRUNCH) $(BIN_DIR)/song.mod.addr
	$(MEGACRUNCH) $(BIN_DIR)/qrspr.bin.addr
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
	ln6502 --target=mega65 mega65-custom.scm -o $@ $^ --load-address 0x1600 --raw-multiple-memories --cstartup=mystartup --rtattr printf=nofloat --rtattr exit=simplified --output-format=prg --verbose --list-file=$(EXE_DIR)/intro4.lst

$(EXE_DIR)/intro4.prg.mc: $(EXE_DIR)/intro4.prg
	$(MEGACRUNCH) -f 1600 $(EXE_DIR)/intro4.prg

# -----------------------------------------------------------------------------

$(EXE_DIR)/intro4.d81: $(EXE_DIR)/intro4.prg.mc  $(BIN_DIR)/alldata.bin
	$(RM) $@
	$(CC1541) -n "intro4" -i " 2024" -d 19 -v\
	 \
	 -f "autoboot.c65" -w $(EXE_DIR)/intro4.prg.mc \
	 -f "introdata" -w $(BIN_DIR)/alldata.bin \
	 -f "automata" -w $(BIN_DIR)/automata.prg \
	 -f "amiga theme" -w "$(BIN_DIR)/Amiga Theme.prg" \
	 -f "megatorn" -w $(BIN_DIR)/megatorn.prg \
	 -f "megatrn.ifflcrch" -w $(BIN_DIR)/megatrn.ifflcrch.prg \
	 -f "megaint" -w $(BIN_DIR)/megaint.prg \
	 -f "megaint.data" -w $(BIN_DIR)/megaint.data.prg \
	$@

# -----------------------------------------------------------------------------

run: $(EXE_DIR)/intro4.d81

# test converting C file to asm
#	cc6502 --target=mega65 $(SRC_DIR)/skeleton.c --assembly-source=$(EXE_DIR)/skeleton.s

ifeq ($(megabuild), 1)
	$(MEGAFTP) -c "put .\exe\intro4.d81 intro4.d81" -c "quit"
	$(EL) -m INTRO4.D81 -r $(EXE_DIR)/intro4.prg.mc
ifeq ($(attachdebugger), 1)
	m65dbg --device /dev/ttyS2
endif
else
ifeq ($(attachdebugger), 1)
	cmd.exe /c "$(XMEGA65) -uartmon :4510 -autoload -8 $(EXE_DIR)/intro4.d81" & m65dbg -l tcp 4510
else
	cmd.exe /c "$(XMEGA65) -autoload -8 $(EXE_DIR)/intro4.d81"
endif
endif

clean:
	-rm -f $(OBJS) $(OBJS:%.o=%.lst) $(OBJS_DEBUG) $(OBJS_DEBUG:%.o=%.lst)
	-rm -f $(EXE_DIR)/intro4.d81 $(EXE_DIR)/hello.elf $(EXE_DIR)/hello.prg $(EXE_DIR)/hello.prg.mc $(EXE_DIR)/hello.lst $(EXE_DIR)/hello-debug.lst
