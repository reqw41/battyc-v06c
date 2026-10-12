; Magnet picture cache: one 304-byte slot per magnet at 7a00..7ebf.
; 4x24 cells (the disc is 25x24), column-major, three bytes each:
;   P1 = grey ring + cyan body of the on picture (its planes C and E),
;   P2 = cyan body + red arrows and core of the on picture (its plane A),
;   marks-off = grey marks of the off picture (plane C);
; then 2x8 bytes of the ball in the middle. A last pass recolours it:
; plane C is set over the ball (on: red -> yellow; off, with plane A: cyan),
; then planes A and C are cleared in a small glint (on: white, off: paper).
; The disc is P1|P2, the ring is P1&~P2.
;   on  = grey ring (C+E), cyan body (A+C+E), red arrows (A), yellow core;
;   off = grey ring and marks (C+E) on paper (E), cyan ball (A+C+E).
; The slot is rebuilt whenever the round window returns this RAM.
MagRows EQU 24
MagCacheSlots: dw $7a00,$7b30,$7c60,$7d90
 ASSERT $7d90+304 <= $7ec8
MagCacheMeta: ds 8,0 ; plane A column, top row
MagnetCoreOff: db $1c,$3e,$7f,$7f,$7f,$7f,$3e,$1c ; the ball, rows 8..15
MagnetGlintOn: db $00,$08,$1c,$1c,$08 ; rows 9..13: white centre of the yellow core
MagnetGlintOff: db $18,$30,$20,$20,$00 ; glint of the cyan ball
MCIndex: db 0
MCBase: dw 0

MagCacheBuildAll:
 xor a
mcb_all:
 ld hl,magnets_quantity
 cp (hl)
 ret nc
 ld (MCIndex),a
 call MagCacheBuildOne
 ld a,(MCIndex)
 inc a
 jp mcb_all

MagCacheBuildOne:
 ld a,(MCIndex)
 add a,a
 ld c,a
 ld hl,MagCacheSlots
 call hl_add_a
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (MCBase),hl
 ld a,c
 ld hl,MagCacheMeta
 call hl_add_a
 ex de,hl
 ld a,c
 add a,a
 add a,a
 add a,a
 ld hl,magnet_properties+2
 call hl_add_a
 ld a,(hl)
 sub 5
 ld b,a
 and 7
 ld (NativeShift),a
 ld a,b
 rrca
 rrca
 rrca
 and 31
 or $a0
 ld (de),a
 inc de
 inc hl
 inc hl
 ld a,229
 sub (hl)
 ld (de),a
 ld hl,(MCBase)
 ex de,hl
 push de
 ld hl,spr_magnet_circle_on+2
 ld bc,$2f3c ; cpl, 30-row column: ring + body
 call mcb_pass
 pop de
 inc de
 push de
 ld hl,spr_magnet_circle_on+3
 ld bc,$003c ; body
 call mcb_pass
 pop de
 inc de
 push de
 ld hl,spr_magnet_circle_off+2
 ld bc,$2f00+MagRows*2 ; cpl, off-sprite column: the disc
 call mcb_pass
 ; P2 = body | (disc & ~P1): the red part is the disc outside ring and body
 ld hl,(MCBase)
 ld b,MagRows*4
mcb_red:
 ld a,(hl)
 cpl
 inc hl
 inc hl
 and (hl)
 dec hl
 or (hl)
 ld (hl),a
 inc hl
 inc hl
 dec b
 jp nz,mcb_red
 pop de
 ld hl,spr_magnet_circle_off+3
 ld bc,MagRows*2 ; nop
 call mcb_pass
 ld de,MagnetCoreOff
 ld hl,(MCBase)
 ld bc,MagRows*12
 add hl,bc
 ld b,8
mcb_core_off:
 push bc
 call mcb_core_byte
 ld (hl),a
 push hl
 ld a,8
 call hl_add_a
 ld (hl),c
 pop hl
 inc hl
 pop bc
 dec b
 jp nz,mcb_core_off
 ret
mcb_core_byte:
 ld a,(de)
 inc de
 jp NativeSampleShift ; keeps DE and HL

; HL=source byte of column 0, DE=first cache byte, C=source column stride,
; B=opcode applied to the source byte before the shift (cpl or nop).
mcb_pass:
 ld a,b
 ld (mcb_inv1),a
 ld (mcb_inv2),a
 ld a,c
 ld (mcb_stride+1),a
 xor a
mcb_col:
 ld (mcb_colno+1),a
 ld a,MagRows
mcb_row:
 push af
 push de
 ld a,(hl)
mcb_inv1:
 nop
 call NativeSampleShift
 ld d,a
mcb_colno:
 ld a,0
 or a
 jp z,mcb_store
 push hl
mcb_stride:
 ld a,0
 cpl
 inc a
 add a,l
 ld l,a
 jp c,mcb_previous
 dec h
mcb_previous:
 ld a,(hl)
mcb_inv2:
 nop
 call NativeSampleShift
 ld a,c
 or d
 ld d,a
 pop hl
mcb_store:
 ld a,d
 pop de
 ld (de),a
 inc de
 inc de
 inc de
 inc hl
 inc hl
 pop af
 dec a
 jp nz,mcb_row
 ld a,(mcb_stride+1)
 sub MagRows*2
 call hl_add_a
 ld a,(mcb_colno+1)
 inc a
 cp 4
 jp nz,mcb_col
 ret

; Repaint the rows of every marked magnet that the restored brick can touch.
MagnetRepaintMarked:
 ld a,(NativeRestoreMagnetCount)
 or a
 ret z
 xor a
mrm_magnet:
 ld (MCIndex),a
 ld hl,MagnetRedrawFlags
 call hl_add_a
 ld a,(hl)
 or a
 jp z,mrm_next
 ld (hl),0
 ld a,(MCIndex)
 add a,a
 ld hl,MagCacheMeta+1
 call hl_add_a
 ld a,(NativeRestoreOrigin+1)
 add a,(hl)
 sub 225 ; first touched magnet row, may be negative
 ld b,a
 ld c,10
 jp p,mrm_bottom
 add a,c
 ld c,a
 ld b,0
mrm_bottom:
 ld a,b
 add a,c
 cp MagRows+1
 jp c,mrm_paint
 ld a,MagRows
 sub b
 ld c,a
mrm_paint:
 ld a,(MCIndex)
 call MagnetPaint
mrm_next:
 ld a,(MCIndex)
 inc a
 cp 4
 jp nz,mrm_magnet
 ret

; A=magnet. Paint its current state from the cache: all rows, or C rows
; starting at row B. Pixels outside the cover are left alone. The cache
; column is read through SP, so interrupts are held off for one column.
MagnetPaintFull:
 ld bc,MagRows
MagnetPaint:
 ld (MCIndex),a
 ld a,(SUWindowValid)
 or a
 ret nz ; the round window holds the cache RAM
 ld a,b
 ld (mp_first+1),a
 add a,c
 ld (mp_last+1),a
 ld a,(MCIndex)
 rlca
 rlca
 rlca
 rlca
 ld hl,magnet_properties+1
 call hl_add_a
 ld a,(hl)
 and 1
 ld (mp_off+1),a
 ld hl,mp_on_row
 jp z,mp_state
 ld hl,mp_off_row
mp_state:
 ld (mp_enter+1),hl
 ld a,(MCIndex)
 add a,a
 ld c,a
 ld hl,MagCacheMeta
 call hl_add_a
 ld d,(hl)
 inc hl
 ld b,(hl)
 ld a,b
mp_first:
 sub 0
 ld e,a
 ld a,b
mp_last:
 sub 0
 ld (mp_on_end+1),a
 ld (mp_off_end+1),a
 ld a,c
 ld hl,MagCacheSlots
 call hl_add_a
 ld a,(hl)
 inc hl
 ld h,(hl)
 ld l,a
 ld (MCBase),hl
 ld a,(mp_first+1)
 ld c,a
 add a,a
 add a,c
 call hl_add_a
 ex de,hl
 ld (mp_video+1),hl
 ld hl,0
 add hl,sp
 ld (mp_sp+1),hl
 ex de,hl
 ld a,4
mp_col:
 ld (mp_cols+1),a
 ld (mp_cache+1),hl
 di
 ld sp,hl
mp_video:
 ld hl,0 ; plane A
 ld e,l
 ld a,h
 add a,$20
 ld d,a ; plane C
mp_enter:
 jp mp_on_row
mp_on_row:
 pop bc ; C=P1 (ring+body), B=P2 (body+red)
 inc sp
 ld a,(hl)
 or c
 xor c
 or b
 ld (hl),a
 ld a,(de)
 or b
 xor b
 or c
 ld (de),a
 ld a,d
 add a,$20
 ld d,a
 ld a,(de)
 or b
 xor b
 or c
 ld (de),a
 ld a,d
 sub $20
 ld d,a
 dec e
 dec l
 ld a,l
mp_on_end:
 cp 0
 jp nz,mp_on_row
 jp mp_col_done
mp_off_row:
 pop bc ; C=P1, B=P2
 ld a,(hl)
 or c
 xor c
 or b
 xor b
 ld (hl),a ; A: the disc is cleared
 ld a,d
 add a,$20
 ld d,a
 ld a,(de)
 or c
 or b
 ld (de),a ; E: the whole disc
 ld a,d
 sub $20
 ld d,a
 ld a,(de)
 or c
 or b
 xor b
 pop bc ; C=marks-off
 dec sp
 or c
 ld (de),a ; C: the ring and the marks
 dec e
 dec l
 ld a,l
mp_off_end:
 cp 0
 jp nz,mp_off_row
mp_col_done:
mp_sp:
 ld sp,0
 ei
 ld hl,mp_video+2
 inc (hl)
mp_cache:
 ld hl,0
 ld bc,MagRows*3
 add hl,bc
mp_cols:
 ld a,0
 dec a
 jp nz,mp_col
mp_off:
 ld a,0
 or a
 ld a,0 ; on: plane A already holds the core (NOP)
 ld hl,MagnetGlintOn
 jp z,mp_core
 ld a,$12 ; off: LD (DE),A
 ld hl,MagnetGlintOff
mp_core:
 ld (mp_core_a),a
 ld (mp_glint+1),hl
 ld a,(MCIndex)
 add a,a
 ld hl,MagCacheMeta
 call hl_add_a
 ld d,(hl)
 inc d
 inc hl
 ld a,(hl)
 sub 8
 ld e,a
 push de
 ld hl,(MCBase)
 ld bc,MagRows*12
 add hl,bc
 ld b,2
mp_core_col:
 push de
 ld c,8
mp_core_row:
 ld a,(de)
 or (hl)
mp_core_a:
 nop
 ld a,d
 add a,$20
 ld d,a
 ld a,(de)
 or (hl)
 ld (de),a
 ld a,d
 sub $20
 ld d,a
 inc hl
 dec e
 dec c
 jp nz,mp_core_row
 pop de
 inc d
 dec b
 jp nz,mp_core_col
 pop de
 dec e
 ld a,(MCIndex)
 rlca
 rlca
 rlca
 rlca
 ld hl,magnet_properties+2
 call hl_add_a
 ld a,(hl)
 sub 5
 and 7
 ld hl,NativeShift
 ld b,(hl)
 push bc
 ld (hl),a
mp_glint:
 ld hl,0
 ld b,5
mp_glint_row:
 push bc
 ld a,(hl)
 inc hl
 call NativeSampleShift
 call mp_glint_byte
 inc d
 ld a,c
 call mp_glint_byte
 dec d
 dec e
 pop bc
 dec b
 jp nz,mp_glint_row
 pop bc
 ld a,b
 ld (NativeShift),a
 ret
mp_glint_byte: ; clear the bits of A in planes A and C
 cpl
 ld b,a
 ld a,(de)
 and b
 ld (de),a
 ld a,d
 add a,$20
 ld d,a
 ld a,(de)
 and b
 ld (de),a
 ld a,d
 sub $20
 ld d,a
 ret

PaceStartExtended:
 ld hl,RCBegin
 ld de,RCBegin
 ld a,(balls_quantity)
 cp 3
 jp z,pace_dispatch_ready
 ld a,(MonoActiveCount)
 cp 5
 jp c,pace_dispatch_ready
 ld hl,PaceAccountDraw
 ld de,PaceAccountOld
pace_dispatch_ready:
 ld (mono_pace_draw_call+1),hl
 ex de,hl
 ld (mono_pace_old_call+1),hl
 ld a,(balls_quantity)
 cp 3
 ret z
 jp PaceStartBody

