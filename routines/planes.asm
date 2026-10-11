; Four video planes: A/C background, E/8000 sprites.
; No shadow bitmap and no expanded RAM.
; Static shadow is retained; dynamic sprites do not write to it.
planes_reset:
 xor a
 ld (BorderColor),a
 ld hl,0
 add hl,sp
 ld (pr_restore+1),hl
 ld de,0
 di
 xor a
 out ($10),a
 ld hl,$a000
 ld sp,hl
 ld b,0
 ld c,4
pr_f:
 DUP 4
 push de
 EDUP
 dec b
 jp nz,pr_f
 dec c
 jp nz,pr_f
 ld hl,$c000
 ld sp,hl
 ld b,0
 ld c,4
pr_a:
 DUP 4
 push de
 EDUP
 dec b
 jp nz,pr_a
 dec c
 jp nz,pr_a
 ld hl,$e000
 ld sp,hl
 ld b,0
 ld c,4
pr_c:
 DUP 4
 push de
 EDUP
 dec b
 jp nz,pr_c
 dec c
 jp nz,pr_c
 ld hl,0
 ld sp,hl
 ld b,0
 ld c,4
pr_e:
 DUP 4
 push de
 EDUP
 dec b
 jp nz,pr_e
 dec c
 jp nz,pr_e
pr_restore:
 ld sp,0
 ei
pr_slots:
 ld hl,NativeAttrs
 ld bc,NativeAttrBytes
 ld a,$d0
pr_attrs:
 ld (hl),a
 inc hl
 dec bc
 ld a,b
 or c
 ld a,$d0
 jp nz,pr_attrs
 xor a
 ld (OverlayActive),a
 ld hl,plane_old
 ld b,44
 xor a
pr_sl:
 ld (hl),a
 inc hl
 dec b
 jp nz,pr_sl
 call RCReset
 jp SpriteCacheReset

; HL shadow source, DE C-plane destination, A bitmap. Preserve pointers/counts.
background_write:
 call background_select
 ; caller has stored bitmap in background_pixel
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
 ld l,a
 ld h,0
 ld bc,background_colors
 add hl,bc
 ld a,(hl)
 ld (background_color),a
 pop de
 pop bc
 pop hl
 ret
background_write_selected:
 xor a
 out ($10),a
 ld a,(background_color)
 and 1
 ld a,0
 jp z,bw_c
 ld a,(background_pixel)
bw_c:
 ld (de),a
 ld a,d
 sub $20
 ld d,a
 ld a,(background_color)
 and 2
 ld a,0
 jp z,bw_a
 ld a,(background_pixel)
bw_a:
 ld (de),a
 ld a,d
 add a,$20
 ld d,a
 ret
background_color: db 0
background_pixel: db 0
background_colors: db 3,3,2,3,3,3,2,3,2,2,2,2,2,1,2,2

; Clear ordinary footprints. Enemy/bonus rectangles are replaced by RCFlush.
planes_begin:
 call RCBoundary
 ld hl,plane_old
 ld (plane_slot),hl
 ld b,11
pb_loop:
 push bc
 ld hl,(plane_slot)
 ld d,(hl)
 inc hl
 ld e,(hl)
 inc hl
 ld b,(hl)
 ld (hl),0
 inc hl
 ld c,(hl)
 inc hl
 ld (plane_slot),hl
 ld a,b
 or a
 call nz,FastEraseOld
 pop bc
 dec b
 jp nz,pb_loop
 ld hl,plane_old
 ld (plane_slot),hl
 ret
FastErasePlain:
 ld hl,0
 add hl,sp
 ld (fr_restore+1),hl
 ld a,(ClearRows)
 or a
 rra
 ld e,a
 ld a,fr_words_end%256
 sub e
 ld l,a
 ld a,fr_words_end/256
 sbc a,0
 ld h,a
 ld (fr_dispatch+1),hl
 xor a
 ld (ClearPass),a
 ld bc,0
 di
fr_pass:
 ld hl,(ClearDst)
 ld a,(ClearPass)
 or a
 jp z,fr_position
 ld a,h
 sub $60
 ld h,a
fr_position:
 ld a,(ClearColumns)
 ld (fr_columns_left),a
fr_column:
 ld a,(ClearDst)
 ld l,a
 ld a,(ClearRows)
 or a
 rra
 jp nc,fr_even
 xor a
 ld (hl),a
 jp fr_stack
fr_even:
 inc l
fr_stack:
 ld sp,hl
fr_dispatch:
 jp fr_words_end
 DUP 32
 push bc
 EDUP
fr_words_end:
 inc h
 ld a,(fr_columns_left)
 dec a
 ld (fr_columns_left),a
 jp nz,fr_column
 ld a,(ClearPass)
 inc a
 ld (ClearPass),a
 cp 2
 jp c,fr_pass
fr_restore:
 ld sp,0
 ei
 ret
fr_columns_left: db 0

 INCLUDE "./routines/direct_sprites.asm"
 INCLUDE "./routines/color_sprites.asm"

; Persistent life icons use the original sprite mask in E/F. Do not register
; their footprints in the moving-object erase list.
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

; Input HL=C-plane address, A=pixel. Keeps the animation source/counts.
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
