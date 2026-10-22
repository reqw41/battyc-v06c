; НЕ СОБИРАЕТСЯ. Этот файл не подключает ни batty.asm, ни другие
; собираемые файлы: остаток прежнего варианта вывода — четырёхплоскостная
; база до опытов с тремя плоскостями (LOCAL-COMPOSITE.md).
; Появился в c77b911, 11.10.2026; подключение снято в c95a146, 11.10.2026 —
; три плоскости с save-under.
; Текущий вывод — routines/mono_renderer.asm. Оставлен как архив решений:
; при правках игры его не трогать.
; Interleaved E/F pairs for one column in ordinary RAM. The old video image stays visible
; until its replacement (including every overlapping object) is ready.
RCBufE EQU $7100
RCBufF EQU $7120
RCObjects EQU $7140
RCCurrent EQU $71a4
RCPrevious EQU $71ac
RCRect EQU $71b4
RCActive EQU $71b8
RCTarget EQU $71b9
RCCount EQU $71ba
RCObjPtr EQU $71bb
RCColumn EQU $71bd
RCY EQU $71be
RCCols EQU $71bf
RCRows EQU $71c0
RCIndex EQU $71c1
RCWidth EQU $71c2
RCShift EQU $71c3
RCSource EQU $71c4
RCRow EQU $71c6
RCEnd EQU $71c7
RCWhite EQU $71c8
RCLeft EQU $71c9
RCDesc EQU $71ca
RCStride EQU $71cc
RCCover EQU $71cd
RCBlack EQU $71ce
RCBuffer EQU $71cf
RCPair EQU $71d0
RCBegin:
 xor a
 ld (RCCount),a
 ld (RCTarget),a
 ld (RCCurrent+2),a
 ld (RCCurrent+6),a
 ld a,(object_bonus)
 ld b,a
 ld a,(object_enemy)
 or b
 ld b,a
 ld a,(RCPrevious+2)
 or b
 ld b,a
 ld a,(RCPrevious+6)
 or b
 ld (RCActive),a
 ret
rcb_erase:
 inc hl
 inc hl
 ld a,(hl)
 or a
 ret z
 ld b,a
 ld (hl),0
 inc hl
 ld c,(hl)
 dec hl
 dec hl
 ld a,$e0
 sub (hl)
 ld e,a
 dec hl
 ld a,(hl)
 add a,$e0
 ld d,a
 jp plane_erase_dual
RCRecord:
 xor a
 ld (RCTarget),a
 ld a,(RCActive)
 or a
 ret z
 ld a,(RCCount)
 add a,a
 add a,a
 add a,a
 ld hl,RCObjects
 call hl_add_a
 ; Eight bytes: column, Y, source width, shift, source, rows, white rows.
 ld a,(plane_dst+1)
 sub $e0
 ld (hl),a
 inc hl
 ld a,(plane_y)
 ld (hl),a
 inc hl
 ld a,(direct_width)
 ld (hl),a
 inc hl
 ld a,(PreparedFlag)
 or a
 ld a,(direct_shift)
 jp z,rcre_raw
 or $80
rcre_raw:
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
 ld a,(direct_rows)
 ld (hl),a
 inc hl
 ld a,(color_enemy)
 or a
 ld a,$ff
 jp z,rcre_white
 push hl
 ld hl,(direct_source)
 dec hl
 ld a,(hl)
 or a
 rra
 pop hl
rcre_white:
 ld (hl),a
 ld a,(RCCount)
 inc a
 ld (RCCount),a
 ld hl,(IXobj)
 ld a,(hl)
 and $7f
 ld de,RCCurrent
 cp 4
 jp z,rcre_target
 cp 8
 ret c
 cp 11
 ret nc
 ld de,RCCurrent+4
rcre_target:
 ld a,1
 ld (RCTarget),a
 ld a,(plane_dst+1)
 sub $e0
 ld (de),a
 inc de
 ld a,(plane_y)
 ld (de),a
 inc de
 ld a,(direct_columns)
 ld (de),a
 inc de
 ld a,(direct_rows)
 ld (de),a
 ld hl,(plane_slot)
 dec hl
 dec hl
 ld (hl),0
 ret
RCFlush:
 ld a,(RCActive)
 or a
 ret z
 xor a
 ld (RCPair),a
rcf_pair:
 ld a,(RCPair)
 ld hl,RCCurrent
 call hl_add_a
 ld de,RCRect
 ld b,4
rcf_copy:
 ld a,(hl)
 ld (de),a
 inc hl
 inc de
 dec b
 jp nz,rcf_copy
 ld a,(RCPair)
 ld hl,RCPrevious
 call hl_add_a
 ld a,(hl)
 ld (rcf_oldcol+1),a
 inc hl
 ld a,(hl)
 ld (rcf_oldy+1),a
 inc hl
 ld a,(hl)
 or a
 jp z,rcf_new
 ld b,a
 inc hl
 ld c,(hl)
 ld a,(RCRect+2)
 or a
 jp z,rcf_oldonly
 ; Union if close enough to fit the 32-row column scratch.
 ld a,(RCRect+1)
rcf_oldy:
 sub 0
 jp nc,rcf_down
 cpl
 inc a
rcf_down:
 ld b,a
 ld a,(RCRect+3)
 cp c
 jp nc,rcf_height_max
 ld a,c
rcf_height_max:
 add a,b
 cp 33
 jp nc,rcf_separate
 ld a,(RCRect)
rcf_oldcol:
 sub 0
 jp nc,rcf_right
 cpl
 inc a
rcf_right:
 cp 5
 jp nc,rcf_separate
 ld a,(RCPair)
 ld hl,RCPrevious
 call hl_add_a
 ld de,RCRect
 call rc_union_axis
 inc hl
 inc de
 call rc_union_axis
rcf_new:
 call RCCompose
 jp rcf_remember
rcf_separate:
 ld a,(RCPair)
 ld hl,RCPrevious+2
 call hl_add_a
 ld b,(hl)
 push bc
 call RCCompose
 pop bc
rcf_oldonly:
 ld a,(rcf_oldcol+1)
 ld (RCRect),a
 ld a,(rcf_oldy+1)
 ld (RCRect+1),a
 ld a,b
 ld (RCRect+2),a
 ld a,c
 ld (RCRect+3),a
 call RCCompose
rcf_remember:
 ld a,(RCPair)
 ld hl,RCCurrent
 call hl_add_a
 ld a,(RCPair)
 ld de,RCPrevious
 push hl
 ex de,hl
 call hl_add_a
 ex de,hl
 pop hl
 ld b,4
rcf_save:
 ld a,(hl)
 ld (de),a
 inc hl
 inc de
 dec b
 jp nz,rcf_save
 ld a,(RCPair)
 add a,4
 ld (RCPair),a
 cp 8
 jp c,rcf_pair
 xor a
 ld (RCActive),a
 ld (RCTarget),a
 ret
; HL old start, DE new start; lengths are two bytes after starts.
rc_union_axis:
 ld a,(de)
 ld b,a
 ld a,(hl)
 cp b
 jp nc,rcu_min
 ld b,a
rcu_min:
 ld a,(hl)
 inc hl
 inc hl
 add a,(hl)
 ld c,a
 ld a,(de)
 inc de
 inc de
 ld h,a ; pointer HL no longer needed by caller (reload below)
 ld a,(de)
 add a,h
 cp c
 jp nc,rcu_max
 ld a,c
rcu_max:
 sub b
 ld (de),a
 dec de
 dec de
 ld a,b
 ld (de),a
 ld a,(RCPair)
 ld hl,RCPrevious
 jp hl_add_a
RCCompose:
 ld a,(RCRect+2)
 or a
 ret z
 ld (RCCols),a
 ld a,(RCRect+3)
 ld (RCRows),a
 ld a,(RCRect)
 ld (RCColumn),a
 ld a,(RCRect+1)
 ld (RCY),a
rcc_column:
 xor a
 ld (RCPainted),a
 ld hl,0
 add hl,sp
 ld (rcc_restore+1),hl
 di
 ld sp,RCBufF+32
 ld de,0
 DUP 32
 push de
 EDUP
rcc_restore:
 ld sp,0
 ei
 ld a,(RCCount)
 or a
 jp z,rcc_empty
 ld (RCLeft),a
 ld hl,RCObjects
rcc_object:
 ld (RCDesc),hl
 ld a,(RCColumn)
 sub (hl)
 jp c,rcc_next
 ld (RCIndex),a
 inc hl
 ld a,(RCY)
 sub (hl)
 jp nc,rcc_row
 xor a
rcc_row:
 ld (RCRow),a
 inc hl
 ld c,(hl)
 inc hl
 ld a,(hl)
 ld (RCShift),a
 and 7
 jp z,rcc_cols
 inc c
rcc_cols:
 ld a,(RCIndex)
 cp c
 jp nc,rcc_next
 inc hl
 ld e,(hl)
 inc hl
 ld d,(hl)
 inc hl
 ld a,(hl)
 ld b,a
 ld a,(RCRow)
 cp b
 jp nc,rcc_next
 inc hl
 ld a,(hl)
 ld (RCWhite),a
 ld hl,(RCDesc)
 inc hl
 ld a,(RCY)
 ld c,a
 ld a,(hl)
 add a,b
 ld b,a
 ld a,(RCRows)
 add a,c
 cp b
 jp c,rcc_end
 ld a,b
rcc_end:
 ld b,a
 ld a,(hl)
 ld c,a
 ld a,(RCY)
 cp c
 jp nc,rcc_start
 ld a,c
rcc_start:
 ld c,a
 ld a,b
 sub c
 jp c,rcc_next
 jp z,rcc_next
 ld (RCEnd),a
 ld a,(RCY)
 ld b,a
 ld a,c
 sub b
 add a,a
 add a,RCBufE%256
 ld (RCBuffer),a
 ex de,hl
 ld a,(RCShift)
 or a
 jp m,RCPreparedColumn
 ; Raw-only metadata: prepared/off-column objects never consume it.
 push hl
 ld hl,(RCDesc)
 inc hl
 inc hl
 ld a,(hl)
 ld (RCWidth),a
 add a,a
 ld (RCStride),a
 pop hl
 ld a,(RCRow)
 or a
 jp z,rcc_source_col
 ld b,a
 ld a,(RCStride)
 ld e,a
 ld d,0
rcc_source_row:
 add hl,de
 dec b
 jp nz,rcc_source_row
rcc_source_col:
 ld a,(RCIndex)
 add a,a
 ld e,a
 ld d,0
 add hl,de
 ld (RCSource),hl
 ld a,1
 ld (RCPainted),a
 ld a,(RCShift)
 or a
 jp z,RCFastColumn
 ld (SpriteCacheShift),a
 call SpriteSetRotation
rcc_pixel:
 ld hl,(RCSource)
 ld a,(RCIndex)
 ld b,a
 ld a,(RCWidth)
 cp b
 ld b,0
 ld c,0
 jp z,rcc_trailing
 ld b,(hl)
 inc hl
 ld a,(hl)
 and b
 ld c,a
rcc_trailing:
 ld a,b
 ld (RCCover),a
 ld a,c
 ld (RCBlack),a
 ld a,(RCShift)
 or a
 jp z,rcc_apply
 ld a,(RCCover)
 call SpriteRotate
 ld (RCCover),a
 ld a,(RCBlack)
 call SpriteRotate
 ld (RCBlack),a
 ld a,(RCIndex)
 or a
 jp z,rcc_apply
 ld hl,(RCSource)
 dec hl
 ld a,(hl)
 dec hl
 and (hl)
 ld e,a
 ld a,(hl)
 call SpriteRotate
 ld a,(RCCover)
 or c
 ld (RCCover),a
 ld a,e
 call SpriteRotate
 ld a,(RCBlack)
 or c
 ld (RCBlack),a
rcc_apply:
 ld a,(RCCover)
 ld b,a
 ld a,(RCBlack)
 ld c,a
 ld a,(RCBuffer)
 ld l,a
 ld h,RCBufE/256
 ld a,(RCRow)
 ld e,a
 ld a,(RCWhite)
 cp e
 jp z,rcc_enemy
 jp c,rcc_enemy
 ld a,b
 or (hl)
 ld (hl),a
 ld a,l
 xor 1
 ld l,a
 ld a,b
 cpl
 and (hl)
 or c
 ld (hl),a
 jp rcc_advance
rcc_enemy:
 ld a,b
 cpl
 and (hl)
 or c
 ld (hl),a
 ld a,l
 xor 1
 ld l,a
 ld a,b
 or (hl)
 ld (hl),a
rcc_advance:
 ld a,(RCBuffer)
 add a,2
 ld (RCBuffer),a
 ld a,(RCRow)
 inc a
 ld (RCRow),a
 ld hl,(RCSource)
 ld a,(RCStride)
 ld e,a
 ld d,0
 add hl,de
 ld (RCSource),hl
 ld a,(RCEnd)
 dec a
 ld (RCEnd),a
 jp nz,rcc_pixel
 jp rcc_next
RCPreparedColumn:
 ; Full source height remains in the cache header, even at bottom clipping.
 dec hl
 ld a,(hl)
 add a,a
 ld e,a
 ld d,0
 inc hl
 ld a,(RCIndex)
 or a
 jp z,rcp_row_offset
 ld b,a
rcp_col_offset:
 add hl,de
 dec b
 jp nz,rcp_col_offset
rcp_row_offset:
 ld a,(RCRow)
 add a,a
 call hl_add_a
 ex de,hl
 ld hl,0
 add hl,sp
 ld (rcp_restore+1),hl
 ex de,hl
 di
 ld sp,hl
 ld a,(RCBuffer)
 ld l,a
 ld h,RCBufE/256
 ld a,(RCEnd)
 ld c,a
 ld a,(RCPainted)
 or a
 jp nz,rcp_row
rcp_copy:
 pop de
 ld (hl),e
 inc l
 ld (hl),d
 inc l
 dec c
 jp nz,rcp_copy
 jp rcp_restore
rcp_row:
 pop de
 ld a,d
 or e
 cpl
 ld b,a
 and (hl)
 or e
 ld (hl),a
 inc l
 ld a,b
 and (hl)
 or d
 ld (hl),a
 inc l
 dec c
 jp nz,rcp_row
rcp_restore:
 ld sp,0
 ei
 ld a,1
 ld (RCPainted),a
 jp rcc_next
RCFastColumn:
 ld a,(RCStride)
 dec a
 ld (rcfc_stride+1),a
 ld a,(RCEnd)
 ld (rcfc_rows+1),a
 ld a,(RCWhite)
 ld b,a
 ld a,(RCRow)
 ld c,a
 ld a,b
 sub c
 add a,a
 ld b,a
 ld a,(RCBuffer)
 ld l,a
 add a,b
 ld (rcfc_boundary+1),a
 ld h,RCBufE/256
 ld a,(RCWhite)
 cp c
 jp z,rcfc_enemy
 jp nc,rcfc_mode_ready
rcfc_enemy:
 ld a,l
 xor 1
 ld l,a
rcfc_mode_ready:
 push hl
 ld hl,(RCSource)
 ex de,hl
 pop hl
rcfc_row:
 ld a,(de)
 inc de
 ld b,a
 ld a,(de)
 and b
 ld c,a
 ld a,b
 or (hl)
 ld (hl),a
 ld a,l
 xor 1
 ld l,a
 ld a,b
 cpl
 and (hl)
 or c
 ld (hl),a
 ld a,l
 xor 1
 add a,2
 ld l,a
 and $fe
rcfc_boundary:
 cp 0
 jp nz,rcfc_advance
 ld a,l
 xor 1
 ld l,a
rcfc_advance:
 ld a,e
rcfc_stride:
 add a,0
 ld e,a
 jp nc,rcfc_rows
 inc d
rcfc_rows:
 ld a,0
 dec a
 ld (rcfc_rows+1),a
 jp nz,rcfc_row
 jp rcc_next
rcc_next:
 ld hl,(RCDesc)
 ld de,8
 add hl,de
 ld a,(RCLeft)
 dec a
 ld (RCLeft),a
 jp nz,rcc_object
rcc_empty:
 ; E/F are committed next to each other for each scanline.
 ld a,(RCColumn)
 add a,$e0
 ld d,a
 ld a,(RCY)
 ld e,a
 ld a,$e0
 sub e
 ld e,a
 di
 ld hl,0
 add hl,sp
 ld (rcc_commit_restore+1),hl
 ld a,(RCRows)
 ld l,a
 ld sp,RCBufE
rcc_commit:
 pop bc
 ld a,c
 ld (de),a
 ld a,d
 xor $60
 ld d,a
 ld a,b
 ld (de),a
 ld a,d
 xor $60
 ld d,a
 dec e
 dec l
 jp nz,rcc_commit
rcc_commit_restore:
 ld sp,0
 ei
 ld a,(RCColumn)
 inc a
 ld (RCColumn),a
 ld a,(RCCols)
 dec a
 ld (RCCols),a
 jp nz,rcc_column
 ret
