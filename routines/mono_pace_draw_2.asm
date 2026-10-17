ps_count:
 sub 117
 jp c,ps_done
 inc (hl)
 jp ps_count
ps_done:
 add a,117
 ld (ps_acc+1),a
 ret

; Wait until a logic step is owed.
WaitGameplayFrame:
 ei
pw_loop:
 call PaceUpdate
 ld a,(hl)
 or a
 jp z,pw_loop
 ret
 DS 6,0 ; free, keeps the sprite pads at their old addresses

 INCLUDE "routines/magnet_center_guard.asm"
