; Fourth menu colour bit. UiPixelColor's saved HL/AF are still on the stack.
UiMenuOverlay:
 ld a,(UiColor)
 and 8
 ld a,0
 jp z,UiMenuHighByteReady
 ld a,(UiPixel)
UiMenuHighByteReady:
 push af
 ld a,h
 sub $60
 ld h,a
 pop af
 ld (hl),a
 pop hl
 pop af
 ret
