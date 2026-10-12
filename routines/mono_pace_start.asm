; Lower bound for fixed loops, then the actual number of union pairs.
; Units: 64 synchronized Vector cycles. Pair minimum is >=256 cycles.
PaceWork EQU $71e3
 ASSERT PaceWork+2 <= PreparedCover
PaceStartBody:
 ld a,(MonoActiveCount)
 ld hl,PacePairs
 call hl_add_a
 ld e,(hl)
 ld d,0
 ld hl,231 ; 14784 cycles; empty MonoRender takes 14824
 add hl,de
 ld (PaceWork),hl
 ret
PacePairs: db 0,0,4,12,24,40,60,84,112,144,180,220

 INCLUDE "routines/game_over_player_line.asm"
