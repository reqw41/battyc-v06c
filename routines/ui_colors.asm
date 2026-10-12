; Menus use all four planes and their own sixteen-entry Vector palette.
UiActive: db 1
UiColor: db 7
UiPixel: db 0
UiColorMap: db 15,14,15,15,13,14,15,15,11,10,15,15,15,0,15,15
; Legacy Specialist color code -> native Vector RGB color index.
UiSetColor:
 push hl
 push bc
 rrca
 rrca
 rrca
 rrca
 and $0f
 ld hl,UiColorMap
 ld c,a
 ld b,0
 add hl,bc
 ld a,(hl)
 ld (UiColor),a
 pop bc
 pop hl
 ret
; HL C-plane pixel, A glyph byte. Preserve all caller registers.
UiPixelWrite:
 push af
 ld a,(UiActive)
 or a
 jp nz,UiPixelColor
 jp UiMonoOutline
UiPixelColor:
 pop af
 ld (UiPixel),a
 push af
 push hl
 ld a,(UiColor)
 and 2
 ld a,0
 jp z,UiWriteC
 ld a,(UiPixel)
UiWriteC:
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(UiColor)
 and 4
 ld a,0
 jp z,UiWriteA
 ld a,(UiPixel)
UiWriteA:
 ld (hl),a
 ld a,h
 add a,$40
 ld h,a
 ld a,(UiColor)
 and 1
 ld a,$ff
 jp nz,UiWriteE
 ld a,(UiPixel)
 cpl
UiWriteE:
 ld (hl),a
 jp UiMenuOverlay
