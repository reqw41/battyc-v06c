; Native column-major (~coverage,lit) pairs. Only lit affects sprite plane.
; Old eight-row tiles are cleared once through a bitmap; all current owners
; are OR-blitted from original sources. Moving caches/isolation are obsolete.
MonoRawSources EQU 1
; Upper-field objects go first and the paddles last: with a raster-tied
; frame they are replaced before the beam leaves the top border.
; Owners 1..3 must stay the balls (dedicated blit), owner 4 is the bonus.
MonoObjects: dw object_enemy,object_ball_1,object_ball_2,object_ball_3
 dw object_bonus,object_bullet_1,object_bat_2,object_bat_1,object_bat_temp
 dw object_bullet_2,object_rocket
MonoSlots EQU MonoOnlySlot-22
MonoOnlySlot: dw $7f00
MonoCapacities EQU MonoOnlyCapacity-11
MonoOnlyCapacity: db 228
MonoDesc: ds 77,0 ; top address, cols, rows, source, shift
MonoOld: ds 77,0  ; second descriptor bank; no per-frame geometry copy
 ASSERT high MonoDesc == high (MonoOld+77)
 ASSERT high MonoRegions == high (MonoRegions+55)
MonoTags EQU MonoOnlyTags-44
MonoOnlyTags: ds 4,0 ; only the static glyph owner has a shifted cache
MonoOwner: db 0
MonoPtr: dw 0
MonoOldPtr: dw 0
MonoDrawSource: dw 0
MonoDrawVideo: dw 0
MonoDrawCols: db 0
MonoDrawRows: db 0
MonoColumn: db 0
MonoTop: db 0
MonoRows: db 0
MonoCols: db 0
MonoScan EQU $7f76
MonoCandidates EQU $7f60
MonoCandidateCount EQU $7f77
MonoCandidatePtr EQU MonoRegions
MonoSelectPtr EQU MonoRegions
MonoSelectCount EQU $7f78
MonoOldRight EQU MonoRegions
MonoOldBottom EQU MonoRegions
MonoSingleFlag EQU $7f79
MonoNewTop EQU MonoRegions
MonoNewRows EQU MonoRegions
MonoDeltaCol EQU MonoRegions
MonoSpanTop EQU MonoRegions
MonoSpanBottom EQU MonoRegions
MonoSpanRows EQU MonoRegions
MonoSource EQU MonoRegions
MonoScratch EQU $7100
MonoBlack EQU $7120
PreparedRow EQU $71e8
PreparedCover EQU $71e7
SpriteCacheOriginal EQU $71d1
SpriteCacheEntry EQU $71d3
SpriteCacheBuffer EQU $71d5
SpriteCacheIndex EQU $71d7
SpriteCacheShift EQU $71d8
SpriteCacheHeight EQU $71d9
SpriteCacheWidth EQU $71da
SpriteCacheRows EQU $71db
SpriteCacheBytes EQU $71dc
SpriteCacheCarryMask EQU $71dd
SpriteCacheCarryPixel EQU $71de
ClearDst EQU $71df
ClearColumns EQU $71e1
ClearRows EQU $71e2
SUWindowValid: db 0
; Read-only compatibility counters: 3+1 has no sprite save-under.
; This ordinary RAM gap starts zeroed in the ROM image.
SUCount EQU $7140
SUStatic EQU $7141
SUNoRoom EQU $7142
SUDropped EQU $7143
 ASSERT MonoBlack+32 <= SUCount
 ASSERT SUDropped < SpriteCacheOriginal
SpriteShiftMasks: db $ff,$7f,$3f,$1f,$0f,$07,$03,$01
MonoReset EQU PaceReset
MonoResetBody:
 ld hl,MonoDesc
 ld b,77+77+4
 xor a
mr_zero:
 ld (hl),a
 inc hl
 dec b
 jp nz,mr_zero
 ld (SUWindowValid),a
 ld hl,plane_old
 ld b,44
mr_old:
 ld (hl),a
 inc hl
 dec b
 jp nz,mr_old
 jp NativeDigitInvalidate
RCBegin:
RCFlush:
SUInvalidate:
 ret
MonoCachePrepare:
 ld a,(direct_shift)
 or a
 jp nz,mono_cache_needed
 ld hl,(direct_source)
 dec hl
 ld a,(direct_rows)
 cp (hl)
 ret z
mono_cache_needed:
 ld hl,(direct_source)
 dec hl
 dec hl
 ld (SpriteCacheOriginal),hl
 ex de,hl
 ld a,(MonoOwner)
 add a,a
 add a,a
 ld hl,MonoTags
 call hl_add_a
 ld (SpriteCacheEntry),hl
 ld a,e
 cp (hl)
 jp nz,mcp_miss
 inc hl
 ld a,d
 cp (hl)
 jp nz,mcp_miss
 inc hl
 ld a,(direct_shift)
 cp (hl)
 jp nz,mcp_miss
 inc hl
 ld a,(direct_rows)
 cp (hl)
 jp z,mcp_hit
mcp_miss:
 ld hl,(SpriteCacheEntry)
 ld (hl),e
 inc hl
 ld (hl),d
 inc hl
 ld a,(direct_shift)
 ld (hl),a
 inc hl
 ld a,(direct_rows)
 ld (hl),a
 ld (SpriteCacheHeight),a
 ld a,(direct_shift)
 ld (SpriteCacheShift),a
 call MonoCacheAddress
 call SpriteCacheBuild
mcp_hit:
 call MonoCacheAddress
 inc hl
 inc hl
 ld (direct_source),hl
 ret
MonoRender:
mono_new_base:
 ld hl,MonoDesc
 ld (MonoPtr),hl
 xor a
 ld (MonoOwner),a
 ld (MonoActiveCount),a
mono_prepare:
 ld hl,(MonoPtr)
 inc hl
 inc hl
 ld (hl),0
 ld a,(MonoOwner)
 add a,a
 ld l,a
 ld h,high MonoObjects
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (IXobj),hl
 ld a,(hl)
 or a
 jp z,mono_next
 xor a
 ld (color_valid),a
 call plane_object_fast
 ld a,(color_valid)
 or a
 jp z,mono_next
 ex de,hl ; plane_object_fast returns video in HL
 ld hl,(MonoPtr)
 ld (hl),e
 inc hl
 ld (hl),d
 inc hl
 ld a,(direct_columns)
 ld (hl),a
 inc hl
 ld a,(direct_rows)
 ld (hl),a
 inc hl
 push hl
 ld hl,(direct_source)
 ex de,hl
 pop hl
 ld (hl),e
 inc hl
 ld (hl),d
 inc hl
 ld a,(direct_shift)
 ld (hl),a
 ld hl,MonoActiveCount
 inc (hl)
mono_next:
 ld a,(MonoPtr)
 add a,7
 ld (MonoPtr),a
 ld a,(MonoOwner)
 inc a
 ld (MonoOwner),a
 cp 11
 jp nz,mono_prepare
 ; Every sprite is redrawn from its original native source. No shifted
 ; moving-object cache or pairwise isolation pass is required.
 call GameplaySyncPoint
 call PaceStart
 ; No image is ever erased before its replacement is on the screen.
 ; An owner whose old+new bounding box touches no other owner is replaced
 ; in place: the new picture is stored over the box and only the leftover
 ; strips of the old one are zeroed afterwards. Owners that share a box are
 ; handled together the old way: zero their old boxes, then OR-draw them.
 ;
 ; Pass A packs one eight-byte record per active owner:
 ; flag (1 isolated, 2 shared), union box (column, end, top, bottom),
 ; owner number, low bytes of its old and new descriptors.
mono_old_base:
 ld hl,MonoOld
 ex de,hl
 ld hl,(mono_new_base+1)
 ld bc,MonoUnion
 xor a
 ld (MonoFastDraw),a
mono_a_owner:
 ld (mono_a_index+1),a
 inc hl
 inc hl
 inc de
 inc de
 ld a,(de)
 or (hl)
 jp z,mono_a_idle
 ld a,1
 ld (bc),a
 inc bc
 ld a,(de)
 or a
 jp z,mono_a_new_only
 ld a,(hl)
 or a
 jp z,mono_a_old_only
 dec hl
 dec de
 ld a,(de)
 cp (hl)
 jp c,mono_a_col
 ld a,(hl)
mono_a_col:
 ld (bc),a
 inc bc
 ld a,(de)
 inc de
 ex de,hl
 add a,(hl)
 ex de,hl
 ld (mono_a_oend+1),a
 ld a,(hl)
 inc hl
 add a,(hl)
mono_a_oend:
 cp 0
 jp nc,mono_a_end
 ld a,(mono_a_oend+1)
mono_a_end:
 ld (bc),a
 inc bc
 dec hl
 dec hl
 dec de
 dec de
 ld a,(de)
 cp (hl)
 jp nc,mono_a_top
 ld a,(hl)
mono_a_top:
 ld (bc),a
 inc bc
 ld a,(de)
 inc de
 inc de
 inc de
 ex de,hl
 sub (hl)
 ex de,hl
 inc a
 ld (mono_a_obottom+1),a
 ld a,(hl)
 inc hl
 inc hl
 inc hl
 sub (hl)
 inc a
mono_a_obottom:
 cp 0
 jp c,mono_a_bottom
 ld a,(mono_a_obottom+1)
mono_a_bottom:
 ld (bc),a
 inc bc
 jp mono_a_tail
mono_a_old_only:
 push hl
 ld h,d
 ld l,e
 call mono_a_box
 pop hl
 inc hl
 inc de
 jp mono_a_tail
mono_a_new_only:
 push hl
 call mono_a_box
 pop hl
 inc hl
 inc de
mono_a_tail: ; both pointers are at descriptor+3
 ld a,(mono_a_index+1)
 ld (bc),a
 inc bc
 ld a,e
 sub 3
 ld (bc),a
 inc bc
 ld a,l
 sub 3
 ld (bc),a
 inc bc
 ld a,l
 add a,4
 ld l,a
 ld a,e
 add a,4
 ld e,a
 jp mono_a_index
mono_a_idle:
 ld a,l
 add a,5
 ld l,a
 ld a,e
 add a,5
 ld e,a
mono_a_index:
 ld a,0
 inc a
 cp 11
 jp nz,mono_a_owner
 ld a,c
 sub low MonoUnion
 rrca
 rrca
 rrca
 and 31
 ld (MonoActiveN),a
 call mono_pairs
 ld a,(MonoSharedAny)
 or a
 jp z,mono_isolated
 ld hl,mono_h_shared_zero
 call mono_each
 ld hl,mono_h_shared_draw
 call mono_each
mono_isolated:
 xor a ; NOP: store instead of OR
 call MonoMergeMode
 ld hl,mono_h_isolated
 call mono_each
 ld a,$b6 ; OR (HL)
 call MonoMergeMode
 jp mono_copy_old
; HL=descriptor+2, BC=box to fill (advanced). Keeps DE.
mono_a_box:
 push de
 ld a,(hl)
 dec hl
 ld e,(hl)
 add a,e
 ld d,a
 ld a,e
 ld (bc),a
 inc bc
 ld a,d
 ld (bc),a
 inc bc
 dec hl
 ld a,(hl)
 ld (bc),a
 inc bc
 inc hl
 inc hl
 inc hl
 sub (hl)
 inc a
 ld (bc),a
 inc bc
 pop de
 ret

; Mark every pair of records whose union boxes intersect.
mono_pairs:
 xor a
 ld (MonoSharedAny),a
 ld a,(MonoActiveN)
 cp 2
 ret c
 dec a
 ld b,a
 ld hl,MonoUnion+1
mono_pair_i:
 push bc
 push hl
 ld d,h
 ld e,l
 ld c,b
mono_pair_j:
 ld a,l
 add a,8
 ld l,a
 push hl
 push de
 inc hl
 ld a,(de) ; column i
 cp (hl) ; end j
 jp nc,mono_pair_next
 dec hl
 inc de
 ld a,(de) ; end i
 ld b,a
 ld a,(hl) ; column j
 cp b
 jp nc,mono_pair_next
 inc hl
 inc hl ; top j
 inc de
 inc de ; bottom i
 ld a,(de)
 ld b,a
 ld a,(hl)
 cp b
 jp c,mono_pair_next
 inc hl ; bottom j
 dec de ; top i
 ld a,(de)
 cp (hl)
 jp c,mono_pair_next
 pop de
 pop hl
 push hl
 push de
 dec hl
 ld (hl),2
 dec de
 ld a,2
 ld (de),a
 ld (MonoSharedAny),a
mono_pair_next:
 pop de
 pop hl
 dec c
 jp nz,mono_pair_j
 pop hl
 ld a,l
 add a,8
 ld l,a
 pop bc
 dec b
 jp nz,mono_pair_i
 ret

; Call handler HL for every record with A=flag, HL=record.
mono_each:
 ld (mono_each_call+1),hl
 ld a,(MonoActiveN)
 or a
 ret z
 ld b,a
 ld hl,MonoUnion
mono_each_rec:
 push bc
 push hl
 ld a,(hl)
mono_each_call:
 call 0
 pop hl
 ld a,l
 add a,8
 ld l,a
 pop bc
 dec b
 jp nz,mono_each_rec
 ret
mono_h_shared_zero:
 cp 2
 ret nz
 ld de,6
 add hl,de
 ld l,(hl)
 ld a,(mono_old_base+2)
 ld h,a
 ld a,$ff
 ld (mono_z_ncol+1),a
 jp mono_z_old
mono_h_shared_draw:
 cp 2
 ret nz
 jp mono_rec_draw
mono_h_isolated:
 dec a
 ret nz
 push hl
 call mono_rec_draw
 pop hl
 ld de,6
 add hl,de
 ld e,(hl)
 inc hl
 ld l,(hl)
 ld a,(mono_old_base+2)
 ld d,a
 ld a,(mono_new_base+2)
 ld h,a
 ; fall through: zero what is left of the old picture outside the new box
; DE=old descriptor, HL=new descriptor.
mono_zero_strips:
 push de
 push hl
 ld b,4
mono_z_same:
 ld a,(de)
 cp (hl)
 jp nz,mono_z_moved
 inc de
 inc hl
 dec b
 jp nz,mono_z_same
 pop hl
 pop de
 ret ; same geometry: the stored picture covered the old one
mono_z_moved:
 pop hl
 pop de
 ld a,(hl)
 ld (mono_z_ntop+1),a
 ld c,a
 inc hl
 ld a,(hl)
 ld (mono_z_ncol+1),a
 ld b,a
 inc hl
 ld a,(hl)
 or a
 jp nz,mono_z_new
 ld a,$ff
 ld (mono_z_ncol+1),a
 jp mono_z_old_de
mono_z_new:
 add a,b
 ld (mono_z_nend+1),a
 inc hl
 ld a,c
 sub (hl)
 inc a
 ld (mono_z_nbottom+1),a
mono_z_old_de:
 ex de,hl
mono_z_old: ; HL=old descriptor
 ld a,(hl)
 ld (mono_z_top+1),a
 ld (mono_z_top2+1),a
 ld c,a
 inc hl
 ld b,(hl)
 inc hl
 ld a,(hl)
 or a
 ret z
 add a,b
 ld (mono_z_end+1),a
 inc hl
 ld a,(hl)
 ld (mono_z_rows+1),a
 ld a,c
 sub (hl)
 inc a
 ld (mono_z_bottom+1),a
mono_pace_old_call:
 call PaceAccountOld
mono_z_col:
 ld h,b
 ld a,b
mono_z_ncol:
 cp 0
 jp c,mono_z_whole
mono_z_nend:
 cp 0
 jp nc,mono_z_whole
mono_z_top:
 ld a,0
 ld l,a
mono_z_ntop:
 sub 0
 jp c,mono_z_below
 call nz,mono_z_run
mono_z_below:
mono_z_nbottom:
 ld a,0
 ld l,a
 dec l
mono_z_bottom:
 sub 0
 jp c,mono_z_next
 call nz,mono_z_run
 jp mono_z_next
mono_z_whole:
mono_z_top2:
 ld l,0
mono_z_rows:
 ld a,0
 call mono_z_run
mono_z_next:
 inc b
 ld a,b
mono_z_end:
 cp 0
 jp nz,mono_z_col
 ret
mono_z_run:
 ld c,a
 xor a
mono_z_byte:
 ld (hl),a
 dec l
 dec c
 jp nz,mono_z_byte
 ret

; HL=record: draw its owner's new picture in the current merge mode.
mono_rec_draw:
 ld de,5
 add hl,de
 ld a,(hl)
 ld (MonoOwner),a
 inc hl
 inc hl
 ld l,(hl)
 ld a,(mono_new_base+2)
 ld h,a
 ld (MonoPtr),hl
 inc hl
 inc hl
 ld a,(hl)
 or a
 ret z
 dec hl
 dec hl
 ld e,(hl)
 inc hl
 ld d,(hl)
 inc hl
 ld a,(hl)
 ld (MonoDrawCols),a
 inc hl
 ld a,(hl)
 ld (MonoDrawRows),a
 inc hl
 ld c,(hl)
 inc hl
 ld b,(hl)
 inc hl
 ld a,(hl)
 ld (direct_shift),a
 ex de,hl
 ld (MonoDrawVideo),hl
 ld h,b
 ld l,c
 ld (MonoDrawSource),hl
mono_pace_draw_call:
 call PaceAccountDraw
 ld a,(direct_shift)
 ld b,a
 jp MonoDrawWhite
; A=$b6 (OR with the screen) or 0 (store): how the blits merge a sprite byte.
MonoMergeMode:
 ld (MonoStoreOp),a
 ld (mono_bare_merge),a
 ld (BallShiftLeadMerge),a
 ld (BallShiftSpillMerge),a
 ret
MonoStoreOp: db $b6
MonoSharedAny: db 0
MonoActiveN: db 0
 IF high $ != high ($+87)
 DS 256-low $,0
 ENDIF
MonoUnion: ds 88,0
 ASSERT high MonoUnion == high (MonoUnion+87)
mono_copy_old:
 ld hl,(mono_new_base+1)
 ex de,hl
 ld hl,(mono_old_base+1)
 ld (mono_new_base+1),hl
 ex de,hl
 ld (mono_old_base+1),hl
 ret
MonoDraw:
 ld hl,0
 add hl,sp
 ld (mono_draw_restore+1),hl
 ld hl,(MonoDrawSource)
 di
 ld sp,hl
 ld hl,(MonoDrawVideo)
 ld a,(MonoDrawCols)
 ld b,a
 jp MonoDrawBare
mono_draw_restore:
 ld sp,0
 ei
 ret
MonoComposeColumn EQU MonoClearColumn
MonoZeroRange EQU RCBegin
; Outlined round text saves/restores its 10x40 rectangle in all four planes.
; Active moving objects have already been removed at the round transition.
MonoFindIsolated:
MonoEraseFringes:
 ret ; obsolete in clear-old/redraw renderer

MonoRemove:
 call NativeRestoreQueueFlush
 ; Empty new list makes MonoRender restore all old sprite regions to zero.
 ld hl,(mono_new_base+1)
 ld b,11
mono_remove_new:
 inc hl
 inc hl
 ld (hl),0
 ld de,5
 add hl,de
 dec b
 jp nz,mono_remove_new
 ; Use old geometry directly; no callbacks or sprite preparation here.
 ld hl,(mono_old_base+1)
 ld b,11
mono_remove_old:
 push bc
 push hl
 ld e,(hl)
 inc hl
 ld d,(hl)
 inc hl
 ld b,(hl)
 ld (hl),0
 inc hl
 ld c,(hl)
 ld a,b
 or a
 jp z,mono_remove_skip
 call plane_erase_dual

mono_remove_skip:
 pop hl
 ld de,7
 add hl,de
 pop bc
 dec b
 jp nz,mono_remove_old
 jp SpriteCacheReset

MonoPairPrepare:
 ret

 ASSERT low MonoObjects == 0



SpriteCacheBuild:
 ld hl,(IXobj)
 ld a,(hl)
 cp 3
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
 jp SpriteCacheShiftSetup

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
 jp mnn_lit
MonoCoverCodeEnd:

BallShiftMaskInit:
 ld hl,SpriteShiftMasks
 ld a,(direct_shift)
 call hl_add_a
 ld a,(hl)
 ld (BallShiftLead+1),a
 cpl
 ld (BallShiftSpill+1),a
 ret

 INCLUDE "routines/zx_field_frame.asm"
; HL=plane C address of the cell top, DE=cell bitmap, C=rows.
zf_cell:
 ld a,(de)
 inc de
zf_mirror:
 ld b,0
 inc b
 call z,zf_reverse
 ld b,a
zf_mode:
 ld a,0
 or a
 call nz,zf_row_masks
zf_mask_c:
 ld a,0
 and b
 ld (hl),a
 ld a,h
 add a,$20
 ld h,a
 ld a,b
 cpl
zf_mask_e:
 or 0
 ld (hl),a
 ld a,h
 sub $40
 ld h,a
zf_mask_a:
 ld a,0
 and b
 ld (hl),a
 ld a,h
 add a,$20
 ld h,a
 dec l
 dec c
 jp nz,zf_cell
 ret
zf_row_masks:
 ld a,(zf_pattern_c)
 rlca
 ld (zf_pattern_c),a
 sbc a,a
 ld (zf_mask_c+1),a
 ld (zf_mask_e+1),a
 ld a,(zf_pattern_a)
 rlca
 ld (zf_pattern_a),a
 sbc a,a
 ld (zf_mask_a+1),a
 ret
zf_reverse: ; A = A with its bits in reverse order
 push hl
 push bc
 ld c,a
 ld b,8
zf_reverse_bit:
 ld a,c
 rra
 ld c,a
 ld a,h
 rla
 ld h,a
 dec b
 jp nz,zf_reverse_bit
 ld a,h
 pop bc
 pop hl
 ret

; Gameplay frame wait, requested by the game loop and taken once per step.
GameplaySyncPoint:
 ld a,(GameplaySync)
 or a
 ret z ; carry clear: no wait was taken here
 xor a
 ld (GameplaySync),a
 call WaitGameplayFrame
 scf
 ret
GameplaySync: db 0

NativeMagCacheAfterWindow:
 call MagCacheBuildAll
 jp SpriteCacheReset

 INCLUDE "routines/brick_restore_queue_upper.asm"
QueueFresh: db 0
QueueMode: db 0

NativeRestoreQueueGate:
 ld a,(QueueInStep)
 or a
 ret z ; ordinary one/two-ball restores and queue overflow stay complete
 ld a,(NativeRestoreMagnetCount)
 or a
 jp nz,brq_magnet_gate
 ld a,(QueueFresh)
 or a
 jp z,brq_idle_whole
 ld a,(MonoActiveCount)
 cp 7
 jp c,brq_whole_zero
 jp brq_grouped_mode
brq_magnet_gate:
 ld a,(QueueFresh)
 or a
 ret nz
 ld a,(MonoActiveCount)
 cp 7
 ret nc
brq_grouped_mode:
 ld a,(QueueMode)
 cp 3
 ld a,8
 jp nc,brq_nomag_mode
 ld a,5
brq_nomag_mode:
 ld (QueueMode),a ; two columns fit an idle six-owner magnet frame
 ret
brq_whole_zero:
 xor a
brq_idle_whole:
 ld (QueueMode),a ; no magnet and a light scene: finish the whole brick
 ret
NativeRestoreQueueColumn:
 ld a,(QueueMode)
 or a
 ret z
 ld a,d
brq_cut_column:
 sub 0
 ret z
 cp 1
 jp nz,brq_column_skip
 ld a,(QueueMode)
 cp 5
 ret nc ; grouped no-magnet mode also includes the following column
brq_column_skip:
 scf
 ret
QueueCut EQU brq_cut_column+1

brq_get_slot:
 ld hl,wins_recovery_data
 jp hl_add_a
