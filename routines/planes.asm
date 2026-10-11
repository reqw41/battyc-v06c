; A/C/E = eight background colours; 8000 = white overlay.
planes_reset:
 xor a
 ld (BorderColor),a
 ld hl,0
 add hl,sp
 ld (pr_restore+1),hl
 ld de,0
 di
 out ($10),a
 ld hl,0
 ld sp,hl
 ld b,0
 ld c,16
pr_fill:
 DUP 4
 push de
 EDUP
 dec b
 jp nz,pr_fill
 dec c
 jp nz,pr_fill
pr_restore:
 ld sp,0
 ei
 ld hl,NativeAttrs
 ld bc,NativeAttrBytes
pr_attrs:
 ld a,$d0
 ld (hl),a
 inc hl
 dec bc
 ld a,b
 or c
 jp nz,pr_attrs
 xor a
 ld (OverlayActive),a
 jp MonoReset
background_write:
 call background_select
 jp background_write_selected
background_select:
 push hl
 push bc
 push de
 ld a,l
 rrca
 rrca
 rrca
 and $1f
 or $c0
 ld l,a
 call NativeAttrAddress
 ld a,(hl)
 rrca
 rrca
 rrca
 rrca
 and $0f
 ld hl,background_colors
 call hl_add_a
 ld a,(hl)
 ld (background_color),a
 pop de
 pop bc
 pop hl
 ret
background_write_selected:
 push bc
 push de
 ld a,(background_pixel)
 ld c,a
 ld a,e
 cp $39
 jp nc,bw_field
 ld c,0 ; solid E-only paper under the paddle, logical Y >=168
bw_field:
 ld a,(background_color)
 and 2
 ld a,0
 jp z,bw_c
 ld a,c
bw_c:
 ld (de),a
 ld a,d
 sub $20
 ld d,a
 ld a,(background_color)
 and 4
 ld a,0
 jp z,bw_a
 ld a,c
bw_a:
 ld (de),a
 ld a,d
 add a,$40
 ld d,a
 ; Paper index 1. Odd ink sets E too; even ink clears it.
 ld a,(background_color)
 and 1
 ld a,$ff
 jp nz,bw_e
 ld a,c
 cpl
bw_e:
 ld (de),a
 pop de
 pop bc
 ret
background_color: db 0
background_pixel: db 0
background_colors: db 6,4,5,6,7,4,5,6,7,4,5,6,7,2,6,7
planes_begin:
 ld hl,plane_old
 ld (plane_slot),hl
 ret
FastErasePlain:
 ld hl,(ClearDst)
 ld a,h
 cp $e0
 jp c,fep_ready
 sub $60
 ld h,a
fep_ready:
 ld a,(ClearColumns)
 ld b,a
fep_col:
 push hl
 ld a,(ClearRows)
 ld c,a
fep_row:
 xor a
 ld (hl),a
 dec l
 dec c
 jp nz,fep_row
 pop hl
 inc h
 dec b
 jp nz,fep_col
 ret
plane_erase_dual:
 ld a,c
 or a
 ret z
 ld (ClearRows),a
 ld a,b
 ld (ClearColumns),a
 ex de,hl
 ld (ClearDst),hl
 jp FastErasePlain
 INCLUDE "routines/direct_sprites.asm"
plane_static_object:
 ld hl,(plane_slot)
 push hl
 ld hl,plane_static_slot
 ld (plane_slot),hl
 ld a,$fe
 ld (pd_visible_limit+1),a
 ld (pd_height_limit+1),a
 inc a
 ld (pd_height_compare+1),a
 call plane_object
 ld a,$c0
 ld (pd_visible_limit+1),a
 ld (pd_height_limit+1),a
 inc a
 ld (pd_height_compare+1),a
 pop hl
 ld (plane_slot),hl
 ret
plane_static_slot: ds 4,0
plane_object:
 xor a
 ld (color_valid),a
 call plane_object_fast
 ld a,(color_valid)
 or a
 ret z
 ld a,11
 ld (MonoOwner),a
 call MonoCachePrepare
 ld hl,(direct_source)
 ld (MonoDrawSource),hl
 ld hl,(plane_dst)
 ld (MonoDrawVideo),hl
 ld a,(direct_columns)
 ld (MonoDrawCols),a
 ld a,(direct_rows)
 ld (MonoDrawRows),a
 xor a
 ld (MonoDrawBat),a
 jp MonoDraw
color_valid: db 0
color_height: db 0
color_enemy: db 0
WarmStart:
 ld sp,stack
 jp game_start
 INCLUDE "routines/mono_cache.asm"

plane_screen_write:
 ld (background_pixel),a
 push hl
 push de
 push bc
 ex de,hl
 ld a,d
 sub $c0
 add a,scr_buff/256
 ld h,a
 ld a,$e0
 sub e
 ld l,a
 ld a,(background_pixel)
 call background_write
 pop bc
 pop de
 pop hl
 ret
