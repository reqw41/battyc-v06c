; Read the 3x3 logical neighbourhood once. Only the cross is repainted.
; Magnets lie above the texture: the brick is restored as plain texture,
; then the touched rows of every marked magnet are repainted from its cache.
NativeRestoreBrick:
 call NativeRestoreBrickBody
 jp MagnetRepaintMarked
NativeRestoreBrickBody:
 ld hl,(LB28F+1)
 ld (NativeRestoreOrigin),hl
 call NativeRestoreChooseMagnets
 call NativeRestoreQueueGate
NativeRestoreGridStart:
 ld hl,(cur_level_ptr)
 ld de,-16
 add hl,de
 ld de,NativeRestoreGrid
 ld b,3
NativeRestoreGridRow:
 ld c,3
NativeRestoreGridCell:
 ld a,(hl)
 rlca
 sbc a,a
 cpl
 ld (de),a
 inc de
 inc hl
 dec c
 jp nz,NativeRestoreGridCell
 push de
 ld de,12
 add hl,de
 pop de
 dec b
 jp nz,NativeRestoreGridRow
 ld hl,(NativeRestoreOrigin)
 ld a,l
 cp 8
 jp nz,NativeRestoreGridRight
 xor a
 ld (NativeRestoreGrid),a
 ld (NativeRestoreGrid+3),a
 ld (NativeRestoreGrid+6),a
NativeRestoreGridRight:
 ld a,l
 cp 232
 jp nz,NativeRestoreGridTop
 xor a
 ld (NativeRestoreGrid+2),a
 ld (NativeRestoreGrid+5),a
 ld (NativeRestoreGrid+8),a
NativeRestoreGridTop:
 ld a,h
 cp 32
 jp nz,NativeRestoreGridBottom
 xor a
 ld (NativeRestoreGrid),a
 ld (NativeRestoreGrid+1),a
 ld (NativeRestoreGrid+2),a
NativeRestoreGridBottom:
 ld a,h
 cp 120
 jp nz,NativeRestoreCenter
 xor a
 ld (NativeRestoreGrid+6),a
 ld (NativeRestoreGrid+7),a
 ld (NativeRestoreGrid+8),a
NativeRestoreCenter:
 call NativeRestoreQueueSparseGate
 call NativeRestoreResetMasks
 ld a,(NativeRestoreGrid+3)
 and $80
 cpl
 ld (NativeRestoreLeftMask),a
 ld a,(NativeRestoreGrid+5)
 and 1
 cpl
 ld (NativeRestoreRightMask),a
 ld a,(NativeRestoreGrid+1)
 cpl
 ld (NativeRestoreTopMask),a
 ld a,(NativeRestoreGrid+7)
 cpl
 ld (NativeRestoreBottomMask),a
 ld a,$ff
 ld (NativeRestoreLeftClip),a
 ld (NativeRestoreRightClip),a
 xor a
 ld (NativeRestoreRowClip),a
 ld hl,(NativeRestoreOrigin)
 call NativeRestoreRect
 ; Left fringe. Horizontal masks do not affect its last bit.
 ld a,(NativeRestoreGrid+3)
 or a
 jp nz,NativeRestoreRightFringe
 call NativeRestoreResetMasks
 ld a,(NativeRestoreGrid)
 cpl
 ld (NativeRestoreTopMask),a
 ld a,(NativeRestoreGrid+6)
 cpl
 ld (NativeRestoreBottomMask),a
 xor a
 ld (NativeRestoreLeftClip),a
 ld (NativeRestoreRowClip),a
 inc a
 ld (NativeRestoreRightClip),a
 ld hl,(NativeRestoreOrigin)
 ld a,l
 sub 16
 ld l,a
 call NativeRestoreRect
NativeRestoreRightFringe:
 ld a,(NativeRestoreGrid+5)
 or a
 jp nz,NativeRestoreTopFringe
 call NativeRestoreResetMasks
 ld a,(NativeRestoreGrid+2)
 cpl
 ld (NativeRestoreTopMask),a
 ld a,(NativeRestoreGrid+8)
 cpl
 ld (NativeRestoreBottomMask),a
 xor a
 ld (NativeRestoreRightClip),a
 ld (NativeRestoreRowClip),a
 ld a,$80
 ld (NativeRestoreLeftClip),a
 ld hl,(NativeRestoreOrigin)
 ld a,l
 add a,16
 ld l,a
 call NativeRestoreRect
NativeRestoreTopFringe:
 ld a,(NativeRestoreGrid+1)
 or a
 jp nz,NativeRestoreBottomFringe
 call NativeRestoreResetMasks
 ld hl,NativeRestoreGrid
 call NativeRestoreHorizontalMasks
 ld a,3
 ld (NativeRestoreRowClip),a
 ld hl,(NativeRestoreOrigin)
 ld a,h
 sub 8
 ld h,a
 call NativeRestoreRect
NativeRestoreBottomFringe:
 ld a,(NativeRestoreGrid+7)
 or a
 ret nz
 call NativeRestoreResetMasks
 ld hl,NativeRestoreGrid+6
 call NativeRestoreHorizontalMasks
 ld a,1
 ld (NativeRestoreRowClip),a
 ld hl,(NativeRestoreOrigin)
 ld a,h
 add a,8
 ld h,a
 jp NativeRestoreRect
NativeRestoreHorizontalMasks:
 ld a,(hl)
 and $80
 cpl
 ld (NativeRestoreLeftMask),a
 inc hl
 inc hl
 ld a,(hl)
 and 1
 cpl
 ld (NativeRestoreRightMask),a
 ld a,$ff
 ld (NativeRestoreLeftClip),a
 ld (NativeRestoreRightClip),a
 ret
NativeRestoreResetMasks:
 ld a,$ff
 ld (NativeRestoreLeftMask),a
 ld (NativeRestoreRightMask),a
 ld (NativeRestoreTopMask),a
 ld (NativeRestoreBottomMask),a
 ret
NativeRestoreRect:
 ld a,l
 cp 8
 ret c
 cp 248
 ret nc
 ld (NativeRestoreXY),hl
 call NativeRestoreAddressSetup
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
 jp NativeRestoreTextureColumn
 ; DE=C video. Cell rows are aligned to eight pixels, so the texture
 ; pointer can descend within its sixteen-byte period without wrapping.
NativeRestoreTextureColumn:
 call NativeRestoreQueueColumn
 ret c
 ld a,(NativeRestoreClip+1)
 or a
 ret z
 push de
 ld a,d
 and 1
 ld hl,(NativeTextureLeft+1)
 jp z,NativeRestoreSource
 ld hl,(NativeTextureRight+1)
NativeRestoreSource:
 ld a,e
 sub $21
 and 15
 call hl_add_a
 ld b,8
 ld a,(NativeRestoreRowClip)
 or a
 jp z,NativeRestoreFastCheck
 ld b,1
 cp 3
 jp nz,NativeRestoreFastCheck
 ld a,e
 sub 7
 ld e,a
 push de
 ld de,-7
 add hl,de
 pop de
NativeRestoreFastCheck:
 ld a,(NativeRestoreClip+1)
 cp $ff
 jp nz,NativeRestoreFringeFast
 ld a,b
 cp 8
 jp z,NativeRestoreCopyFull
 jp NativeRestoreFringeFast
; Former immediates of the retired sampled row loop; still used as variables.
NativeRestoreMask: db 0,0
NativeRestoreClip: db 0,0
NativeRestoreXY: dw 0
NativeRestoreOrigin: dw 0
NativeRestoreGrid: ds 9,0
NativeRestoreLeftMask: db 0
NativeRestoreRightMask: db 0
NativeRestoreTopMask: db 0
NativeRestoreBottomMask: db 0

NativeRestoreRowClip: db 0
NativeRestoreLeftClip: db 0
NativeRestoreRightClip: db 0
