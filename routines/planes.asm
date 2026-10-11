; Three shared video planes A/C/E; 8000 is hidden save-under/cache RAM.
; No shadow bitmap and no expanded RAM.
; A selects the darker background shade; dynamic sprites leave it untouched.
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
 call SUInvalidate
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
 add a,$40
 ld d,a
 xor a
 ld (de),a
 ld a,d
 sub $20
 ld d,a
 ret
background_color: db 0
background_pixel: db 0
background_colors: db 3,3,3,3,3,3,3,3,3,3,3,3,3,1,3,3

; Restore ordinary footprints in reverse order before drawing the new step.
planes_begin:
 call SUInvalidate
 ld hl,plane_old
 ld (plane_slot),hl
 ret
FastErasePlain:
 ; Only persistent HUD clearing uses this compatibility entry.
 call SUInvalidate
 ld hl,(ClearDst)
 ld a,(ClearColumns)
 ld b,a
fec_col:
 push hl
 ld a,(ClearRows)
 ld c,a
fec_row:
 xor a
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 xor a
 ld (hl),a
 ld a,h
 add a,$20
 ld h,a
 dec l
 dec c
 jp nz,fec_row
 pop hl
 inc h
 dec b
 jp nz,fec_col
 ret

 INCLUDE "./routines/direct_sprites.asm"
 INCLUDE "./routines/color_sprites.asm"

; Persistent life icons use the original sprite mask in E/F. Do not register
; their footprints in the moving-object erase list.
plane_static_object:
 ld a,1
 ld (SUStatic),a
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
 xor a
 ld (SUStatic),a
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
