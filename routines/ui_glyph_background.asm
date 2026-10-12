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

 ; Save is completed before replacing each byte of the temporary panel.
MonoWindowSaveByte:
 ld a,h
 cp $e0
 ld a,0
 jp c,MonoWindowDarkByte
 dec a
MonoWindowDarkByte:
 ld (hl),a
 ret
