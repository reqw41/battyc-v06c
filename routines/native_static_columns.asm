; The only static picture left in the RGB planes is the Double Play
; separator (magnets have their own cache, HUD and lives use the sprite
; plane). Build its shifted columns once, then POP rows: lit pixels become
; yellow (A+C), covered unlit pixels paper (E), the rest is left alone.
NativeStaticColumns:
 xor a
 ld hl,MonoTags+44
 ld (hl),a
 inc hl
 ld (hl),a
 ld a,(NativeHeight)
 ld (SpriteCacheHeight),a
 ld (nsc_height+1),a
 ld a,(NativeShift)
 ld (SpriteCacheShift),a
 ld hl,(NativeSource)
 dec hl
 dec hl
 ld (SpriteCacheOriginal),hl
 ld hl,$7ed0
 ld (SpriteCacheBuffer),hl
 call SpriteCacheBuild
nsc_cache_ready:
 ld a,($7ed0)
 ld (NativeLeft),a
 ld hl,$7ed2
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
 pop de ; E=~cover, D=lit
 ld a,(hl)
 and e
 or d
 ld (hl),a ; A: lit
 ld a,h
 add a,$20
 ld h,a
 ld a,(hl)
 and e
 or d
 ld (hl),a ; C: lit
 ld a,h
 add a,$20
 ld h,a
 ld a,(hl)
 and e ; cleared under the cover...
 ld b,a
 ld a,e
 or d
 cpl ; ...and set where it is covered but not lit
 or b
 ld (hl),a ; E
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
