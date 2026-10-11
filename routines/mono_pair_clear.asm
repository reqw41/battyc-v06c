; Fixed ten-row tail. Five PUSHes write all ten white-plane bytes.
MonoPairClearTail:
 ld a,(ClearColumns)
 or a
 ret z
 ld hl,0
 add hl,sp
 ld (mpc_restore+1),hl
 ld hl,(ClearDst)
 inc l
 ld a,(ClearColumns)
 ld b,a
 ld de,0
 di
mpc_column:
 ld sp,hl
 DUP 5
 push de
 EDUP
 inc h
 dec b
 jp nz,mpc_column
mpc_restore:
 ld sp,0
 ei
 ret
