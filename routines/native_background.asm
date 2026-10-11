; Virtual legacy pointers are coordinates only: 7000+256*column+row.
; Background uses A/C with E=0; moving sprites use C/E and preserve A.
NativeAttrs EQU $6e00
NativeAttrBytes EQU 768
OverlayActive: db 0
NativeReadValue: db 0
NativeWriteValue: db 0
NativeReadDE:
 ex de,hl
 call NativeReadHL
 ex de,hl
 ret
NativeReadBC:
 push hl
 ld h,b
 ld l,c
 call NativeReadHL
 pop hl
 ret
NativeWriteDE:
 ex de,hl
 call NativeWriteHL
 ex de,hl
 ret
NativeWriteBC:
 push hl
 ld h,b
 ld l,c
 call NativeWriteHL
 pop hl
 ret
NativeAndHL:
 push bc
 ld b,a
 call NativeReadHL
 and b
 pop bc
 ret
NativeOrHL:
 push bc
 ld b,a
 call NativeReadHL
 or b
 pop bc
 ret
NativeXorHL:
 push bc
 ld b,a
 call NativeReadHL
 xor b
 pop bc
 ret
NativeReadHL:
 call SUInvalidate
 push af
 ld a,h
 cp $70
 jp c,NativeReadOrdinary
 cp $91
 jp nc,NativeReadOrdinary
 push bc
 push de
 push hl
 cp $90
 ld a,0
 jp z,NativeReadResult
 ld a,l
 cp $c0
 jp nc,NativeReadAttr
 call NativePixelAddress
 ld a,(de)
 ld b,a
 ld a,d
 sub $20
 ld d,a
 ld a,(de)
 or b
 jp NativeReadResult
NativeReadAttr:
 and $1f
 cp 24
 ld a,$d0
 jp nc,NativeReadResult
 call NativeAttrAddress
 ld a,(hl)
NativeReadResult:
 ld (NativeReadValue),a
 pop hl
 pop de
 pop bc
 pop af
 ld a,(NativeReadValue)
 ret
NativeReadOrdinary:
 pop af
 ld a,(hl)
 ret
NativeWriteHL:
 push af
 ld (NativeWriteValue),a
 ld a,h
 cp $70
 jp c,NativeWriteOrdinary
 cp $91
 jp nc,NativeWriteOrdinary
 cp $90
 jp z,NativeWriteIgnore
 push bc
 push de
 push hl
 ld a,l
 cp $c0
 jp nc,NativeWriteAttr
 call NativePixelAddress
 ld a,(NativeWriteValue)
 ld (background_pixel),a
 call background_write
 jp NativeWriteDone
NativeWriteAttr:
 and $1f
 cp 24
 jp nc,NativeWriteDone
 call NativeAttrAddress
 ld a,(NativeWriteValue)
 ld (hl),a
NativeWriteDone:
 pop hl
 pop de
 pop bc
NativeWriteIgnore:
 pop af
 ret
NativeWriteOrdinary:
 pop af
 ld (hl),a
 ret
; HL virtual coordinate -> DE native C-plane address.
NativePixelAddress:
 ld a,h
 sub $70
 add a,$c0
 ld d,a
 ld a,$e0
 sub l
 ld e,a
 ret
; Virtual attribute pointer -> packed 24-byte column at NativeAttrs.
NativeAttrAddress:
 ld a,l
 and $1f
 ld e,a
 ld d,0
 ld a,h
 sub $70
 ld l,a
 ld h,0
 push bc
 add hl,hl
 add hl,hl
 add hl,hl
 ld b,h
 ld c,l
 add hl,hl
 add hl,bc
 pop bc
 add hl,de
 ld de,NativeAttrs
 add hl,de
 ret
NativeRecolorCell:
 call SUInvalidate
 push af
 push bc
 push de
 push hl
 ld a,l
 and $1f
 cp 24
 jp nc,NativeRecolorDone
 push hl
 call NativeReadHL
 rrca
 rrca
 rrca
 rrca
 and $0f
 ld c,a
 ld b,0
 ld hl,background_colors
 add hl,bc
 ld a,(hl)
 ld (background_color),a
 ld d,0
 ld e,0
 rra
 jp nc,NativeRecolorA
 ld d,$ff
NativeRecolorA:
 rra
 jp nc,NativeRecolorMasks
 ld e,$ff
NativeRecolorMasks:
 pop hl
 ld a,l
 and $1f
 add a,a
 add a,a
 add a,a
 ld c,a
 ld a,$e0
 sub c
 ld l,a
 ld a,h
 sub $70
 add a,$c0
 ld h,a
 ld b,8
NativeRecolorRow:
 ld a,(hl)
 ld c,a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 or c
 ld c,a
 and e
 ld (hl),a
 ld a,h
 add a,$20
 ld h,a
 ld a,c
 and d
 ld (hl),a
 push hl
 ld a,h
 add a,$20
 ld h,a
 ld a,(background_color)
 and 1
 ld a,$ff
 jp nz,MonoRecolorE
 ld a,c
 cpl
MonoRecolorE:
 ld (hl),a
 pop hl
 dec l
 dec b
 jp nz,NativeRecolorRow
NativeRecolorDone:
 pop hl
 pop de
 pop bc
 pop af
 ret

NativeStaticObject:
 ld hl,(IXobj)
 ld de,object_lives_indicator
 ld a,h
 cp d
 jp nz,NativeStaticScoreCheck
 ld a,l
 cp e
 jp z,plane_static_object
NativeStaticScoreCheck:
 ld de,object_score_indicator
 ld a,h
 cp d
 jp nz,NativeStaticBackground
 ld a,l
 cp e
 jp z,plane_static_object
NativeStaticBackground:
 ld hl,(IXobj)
 ld a,(hl)
 or a
 ret z
 ret m
 cp 3
 jp nz,plane_static_object
 call SUInvalidate
 ld hl,(IXobj)
 ld a,(hl)
 or a
 ret m
 call sprite_draw_prepare
 ld hl,(IXobj)
 call sprite_search
 ex de,hl
 ld a,(hl)
 ld (NativeWidth),a
 inc hl
 ld a,(hl)
 ld (NativeHeight),a
 inc hl
 ld (NativeSource),hl
 ld hl,(IXobj)
 ld de,4
 add hl,de
 ld a,(hl)
 cp $c0
 ret nc
 ld b,a
 ld a,$c0
 sub b
 ld b,a
 ld a,(NativeHeight)
 cp b
 jp c,NativeStaticHeight
 ld a,b
 ld (NativeHeight),a
NativeStaticHeight:
 ld de,6
 add hl,de
 ld d,(hl)
 inc hl
 ld e,(hl)
 ex de,hl
 ld (NativeDest),hl
 ex de,hl
 ld de,10
 add hl,de
 ld a,(hl)
 or a
 ld a,0
 jp m,NativeStaticShift
 ld hl,(IXobj)
 inc hl
 inc hl
 ld a,(hl)
 and 7
NativeStaticShift:
 ld (NativeShift),a
NativeStaticRow:
 xor a
 ld (NativeCarryMask),a
 ld (NativeCarryPixel),a
 ld a,(NativeWidth)
 ld (NativeLeft),a
NativeStaticByte:
 ld hl,(NativeSource)
 ld a,(hl)
 ld (NativeMask),a
 inc hl
 ld a,(hl)
 ld (NativePixel),a
 inc hl
 ld (NativeSource),hl
 ld a,(NativeShift)
 or a
 jp z,NativeStaticNoShift
 ld a,(NativeMask)
 call NativeRotateByte
 ld (NativeMask),a
 ld a,c
 ld (NativeNextMask),a
 ld a,(NativePixel)
 call NativeRotateByte
 ld (NativePixel),a
 ld a,c
 ld (NativeNextPixel),a
 jp NativeStaticMerge
NativeStaticNoShift:
 xor a
 ld (NativeNextMask),a
 ld (NativeNextPixel),a
NativeStaticMerge:
 ld a,(NativeCarryMask)
 ld b,a
 ld a,(NativeMask)
 or b
 ld b,a
 ld a,(NativeCarryPixel)
 ld c,a
 ld a,(NativePixel)
 or c
 ld c,a
 ld hl,(NativeDest)
 call NativeReadHL
 or b
 xor c
 call NativeWriteHL
 inc h
 ld (NativeDest),hl
 ld a,(NativeNextMask)
 ld (NativeCarryMask),a
 ld a,(NativeNextPixel)
 ld (NativeCarryPixel),a
 ld a,(NativeLeft)
 dec a
 ld (NativeLeft),a
 jp nz,NativeStaticByte
 ld a,(NativeShift)
 or a
 jp z,NativeStaticEndRow
 ld a,(NativeCarryMask)
 ld b,a
 ld a,(NativeCarryPixel)
 ld c,a
 ld hl,(NativeDest)
 call NativeReadHL
 or b
 xor c
 call NativeWriteHL
NativeStaticEndRow:
 ld hl,(NativeDest)
 ld a,(NativeWidth)
 ld b,a
 ld a,h
 sub b
 ld h,a
 inc l
 ld (NativeDest),hl
 ld a,(NativeHeight)
 dec a
 ld (NativeHeight),a
 jp nz,NativeStaticRow
 ret
NativeSource: dw 0
NativeDest: dw 0
NativeWidth: db 0
NativeHeight: db 0
NativeShift: db 0
NativeLeft: db 0
NativeMask: db 0
NativePixel: db 0
NativeNextMask: db 0
NativeNextPixel: db 0
NativeCarryMask: db 0
NativeCarryPixel: db 0

NativePrintDigit:
 ld hl,spr_score_digits+2
 add a,l
 ld l,a
 jp nc,NativeDigitSourceReady
 inc h
NativeDigitSourceReady:
 ld (NativeSource),hl
 ld hl,(score_screen_ptr)
 ld (NativeDest),hl
 ld a,8
 ld (NativeHeight),a
NativeDigitRow:
 ld hl,(NativeSource)
 inc hl
 ld b,(hl)
 inc hl
 ld (NativeSource),hl
 ld hl,(NativeDest)
 call NativePixelAddress
 ld a,d
 sub $40
 ld d,a
 ld a,b
 ld (de),a
 inc l
 ld (NativeDest),hl
 ld a,(NativeHeight)
 dec a
 ld (NativeHeight),a
 jp nz,NativeDigitRow
 ld hl,(NativeDest)
 ld a,l
 sub 8
 ld l,a
 inc h
 ld (score_screen_ptr),hl
 ret

NativePrintBrick:
 call SUInvalidate
 ld (NativeBrickDest),hl
 push hl
 ld c,h
 ld hl,(cur_level_ptr)
 ld a,(hl)
 and $0f
 ld hl,briks_colors-1
 call hl_add_a
 ld b,(hl)
 ld hl,(brik_attr_buf)
 ld h,c
 dec l
 ld a,b
 call NativeWriteHL
 inc h
 call NativeWriteHL
 ld a,b
 or a
 ld hl,spr_brik_1
 jp nz,NativeBrickSource
 ld hl,spr_brik_black
NativeBrickSource:
 ld (NativeSource),hl
 ld a,b
 rrca
 rrca
 rrca
 rrca
 and $0f
 ld e,a
 ld d,0
 ld hl,background_colors
 add hl,de
 ld a,(hl)
 ld (background_color),a
 pop hl
 call NativePixelAddress
 ex de,hl
 ; The outline above the brick is erased in both background planes.
 inc l
 call NativeBrickZero
 inc h
 call NativeBrickZero
 dec h
 dec l
 ld a,h
 cp $c1
 jp z,NativeBrickBody
 push hl
 dec h
 ld c,$fe
 call NativeBrickEdge
 pop hl
NativeBrickBody:
 ex de,hl
 ld hl,(NativeSource)
 ld b,8
NativeBrickRow:
 ld a,(hl)
 inc hl
 ld (background_pixel),a
 call background_write_selected
 inc d
 ld a,(hl)
 inc hl
 ld (background_pixel),a
 call background_write_selected
 dec d
 dec e
 dec b
 jp nz,NativeBrickRow
 ex de,hl
 call NativeBrickZero
 inc h
 call NativeBrickZero
 ld a,h
 cp $de
 ret z
 ld hl,(NativeBrickDest)
 call NativePixelAddress
 ex de,hl
 inc h
 inc h
 ld c,$7f
 jp NativeBrickEdge
NativeBrickZero:
 push hl
 xor a
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 xor a
 ld (hl),a
 ld a,h
 add a,$40
 ld h,a
 ld a,$ff
 ld (hl),a
 pop hl
 ret
NativeBrickEdge:
 ld b,8
NativeBrickEdgeRow:
 ld a,(hl)
 and c
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and c
 ld (hl),a
 ld a,h
 add $40
 ld h,a
 ld a,c
 cpl
 or (hl)
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 dec l
 dec b
 jp nz,NativeBrickEdgeRow
 ret
NativeBrickDest: dw 0

; Repeat the two-column texture directly in the C video plane.
NativeFillTexture:
 call SUInvalidate
 inc hl
 inc hl
 ld (NativeTextureLeft+1),hl
 ld de,16
 add hl,de
 ld (NativeTextureRight+1),hl
 ld hl,$c021
 ld b,32
NativeTextureColumn:
 ld c,12
NativeTextureTile:
 ld a,h
 and 1
 jp nz,NativeTextureRight
NativeTextureLeft:
 ld de,0
 jp NativeTextureData
NativeTextureRight:
 ld de,0
NativeTextureData:
 ld a,16
NativeTextureByte:
 push af
 ld a,(de)
 ld (background_pixel),a
 ld a,l
 cp $39
 ld a,(background_pixel)
 jp nc,MonoTextureField
 xor a
MonoTextureField:
 ld (hl),a
 push hl
 ld (background_pixel),a
 ld a,h
 add a,$20
 ld h,a
 ld a,(background_pixel)
 cpl
 ld (hl),a
 pop hl
 inc de
 inc l
 pop af
 dec a
 jp nz,NativeTextureByte
 dec c
 jp nz,NativeTextureTile
 ld l,$21
 inc h
 dec b
 jp nz,NativeTextureColumn
 ret
