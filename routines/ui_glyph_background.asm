; HL C plane, C glyph bitmap. Cut the core only in the white overlay.
; The underlying A/C/E pattern is preserved, including coloured bricks.
UiGlyphBackground:
 ld a,h
 sub $40
 ld h,a
 ld a,c
 cpl
 and (hl)
 ld (hl),a
 jp UiMonoDone

MonoWindowSaveByte:
 ld a,h
 cp $a0
 ret nc
 xor a
 ld (hl),a
 ret
