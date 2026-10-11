PreparedDraw:
 ld hl,(direct_source)
 ld (PreparedSource),hl
PreparedSetup:
 dec hl
 ld a,(hl)
 add a,a
 ld (pd_stride+1),a
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
PreparedMask:
 ld sp,hl
 ld hl,(PreparedDst)
 ld a,(direct_rows)
 ld c,a
prepared_mask_row:
 pop de
 ld a,d
 or e
 cpl
 ld b,a
 and (hl)
 or e
 ld (hl),a
 ld a,h
 xor $60
 ld h,a
 ld a,b
 and (hl)
 or d
 ld (hl),a
 ld a,h
 xor $60
 ld h,a
 dec l
 dec c
 jp nz,prepared_mask_row
 jp pd_restore
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
PreparedFlag EQU $71e4
PreparedRow EQU $71e5
PreparedCover EQU $71e7
PreparedSource EQU $71e8
PreparedDst EQU $71ea
PreparedCols EQU $71ec
RCPainted EQU $71ed
