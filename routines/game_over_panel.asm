; Dark level paper behind both loss-message lines: X=64..199, Y=64..112.
; It is drawn once after removing moving objects; keep the rest of the field.
DrawGameOverPanel:
 ld hl,$c8a0
 ld b,17
GameOverPanelColumn:
 ld c,49
GameOverPanelRow:
 xor a
 ld (hl),a
 push hl
 ld a,h
 sub $20
 ld h,a
 xor a
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 xor a
 ld (hl),a
 ld a,h
 add $60
 ld h,a
 ld a,$ff
 ld (hl),a
 pop hl
 dec l
 dec c
 jp nz,GameOverPanelRow
 ld l,$a0
 inc h
 dec b
 jp nz,GameOverPanelColumn
 ret
