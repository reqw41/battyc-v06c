; Arrow and caption over the menu control pointer: PRESS A / PRESS B
spr_press_a:
  DEFB $04,$0D,$00,$00,$80,$00,$00,$01
  DEFB $C0,$00,$00,$03,$E0,$00,$00,$01
  DEFB $C0,$00,$00,$01,$C0,$00,$00,$01
  DEFB $C0,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$08,$AE,$EE,$28,$08,$A8
  DEFB $22,$28,$0E,$CE,$EE,$38,$0A,$A8
  DEFB $88,$28,$0E,$EE,$EE,$38

spr_press_b:
  DEFB $04,$0D,$00,$00,$80,$00,$00,$01
  DEFB $C0,$00,$00,$03,$E0,$00,$00,$01
  DEFB $C0,$00,$00,$01,$C0,$00,$00,$01
  DEFB $C0,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$08,$AE,$EE,$38,$08,$A8
  DEFB $22,$28,$0E,$CE,$EE,$38,$0A,$A8
  DEFB $88,$28,$0E,$EE,$EE,$38
