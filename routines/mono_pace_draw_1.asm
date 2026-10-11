; Only rows that will really be drawn contribute. Ignore cache builds,
; erase work and IRQs. A shifted spill column is also deliberately ignored.
PaceAccountDraw:
 ld a,(MonoFastDraw)
 or a
 jp z,pad_white
 ld hl,MonoShifts
 ld a,(MonoOwner)
 call hl_add_a
 ld a,(hl)
 or a
 jp nz,pad_shift
pad_white:
 ld hl,PaceWhiteRows
 ld a,(MonoDrawCols)
 ld b,a
 jp pad_rows
pad_shift:
 ld hl,PaceShiftRows
 ld a,(MonoDrawCols)
 dec a
 ld b,a

 jp pad_rows
