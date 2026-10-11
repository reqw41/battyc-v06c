; Only rows that will really be drawn contribute. Ignore cache builds,
; erase work and IRQs. A shifted spill column is also deliberately ignored.
PaceAccountDraw:
 ld a,(MonoDrawBat)
 or a
 jp nz,pad_bat
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
pad_bat:
 ld hl,PaceBatRows
 ld a,(MonoDrawCols)
 ld b,a
 jp pad_rows
pad_shift:
 ld hl,PaceShiftRows
 ld a,(MonoDrawCols)
 dec a
 ld b,a
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
