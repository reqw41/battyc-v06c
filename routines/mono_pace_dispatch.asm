; Avoid row-cost accounting overhead in small scenes. Their normal raster
; waiter is retained; only scenes with >=5 active old/new owners use the guard.
PaceStart:
 ld a,(MonoActiveCount)
 cp 5
 ld hl,PaceAccountDraw
 ld de,PaceAccountOld
 jp nc,pace_dispatch_ready
 ld hl,RCBegin ; shared RET
 ld de,RCBegin
pace_dispatch_ready:
 ld (mono_pace_draw_call+1),hl
 ex de,hl
 ld (mono_pace_old_call+1),hl
 jp PaceStartBody

 INCLUDE "routines/magnet_center_setup.asm"
