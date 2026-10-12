; Lower bound for fixed loops, then the actual number of union pairs.
; Units: 64 synchronized Vector cycles. Pair minimum is >=192 cycles.
PaceWork EQU $71e3
 ASSERT PaceWork+2 <= PreparedCover
PaceStartBody:
 ld a,(MonoActiveCount)
 ld hl,PacePairs
 call hl_add_a
 ld e,(hl)
 ld d,0
 ld hl,221 ; 14144 cycles; conservative after direct object-table indexing
 add hl,de
 ld (PaceWork),hl
 ret
PacePairs: db 0,0,3,9,18,30,45,63,84,108,135,165

 INCLUDE "routines/game_over_player_line.asm"
