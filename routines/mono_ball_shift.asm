MonoDrawWhite EQU MonoBallDrawDispatch
MonoBallDrawDispatch:
 ld a,(MonoOwner)
 or a
 jp z,MonoDrawWhiteGeneral
 cp 4
 jp nc,MonoDrawWhiteGeneral
 ld a,(MonoDrawCols)
 cp 2
 jp z,MonoBallShiftDraw
 jp MonoDrawWhiteGeneral
; Isolated balls: one source column -> two destination columns, no scratch.
MonoBallShiftDraw:
 call BallShiftMaskInit
 ld a,(direct_shift)
 cpl
 and 7
 ld hl,BallShiftR7
 call hl_add_a
 ld (BallShiftRotate+1),hl
 ld hl,0
 add hl,sp
 ld (mono_draw_restore+1),hl
 ld hl,(MonoDrawSource)
 di
 ld sp,hl
 ld hl,(MonoDrawVideo)
 ld a,(MonoDrawRows)
 ld c,a
 jp BallShiftRow
