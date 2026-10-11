; Cached column-major (~coverage,lit) pairs. Only lit affects sprite plane.
; Draw new pixels first, then replace old rectangles with final new unions.
; No old/new bounding-box union, no background read, no transient blanking.
MonoObjects: dw object_bonus,object_ball_1,object_ball_2,object_ball_3
 dw object_bullet_1,object_bullet_2,object_bat_2,object_bat_1,object_bat_temp
 dw object_enemy,object_rocket
MonoSlots: dw $7a00,$7a80,$7ac0,$7b00,$7b40,$7b68,$7b90,$7c34,$7cd8,$7d7c,$7e1c,$7f00
MonoCapacities: db 128,64,64,64,40,40,164,164,164,160,228,228
MonoDesc: ds 77,0 ; top address, cols, rows, cached source, bottom-strip bat flag
MonoOld: ds 55,0  ; previous top address, cols, rows, bat flag
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
MonoScanPtr: dw 0
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
SUCount: db 0
SUStatic: db 0
SUNoRoom: db 0
SUDropped: db 0
SpriteShiftMasks: db $ff,$7f,$3f,$1f,$0f,$07,$03,$01
MonoReset:
 ld hl,MonoDesc
 ld b,77+55+48
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
SpriteCacheReset:
 ld hl,MonoTags
 ld b,48
 xor a
mcr_zero:
 ld (hl),a
 inc hl
 dec b
 jp nz,mcr_zero
 ret
RCBegin:
RCFlush:
SUInvalidate:
 ret
MonoCachePrepare:
 ld hl,(IXobj)
 ld a,(hl)
 cp 3
 jp z,mono_cache_needed
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
MonoCacheAddress:
 ld a,(MonoOwner)
 add a,a
 ld hl,MonoSlots
 call hl_add_a
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (SpriteCacheBuffer),hl
 ret
MonoRender:
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
 call MonoCachePrepare
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
 ld hl,(IXobj)
 ld a,(hl)
 cp 1
 jp nz,mono_next
 ld a,(plane_y)
 cp 168
 jp c,mono_next
 ld hl,(MonoPtr)
 ld de,6
 add hl,de
 ld (hl),1
mono_next:
 ld hl,(MonoPtr)
 ld de,7
 add hl,de
 ld (MonoPtr),hl
 ld a,(MonoOwner)
 inc a
 ld (MonoOwner),a
 cp 11
 jp nz,mono_prepare
 ld hl,MonoDesc
 ld (MonoPtr),hl
 ld b,11
mono_draw_all:
 push bc
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
 inc hl
 ld a,(hl)
 ld (MonoDrawBat),a
 ex de,hl
 ld (MonoDrawVideo),hl
 ld h,b
 ld l,c
 ld (MonoDrawSource),hl
 ld a,(MonoDrawCols)
 or a
 call nz,MonoDraw
 ld hl,(MonoPtr)
 ld de,7
 add hl,de
 ld (MonoPtr),hl
 pop bc
 dec b
 jp nz,mono_draw_all
 ld hl,MonoOld
 ld (MonoOldPtr),hl
 ld b,11
mono_erase_all:
 push bc
 ld hl,(MonoOldPtr)
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
 inc hl
 ld a,(hl)
 ld (MonoOldBat),a
 ld a,(MonoCols)
 or a
 jp z,mono_erase_next
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
 ld a,(MonoOldBat)
 or a
 jp z,mono_old_nextcol
 ld a,(MonoColumn)
 add a,$60
 ld h,a
 ld a,(MonoTop)
 ld l,a
 ld de,MonoBlack
 ld a,(MonoRows)
 ld b,a
mono_commit_black:
 ld a,(de)
 cpl
 ld (hl),a
 inc e
 dec l
 dec b
 jp nz,mono_commit_black
mono_old_nextcol:
 ld hl,MonoColumn
 inc (hl)
 ld hl,MonoCols
 dec (hl)
 jp nz,mono_old_column
mono_erase_next:
 ld hl,(MonoOldPtr)
 ld de,5
 add hl,de
 ld (MonoOldPtr),hl
 pop bc
 dec b
 jp nz,mono_erase_all
 ; Keep only previous geometry, never previous background or sprite bytes.
 ld hl,MonoDesc
 ld de,MonoOld
 ld b,11
mono_copy_old:
 ld c,4
mono_copy_geometry:
 ld a,(hl)
 ld (de),a
 inc hl
 inc de
 dec c
 jp nz,mono_copy_geometry
 inc hl
 inc hl
 ld a,(hl)
 ld (de),a
 inc hl
 inc de
 dec b
 jp nz,mono_copy_old
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
mono_draw_col:
 ld a,(MonoDrawRows)
 ld c,a
mono_draw_row:
 pop de
 ld a,d
 or (hl)
 ld (hl),a
 ld a,(MonoDrawBat)
 or a
 jp z,mono_draw_nextrow
 ld a,h
 add a,$60
 ld h,a
 ld a,(hl)
 and e
 ld (hl),a
 ld a,h
 sub $60
 ld h,a
mono_draw_nextrow:
 dec l
 dec c
 jp nz,mono_draw_row
 ld a,(MonoDrawRows)
 add a,l
 ld l,a
 inc h
 dec b
 jp nz,mono_draw_col
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
 ld de,MonoBlack
 ld a,(MonoRows)
 ld b,a
 xor a
mono_clear_scratch:
 ld (hl),a
 ld (de),a
 inc hl
 inc de
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
 inc hl
 ld a,(hl)
 ld (MonoNewBat),a
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
 ld a,(MonoNewBat)
 or a
 jp z,mono_union_rownext
 ld a,e
 add a,32
 ld e,a
 ld a,c
 cpl
 ld c,a
 ld a,(de)
 or c
 ld (de),a
 ld a,e
 sub 32
 ld e,a
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
 ld a,(MonoOldBat)
 or a
 jp z,mono_single_nextrow
 ld a,h
 add a,$60
 ld h,a
 ld a,(MonoNewBat)
 or a
 ld a,$ff
 jp z,mono_single_paper
 ld a,c
mono_single_paper:
 ld (hl),a
 ld a,h
 sub $60
 ld h,a
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
MonoZeroColumn:
 ld a,(MonoColumn)
 ld h,a
 ld a,(MonoTop)
 ld l,a
 ld a,(MonoRows)
 ld b,a
MonoZeroRange:
 ld a,b
 or a
 ret z
mono_zero_row:
 xor a
 ld (hl),a
 ld a,(MonoOldBat)
 or a
 jp z,mono_zero_next
 ld a,h
 add a,$60
 ld h,a
 ld (hl),$ff
 ld a,h
 sub $60
 ld h,a
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
 ld hl,MonoDesc
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
; Round text uses only the sprite plane: save/restore its 10x40 rectangle.
; Active moving objects have already been removed at the round transition.
SUWindowSave:
 xor a
 ld (UiActive),a
 call MonoRemove
 call MonoWindowSetup
 call MonoWindowCopySave
 ld a,1
 ld (SUWindowValid),a
 ret
SUWindowRestore:
 ld a,(SUWindowValid)
 or a
 ret z
 call MonoWindowSetup
 call MonoWindowCopyRestore
 xor a
 ld (SUWindowValid),a
 ld (OverlayActive),a
 jp SpriteCacheReset
MonoWindowSetup:
 ld hl,$8158
 call screen_addr_calc
 ld a,h
 sub $40
 ld h,a
 ld (MonoDrawVideo),hl
 ld hl,$7a00
 ld (MonoDrawSource),hl
 ret
MonoWindowCopySave:
 ld a,0
 ld (mono_window_mode+1),a
 jp MonoWindowCopy
MonoWindowCopyRestore:
 ld a,1
 ld (mono_window_mode+1),a
MonoWindowCopy:
 ld hl,(MonoDrawSource)
 ex de,hl
 ld hl,(MonoDrawVideo)
 ld b,10
mono_window_col:
 ld c,40
mono_window_row:
mono_window_mode:
 ld a,0
 or a
 jp nz,mono_window_restore
 ld a,(hl)
 ld (de),a
 xor a
 ld (hl),a
 jp mono_window_next
mono_window_restore:
 ld a,(de)
 ld (hl),a
mono_window_next:
 inc de
 dec l
 dec c
 jp nz,mono_window_row
 ld a,l
 add a,40
 ld l,a
 inc h
 dec b
 jp nz,mono_window_col
 ret
MonoRemove:
 ; Empty new list makes MonoRender restore all old sprite regions to zero.
 ld hl,MonoDesc
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
 ld hl,MonoOld
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
 inc hl
 ld a,(hl)
 ld (MonoOldBat),a
 ld a,b
 or a
 jp z,mono_remove_skip
 call plane_erase_dual
 ld a,(MonoOldBat)
 or a
 call nz,MonoRestorePaper
mono_remove_skip:
 pop hl
 ld de,5
 add hl,de
 pop bc
 dec b
 jp nz,mono_remove_old
 jp SpriteCacheReset

MonoRestorePaper:
 ld hl,(ClearDst)
 ld a,h
 add a,$60
 ld h,a
 ld a,(ClearColumns)
 ld b,a
mono_restore_paper_col:
 push hl
 ld a,(ClearRows)
 ld c,a
mono_restore_paper_row:
 ld (hl),$ff
 dec l
 dec c
 jp nz,mono_restore_paper_row
 pop hl
 inc h
 dec b
 jp nz,mono_restore_paper_col
 ret
