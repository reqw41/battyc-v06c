; Overwrite the left half, OR the right; clear only the uncovered right tail.
MonoDrawPair:
 ld a,(MonoShifts+7)
 or a
 ld b,3
 jp z,mdp_left_width
 inc b
mdp_left_width:
 ld hl,(MonoDrawVideo)
 ld a,h
 add a,b
 ld h,a
 ld (ClearDst),hl
 ld a,(MonoDrawCols)
 sub b
 ld (ClearColumns),a
 call MonoPairClearTail
 ld a,1
 ld (MonoFastDraw),a
 ld hl,(mono_new_base+1)
 ld de,49
 add hl,de
 ld a,(MonoShifts+7)
 call MonoDrawHalf
 xor a
 ld (MonoFastDraw),a
 ld hl,(mono_new_base+1)
 ld de,56
 add hl,de
 ld a,(MonoShifts+8)
MonoDrawHalf:
 ld (direct_shift),a
 ld b,a
 ld e,(hl)
 inc hl
 ld d,(hl)
 inc hl
 inc hl
 inc hl
 push hl
 ex de,hl
 ld (MonoDrawVideo),hl
 pop hl
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (MonoDrawSource),hl
 ld a,b
 or a
 ld a,3
 jp z,mdh_width
 inc a
mdh_width:
 ld (MonoDrawCols),a
 jp MonoDrawWhite
