; Source SP reads one E/F pair; video writes E, C, A together for each row.
PreparedDraw:
 ld hl,(direct_source)
 ld (PreparedSource),hl
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
 ld a,d
 xor e
 ld d,a
 ld a,(hl)
 and b
 or d
 ld (hl),a
 ; E=white coverage and F=black/colored coverage in the source.
 ld a,e
 and d
 ld e,a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and b
 or e
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 and b
 or e
 ld (hl),a
 ld a,h
 add a,$40
 ld h,a
 dec l
 dec c
 jp nz,prepared_mask_row
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
