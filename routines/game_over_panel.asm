; Dark level paper behind both loss-message lines: X=64..191, Y=135..159.
; It is drawn once after removing moving objects; keep the rest of the field.
DrawGameOverPanel:
 ld hl,$c859
 ld b,16
GameOverPanelColumn:
 ld c,25
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
 ld l,$59
 inc h
 dec b
 jp nz,GameOverPanelColumn
 ret
