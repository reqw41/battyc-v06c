; Clear the old contour including its one-pixel margins before replacement.
; HL = C-plane baseline address, B = original character count and flags.
ClearOutlinedLine:
 push hl
 push bc
 push de
 ld a,b
 and $3f
 add a,2
 ld (ClearColumns),a
 ld a,8
 ld (ClearRows),a
 jp ClearOutlinedLinePixels
