MonoIncludeRegion:
 ld c,(hl)
 inc hl
 ld b,(hl)
 inc hl
 ld a,(hl)
 or a
 ret z
 add a,b
 ld d,a
 inc hl
 ld a,c
 sub (hl)
 inc a
 ld e,a
 ld hl,(MonoRegionPtr)
 ld a,b
 cp (hl)
 jp nc,mir_right
 ld (hl),a
mir_right:
 inc hl
 ld a,(hl)
 cp d
 jp nc,mir_top
 ld (hl),d
mir_top:
 inc hl
 ld a,(hl)
 cp c
 jp nc,mir_bottom
 ld (hl),c
mir_bottom:
 inc hl
 ld a,e
 cp (hl)
 ret nc
 ld (hl),a
 ret
