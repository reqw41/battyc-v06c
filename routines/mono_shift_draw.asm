; Read native pairs with POP and merge each lead/spill directly into video.
; Every write keeps a chosen part of the screen byte: all of it when the
; sprite is ORed in, or, when it replaces its own old picture, exactly the
; half that the neighbouring source column owns. A destination byte thus goes
; from the old picture to the new one without an empty moment.
MonoShiftDraw:
 ld a,(direct_shift)
 add a,a
 ld hl,MonoDrawRotations
 call hl_add_a
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (msd_rotate+1),hl
 ld hl,SpriteShiftMasks
 ld a,(direct_shift)
 call hl_add_a
 ld a,(hl)
 ld (msd_lead+1),a
 ld b,a
 cpl
 ld (msd_spill+1),a
 ld c,a
 ld a,(MonoStoreOp)
 or a
 jp z,msd_store
 ld bc,$ffff ; OR: keep the whole byte
 ld a,b
 jp msd_keep
msd_store:
 xor a ; the first column owns its whole byte
msd_keep:
 ld (msd_lead_keep+1),a
 ld a,b
 ld (msd_spill_keep+1),a ; spill keeps the lead part of the next column
 ld (msd_spill_normal+1),a
 ld a,c
 ld (msd_lead_later+1),a ; later leads keep the spill already written
 ld a,$24 ; INC H
 ld (msd_spill_inc),a
 inc a ; DEC H
 ld (msd_spill_dec),a
 ld hl,(MonoDrawSource)
 dec hl
 ld a,(MonoDrawRows)
 ld c,a
 ld a,(hl)
 sub c
 add a,a
 ld (msd_source_skip+1),a
 dec hl
 ld a,(hl)
 ld (MonoNativeCols),a
 ld hl,0
 add hl,sp
 ld (mono_draw_restore+1),hl
 ld hl,(MonoDrawSource)
 di
 ld sp,hl
 ld hl,(MonoDrawVideo)
msd_column:
 ld a,(MonoDrawCols)
 cp 1
 jp nz,msd_column_ready
 ; The last visible byte may not spill into the following RGB plane.
 ; Keep the second OR on the same byte, with a zero mask.
 xor a
 ld (msd_spill+1),a
 ld (msd_spill_inc),a
 ld (msd_spill_dec),a
 dec a
 ld (msd_spill_keep+1),a ; second write lands on the same byte: keep it
 jp msd_column_go
msd_column_ready:
 ; The spill of the last source column has no later lead: it owns its byte.
 ld a,(MonoNativeCols)
 dec a
 jp nz,msd_column_go
 ld a,(MonoStoreOp)
 ld (msd_spill_keep+1),a
 or a
 jp z,msd_column_go
 ld a,$ff
 ld (msd_spill_keep+1),a
msd_column_go:
 ld a,(MonoDrawRows)
 ld c,a
msd_row:
 pop de
 ld a,d
msd_rotate:
 jp msd_r0
msd_r7: rrca
msd_r6: rrca
msd_r5: rrca
msd_r4: rrca
msd_r3: rrca
msd_r2: rrca
msd_r1: rrca
msd_r0:
 ld d,a
msd_lead:
 and $ff
 ld e,a
 ld a,(hl)
msd_lead_keep:
 and $ff
 or e
 ld (hl),a
msd_spill_inc:
 inc h
 ld a,d
msd_spill:
 and 0
 ld e,a
 ld a,(hl)
msd_spill_keep:
 and $ff
 or e
 ld (hl),a
msd_spill_dec:
 dec h
 dec l
 dec c
 jp nz,msd_row
 ld a,(MonoDrawRows)
 add a,l
 ld l,a
 inc h
 ld a,(MonoDrawCols)
 dec a
 ld (MonoDrawCols),a
 jp z,mono_draw_restore
 ld a,(MonoNativeCols)
 dec a
 ld (MonoNativeCols),a
 jp z,mono_draw_restore
 ld (MonoDrawVideo),hl
msd_lead_later:
 ld a,0 ; the lead of every later column meets the previous spill
 ld (msd_lead_keep+1),a
msd_spill_normal:
 ld a,0
 ld (msd_spill_keep+1),a
 ld hl,0
 add hl,sp
msd_source_skip:
 ld de,0
 add hl,de
 ld sp,hl
 ld hl,(MonoDrawVideo)
 jp msd_column
MonoDrawRotations: dw msd_r0,msd_r1,msd_r2,msd_r3,msd_r4,msd_r5,msd_r6,msd_r7
 ASSERT high MonoShifts == high (MonoShifts+10)
