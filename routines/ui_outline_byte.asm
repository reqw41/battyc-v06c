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
; Ordinary coloured menu text retains its original single pass.
PrintOutlinedLine:
 ld a,(UiActive)
 or a
 jp nz,PrintLineBody
 push bc
 push de
 push hl
 xor a
 ld (UiStencilPass),a
 call PrintLineBody
 pop hl
 pop de
 pop bc
 ld a,1
 ld (UiStencilPass),a
 call PrintLineBody
 xor a
 ld (UiStencilPass),a
 ret
