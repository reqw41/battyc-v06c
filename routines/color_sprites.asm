; 00 transparent, E white, F level enemy color, E+F black.
; The source mask is the original silhouette, including its black outline.
plane_object:
 xor a
 ld (PreparedFlag),a
 ld (color_valid),a
 ld (color_enemy),a
 ld hl,(IXobj)
 ld a,(hl)
 ld hl,color_write_white
 and $7f
 cp 8
 jp c,color_select
 cp 11
 jp nc,color_select
 ld a,1
 ld (color_enemy),a
 ld hl,color_write_enemy
color_select:
 ld (color_write+1),hl
 call plane_object_fast
 ld a,(color_valid)
 or a
 ret z
 call SpriteCachePrepare
 ld hl,(direct_source)
 dec hl
 ld a,(hl)
 or a
 rra
 ld b,a
 ld a,(direct_rows)
 sub b
 jp nc,color_limit_ready
 xor a
color_limit_ready:
 ld (color_white_limit),a
 call RCRecord
 ld a,(RCTarget)
 or a
 ret nz
 ld a,(PreparedFlag)
 or a
 jp nz,PreparedDraw
 ; Aligned, unclipped sprites never use the rotation/carry byte path.
 ld a,(direct_shift)
 or a
 jp nz,color_prepare_rotations
 ld a,(direct_width)
 cp 9
 jp nc,color_prepare_rotations
 ld a,(direct_clipped)
 or a
 jp z,color_start_stack
color_prepare_rotations:
 ld a,(direct_shift)
 add a,a
 ld e,a
 ld d,0
 ld hl,color_rotations
 add hl,de
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (color_rotate_cover+1),hl
 ld de,color_black_r0-color_cover_r0
 add hl,de
 ld (color_rotate_black+1),hl
 ld a,(direct_shift)
 ld hl,SpriteShiftMasks
 call hl_add_a
 ld a,(hl)
color_mask_ready:
 ld (color_leading_cover+1),a
 ld (color_leading_black+1),a
 xor $ff
 ld (color_spill_cover+1),a
 ld (color_spill_black+1),a
color_start_stack:
 ld hl,0
 add hl,sp
 ld (color_restore+1),hl
 ld hl,(direct_source)
 di
 ld sp,hl
 ld hl,(plane_dst)
 ld a,h
 sub $60
 ld h,a
 ld a,(direct_shift)
 or a
 jp z,color_fast_entry
color_row:
 ex de,hl
 ld hl,color_after_write
 ld (color_continue+1),hl
 ex de,hl
 ; White upper detail and level-colored lower detail share the same mask.
 ex de,hl
 ld hl,color_write_white
 ld a,(color_enemy)
 or a
 jp z,color_row_writer
 ld a,(color_height)
 ld b,a
 ld a,(color_white_limit)
 cp b
 jp c,color_row_writer
 ld hl,color_write_enemy
color_row_writer:
 ld (color_write+1),hl
 ex de,hl
 xor a
 ld (color_carry_cover),a
 ld (color_carry_black),a
 ld a,(direct_width)
 ld (color_left),a
color_byte:
 pop de
 ld a,d
 and e
 ld d,a
 ld a,e
color_rotate_cover:
 jp color_cover_r0
color_cover_r7:
 rrca
color_cover_r6:
 rrca
color_cover_r5:
 rrca
color_cover_r4:
 rrca
color_cover_r3:
 rrca
color_cover_r2:
 rrca
color_cover_r1:
 rrca
color_cover_r0:
 ld (color_rotated_cover),a
 ld a,d
color_rotate_black:
 jp color_black_r0
color_black_r7:
 rrca
color_black_r6:
 rrca
color_black_r5:
 rrca
color_black_r4:
 rrca
color_black_r3:
 rrca
color_black_r2:
 rrca
color_black_r1:
 rrca
color_black_r0:
 ld (color_rotated_black),a
color_leading_black:
 and $ff
 ld c,a
 ld a,(color_carry_black)
 or c
 ld c,a
 ld a,(color_rotated_cover)
color_leading_cover:
 and $ff
 ld b,a
 ld a,(color_carry_cover)
 or b
 ld b,a
 ld a,h
 cp $a0
 jp nc,color_after_write
color_write:
 jp color_write_white
color_write_white:
 ld a,b
 cpl
 and (hl)
 or c
 ld (hl),a
 ld a,h
 add $60
 ld h,a
 ld a,b
 or (hl)
 ld (hl),a
 jp color_written
color_write_enemy:
 ld a,b
 or (hl)
 ld (hl),a
 ld a,h
 add $60
 ld h,a
 ld a,b
 cpl
 and (hl)
 or c
 ld (hl),a
color_written:
 ld a,h
 sub $60
 ld h,a
color_continue:
 jp color_after_write
color_after_write:
 ld a,(color_rotated_cover)
color_spill_cover:
 and 0
 ld (color_carry_cover),a
 ld a,(color_rotated_black)
color_spill_black:
 and 0
 ld (color_carry_black),a
 inc h
 ld a,(color_left)
 dec a
 ld (color_left),a
 jp nz,color_byte
 ; Reuse the writer once for the trailing partial byte.
 ld a,(direct_shift)
 or a
 jp z,color_row_end
 ld a,h
 cp $a0
 jp nc,color_row_end
 ld a,(color_carry_cover)
 ld b,a
 ld a,(color_carry_black)
 ld c,a
 ; Reuse the selected writer for the final partial byte.
 ex de,hl
 ld hl,color_row_end
 ld (color_continue+1),hl
 ex de,hl
 jp color_write
color_row_end:
 ld a,(direct_width)
 ld b,a
 ld a,h
 sub b
 ld h,a
 dec l
 ld a,h
 add $60
 ld h,a
 ld (plane_dst),hl
 ld a,h
 sub $60
 ld h,a
 ld a,(color_height)
 dec a
 ld (color_height),a
 jp nz,color_row
 jp color_restore
color_fast_entry:
 ; The unrolled dispatch has eight entries; wider assets use the byte loop.
 ld a,(direct_width)
 cp 9
 jp nc,color_row
 ld a,(direct_clipped)
 or a
 jp nz,color_row
 ; Select the row continuation once instead of checking the object every row.
 ld hl,color_fast_dispatch
 ld a,(color_enemy)
 or a
 jp z,color_fast_mode_ready
 ld hl,color_fast_enemy_boundary
color_fast_mode_ready:
 ld (color_fast_row_mode+1),hl
 xor a
 ld (color_pass),a
 ld hl,color_cover_table
 jp color_fast_setup
color_fast_black:
 ld a,1
 ld (color_pass),a
 ld hl,(direct_source)
 ld sp,hl
 ld hl,color_black_table
color_fast_setup:
 ld a,(direct_width)
 dec a
 add a,a
 ld e,a
 ld d,0
 add hl,de
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (color_fast_dispatch+1),hl
 ld a,(direct_width)
 ld (color_fast_width+1),a
 ld hl,(plane_dst)
 ld a,(color_pass)
 or a
 jp z,color_fast_position
 ld a,h
 sub $60
 ld h,a
color_fast_position:
 ld a,(direct_rows)
 ld c,a
color_fast_dispatch:
 jp color_cover_1
color_cover_8:
 pop de
 ld a,e
 or (hl)
 ld (hl),a
 inc h
color_cover_7:
 pop de
 ld a,e
 or (hl)
 ld (hl),a
 inc h
color_cover_6:
 pop de
 ld a,e
 or (hl)
 ld (hl),a
 inc h
color_cover_5:
 pop de
 ld a,e
 or (hl)
 ld (hl),a
 inc h
color_cover_4:
 pop de
 ld a,e
 or (hl)
 ld (hl),a
 inc h
color_cover_3:
 pop de
 ld a,e
 or (hl)
 ld (hl),a
 inc h
color_cover_2:
 pop de
 ld a,e
 or (hl)
 ld (hl),a
 inc h
color_cover_1:
 pop de
 ld a,e
 or (hl)
 ld (hl),a
 inc h
 jp color_fast_row_end
color_black_8:
 pop de
 ld a,d
 and e
 ld d,a
 ld a,e
 cpl
 and (hl)
 or d
 ld (hl),a
 inc h
color_black_7:
 pop de
 ld a,d
 and e
 ld d,a
 ld a,e
 cpl
 and (hl)
 or d
 ld (hl),a
 inc h
color_black_6:
 pop de
 ld a,d
 and e
 ld d,a
 ld a,e
 cpl
 and (hl)
 or d
 ld (hl),a
 inc h
color_black_5:
 pop de
 ld a,d
 and e
 ld d,a
 ld a,e
 cpl
 and (hl)
 or d
 ld (hl),a
 inc h
color_black_4:
 pop de
 ld a,d
 and e
 ld d,a
 ld a,e
 cpl
 and (hl)
 or d
 ld (hl),a
 inc h
color_black_3:
 pop de
 ld a,d
 and e
 ld d,a
 ld a,e
 cpl
 and (hl)
 or d
 ld (hl),a
 inc h
color_black_2:
 pop de
 ld a,d
 and e
 ld d,a
 ld a,e
 cpl
 and (hl)
 or d
 ld (hl),a
 inc h
color_black_1:
 pop de
 ld a,d
 and e
 ld d,a
 ld a,e
 cpl
 and (hl)
 or d
 ld (hl),a
 inc h
 jp color_fast_row_end
color_fast_row_end:
 ld a,h
color_fast_width:
 sub 0
 ld h,a
 dec l
 dec c
 jp z,color_fast_pass_end
color_fast_row_mode:
 jp color_fast_dispatch
color_fast_enemy_boundary:
 ld a,(color_white_limit)
 cp c
 jp nz,color_fast_dispatch
 ld a,h
 xor $60
 ld h,a
 jp color_fast_dispatch
color_fast_pass_end:
 ld a,(color_pass)
 or a
 jp z,color_fast_black
 jp color_restore
color_cover_table:
 dw color_cover_1,color_cover_2,color_cover_3,color_cover_4
 dw color_cover_5,color_cover_6,color_cover_7,color_cover_8
color_black_table:
 dw color_black_1,color_black_2,color_black_3,color_black_4
 dw color_black_5,color_black_6,color_black_7,color_black_8
color_pass: db 0
color_enemy: db 0
color_restore:
 ld sp,0
 ei
 ret
color_rotations:
 dw color_cover_r0,color_cover_r1,color_cover_r2,color_cover_r3
 dw color_cover_r4,color_cover_r5,color_cover_r6,color_cover_r7
color_valid: db 0
color_height: db 0
color_left: db 0
color_carry_cover: db 0
color_carry_black: db 0
color_rotated_cover: db 0
color_rotated_black: db 0

color_white_limit: db 0



WarmStart:
 ld sp,stack
 jp game_start
