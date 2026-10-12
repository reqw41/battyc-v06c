; Same solid glyph bitmap as the menu, in the white sprite plane only.
UiMonoOutline:
 pop af
 push hl
 push bc
 ld b,a
 ld a,h
 sub $40
 ld h,a
 ld a,(hl)
 or b
 ld (hl),a
 ld a,1
 ld (OverlayActive),a
 pop bc
 pop hl
 ret
