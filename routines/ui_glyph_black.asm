; HL C plane, C glyph bitmap. Clear its core in all four planes.
; Executed only after the entire line's white contour has been drawn.
UiGlyphBlack:
 ld a,c
 cpl
 ld b,a
 ld a,(hl)
 and b
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and b
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and b
 ld (hl),a
 ld a,h
 add a,$60
 ld h,a
 ld a,(hl)
 and b
 ld (hl),a
 jp UiMonoDone

MonoWindowSaveByte:
 ld a,h
 cp $a0
 ret nc
 xor a
 ld (hl),a
 ret
