; Native column-major (~coverage,lit) pairs. Only lit affects sprite plane.
; Isolated owners overwrite the new rectangle and clear only retiring fringes.
; Intersecting owners use OR and final composition of their old rectangles.
MonoObjects: dw object_bonus,object_ball_1,object_ball_2,object_ball_3
 dw object_bullet_1,object_bullet_2,object_bat_2,object_bat_1,object_bat_temp
 dw object_enemy,object_rocket
MonoSlots: dw $7a00,$7a80,$7ac0,$7b00,$7b40,$7b68,$7b90,$7c34,$7cd8,$7d7c,$7e1c,$7f00
MonoCapacities: db 128,64,64,64,40,40,164,164,164,160,228,228
MonoDesc: ds 77,0 ; top address, cols, rows, source, bottom-strip bat flag
MonoOld: ds 77,0  ; second descriptor bank; no per-frame geometry copy
 ASSERT high MonoDesc == high (MonoOld+77)
 ASSERT high MonoRegions == high (MonoRegions+55)
MonoTags: ds 48,0 ; source pointer, shift, clipped height, per owner
MonoOwner: db 0
MonoPtr: dw 0
MonoOldPtr: dw 0
MonoDrawSource: dw 0
MonoDrawVideo: dw 0
MonoDrawCols: db 0
MonoDrawRows: db 0
MonoDrawBat: db 0
MonoColumn: db 0
MonoTop: db 0
MonoRows: db 0
MonoCols: db 0
MonoOldBat: db 0
MonoScan: db 0
MonoCandidates: ds 22,0
MonoCandidateCount: db 0
MonoCandidatePtr: dw 0
MonoSelectPtr: dw 0
MonoSelectCount: db 0
MonoOldRight: db 0
MonoOldBottom: db 0
MonoSingleFlag: db 0
MonoNewTop: db 0
MonoNewRows: db 0
MonoNewBat: db 0
MonoDeltaCol: db 0
MonoSpanTop: db 0
MonoSpanBottom: db 0
MonoSpanRows: db 0
MonoSource: dw 0
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
 ld b,77+77+48
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
 ret
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
 ld hl,plane_old
 ld (plane_slot),hl
 xor a
 ld (MonoOwner),a
mono_prepare:
 ld hl,(MonoPtr)
 inc hl
 inc hl
 ld (hl),0
 ld a,(MonoOwner)
 add a,a
 ld hl,MonoObjects
 call hl_add_a
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
 ld hl,MonoShifts
 ld a,(MonoOwner)
 call hl_add_a
 ld a,(direct_shift)
 ld (hl),a
 ld hl,(plane_dst)
 ex de,hl
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
 ld (hl),0
mono_next:
 ld a,(MonoPtr)
 add a,7
 ld (MonoPtr),a
 ld a,(MonoOwner)
 inc a
 ld (MonoOwner),a
 cp 11
 jp nz,mono_prepare
 call MonoCompositeBat
 call MonoFindIsolated
 call MonoPairPrepare
 call PaceStart
 xor a
 ld (MonoOwner),a
 ld hl,MonoRegions
 ld (MonoRegionPtr),hl
 ld hl,(mono_new_base+1)
 ld (MonoPtr),hl
 ld b,11
mono_draw_all:
 push bc
 ld hl,(MonoPtr)
 inc hl
 inc hl
 ld a,(hl)
 or a
 jp z,mono_draw_next
 ld hl,(MonoRegionPtr)
 ld de,4
 add hl,de
 ld a,(hl)
 ld (MonoFastDraw),a
 ld hl,(MonoPtr)
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
 ex de,hl
 ld (MonoDrawVideo),hl
 ld h,b
 ld l,c
 ld (MonoDrawSource),hl
mono_pace_draw_call:
 call PaceAccountDraw
 call MonoDrawPrepared
mono_draw_next:
 ld a,(MonoRegionPtr)
 add a,5
 ld (MonoRegionPtr),a
 ld a,(MonoOwner)
 inc a
 ld (MonoOwner),a
 ld a,(MonoPtr)
 add a,7
 ld (MonoPtr),a
 pop bc
 dec b
 jp nz,mono_draw_all
 ld hl,(mono_new_base+1)
 ld (MonoPtr),hl
 ld hl,MonoRegions
 ld (MonoRegionPtr),hl
mono_old_base:
 ld hl,MonoOld
 ld (MonoOldPtr),hl
 ld b,11
mono_erase_all:
 push bc
 ld hl,(MonoOldPtr)
 inc hl
 inc hl
 ld a,(hl)
 or a
 jp z,mono_erase_next
 dec hl
 dec hl
 ld a,(hl)
 ld (MonoTop),a
 inc hl
 ld a,(hl)
 ld (MonoColumn),a
 inc hl
 ld a,(hl)
 ld (MonoCols),a
 inc hl
 ld a,(hl)
 ld (MonoRows),a
mono_pace_old_call:
 call PaceAccountOld
 ld hl,(MonoRegionPtr)
 ld de,4
 add hl,de
 ld a,(hl)
 or a
 jp z,mono_erase_general
 call MonoEraseFringes
 jp mono_erase_next
mono_erase_general:
 call MonoSelectCandidates
mono_old_column:
 call MonoComposeColumn
 ld a,(MonoSingleFlag)
 or a
 jp nz,mono_old_nextcol
 ld a,(MonoColumn)
 ld h,a
 ld a,(MonoTop)
 ld l,a
 ld de,MonoScratch
 ld a,(MonoRows)
 ld b,a
mono_commit:
 ld a,(de)
 ld (hl),a
 inc e
 dec l
 dec b
 jp nz,mono_commit
mono_old_nextcol:
 ld hl,MonoColumn
 inc (hl)
 ld hl,MonoCols
 dec (hl)
 jp nz,mono_old_column
mono_erase_next:
 ld a,(MonoPtr)
 add a,7
 ld (MonoPtr),a
 ld a,(MonoRegionPtr)
 add a,5
 ld (MonoRegionPtr),a
 ld a,(MonoOldPtr)
 add a,7
 ld (MonoOldPtr),a
 pop bc
 dec b
 jp nz,mono_erase_all
 ; The completed new list becomes previous without copying any records.
mono_copy_old:
 ld hl,(mono_new_base+1)
 ex de,hl
 ld hl,(mono_old_base+1)
 ld (mono_new_base+1),hl
 ex de,hl
 ld (mono_old_base+1),hl
 ret
MonoDraw:
 ld a,(MonoFastDraw)
 or a
 ld a,$b6 ; OR M
 jp z,mono_draw_mode
 xor a
mono_draw_mode:
 ld (mono_bare_merge),a
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
MonoComposeColumn:
 xor a
 ld (MonoSingleFlag),a
 ld a,(MonoCandidateCount)
 cp 2
 jp nc,mono_many_candidates
 ld a,1
 ld (MonoSingleFlag),a
 ld a,(MonoCandidateCount)
 or a
 jp z,MonoZeroColumn
 jp mono_candidates_ready
mono_many_candidates:
 ld hl,MonoScratch
 ld a,(MonoRows)
 ld b,a
 xor a
mono_clear_scratch:
 ld (hl),a
 inc hl
 dec b
 jp nz,mono_clear_scratch
mono_candidates_ready:
 ld a,(MonoCandidateCount)
 or a
 ret z
 ld (MonoScan),a
 ld hl,MonoCandidates
 ld (MonoCandidatePtr),hl
mono_union_object:
 ld hl,(MonoCandidatePtr)
 ld e,(hl)
 inc hl
 ld d,(hl)
 inc hl
 ld (MonoCandidatePtr),hl
 ex de,hl
 ld a,(hl)
 ld (MonoNewTop),a
 inc hl
 ld b,(hl)
 inc hl
 ld c,(hl)
 ld a,(MonoColumn)
 sub b
 jp c,mono_union_next
 cp c
 jp nc,mono_union_next
 ld (MonoDeltaCol),a
 inc hl
 ld a,(hl)
 ld (MonoNewRows),a
 or a
 jp z,mono_union_next
 inc hl
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (MonoSource),hl
 ld a,(MonoNewTop)
 ld b,a
 ld a,(MonoTop)
 cp b
 jp c,mono_span_top
 ld a,b
mono_span_top:
 ld (MonoSpanTop),a
 ld a,(MonoNewRows)
 ld c,a
 ld a,(MonoNewTop)
 sub c
 inc a
 ld b,a
 ld a,(MonoRows)
 ld c,a
 ld a,(MonoTop)
 sub c
 inc a
 cp b
 jp nc,mono_span_bottom
 ld a,b
mono_span_bottom:
 ld (MonoSpanBottom),a
 ld b,a
 ld a,(MonoSpanTop)
 sub b
 jp c,mono_union_next
 inc a
 ld (MonoSpanRows),a
 ld a,(MonoNewRows)
 add a,a
 ld e,a
 ld d,0
 ld hl,(MonoSource)
 ld a,(MonoDeltaCol)
 or a
 jp z,mono_span_rowoffset
 ld b,a
mono_span_coloffset:
 add hl,de
 dec b
 jp nz,mono_span_coloffset
mono_span_rowoffset:
 ld a,(MonoSpanTop)
 ld b,a
 ld a,(MonoNewTop)
 sub b
 add a,a
 call hl_add_a
 ld (MonoSource),hl
 ld a,(MonoSpanTop)
 ld b,a
 ld a,(MonoTop)
 sub b
 add a,MonoScratch%256
 ld e,a
 ld d,MonoScratch/256
 ld a,(MonoSpanRows)
 ld b,a
 ld a,(MonoSingleFlag)
 or a
 jp nz,MonoSingleCommit
mono_union_rows:
 ld c,(hl)
 inc hl
 ld a,(de)
 or (hl)
 ld (de),a
 inc hl
mono_union_rownext:
 inc e
 dec b
 jp nz,mono_union_rows
mono_union_next:
 ld a,(MonoSingleFlag)
 or a
 jp nz,MonoZeroColumn
 ld hl,MonoScan
 dec (hl)
 jp nz,mono_union_object
 ret
MonoSingleCommit:
 ex de,hl
 ld a,(MonoColumn)
 ld h,a
 ld a,(MonoSpanTop)
 ld l,a
 ld a,(MonoSpanRows)
 ld b,a
mono_single_rows:
 ld a,(de)
 ld c,a
 inc de
 ld a,(de)
 ld (hl),a
 inc de
mono_single_nextrow:
 dec l
 dec b
 jp nz,mono_single_rows
 ld a,(MonoSpanTop)
 ld b,a
 ld a,(MonoTop)
 sub b
 ld b,a
 ld a,(MonoColumn)
 ld h,a
 ld a,(MonoTop)
 ld l,a
 call MonoZeroRange
 ld a,(MonoSpanBottom)
 ld b,a
 ld a,(MonoOldBottom)
 ld c,a
 ld a,b
 sub c
 ld b,a
 ld a,(MonoSpanBottom)
 dec a
 ld l,a
 ld a,(MonoColumn)
 ld h,a
 jp MonoZeroRange
MonoZeroRange:
 ld a,b
 or a
 ret z
mono_zero_row:
 xor a
 ld (hl),a
mono_zero_next:
 dec l
 dec b
 jp nz,mono_zero_row
 ret
MonoSelectCandidates:
 xor a
 ld (MonoCandidateCount),a
 ld hl,MonoCandidates
 ld (MonoCandidatePtr),hl
 ld a,(MonoColumn)
 ld b,a
 ld a,(MonoCols)
 add a,b
 ld (MonoOldRight),a
 ld a,(MonoRows)
 ld b,a
 ld a,(MonoTop)
 sub b
 inc a
 ld (MonoOldBottom),a
 ld hl,(mono_new_base+1)
 ld (MonoSelectPtr),hl
 ld a,11
 ld (MonoSelectCount),a
mono_select:
 ld hl,(MonoSelectPtr)
 ld e,(hl)
 inc hl
 ld d,(hl)
 inc hl
 ld a,(hl)
 or a
 jp z,mono_select_next
 add a,d
 ld b,a
 ld a,(MonoColumn)
 cp b
 jp nc,mono_select_next
 ld a,(MonoOldRight)
 cp d
 jp c,mono_select_next
 jp z,mono_select_next
 ld a,(MonoOldBottom)
 cp e
 jp c,mono_select_vertical
 jp nz,mono_select_next
mono_select_vertical:
 inc hl
 ld a,e
 sub (hl)
 inc a
 ld b,a
 ld a,(MonoTop)
 cp b
 jp c,mono_select_next
 ld hl,(MonoSelectPtr)
 ex de,hl
 ld hl,(MonoCandidatePtr)
 ld (hl),e
 inc hl
 ld (hl),d
 inc hl
 ld (MonoCandidatePtr),hl
 ld hl,MonoCandidateCount
 inc (hl)
mono_select_next:
 ld hl,(MonoSelectPtr)
 ld de,7
 add hl,de
 ld (MonoSelectPtr),hl
 ld hl,MonoSelectCount
 dec (hl)
 jp nz,mono_select
 ret
; Outlined round text saves/restores its 10x40 rectangle in all four planes.
; Active moving objects have already been removed at the round transition.
 INCLUDE "routines/mono_isolation.asm"

MonoRemove:
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

 INCLUDE "routines/mono_composite_bat.asm"
 INCLUDE "routines/mono_pair_clear.asm"
