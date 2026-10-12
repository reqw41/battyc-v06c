; HL E plane, B contour. The later core pass removes all glyph interiors.
UiOutlineByte:
 ld a,h
 sub $60
 ld h,a
 ld a,(hl)
 or b
 ld (hl),a
 ld a,h
 add a,$60
 ld h,a
 ret

UiStencilPass EQU $71e6
 ASSERT UiStencilPass == MonoPairActive+1
 ASSERT UiStencilPass < PreparedCover
; All text uses the same solid menu glyphs; gameplay writes white only.
PrintOutlinedLine:
 jp PrintLineBody
