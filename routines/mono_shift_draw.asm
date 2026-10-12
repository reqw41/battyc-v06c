mdp_normal:
 ld a,(MonoOwner)
 add a,low MonoShifts
 ld l,a
 ld h,high MonoShifts
 ld a,(hl)
 ld (direct_shift),a
 ld b,a
 ld hl,(MonoDrawSource)
 ld (direct_source),hl
 ld a,(MonoDrawRows)
 ld (direct_rows),a
 ld a,(MonoFastDraw)
 or a
 jp z,mdp_cache
 jp MonoDrawWhite
mdp_cache:
 ld hl,MonoObjects
 ld a,(MonoOwner)
 add a,a
 call hl_add_a
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (IXobj),hl
 call MonoCachePrepare
 ld hl,(direct_source)
 ld (MonoDrawSource),hl
 ex de,hl
 ld hl,(MonoPtr)
 ld bc,4
 add hl,bc
 ld (hl),e
 inc hl
 ld (hl),d
 jp MonoDraw

MonoShiftDraw:
 ld a,(MonoFastDraw)
 or a
 ld a,0
 jp nz,msd_merge_ready
 ld a,$b6
msd_merge_ready:
 ld (msd_merge),a
 ld (msd_last_merge),a
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
 cpl
 ld (msd_spill+1),a
 ld hl,(MonoDrawSource)
 dec hl
 ld a,(hl)
 ld b,a
 ld a,(MonoDrawRows)
 ld (msd_height+1),a
 ld c,a
 ld a,b
 sub c
 add a,a
 ld (msd_source_skip+1),a
 dec hl
 ld a,(hl)
 ld (MonoNativeCols),a
 ld hl,MonoScratch
 ld b,c
 xor a
msd_clear:
 ld (hl),a
 inc hl
 dec b
 jp nz,msd_clear
 ld hl,0
 add hl,sp
 ld (mono_draw_restore+1),hl
 ld hl,(MonoDrawSource)
 di
 ld sp,hl
 ld hl,(MonoDrawVideo)
msd_column:
 ld bc,MonoScratch
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
 ld a,(bc)
 or e
msd_merge:
 nop
 ld (hl),a
 ld a,d
msd_spill:
 and 0
 ld (bc),a
 inc c
 dec l
 ld a,c
msd_height:
 cp 0
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
 jp z,msd_last_column
 ld (MonoDrawVideo),hl
 ld hl,0
 add hl,sp
msd_source_skip:
 ld de,0
 add hl,de
 ld sp,hl
 ld hl,(MonoDrawVideo)
 jp msd_column
msd_last_column:
 ld bc,MonoScratch
 ld a,(MonoDrawRows)
 ld d,a
msd_last_row:
 ld a,(bc)
msd_last_merge:
 nop
 ld (hl),a
 inc c
 dec l
 dec d
 jp nz,msd_last_row
 jp mono_draw_restore
MonoDrawRotations: dw msd_r0,msd_r1,msd_r2,msd_r3,msd_r4,msd_r5,msd_r6,msd_r7

 ASSERT high MonoShifts == high (MonoShifts+10)
