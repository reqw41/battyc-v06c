pad_rows:
 ld a,(MonoDrawRows)
 call hl_add_a
 ld e,(hl)
 ld d,0
 ld hl,60 ; 3840 cycles of successful owner preparation/control
 ld a,b
 or a
 jp z,pad_add
pad_columns:
 add hl,de
 dec b
 jp nz,pad_columns
pad_add:
 ex de,hl
 ld hl,(PaceWork)
 add hl,de
 ld (PaceWork),hl
 ret

 INCLUDE "routines/magnet_center_guard.asm"
