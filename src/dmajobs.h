#ifndef __DMAJOBS_H
#define __DMAJOBS_H

#include "dma.h"

extern dma_job dma_clearentiresafecolorram;

extern dma_job dma_clearheaderlinecolorram1;
extern dma_job dma_clearheaderlinecolorram2;
extern dma_job dma_clearheaderlinescreenram1;
extern dma_job dma_clearheaderlinescreenram2;

extern dma_job dma_clearfooterlinescolorram1;
extern dma_job dma_clearfooterlinescolorram2;
extern dma_job dma_clearfooterlinesscreenram1;
extern dma_job dma_clearfooterlinesscreenram2;

extern dma_job dma_clearfullcolorram1;
extern dma_job dma_clearfullcolorram2;
extern dma_job dma_clearfullscreen1;
extern dma_job dma_clearfullscreen2;

extern dma_job dma_clearcolorram1;
extern dma_job dma_clearcolorram2;
extern dma_job dma_clearscreen1;
extern dma_job dma_clearscreen2;

extern dma_job dma_cleartoplinecolorram1;
extern dma_job dma_cleartoplinecolorram2;
extern dma_job dma_cleartoplinescreenram1;
extern dma_job dma_cleartoplinescreenram2;

extern dma_job dma_clearbottomlinecolorram1;
extern dma_job dma_clearbottomlinecolorram2;
extern dma_job dma_clearbottomlinescreenram1;
extern dma_job dma_clearbottomlinescreenram2;

extern dma_job dma_copycolorramup;
extern dma_job dma_copyscreenramup;

extern dma_job dma_copycolorramdown;
extern dma_job dma_copyscreenramdown;

#endif