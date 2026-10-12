MonoWindowSaveByte:
 ld a,h
 cp $e0
 ld a,0
 jp c,MonoWindowDarkByte
 dec a
MonoWindowDarkByte:
 ld (hl),a
 ret

