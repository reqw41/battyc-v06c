ps_count:
 sub 117
 jp c,ps_done
 inc (hl)
 jp ps_count
ps_done:
 add a,117
 ld (ps_acc+1),a
 ret

; Wait until the logic steps of the next draw are owed (PaceTail sets 1 or 2).
WaitGameplayFrame:
 ei
pw_loop:
 call PaceUpdate
 ld a,(hl)
pw_steps:
 cp 1
 jp c,pw_loop
 ret
 DS 5,0 ; free, keeps the sprite pads at their old addresses

 INCLUDE "routines/magnet_center_guard.asm"
