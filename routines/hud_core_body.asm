; HUD lies above the texture. A/C remain zero; E=~core is level paper/black.
HudClearCoreBody:
 ld hl,(MonoDrawVideo)
 ld a,h
 add a,$60
 ld h,a
 ld a,(MonoDrawCols)
 ld b,a
hud_core_column:
 ld a,(MonoDrawRows)
 ld c,a
hud_core_row:
 pop de
 ld a,e
 or d
 ld (hl),a
 dec l
 dec c
 jp nz,hud_core_row
 ld a,(MonoDrawRows)
 add a,l
 ld l,a
 inc h
 dec b
 jp nz,hud_core_column
hud_core_restore:
 ld sp,0
 ei
 ret
