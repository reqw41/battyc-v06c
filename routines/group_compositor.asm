; НЕ СОБИРАЕТСЯ. Этот файл не подключает ни batty.asm, ни другие
; собираемые файлы: остаток прежнего варианта вывода — локальные группы
; спрайтов и композиция в ОЗУ («три плоскости», THREE-PLANE-LOCAL-
; COMPOSITOR.md).
; Появился в c3bf6bb, 11.10.2026; подключение снято в 75e0011, 11.10.2026 —
; переход на вывод «3+1».
; Текущий вывод — routines/mono_renderer.asm. Оставлен как архив решений:
; при правках игры его не трогать.
CGRender:
 call CGPrepare
 ld a,(CGFallback)
 or a
 jp z,cgr_groups
 ; Compatibility for test/editor objects exceeding their game's owner slot.
 ; Restore the old image before using the original linear allocator.
 ld a,32
 call PreparedSetStep
 call CGRestoreOldAll
 xor a
 ld (CGFormat),a
 ld (CGPending),a
 ld hl,SUData
 ld (SUDataNext),hl
 ld hl,plane_old
 ld (plane_slot),hl
 jp CGDrawLegacyPrepared
cgr_groups:
 call CGGroups
 ld a,(CGActiveCount)
 or a
 jp z,cgr_finish
 xor a
 ld (CGActiveI),a
cgr_root:
 ld a,(CGActiveI)
 ld hl,CGActive
 call hl_add_a
 ld a,(hl)
 ld (CGRoot),a
 ld a,(CGRoot)
 add a,a
 add a,a
 ld hl,CGRect+1
 call hl_add_a
 ld a,(hl)
 or a
 jp z,cgr_nextroot
 ld a,(CGRoot)
 ld hl,CGLabels
 call hl_add_a
 ld a,(CGRoot)
 cp (hl)
 jp nz,cgr_nextroot
 ld hl,CGSizes
 call hl_add_a
 ld a,(hl)
 cp 1
 jp z,cgr_single
 xor a
 ld (CGMembers),a
 ld hl,CGRecord
 ld b,4
cgr_rzero:
 ld (hl),a
 inc hl
 dec b
 jp nz,cgr_rzero
 xor a
 ld (CGActiveJ),a
 ld hl,CGActive
 ld a,(hl)
cgr_members:
 ld (CGIndex),a
 ld a,(CGIndex)
 ld hl,CGLabels
 call hl_add_a
 ld a,(CGRoot)
 cp (hl)
 jp nz,cgr_nonmember
 ld a,(CGIndex)
 add a,a
 add a,a
 ld hl,CGRect
 call hl_add_a
 ld (CGRectPtr),hl
 inc hl
 ld a,(hl)
 or a
 jp z,cgr_nonmember
 ld a,(CGMembers)
 inc a
 ld (CGMembers),a
 ld a,(CGIndex)
 ld (CGTemp2),a
 ld hl,(CGRectPtr)
 ld de,CGRecord
 ld b,4
 ld a,(CGMembers)
 cp 1
 jp z,cgr_firstrect
 ; Bounding union: even bytes min, odd bytes max.
 ld c,0
cgr_union:
 ld a,(de)
 cp (hl)
 jp c,cgr_min
 ld a,c
 and 1
 ld a,(hl)
 jp z,cgr_put
 jp cgr_unext
cgr_min:
 ld a,c
 and 1
 ld a,(hl)
 jp z,cgr_unext
cgr_put:
 ld (de),a
cgr_unext:
 inc hl
 inc de
 inc c
 dec b
 jp nz,cgr_union
 jp cgr_nonmember
cgr_firstrect:
 ld a,(hl)
 ld (de),a
 inc hl
 inc de
 dec b
 jp nz,cgr_firstrect
cgr_nonmember:
 ld a,(CGActiveJ)
 inc a
 ld (CGActiveJ),a
 ld b,a
 ld a,(CGActiveCount)
 cp b
 jp z,cgr_gathered
 ld a,b
 ld hl,CGActive
 call hl_add_a
 ld a,(hl)
 jp cgr_members
cgr_gathered:
 ld a,(CGMembers)
 or a
 jp z,cgr_nextroot
 cp 1
 jp nz,cgr_tiles
 ld a,(CGTemp2)
 jp cgr_single_owner
cgr_single:
 ld a,(CGRoot)
cgr_single_owner:
 call CGPointers
 ; Same complete footprint: shade straight from its unchanged saved BG.
 ld hl,(CGDPtr)
 ex de,hl
 ld hl,(CGOPtr)
 ld b,4
cgr_same:
 ld a,(de)
 cp (hl)
 jp nz,cgr_isolated_move
 inc hl
 inc de
 dec b
 jp nz,cgr_same
 ld a,(direct_columns)
 ; Copy saved data pointer, avoiding allocation/capture for this owner.
 ld a,(hl)
 ld (de),a
 inc hl
 inc de
 ld a,(hl)
 ld (de),a
 call CGLoad
 call SpriteCachePrepare
 call CGShadeSaved
 jp cgr_nextroot
cgr_isolated_move:
 call CGIsolated
 jp cgr_nextroot
cgr_tiles:
 ld a,1
 call PreparedSetStep
 ld a,(CGRecord)
 ld (CGColumn),a
 ld a,(CGRecord+1)
 ld (CGColEnd),a
 ld a,(CGRecord+3)
 ld (CGYEnd),a
cgr_column:
 ld a,(CGRecord+2)
 ld (CGTileLow),a
cgr_tile:
 ld a,(CGTileLow)
 add a,32
 ld b,a
 ld a,(CGYEnd)
 cp b
 jp c,cgr_tile_end
 ld a,b
cgr_tile_end:
 ld (CGTileEnd),a
 call CGSnapshot
 ld a,10
cgr_old:
 call CGPointers
 call CGIsMember
 jp nz,cgr_old_next
 ld hl,(CGOPtr)
 call CGIntersect
 call nc,CGRestoreSpan
cgr_old_next:
 ld a,(CGIndex)
 dec a
 jp p,cgr_old
 ld a,0
cgr_new:
 call CGPointers
 call CGIsMember
 jp nz,cgr_new_next
 ld hl,(CGDPtr)
 call CGIntersect
 jp c,cgr_new_next
 call CGSaveSpan
 call CGDrawSpan
cgr_new_next:
 ld a,(CGIndex)
 inc a
 cp 11
 jp c,cgr_new
 call CGCommit
 ld a,(CGTileEnd)
 ld b,a
 ld a,(CGYEnd)
 cp b
 ld a,b
 ld (CGTileLow),a
 jp nz,cgr_tile
 ld a,(CGColumn)
 inc a
 ld (CGColumn),a
 ld b,a
 ld a,(CGColEnd)
 cp b
 jp nz,cgr_column
cgr_nextroot:
 ld a,(CGActiveI)
 inc a
 ld (CGActiveI),a
 ld b,a
 ld a,(CGActiveCount)
 cp b
 jp nz,cgr_root
cgr_finish:
 ld a,32
 call PreparedSetStep
 ; Publish records in canonical order after all previous buffers were read.
 ld a,0
cgr_publish:
 call CGPointers
 ld hl,(CGDPtr)
 inc hl
 inc hl
 ld a,(hl)
 or a
 jp z,cgr_publish_next
 ld hl,(CGDPtr)
 push hl
 ld hl,(SURecordNext)
 ex de,hl
 pop hl
 ld b,6
cgr_publish_copy:
 ld a,(hl)
 ld (de),a
 inc hl
 inc de
 dec b
 jp nz,cgr_publish_copy
 ex de,hl
 ld (SURecordNext),hl
 ld a,(SUCount)
 ld hl,CGOwners
 call hl_add_a
 ld a,(CGIndex)
 ld (hl),a
 ld a,(SUCount)
 inc a
 ld (SUCount),a
cgr_publish_next:
 ld a,(CGIndex)
 inc a
 cp 11
 jp c,cgr_publish
 ld a,1
 ld (CGFormat),a
 xor a
 ld (CGPending),a
 ret
CGIsMember:
 ld a,(CGIndex)
 ld hl,CGLabels
 call hl_add_a
 ld a,(CGRoot)
 cp (hl)
 ret
; Clip a six-byte footprint record to one column/tile. Carry = no span.
CGIntersect:
 ld e,(hl)
 inc hl
 ld a,(CGColumn)
 add a,$e0
 sub (hl)
 ret c
 ld c,a
 inc hl
 cp (hl)
 ccf
 ret c
 inc hl
 ld b,(hl)
 ld a,e
 add a,b
 ld d,a                    ; exclusive top of saved rectangle
 ld a,(CGTileEnd)
 cp d
 jp c,cgi_high
 ld a,d
cgi_high:
 ld (CGTemp),a             ; clipped exclusive top
 ld a,(CGTileLow)
 cp e
 jp nc,cgi_low
 ld a,e
cgi_low:
 ld e,a
 ld a,(CGTemp)
 sub e
 scf
 ret z
 ret m
 ld (CGSpanRows),a
 ld a,d
 ld e,a
 ld a,(CGTemp)
 ld d,a
 ld a,e
 sub d
 ld e,a                    ; source row offset
 ld d,0
 push hl
 ld hl,0
 ld a,c
 or a
 jp z,cgi_offset
cgi_col:
 ld a,e
 add a,b
 ld e,a
 jp nc,cgi_no_carry
 inc d
cgi_no_carry:
 dec c
 jp nz,cgi_col
cgi_offset:
 ex de,hl
 add hl,hl
 ex de,hl
 pop hl
 inc hl
 ld a,(hl)
 inc hl
 ld h,(hl)
 ld l,a
 add hl,de
 ld (CGSpanBG),hl
 ld a,(CGTemp)
 dec a
 ld b,a
 ld a,(CGTileLow)
 ld c,a
 ld a,b
 sub c
 add a,CGScratchE%256
 ld l,a
 ld h,CGScratchE/256
 ld (CGSpanDst),hl
 or a
 ret
CGRestoreSpan:
 ld hl,0
 add hl,sp
 ld (cgb_restore_sp+1),hl
 ld hl,(CGSpanBG)
 di
 ld sp,hl
 ld hl,(CGSpanDst)
 ld a,(CGSpanRows)
 ld b,a
cgb_restore_row:
 pop de
 ld (hl),e
 dec h
 ld (hl),d
 inc h
 dec l
 dec b
 jp nz,cgb_restore_row
cgb_restore_sp:
 ld sp,0
 ei
 ret
CGSaveSpan:
 ld hl,(CGSpanDst)
 ex de,hl
 ld hl,(CGSpanBG)
 ld a,(CGSpanRows)
 ld b,a
cgb_save_row:
 ld a,(de)
 ld (hl),a
 inc hl
 dec d
 ld a,(de)
 ld (hl),a
 inc hl
 inc d
 dec e
 dec b
 jp nz,cgb_save_row
 ret
CGDrawSpan:
 call CGLoad
 ; Original source height/stride must survive clipping and cache aliasing.
 call SpriteCachePrepare
 ld hl,(direct_source)
 dec hl
 ld a,(hl)
 add a,a
 ld (pd_stride+1),a
 ld e,a
 ld d,0
 inc hl
 ld a,(plane_dst+1)
 ld b,a
 ld a,(CGColumn)
 add a,$e0
 sub b
 jp z,cgd_row
 ld b,a
cgd_col:
 add hl,de
 dec b
 jp nz,cgd_col
cgd_row:
 ld a,(CGSpanDst)
 sub CGScratchE%256
 ld b,a
 ld a,(CGTileLow)
 add a,b
 ld b,a
 ld a,(plane_dst)
 sub b
 ld (CGTemp),a              ; first source row
 add a,a
 call hl_add_a
 ld (direct_source),hl
 ld a,(CGTemp)
 ld b,a
 ld a,(direct_rows)
 sub b
 ret c
 ret z
 ld b,a
 ld a,(CGSpanRows)
 cp b
 jp c,cgd_rows
 ld a,b
cgd_rows:
 ld (direct_rows),a
 ld a,(color_enemy)
 or a
 jp z,cgd_dst
 ld a,(SpriteCacheHeight)
 or a
 rra
 ld b,a
 ld a,(CGTemp)
 ld c,a
 ld a,b
 sub c
 jp nc,cgd_white
 xor a
cgd_white:
 add a,a
 ld (SpriteCacheHeight),a
cgd_dst:
 ld hl,(CGSpanDst)
 ld (plane_dst),hl
 ld a,1
 ld (direct_columns),a
 jp PreparedDrawKnownStride
; Raster sees only final pairs. Scratch planar pages differ by one.
CGSnapshot:
 ld a,(CGColumn)
 add a,$e0
 ld h,a
 ld a,(CGTileLow)
 ld l,a
 ld (CGVideo),hl
 ld de,CGScratchE
 ld a,(CGTileEnd)
 ld b,a
 ld a,(CGTileLow)
 ld c,a
 ld a,b
 sub c
 ld b,a
cgs_row:
 ld a,(hl)
 ld (de),a
 ld a,h
 sub $20
 ld h,a
 dec d
 ld a,(hl)
 ld (de),a
 ld a,h
 add a,$20
 ld h,a
 inc d
 inc l
 inc e
 dec b
 jp nz,cgs_row
 ret
CGCommit:
 ld hl,0
 add hl,sp
 ld (cgc_restore+1),hl
 ld hl,CGScratchE
 di
 ld sp,hl
 ld hl,(CGVideo)
 ld a,(CGTileEnd)
 ld b,a
 ld a,(CGTileLow)
 ld c,a
 ld a,b
 sub c
 ld (cgc_count+1),a
 ; Two-byte POP supplies adjacent rows in E, then C: paired output to video.
 ld de,CGScratchC
cgc_row:
 ; Source E uses SP, retaining second byte for next row.
 pop bc
 ld a,c
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(de)
 ld (hl),a
 inc e
 ld a,h
 add a,$20
 ld h,a
 inc l
cgc_count:
 ld a,0
 dec a
 ld (cgc_count+1),a
 jp z,cgc_restore
 ld a,b
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(de)
 ld (hl),a
 inc e
 ld a,h
 add a,$20
 ld h,a
 inc l
 ld a,(cgc_count+1)
 dec a
 ld (cgc_count+1),a
 jp nz,cgc_row
cgc_restore:
 ld sp,0
 ei
 ret
; Restore complete interleaved records to video for background event readers.
CGRestoreWhole:
 ld hl,(SUWorkData)
 ld (CGSpanBG),hl
 ld hl,(SUWorkDst)
 ld a,(SUWorkRows)
 dec a
 add a,l
 ld l,a
 ld (CGSpanDst),hl
 ld a,(SUWorkCols)
 ld (CGCols),a
cgw_col:
 ld a,(SUWorkRows)
 ld (CGSpanRows),a
 ld a,32
 ld (cgw_sub+1),a
 ld (cgw_add+1),a
 ld hl,0
 add hl,sp
 ld (cgw_sp+1),hl
 ld hl,(CGSpanBG)
 di
 ld sp,hl
 ld hl,(CGSpanDst)
 ld a,(CGSpanRows)
 ld b,a
cgw_row:
 pop de
 ld (hl),e
 ld a,h
cgw_sub:
 sub 32
 ld h,a
 ld (hl),d
 ld a,h
cgw_add:
 add a,32
 ld h,a
 dec l
 dec b
 jp nz,cgw_row
 ld hl,0
 add hl,sp
 ld (CGSpanBG),hl
cgw_sp:
 ld sp,0
 ei
 ld hl,(CGSpanDst)
 inc h
 ld (CGSpanDst),hl
 ld a,(CGCols)
 dec a
 ld (CGCols),a
 jp nz,cgw_col
 ret
CGRestoreOldAll:
 ld a,10
cgo_next:
 call CGPointers
 ld hl,(CGOPtr)
 ld e,(hl)
 inc hl
 ld d,(hl)
 inc hl
 ld a,(hl)
 or a
 jp z,cgo_skip
 ld (SUWorkCols),a
 inc hl
 ld a,(hl)
 ld (SUWorkRows),a
 inc hl
 ex de,hl
 ld (SUWorkDst),hl
 ex de,hl
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (SUWorkData),hl
 call CGRestoreWhole
cgo_skip:
 ld a,(CGIndex)
 dec a
 jp p,cgo_next
 ret
; Fast isolated stationary footprint. New mask is applied to retained BG.
CGShadeSaved:
 ld hl,(CGDPtr)
 ld de,4
 add hl,de
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (CGSource),hl
 ld a,(direct_columns)
 ld (CGCols),a
 ld hl,(plane_dst)
 ld (CGVideo),hl
 ld hl,(direct_source)
 dec hl
 ld a,(hl)
 add a,a
 ld (cgf_stride+1),a
 inc hl
 ld (PreparedSource),hl
 ld a,(color_enemy)
 or a
 ld a,(direct_rows)
 jp z,cgf_white_ready
 ld b,a
 ld a,(SpriteCacheHeight)
 or a
 rra
 cp b
 jp c,cgf_white_ready
 ld a,b
cgf_white_ready:
 ld (CGWhite),a
 ld b,a
 ld a,(direct_rows)
 sub b
 ld (cgf_color_count+1),a
 ld a,b
 add a,3
 rrca
 rrca
 and $3f
 ld (cgf_group_count+1),a
 ld a,b
 and 3
 add a,a
 ld hl,CGWhiteEntries
 call hl_add_a
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (cgf_dispatch+1),hl
cgf_column:
 ld hl,0
 add hl,sp
 ld (cgf_restore+1),hl
 ld hl,(PreparedSource)
 di
 ld sp,hl
 ld hl,(CGSource)
 ld a,(CGVideo)
 ld c,a
 ld a,(CGVideo+1)
 ld b,a
 ld a,(CGWhite)
 or a
 jp z,cgf_colored
cgf_group_count:
 ld a,0
 ld (cgf_groups+1),a
cgf_dispatch:
 jp cgf_white_0
cgf_white_0:
 pop de
 ld a,(hl)
 and e
 or d
 ld (bc),a
 inc hl
 ld a,(hl)
 and e
 ld e,a
 ld a,b
 sub $20
 ld b,a
 ld a,e
 ld (bc),a
 ld a,b
 add a,$20
 ld b,a
 inc hl
 dec c
cgf_white_1:
 pop de
 ld a,(hl)
 and e
 or d
 ld (bc),a
 inc hl
 ld a,(hl)
 and e
 ld e,a
 ld a,b
 sub $20
 ld b,a
 ld a,e
 ld (bc),a
 ld a,b
 add a,$20
 ld b,a
 inc hl
 dec c
cgf_white_2:
 pop de
 ld a,(hl)
 and e
 or d
 ld (bc),a
 inc hl
 ld a,(hl)
 and e
 ld e,a
 ld a,b
 sub $20
 ld b,a
 ld a,e
 ld (bc),a
 ld a,b
 add a,$20
 ld b,a
 inc hl
 dec c
cgf_white_3:
 pop de
 ld a,(hl)
 and e
 or d
 ld (bc),a
 inc hl
 ld a,(hl)
 and e
 ld e,a
 ld a,b
 sub $20
 ld b,a
 ld a,e
 ld (bc),a
 ld a,b
 add a,$20
 ld b,a
 inc hl
 dec c
cgf_groups:
 ld a,0
 dec a
 ld (cgf_groups+1),a
 jp nz,cgf_white_0
cgf_colored:
 ld a,(cgf_color_count+1)
 or a
 jp z,cgf_pad
 ld (cgf_left+1),a
cgf_color_row:
 pop de
 ld a,(hl)
 and e
 or d
 ld (bc),a
 inc hl
 ld a,(hl)
 and e
 or d
 ld e,a
 ld a,b
 sub $20
 ld b,a
 ld a,e
 ld (bc),a
 ld a,b
 add a,$20
 ld b,a
 inc hl
 dec c
cgf_left:
 ld a,0
 dec a
 ld (cgf_left+1),a
 jp nz,cgf_color_row
cgf_pad:
 ; Even footprint padding must restore BG, never leave an old mask behind.
 ld a,(direct_rows)
 and 1
 jp z,cgf_no_pad
 ld a,(hl)
 ld (bc),a
 inc hl
 ld a,b
 sub $20
 ld b,a
 ld a,(hl)
 ld (bc),a
 inc hl
cgf_no_pad:
 ld (CGSource),hl
cgf_restore:
 ld sp,0
 ei
 ld hl,(PreparedSource)
cgf_stride:
 ld a,0
 call hl_add_a
 ld (PreparedSource),hl
 ld hl,(CGVideo)
 inc h
 ld (CGVideo),hl
 ld a,(CGCols)
 dec a
 ld (CGCols),a
 jp nz,cgf_column
 ret

CGWhiteEntries: dw cgf_white_0,cgf_white_3,cgf_white_2,cgf_white_1
cgf_color_count: ld a,0
