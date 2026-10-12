; Restore empty cells around a destroyed brick from immutable level texture.
; Neighbor outlines are derived from the level map, never from video pixels.
; Retire save-under first, then restore A/C/E; preserve intact brick animation.
NativeRestoreBrick:
 call MagnetAccentReset
 ld hl,(LB28F+1)
 ld a,l
 sub 16
 ld l,a
 ld a,h
 sub 8
 ld h,a
 push hl
 ld hl,(cur_level_ptr)
 ld de,-16
 add hl,de
 ex de,hl
 pop hl
 ld b,3
NativeRestorePatchRow:
 ld c,3
NativeRestorePatchCell:
 ld a,b
 cp 2
 jp z,NativeRestorePatchVisit
 ld a,c
 cp 2
 jp nz,NativeRestorePatchNext
NativeRestorePatchVisit:
 ld a,b
 cp 2
 jp nz,NativeRestoreSetRowClip
 xor a
NativeRestoreSetRowClip:
 ld (NativeRestoreRowClip),a
 push hl
 ld hl,NativeRestoreClipTable-2
 ld a,c
 add a,a
 call hl_add_a
 ld a,(hl)
 ld (NativeRestoreLeftClip),a
 inc hl
 ld a,(hl)
 ld (NativeRestoreRightClip),a
 pop hl
NativeRestoreVisitReady:
 call NativeRestoreEmptyCell
NativeRestorePatchNext:
 inc de
 ld a,l
 add a,16
 ld l,a
 dec c
 jp nz,NativeRestorePatchCell
 ld a,l
 sub 48
 ld l,a
 ld a,h
 add a,8
 ld h,a
 push hl
 ld hl,12
 add hl,de
 ex de,hl
 pop hl
 dec b
 jp nz,NativeRestorePatchRow
 ret

; HL=Y/X, DE=level cell. Preserve the patch traversal registers.
NativeRestoreEmptyCell:
 push af
 push bc
 push de
 push hl
 ld a,l
 cp 8
 jp c,NativeRestoreCellDone
 cp 248
 jp nc,NativeRestoreCellDone
 call NativeBrickPresent
 or a
 jp nz,NativeRestoreCellDone
 ld (NativeRestoreXY),hl
 ex de,hl
 ld (NativeRestoreLevel),hl
 ex de,hl
 ld a,$ff
 ld (NativeRestoreLeftMask),a
 ld (NativeRestoreRightMask),a
 ld (NativeRestoreTopMask),a
 ld (NativeRestoreBottomMask),a
 ; Left neighbor. The periodic field border is applied per pixel row.
 ld a,l
 cp 8
 jp z,NativeRestoreRightNeighbor
 sub 16
 ld l,a
 dec de
 call NativeBrickPresent
 or a
 jp z,NativeRestoreRightNeighbor
NativeRestoreLeftEdge:
 ld a,$7f
 ld (NativeRestoreLeftMask),a
NativeRestoreRightNeighbor:
 ld hl,(NativeRestoreXY)
 ex de,hl
 ld hl,(NativeRestoreLevel)
 ex de,hl
 ld a,l
 cp 232
 jp z,NativeRestoreAbove
 add a,16
 ld l,a
 inc de
 call NativeBrickPresent
 or a
 jp z,NativeRestoreAbove
NativeRestoreRightEdge:
 ld a,$fe
 ld (NativeRestoreRightMask),a
NativeRestoreAbove:
 ld hl,(NativeRestoreLevel)
 ld de,-15
 add hl,de
 ex de,hl
 ld hl,(NativeRestoreXY)
 ld a,h
 sub 8
 ld h,a
 call NativeBrickPresent
 cpl
 ld (NativeRestoreTopMask),a
NativeRestoreBelow:
 ld hl,(NativeRestoreLevel)
 ld de,15
 add hl,de
 ex de,hl
 ld hl,(NativeRestoreXY)
 ld a,h
 add a,8
 ld h,a
 call NativeBrickPresent
 cpl
 ld (NativeRestoreBottomMask),a
 ; Empty cells use the texture color, in the C plane only.
 ld hl,(NativeRestoreXY)
 call scr_buff_attr_calc
 ld a,$d0
 call NativeWriteHL
 inc h
 call NativeWriteHL
 ld hl,(NativeRestoreXY)
 call scr_buff_addr_calc
 call NativePixelAddress
 ld a,(NativeRestoreLeftMask)
 ld (NativeRestoreMask+1),a
 ld a,(NativeRestoreLeftClip)
 ld (NativeRestoreClip+1),a
 call NativeRestoreTextureColumn
 inc d
 ld a,(NativeRestoreRightMask)
 ld (NativeRestoreMask+1),a
 ld a,(NativeRestoreRightClip)
 ld (NativeRestoreClip+1),a
 call NativeRestoreTextureColumn
NativeRestoreCellDone:
 pop hl
 pop de
 pop bc
 pop af
 ret

; DE=C-plane destination. Texture columns descend as logical Y increases.
NativeRestoreTextureColumn:
 ld a,(NativeRestoreClip+1)
 or a
 ret z
 push de
 ld b,8
NativeRestoreTextureRow:
 ld a,(NativeRestoreRowClip)
 or a
 jp z,NativeRestoreReadTexture
 cp 3
 ld a,b
 jp nz,NativeRestoreClipFirst
 cp 1
 jp nz,NativeRestoreSkipPixel
 jp NativeRestoreReadTexture
NativeRestoreClipFirst:
 cp 8
 jp nz,NativeRestoreSkipPixel
NativeRestoreReadTexture:
 ld a,d
 and 1
 ld hl,(NativeTextureLeft+1)
 jp z,NativeRestoreTextureSource
 ld hl,(NativeTextureRight+1)
NativeRestoreTextureSource:
 ld a,e
 sub $21
 and 15
 call hl_add_a
 ld a,(magnets_quantity)
 or a
 ld a,(hl)
 call nz,NativeRestoreMagnetSample
NativeRestoreMask:
 and $ff
 ld c,a
 ld a,b
 cp 8
 ld a,c
 jp nz,NativeRestoreNotFirstRow
 ld hl,NativeRestoreTopMask
 and (hl)
NativeRestoreNotFirstRow:
 ld c,a
 ld a,b
 cp 1
 ld a,c
 jp nz,NativeRestoreWriteRow
 ld hl,NativeRestoreBottomMask
 and (hl)
NativeRestoreWriteRow:
 ld c,a
 ld a,d
 cp $c1
 jp z,NativeRestoreBorderLeft
 cp $de
 ld a,c
 jp nz,NativeRestoreStorePixel
 ld a,$fe
 jp NativeRestoreBorderRow
NativeRestoreBorderLeft:
 ld a,$7f
NativeRestoreBorderRow:
 ld (NativeRestoreBorderMask+1),a
 ld a,$e0
 sub e
 cp 50
 jp c,NativeRestoreKeepBorder
 cp 78
 jp c,NativeRestoreApplyBorder
 cp 106
 jp c,NativeRestoreKeepBorder
 cp 134
 jp nc,NativeRestoreKeepBorder
NativeRestoreApplyBorder:
 ld a,c
NativeRestoreBorderMask:
 and $ff
 jp NativeRestoreStorePixel
NativeRestoreKeepBorder:
 ld a,c
NativeRestoreStorePixel:
 ld c,a
NativeRestoreClipPixel:
 ld a,d
 add $20
 ld d,a
 ld a,(NativeRestoreClip+1)
 cpl
 ld h,a
 ld a,(de)
 and h
 ld l,a
 ld a,(NativeRestoreClip+1)
 ld h,a
 push bc
 ld a,(NativeSampleAccentE)
 and c
 ld b,a
 ld a,c
 cpl
 or b
 pop bc
 and h
 or l
 ld (de),a
 ld a,d
 sub $20
 ld d,a
 ld a,c
NativeRestoreClip:
 and $ff
 ld c,a
 ld a,(NativeRestoreClip+1)
 cpl
 ld h,a
 ld a,(de)
 and h
 or c
 ld (de),a
 ld a,d
 sub $20
 ld d,a
 ld a,(de)
 and h
 ld l,a
 ld a,(NativeSampleAccentA)
 and c
 or l
 ld (de),a
 ld a,d
 add a,$20
 ld d,a
NativeRestoreSkipPixel:
 dec e
 dec b
 jp nz,NativeRestoreTextureRow
 pop de
 ret
NativeRestoreXY: dw 0
NativeRestoreLevel: dw 0
NativeRestoreLeftMask: db 0
NativeRestoreRightMask: db 0
NativeRestoreTopMask: db 0
NativeRestoreBottomMask: db 0

NativeRestoreRowClip: db 0
NativeRestoreLeftClip: db 0
NativeRestoreRightClip: db 0
