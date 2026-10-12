; First pass adds the white cross contour; second pass reveals the background in its core.
; The whole line is outlined before any glyph interior is cut.
UiMonoOutline:
 pop af
 push af
 push hl
 push bc
 push de
 ld c,a
 ld a,(UiStencilPass)
 or a
 jp nz,UiGlyphBackground
 ld a,h
 add a,$20
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
