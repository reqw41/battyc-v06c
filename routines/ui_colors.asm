; UI uses eight colors in A/C/E, ignoring the occupied 8000 plane.
UiActive: db 1
UiColor: db 7
UiPixel: db 0
UiColorMap: db 7,6,7,7,3,2,7,7,5,4,7,7,7,0,7,7
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
 pop af
 push af
 push hl
 push bc
 push de
 ld c,a
 ld a,h
 add a,$20
 ld h,a
 ; Foreground is white. Union neighbouring outlines without covering glyphs.
 ld a,(hl)
 or c
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 or c
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 or c
 ld (hl),a
 ld a,h
 add a,$40
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
 call UiOutlineByte
 inc l
 ld a,c
 and $80
 rlca
 ld b,a
 dec h
 call UiOutlineByte
 inc h
 inc h
 ld a,c
 and 1
 rrca
 ld b,a
 call UiOutlineByte
 ld a,1
 ld (OverlayActive),a
 pop de
 pop bc
 pop hl
 pop af
 ret
; HL E-plane. B outline coverage; exclude existing white pixels.
UiOutlineByte:
 ; Exclude already drawn white strokes from this black outline.
 ld d,(hl)
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and d
 ld d,a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and d
 cpl
 and b
 cpl
 ld d,a
 ld a,(hl)
 and d
 ld (hl),a
 ld a,h
 add a,$20
 ld h,a
 ld a,(hl)
 and d
 ld (hl),a
 ld a,h
 add a,$20
 ld h,a
 ld a,(hl)
 and d
 ld (hl),a
 ret
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
 ld a,0
 jp z,UiWriteE
 ld a,(UiPixel)
UiWriteE:
 ld (hl),a
 pop hl
 pop af
 ret
