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
 cp 1
 ld a,0
 jp nz,mnn_kind
 inc a
mnn_kind:
 ld (MonoBuildBat),a
 or a
 ld hl,mnn_lit
 jp z,mnn_select_cover
 ld hl,mnn_cover
mnn_select_cover:
 ld (mnn_cover_select+1),hl
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
 ld hl,mnn_cover_step
 ld de,mnn_lit_step
 ld a,(SpriteCacheShift)
 or a
 jp nz,mnn_select_spill
 ld hl,mnn_lit
 ld de,mnn_row_next
mnn_select_spill:
 ld (mnn_cover_skip+1),hl
 ex de,hl
 ld (mnn_lit_skip+1),hl
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
 ld a,(MonoNativeFirst)
 or a
 ld a,0
 ld b,a
 jp nz,mnn_select_merge
 ld a,$b6 ; OR M for lit
 ld b,$a6 ; AND M for cover
mnn_select_merge:
 ld (mnn_lit_merge),a
 ld a,b
 ld (mnn_cover_merge),a
 ld a,(SpriteCacheHeight)
 ld c,a
mnn_row:
 pop de
mnn_cover_select:
 jp mnn_lit
mnn_cover:
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
mnn_cover_merge:
 and (hl)
mnn_cover_store:
 ld (hl),a
mnn_cover_skip:
 jp mnn_cover_step
mnn_cover_step:
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
mnn_lit_merge:
 or (hl)
mnn_lit_store:
 ld (hl),a
mnn_lit_skip:
 jp mnn_lit_step
mnn_lit_step:
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
