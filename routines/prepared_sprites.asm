; Native source pair: E=~coverage, D=lit pixels. SP/POP source,
; common A/C/E framebuffer; white rows use all planes, coloured use E only.
PreparedDraw:
 ld hl,(direct_source)
 ld (PreparedSource),hl
 dec hl
 ld a,(hl)
 add a,a
 ld (pd_stride+1),a
 ld a,(direct_rows)
 ld b,a
 ld a,(color_enemy)
 or a
 ld a,b
 jp z,pd_white_count
 ld a,(SpriteCacheHeight)
 or a
 rra
 cp b
 jp c,pd_white_count
 ld a,b
pd_white_count:
 ld (pd_white_rows+1),a
 ld c,a
 ld a,b
 sub c
 ld (pd_color_rows+1),a
 ld a,c
 add a,3
 or a
 rra
 or a
 rra
 ld (pd_white_groups+1),a
 ld a,c
 and 3
 add a,a
 ld hl,PreparedWhiteEntries
 call hl_add_a
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (pd_white_dispatch+1),hl
 ld hl,(plane_dst)
 ld (PreparedDst),hl
 ld a,(direct_columns)
 ld (PreparedCols),a
pd_column:
 ld hl,0
 add hl,sp
 ld (pd_restore+1),hl
 ld hl,(PreparedSource)
 di
 ld sp,hl
 ld hl,(PreparedDst)
pd_white_rows:
 ld a,0
 or a
 jp z,pd_colored
pd_white_groups:
 ld c,0
pd_white_dispatch:
 jp prepared_white_0
prepared_white_0:
 pop de
 ld a,(hl)
 and e
 or d
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and e
 or d
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and e
 or d
 ld (hl),a
 ld a,h
 add a,$40
 ld h,a
 dec l
prepared_white_1:
 pop de
 ld a,(hl)
 and e
 or d
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and e
 or d
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and e
 or d
 ld (hl),a
 ld a,h
 add a,$40
 ld h,a
 dec l
prepared_white_2:
 pop de
 ld a,(hl)
 and e
 or d
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and e
 or d
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and e
 or d
 ld (hl),a
 ld a,h
 add a,$40
 ld h,a
 dec l
prepared_white_3:
 pop de
 ld a,(hl)
 and e
 or d
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and e
 or d
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and e
 or d
 ld (hl),a
 ld a,h
 add a,$40
 ld h,a
 dec l
 dec c
 jp nz,prepared_white_0
pd_colored:
pd_color_rows:
 ld c,0
 ld a,c
 or a
 jp z,pd_restore
prepared_color_row:
 pop de
 ld a,(hl)
 and e
 or d
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and e
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and e
 ld (hl),a
 ld a,h
 add a,$40
 ld h,a
 dec l
 dec c
 jp nz,prepared_color_row
pd_restore:
 ld sp,0
 ei
 ld hl,(PreparedSource)
pd_stride:
 ld a,0
 call hl_add_a
 ld (PreparedSource),hl
 ld hl,(PreparedDst)
 inc h
 ld (PreparedDst),hl
 ld a,(PreparedCols)
 dec a
 ld (PreparedCols),a
 jp nz,pd_column
 ret
PreparedWhiteEntries:
 dw prepared_white_0,prepared_white_3,prepared_white_2,prepared_white_1
PreparedFlag EQU $71e4
PreparedRow EQU $71e5
PreparedCover EQU $71e7
PreparedSource EQU $71e8
PreparedDst EQU $71ea
PreparedCols EQU $71ec
RCPainted EQU $71ed
