; HL E plane, B outline. Protect all existing white overlay pixels.
UiOutlineByte:
 push hl
 ld a,h
 sub $60
 ld h,a
 ld a,(hl)
 cpl
 and b
 cpl
 ld d,a
 pop hl
 ld a,(hl)
 and d
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and d
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and d
 ld (hl),a
 ld a,h
 add a,$40
 ld h,a
 ret
