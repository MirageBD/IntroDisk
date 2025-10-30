#ifndef __AUDIO_H
#define __AUDIO_H

extern uint8_t audio_volume;
extern void audio_applyvolume();
extern void audio_save_master_volumes();
extern void audio_restore_master_volumes();

#endif
