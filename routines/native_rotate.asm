NativeRotateByte:
 push hl
 ld b,a
 ld a,(NativeShift)
 ld c,a
 ld hl,SpriteShiftMasks
 call hl_add_a
 ld a,b
nrb_loop:
 rrca
 dec c
 jp nz,nrb_loop
 ld b,a
 and (hl)
 push af
 ld a,(hl)
 cpl
 and b
 ld c,a
 pop af
 pop hl
 ret
