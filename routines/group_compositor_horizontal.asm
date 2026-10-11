; Equal vertical intervals: only the column intersection is needed.
CGHorizontalIntersect:
 inc hl
 ld a,(CGColumn)
 add a,$e0
 sub (hl)
 ret c
 ld c,a
 inc hl
 cp (hl)
 ccf
 ret c
 inc hl
 inc hl
 ld e,(hl)
 inc hl
 ld d,(hl)
 push de
 ld a,(CGRows)
 add a,a
 ld e,a
 ld d,0
 ld hl,0
 ld a,c
 or a
 jp z,cgh_ready
cgh_offset:
 add hl,de
 dec c
 jp nz,cgh_offset
cgh_ready:
 pop de
 add hl,de
 ld (CGSpanBG),hl
 or a
 ret
