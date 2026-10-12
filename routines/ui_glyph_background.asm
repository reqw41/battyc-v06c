MonoWindowSaveByte:
 ld a,h
 cp $e0
 ld a,0
 jp c,MonoWindowDarkByte
 dec a
MonoWindowDarkByte:
 ld (hl),a
 ret

BallShiftMaskInit:
 ld hl,SpriteShiftMasks
 ld a,(direct_shift)
 call hl_add_a
 ld a,(hl)
 ld (BallShiftLead+1),a
 cpl
 ld (BallShiftSpill+1),a
 ret
