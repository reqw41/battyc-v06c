WaitVideoFrame:
 ei
 ld a,(IntCount)
WaitVideoFrameLast:
 cp 0
 jp nz,wvf_ready
 halt
 ld a,(IntCount)
wvf_ready:
 ld (WaitVideoFrameLast+1),a
 ret
NativeRotateByte:
 push hl
 ld b,a
 ld a,(NativeShift)
 ld c,a
 ld hl,SpriteShiftMasks
 call hl_add_a
 ld a,b
nrb_loop:
 rrca
 dec c
 jp nz,nrb_loop
 ld b,a
 and (hl)
 push af
 ld a,(hl)
 cpl
 and b
 ld c,a
 pop af
 pop hl
 ret

SpriteCacheBuild:
 ld hl,(IXobj)
 ld a,(hl)
 cp 3
 jp z,MonoLegacyBuild
 cp 1
 ld a,0
 jp nz,mnn_kind
 inc a
mnn_kind:
 ld (MonoBuildBat),a
 ld a,(SpriteCacheShift)
 add a,a
 ld hl,MonoNativeRotations
 call hl_add_a
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (mnn_lit_rotate+1),hl
 ld de,mnn_cover_r0-mnn_lit_r0
 add hl,de
 ld (mnn_cover_rotate+1),hl
 ld hl,SpriteShiftMasks
 ld a,(SpriteCacheShift)
 call hl_add_a
 ld a,(hl)
 ld (mnn_lit_lead+1),a
 ld (mnn_cover_lead+1),a
 cpl
 ld (mnn_lit_spill+1),a
 ld (mnn_cover_spill+1),a
 ld hl,(SpriteCacheOriginal)
 ld a,(hl)
 ld (MonoNativeCols),a
 ld b,a
 ld a,(SpriteCacheShift)
 or a
 jp z,mnn_width
 inc b
mnn_width:
 inc hl
 ld a,(SpriteCacheHeight)
 ld c,a
 ld a,(hl)
 sub c
 add a,a
 ld (mnn_source_skip+1),a
 ld hl,(SpriteCacheBuffer)
 ld (hl),b
 inc hl
 ld a,c
 ld (hl),a
 add a,a
 ld (mnn_cover_to_next+1),a
 ld (mnn_cover_from_next+1),a
 ld (mnn_lit_to_next+1),a
 ld (mnn_lit_from_next+1),a
 inc hl
 ld (MonoNativeDest),hl
 ld a,1
 ld (MonoNativeFirst),a
 ld hl,0
 add hl,sp
 ld (mnn_restore+1),hl
 ld hl,(SpriteCacheOriginal)
 inc hl
 inc hl
 di
 ld sp,hl
 ld hl,(MonoNativeDest)
mnn_col:
 ld a,(SpriteCacheHeight)
 ld c,a
mnn_row:
 pop de
 ld a,(MonoBuildBat)
 or a
 jp z,mnn_lit
 ld a,e
 cpl
mnn_cover_rotate:
 jp mnn_cover_r0
mnn_cover_r7: rrca
mnn_cover_r6: rrca
mnn_cover_r5: rrca
mnn_cover_r4: rrca
mnn_cover_r3: rrca
mnn_cover_r2: rrca
mnn_cover_r1: rrca
mnn_cover_r0:
 ld e,a
mnn_cover_lead:
 and $ff
 cpl
 ld b,a
 ld a,(MonoNativeFirst)
 or a
 ld a,b
 jp nz,mnn_cover_store
 and (hl)
mnn_cover_store:
 ld (hl),a
 ld a,(SpriteCacheShift)
 or a
 jp z,mnn_lit
 ld a,l
mnn_cover_to_next:
 add a,0
 ld l,a
 jp nc,mnn_cover_next_ready
 inc h
mnn_cover_next_ready:
 ld a,e
mnn_cover_spill:
 and 0
 cpl
 ld (hl),a
 ld a,l
mnn_cover_from_next:
 sub 0
 ld l,a
 jp nc,mnn_lit
 dec h
mnn_lit:
 inc hl
 ld a,d
mnn_lit_rotate:
 jp mnn_lit_r0
mnn_lit_r7: rrca
mnn_lit_r6: rrca
mnn_lit_r5: rrca
mnn_lit_r4: rrca
mnn_lit_r3: rrca
mnn_lit_r2: rrca
mnn_lit_r1: rrca
mnn_lit_r0:
 ld d,a
mnn_lit_lead:
 and $ff
 ld b,a
 ld a,(MonoNativeFirst)
 or a
 ld a,b
 jp nz,mnn_lit_store
 or (hl)
mnn_lit_store:
 ld (hl),a
 ld a,(SpriteCacheShift)
 or a
 jp z,mnn_row_next
 ld a,l
mnn_lit_to_next:
 add a,0
 ld l,a
 jp nc,mnn_lit_next_ready
 inc h
mnn_lit_next_ready:
 ld a,d
mnn_lit_spill:
 and 0
 ld (hl),a
 ld a,l
mnn_lit_from_next:
 sub 0
 ld l,a
 jp nc,mnn_row_next
 dec h
mnn_row_next:
 inc hl
 dec c
 jp nz,mnn_row
 ld (MonoNativeDest),hl
 ld hl,0
 add hl,sp
mnn_source_skip:
 ld de,0
 add hl,de
 ld sp,hl
 ld hl,(MonoNativeDest)
 ld a,(SpriteCacheShift)
 or a
 jp z,mnn_nextcol
 xor a
 ld (MonoNativeFirst),a
mnn_nextcol:
 ld a,(MonoNativeCols)
 dec a
 ld (MonoNativeCols),a
 jp nz,mnn_col
mnn_restore:
 ld sp,0
 ei
 ret
MonoNativeRotations: dw mnn_lit_r0,mnn_lit_r1,mnn_lit_r2,mnn_lit_r3
 dw mnn_lit_r4,mnn_lit_r5,mnn_lit_r6,mnn_lit_r7
MonoNativeCols: db 0
MonoNativeFirst: db 0
MonoNativeDest: dw 0
MonoLegacyBuild:
 ld a,(SpriteCacheShift)
 add a,a
 ld hl,MonoLitRotations
 call hl_add_a
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (mono_lit_rotate+1),hl
 ld de,mono_cover_r0-mono_lit_r0
 add hl,de
 ld (mono_cover_rotate+1),hl
 ld hl,SpriteShiftMasks
 ld a,(SpriteCacheShift)
 call hl_add_a
 ld a,(hl)
 ld (mono_lit_lead+1),a
 ld (mono_cover_lead+1),a
 cpl
 ld (mono_lit_spill+1),a
 ld (mono_cover_spill+1),a
 ld hl,(IXobj)
 ld a,(hl)
 cp 1
 ld a,0
 jp nz,mono_build_kind
 inc a
mono_build_kind:
 ld (MonoBuildBat),a
 ld hl,(SpriteCacheOriginal)
 ld a,(hl)
 ld (SpriteCacheWidth),a
 ld b,a
 ld a,(SpriteCacheShift)
 or a
 jp z,mono_build_width
 inc b
mono_build_width:
 ld hl,(SpriteCacheBuffer)
 ld (hl),b
 inc hl
 ld a,(SpriteCacheHeight)
 ld (hl),a
 ld (SpriteCacheRows),a
 add a,a
 dec a
 ld (mono_build_step+1),a
 inc hl
 ld (PreparedRow),hl
 ld hl,0
 add hl,sp
 ld (mono_build_restore+1),hl
 ld hl,(SpriteCacheOriginal)
 inc hl
 inc hl
 di
 ld sp,hl
mono_build_row:
 ld hl,(PreparedRow)
 xor a
 ld (SpriteCacheCarryMask),a
 ld (SpriteCacheCarryPixel),a
 ld a,(SpriteCacheWidth)
 ld (SpriteCacheBytes),a
mono_build_byte:
 pop de
 ld a,d
 cpl
 and e
 ld d,a
 ld a,(MonoBuildBat)
 or a
 jp z,mono_build_lit
 ld a,e
mono_cover_rotate:
 jp mono_cover_r0
mono_cover_r7: rrca
mono_cover_r6: rrca
mono_cover_r5: rrca
mono_cover_r4: rrca
mono_cover_r3: rrca
mono_cover_r2: rrca
mono_cover_r1: rrca
mono_cover_r0:
 ld e,a
mono_cover_lead:
 and $ff
 ld b,a
 ld a,(SpriteCacheCarryMask)
 or b
 ld (PreparedCover),a
 ld a,e
mono_cover_spill:
 and 0
 ld (SpriteCacheCarryMask),a
mono_build_lit:
 ld a,d
mono_lit_rotate:
 jp mono_lit_r0
mono_lit_r7: rrca
mono_lit_r6: rrca
mono_lit_r5: rrca
mono_lit_r4: rrca
mono_lit_r3: rrca
mono_lit_r2: rrca
mono_lit_r1: rrca
mono_lit_r0:
 ld d,a
mono_lit_lead:
 and $ff
 ld b,a
 ld a,(SpriteCacheCarryPixel)
 or b
 ld b,a
 ld a,d
mono_lit_spill:
 and 0
 ld (SpriteCacheCarryPixel),a
 ld a,(MonoBuildBat)
 or a
 ld a,b
 jp z,mono_build_store
 ld a,(PreparedCover)
mono_build_store:
 cpl
 ld (hl),a
 inc hl
 ld (hl),b
mono_build_advance:
 ld a,l
mono_build_step:
 add a,0
 ld l,a
 jp nc,mono_build_count
 inc h
mono_build_count:
 ld a,(SpriteCacheBytes)
 dec a
 ld (SpriteCacheBytes),a
 jp nz,mono_build_byte
 ld a,(SpriteCacheShift)
 or a
 jp z,mono_build_nextrow
 ld a,(SpriteCacheCarryPixel)
 ld b,a
 ld a,(MonoBuildBat)
 or a
 ld a,b
 jp z,mono_build_store_spill
 ld a,(SpriteCacheCarryMask)
mono_build_store_spill:
 cpl
 ld (hl),a
 inc hl
 ld (hl),b
mono_build_nextrow:
 ld hl,(PreparedRow)
 inc hl
 inc hl
 ld (PreparedRow),hl
 ld a,(SpriteCacheRows)
 dec a
 ld (SpriteCacheRows),a
 jp nz,mono_build_row
mono_build_restore:
 ld sp,0
 ei
 ret
MonoLitRotations: dw mono_lit_r0,mono_lit_r1,mono_lit_r2,mono_lit_r3
 dw mono_lit_r4,mono_lit_r5,mono_lit_r6,mono_lit_r7
MonoBuildBat: db 0
NativeMagnetSetOverlay:
 push hl
 push af
 ld hl,(IXobj)
 ld a,l
 sub magnet_properties & $ff
 rrca
 rrca
 rrca
 rrca
 and 3
 ld hl,NativeMagnetOverlayFlags
 call hl_add_a
 pop af
 ld (hl),a
 pop hl
 ret

 INCLUDE "routines/restore_background_tail.asm"
