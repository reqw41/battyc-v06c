; Static graphics use native pairs too. Build shifted columns once, then
; program the three colour masks once per attribute block and POP rows.
NativeStaticColumns:
 ld a,(NativeHeight)
 ld (SpriteCacheHeight),a
 ld (nsc_height+1),a
 ld a,(NativeShift)
 ld (SpriteCacheShift),a
 ld hl,(NativeSource)
 dec hl
 dec hl
 ld (SpriteCacheOriginal),hl
 ld a,(spr_magnet_circle_on+1)
 ld (nsc_header+1),a
 ld hl,spr_magnet_circle_on+1
 ld (hl),30 ; column pitch remains 30 when the animated height is 23
 ld hl,$7a00
 ld (SpriteCacheBuffer),hl
 call SpriteCacheBuild
nsc_header:
 ld a,23
 ld (spr_magnet_circle_on+1),a
nsc_cache_ready:
 ld a,($7a00)
 ld (NativeLeft),a
 ld hl,$7a02
 ld (NativeSource),hl
 ld hl,(NativeDest)
 ld a,l
 ld (nsc_top+1),a
nsc_column:
nsc_height:
 ld a,0
 ld (NativeHeight),a
nsc_block:
 ld hl,(NativeDest)
 call background_select
 call NativeStaticMasks
 ld a,l
 and 7
 ld b,a
 ld a,8
 sub b
 ld b,a
 ld a,(NativeHeight)
 cp b
 jp nc,nsc_rows
 ld b,a
nsc_rows:
 sub b
 ld (NativeHeight),a
 ld a,b
 ld (nsc_rows_done+1),a
 ld c,a
 add a,l
 ld l,a
 ld (NativeDest),hl
 ld hl,0
 add hl,sp
 ld (nsc_restore+1),hl
 ld hl,(NativeSource)
 di
 ld sp,hl
 ld hl,(NativeDest)
 ld a,h
 add a,$30
 ld h,a ; A plane
 ld a,l
nsc_rows_done:
 sub 0
 ld b,a
 ld a,$e0
 sub b
 ld l,a
nsc_row:
 pop de
 ld a,(hl)
 ld b,a
 ld a,h
 add a,$20
 ld h,a
 ld a,(hl)
 or b
 and e
 or d
 ld d,a
nsc_c:
 and 0
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ld a,d
nsc_a:
 and 0
 ld (hl),a
 ld a,h
 add a,$40
 ld h,a
 ld a,d
 cpl
nsc_e:
 or 0
 ld (hl),a
 ld a,h
 sub $40
 ld h,a
 dec l
 dec c
 jp nz,nsc_row
 ld hl,0
 add hl,sp
 ld (NativeSource),hl
nsc_restore:
 ld sp,0
 ei
 ld a,(NativeHeight)
 or a
 jp nz,nsc_block
 ld hl,(NativeDest)
nsc_top:
 ld l,0
 inc h
 ld (NativeDest),hl
 ld hl,NativeLeft
 dec (hl)
 jp nz,nsc_column
 jp SpriteCacheReset
