BallShiftRow:
 pop de
 ld a,d
BallShiftRotate:
 jp BallShiftR0
BallShiftR7: rrca
BallShiftR6: rrca
BallShiftR5: rrca
BallShiftR4: rrca
BallShiftR3: rrca
BallShiftR2: rrca
BallShiftR1: rrca
BallShiftR0:
 ld d,a
BallShiftLead:
 and $ff
BallShiftLeadMerge:
 or (hl)
 ld (hl),a
 inc h
 ld a,d
BallShiftSpill:
 and 0
BallShiftSpillMerge:
 or (hl)
 ld (hl),a
 dec h
 dec l
 dec c
 jp nz,BallShiftRow
 jp mono_draw_restore
