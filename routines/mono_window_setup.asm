MonoWindowSetup:
 ld hl,$8158
 call screen_addr_calc
 ld a,h
 sub $40
 ld h,a
 ld (MonoDrawVideo),hl
 ld hl,$7a00
 ld (MonoDrawSource),hl
 ret

 INCLUDE "routines/magnet_sample_center.asm"
