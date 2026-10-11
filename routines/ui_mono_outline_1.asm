; White glyphs with the original cross-shaped one-pixel black contour.
; The overlay byte is replaced, so reprinting does not accumulate strokes.
UiMonoOutline:
 pop af
 push af
 push hl
 push bc
 push de
 ld c,a
 ld a,h
 sub $40
 ld h,a
 ld a,c
 ld (hl),a
 ld a,h
 add a,$60
 ld h,a
 ld a,c
 or a
 rra
 ld b,a
 ld a,c
 add a,a
 or b
 or c
 ld b,a
 call UiOutlineByte
 ld b,c
 inc l
 call UiOutlineByte
 dec l
 dec l
 jp UiMonoOutlineTail
