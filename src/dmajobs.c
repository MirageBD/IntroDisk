#include "constants.h"
#include "dmajobs.h"

dma_job dma_clearentiresafecolorram =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((SAFE_COLOR_RAM) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x01,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= 0x8000-COLOR_RAM_OFFSET,
	.source_addr			= 0b0000000000000000, // 00001000 = NCM chars, 00000100 = trim 8 pixels
	.source_bank_and_flags	= 0x00,
	.dest_addr				=  ((SAFE_COLOR_RAM) & 0xffff),
	.dest_bank_and_flags	= (((SAFE_COLOR_RAM) >> 16) & 0x0f),
	.modulo					= 0x0000
};



dma_job dma_cleartoplinecolorram1 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= 2*RRBSCREENWIDTH,
	.source_addr			= 0b0000000000001100, // 00001000 = NCM chars, 00000100 = trim 8 pixels
	.source_bank_and_flags	= 0x00,
	.dest_addr				=  ((SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2) & 0xffff),
	.dest_bank_and_flags	= (((SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2) >> 16) & 0x0f),
	.modulo					= 0x0000
};

dma_job dma_cleartoplinecolorram2 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2 + 1) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= 2*RRBSCREENWIDTH,
	.source_addr			= 0b0000000000001111, // 00000000 = $0f = pixels with value $0f take on the colour value of $0f as well
	.source_bank_and_flags	= 0x00,
	.dest_addr				=  ((SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2 + 1) & 0xffff),
	.dest_bank_and_flags	= (((SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2 + 1) >> 16) & 0x0f),
	.modulo					= 0x0000
};

dma_job dma_cleartoplinescreenram1 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= 2*RRBSCREENWIDTH,
	.source_addr			= (((FONTCHARMEM/64 + 0 /*star=10*/) >> 0)) & 0xff,
	.source_bank_and_flags	= 0x00,
	.dest_addr				=  ((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2) & 0xffff),
	.dest_bank_and_flags	= (((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2) >> 16) & 0x0f),
	.modulo					= 0x0000
};

dma_job dma_cleartoplinescreenram2 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2 + 1) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= 2*RRBSCREENWIDTH,
	.source_addr			= (((uint32_t)(FONTCHARMEM/64 + 0 /*star=10*/) >> 8)) & 0xff,
	.source_bank_and_flags	= 0x00,
	.dest_addr				=  ((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2 + 1) & 0xffff),
	.dest_bank_and_flags	= (((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2 + 1) >> 16) & 0x0f),
	.modulo					= 0x0000
};









dma_job dma_clearbottomlinecolorram1 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SAFE_COLOR_RAM + 36*RRBSCREENWIDTH2) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= 2*RRBSCREENWIDTH,
	.source_addr			= 0b0000000000001100, // 00001000 = NCM chars, 00000100 = trim 8 pixels
	.source_bank_and_flags	= 0x00,
	.dest_addr				=  ((uint32_t)(SAFE_COLOR_RAM + 36*RRBSCREENWIDTH2) & 0xffff),
	.dest_bank_and_flags	= (((uint32_t)(SAFE_COLOR_RAM + 36*RRBSCREENWIDTH2) >> 16) & 0x0f),
	.modulo					= 0x0000
};

dma_job dma_clearbottomlinecolorram2 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SAFE_COLOR_RAM + 36*RRBSCREENWIDTH2 + 1) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= 2*RRBSCREENWIDTH,
	.source_addr			= 0b0000000000001111, // 00000000 = $0f = pixels with value $0f take on the colour value of $0f as well
	.source_bank_and_flags	= 0x00,
	.dest_addr				=  ((uint32_t)(SAFE_COLOR_RAM + 36*RRBSCREENWIDTH2 + 1) & 0xffff),
	.dest_bank_and_flags	= (((uint32_t)(SAFE_COLOR_RAM + 36*RRBSCREENWIDTH2 + 1) >> 16) & 0x0f),
	.modulo					= 0x0000
};

dma_job dma_clearbottomlinescreenram1 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SCREEN + 36*RRBSCREENWIDTH2) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= 2*RRBSCREENWIDTH,
	.source_addr			= (((uint32_t)(FONTCHARMEM/64 + 0 /*star=10*/) >> 0)) & 0xff,
	.source_bank_and_flags	= 0x00,
	.dest_addr				=  (uint32_t)((SCREEN + 36*RRBSCREENWIDTH2) & 0xffff),
	.dest_bank_and_flags	= (((uint32_t)(SCREEN + 36*RRBSCREENWIDTH2) >> 16) & 0x0f),
	.modulo					= 0x0000
};

dma_job dma_clearbottomlinescreenram2 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SCREEN + 36*RRBSCREENWIDTH2 + 1) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= 2*RRBSCREENWIDTH,
	.source_addr			= (((uint32_t)(FONTCHARMEM/64 + 0 /*star=10*/) >> 8)) & 0xff,
	.source_bank_and_flags	= 0x00,
	.dest_addr				=  ((uint32_t)(SCREEN + 36*RRBSCREENWIDTH2 + 1) & 0xffff),
	.dest_bank_and_flags	= (((uint32_t)(SCREEN + 36*RRBSCREENWIDTH2 + 1) >> 16) & 0x0f),
	.modulo					= 0x0000
};







dma_job dma_copycolorramup =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= ((uint32_t)(SAFE_COLOR_RAM + 2*RRBSCREENWIDTH2) >> 20),
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x01,
	.end_options			= 0x00,
	.command				= 0b00000000, // copy, no chain
	.count					= 38*RRBSCREENWIDTH2,
	.source_addr			= ((uint32_t)(SAFE_COLOR_RAM + 2*RRBSCREENWIDTH2) & 0xffff),
	.source_bank_and_flags	= (((uint32_t)(SAFE_COLOR_RAM + 2*RRBSCREENWIDTH2) >> 16) & 0x0f),
	.dest_addr				= ((uint32_t)(SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2) & 0xffff),
	.dest_bank_and_flags	= (((uint32_t)(SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2) >> 16) & 0x0f),
	.modulo					= 0x0000
};

dma_job dma_copyscreenramup =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= ((uint32_t)(SCREEN + 2*RRBSCREENWIDTH2) >> 20),
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x01,
	.end_options			= 0x00,
	.command				= 0b00000000, // copy, no chain
	.count					= 38*RRBSCREENWIDTH2,
	.source_addr			= ((uint32_t)(SCREEN + 2*RRBSCREENWIDTH2) & 0xffff),
	.source_bank_and_flags	= (((uint32_t)(SCREEN + 2*RRBSCREENWIDTH2) >> 16) & 0x0f),
	.dest_addr				= ((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2) & 0xffff),
	.dest_bank_and_flags	= (((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2) >> 16) & 0x0f),
	.modulo					= 0x0000
};







// N.B. These DMA copies are in reverse order (we don't want to be copying over ourselves)
// that's why the direction flag is set so we copy in reverse order,
// and we add .count to source/dest to start at the end and move to the beginning
dma_job dma_copycolorramdown =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= ((uint32_t)(SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2 + 38*RRBSCREENWIDTH2 - 1) >> 20),
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SAFE_COLOR_RAM + 2*RRBSCREENWIDTH2 + 38*RRBSCREENWIDTH2 - 1) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x01,
	.end_options			= 0x00,
	.command				= 0b00000000, // copy, no chain
	.count					= 38*RRBSCREENWIDTH2,
	.source_addr			=  ((SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2 + 38*RRBSCREENWIDTH2 - 1) & 0xffff),
	.source_bank_and_flags	= (((SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2 + 38*RRBSCREENWIDTH2 - 1) >> 16) & 0x0f) | 0b01000000, // FLAGS = direction (bit6) = -1
	.dest_addr				=  ((SAFE_COLOR_RAM + 2*RRBSCREENWIDTH2 + 38*RRBSCREENWIDTH2 - 1) & 0xffff),
	.dest_bank_and_flags	= (((SAFE_COLOR_RAM + 2*RRBSCREENWIDTH2 + 38*RRBSCREENWIDTH2 - 1) >> 16) & 0x0f) | 0b01000000, // FLAGS = direction (bit6) = -1
	.modulo					= 0x0000
};

dma_job dma_copyscreenramdown =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= ((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2 + 38*RRBSCREENWIDTH2) >> 20),
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SCREEN + 2*RRBSCREENWIDTH2 + 38*RRBSCREENWIDTH2) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x01,
	.end_options			= 0x00,
	.command				= 0b00000000, // copy, no chain
	.count					= 38*RRBSCREENWIDTH2,
	.source_addr			=  ((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2 + 38*RRBSCREENWIDTH2 - 1) & 0xffff),
	.source_bank_and_flags	= (((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2 + 38*RRBSCREENWIDTH2 - 1) >> 16) & 0x0f) | 0b01000000, // FLAGS = direction (bit6) = -1
	.dest_addr				=  ((uint32_t)(SCREEN + 2*RRBSCREENWIDTH2 + 38*RRBSCREENWIDTH2 - 1) & 0xffff),
	.dest_bank_and_flags	= (((uint32_t)(SCREEN + 2*RRBSCREENWIDTH2 + 38*RRBSCREENWIDTH2 - 1) >> 16) & 0x0f) | 0b01000000, // FLAGS = direction (bit6) = -1
	.modulo					= 0x0000
};









dma_job dma_clearfullcolorram1 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((SAFE_COLOR_RAM + 0) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= (RRBSCREENWIDTH*50),
	.source_addr			= 0b0000000000001100, // 00001000 = NCM chars, 00000100 = trim 8 pixels
	.source_bank_and_flags	= 0x00,
	.dest_addr				= ((SAFE_COLOR_RAM + 0) & 0xffff),
	.dest_bank_and_flags	= (((SAFE_COLOR_RAM + 0) >> 16) & 0x0f),
	.modulo					= 0x0000
};

dma_job dma_clearfullcolorram2 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((SAFE_COLOR_RAM + 1) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= (RRBSCREENWIDTH*50),
	.source_addr			= 0b0000000000001111, // 00000000 = $0f = pixels with value $0f take on the colour value of $0f as well
	.source_bank_and_flags	= 0x00,
	.dest_addr				= ((SAFE_COLOR_RAM + 1) & 0xffff),
	.dest_bank_and_flags	= (((SAFE_COLOR_RAM + 1) >> 16) & 0x0f),
	.modulo					= 0x0000
};

dma_job dma_clearfullscreen1 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SCREEN + 0) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= (RRBSCREENWIDTH*50),
	.source_addr			= (((uint32_t)(FONTCHARMEM/64 + 0 /*star=10*/) >> 0)) & 0xff,
	.source_bank_and_flags	= 0x00,
	.dest_addr				= ((uint32_t)(SCREEN + 0) & 0xffff),
	.dest_bank_and_flags	= (((uint32_t)(SCREEN + 0) >> 16) & 0x0f),
	.modulo					= 0x0000
};

dma_job dma_clearfullscreen2 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SCREEN + 1) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= (RRBSCREENWIDTH*50),
	.source_addr			= (((uint32_t)(FONTCHARMEM/64 + 0 /*star=10*/) >> 8)) & 0xff,
	.source_bank_and_flags	= 0x00,
	.dest_addr				= ((uint32_t)(SCREEN + 1) & 0xffff),
	.dest_bank_and_flags	= (((uint32_t)(SCREEN + 1) >> 16) & 0x0f),
	.modulo					= 0x0000
};

// ---------------------------------------------------------------------------------------------

dma_job dma_clearcolorram1 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2 + 0) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= (RRBSCREENWIDTH*40),
	.source_addr			= 0b0000000000001100, // 00001000 = NCM chars, 00000100 = trim 8 pixels
	.source_bank_and_flags	= 0x00,
	.dest_addr				= ((uint32_t)(SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2 + 0) & 0xffff),
	.dest_bank_and_flags	= (((uint32_t)(SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2 + 0) >> 16) & 0x0f),
	.modulo					= 0x0000
};

dma_job dma_clearcolorram2 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2 + 1) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= (RRBSCREENWIDTH*40),
	.source_addr			= 0b0000000000001111, // 00000000 = $0f = pixels with value $0f take on the colour value of $0f as well
	.source_bank_and_flags	= 0x00,
	.dest_addr				= ((uint32_t)(SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2 + 1) & 0xffff),
	.dest_bank_and_flags	= (((uint32_t)(SAFE_COLOR_RAM + 0*RRBSCREENWIDTH2 + 1) >> 16) & 0x0f),
	.modulo					= 0x0000
};

dma_job dma_clearscreen1 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2 + 0) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= (RRBSCREENWIDTH*40),
	.source_addr			= (((uint32_t)(FONTCHARMEM/64 + 0 /*star=10*/) >> 0)) & 0xff,
	.source_bank_and_flags	= 0x00,
	.dest_addr				= ((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2 + 0) & 0xffff),
	.dest_bank_and_flags	= (((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2 + 0) >> 16) & 0x0f),
	.modulo					= 0x0000
};

dma_job dma_clearscreen2 =
{
	.type					= 0x0a,
	.sourcemb_token			= 0x80,
	.sourcemb				= 0x00,
	.destmb_token			= 0x81,
	.destmb					= ((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2 + 1) >> 20),
	.dskipratefrac_token	= 0x84,
	.dskipratefrac			= 0x00,
	.dskiprate_token		= 0x85,
	.dskiprate				= 0x02,
	.end_options			= 0x00,
	.command				= 0b00000011, // fill, no chain
	.count					= (RRBSCREENWIDTH*40),
	.source_addr			= (((uint32_t)(FONTCHARMEM/64 + 0 /*star=10*/) >> 8)) & 0xff,
	.source_bank_and_flags	= 0x00,
	.dest_addr				= ((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2 + 1) & 0xffff),
	.dest_bank_and_flags	= (((uint32_t)(SCREEN + 0*RRBSCREENWIDTH2 + 1) >> 16) & 0x0f),
	.modulo					= 0x0000
};
