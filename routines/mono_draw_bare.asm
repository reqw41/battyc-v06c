; SP is already the source. Keep the invariant bat branch out of every row.
MonoDrawBare:
 ld a,(MonoDrawRows)
 ld c,a
mono_bare_row:
 pop de
 ld a,d
mono_bare_merge:
 or (hl)
 ld (hl),a
 dec l
 dec c
 jp nz,mono_bare_row
 ld a,(MonoDrawRows)
 add a,l
 ld l,a
 inc h
 dec b
 jp nz,MonoDrawBare
 jp mono_draw_restore
