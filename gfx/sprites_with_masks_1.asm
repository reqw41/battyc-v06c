; Формат графики Маска-Спрайт-Маска-Спрайт... По знакоместам!
; Первые две цифры - заголовок:
; 1 - ширина в байтах (без учёта маски)
; 2 - высота в пикселях

; Спрайт: надпись 1UP
; Data block at 68ED
spr_1up:
  DEFB $03,$08,$3C,$3C,$FE,$FE,$FC,$FC
  DEFB $7C,$64,$FE,$92,$FF,$83,$7C,$44
  DEFB $FE,$92,$FF,$99,$7C,$64,$FE,$92
  DEFB $FF,$99,$3C,$24,$FE,$92,$FF,$83
  DEFB $7E,$66,$FE,$82,$FE,$9E,$7E,$42
  DEFB $FE,$C6,$F0,$90,$7E,$7E,$7C,$7C
  DEFB $F0,$F0

; Спрайт: надпись 2UP
; Data block at 691F
spr_2up:
  DEFB $03,$08,$7C,$7C,$FE,$FE,$FE,$FE
  DEFB $FE,$C6,$FE,$92,$FF,$83,$FE,$82
  DEFB $FE,$92,$FF,$99,$FE,$92,$FE,$92
  DEFB $FF,$99,$FE,$E6,$FE,$92,$FF,$83
  DEFB $FE,$CE,$FE,$82,$FE,$9E,$FE,$82
  DEFB $FE,$C6,$F0,$90,$FE,$FE,$7C,$7C
  DEFB $F0,$F0

; Спрайт: надпись HI
; Data block at 6951
spr_hi:
  DEFB $02,$08,$7F,$7F,$BC,$BC,$7F,$4C
  DEFB $BC,$A4,$7F,$4C,$BC,$A4,$7F,$40
  DEFB $BC,$A4,$7F,$40,$BC,$A4,$7F,$4C
  DEFB $BC,$A4,$7F,$4C,$BC,$A4,$7F,$7F
  DEFB $BC,$BC

; Спрайт: цифры для отображения очков
; Data block at 6973
spr_score_digits:
  DEFB $0A,$08,$7C,$00,$FE,$38,$FE,$6C
  DEFB $FE,$6C,$FE,$6C,$FE,$6C,$FE,$38
  DEFB $7C,$00,$3C,$00,$7C,$18,$7C,$38
  DEFB $7C,$18,$3C,$18,$7E,$18,$7E,$3C
  DEFB $7E,$00,$7C,$00,$FE,$38,$FE,$7C
  DEFB $FE,$6C,$FE,$18,$FE,$30,$FE,$7C
  DEFB $FE,$00,$7C,$00,$FE,$38,$FE,$6C
  DEFB $FE,$18,$FE,$18,$FE,$6C,$FE,$38
  DEFB $7C,$00,$3C,$00,$7C,$18,$7C,$38
  DEFB $FC,$28,$FE,$68,$FE,$7C,$FE,$18
  DEFB $3C,$00,$FE,$00,$FE,$7C,$FE,$60
  DEFB $FE,$78,$FE,$0C,$FE,$6C,$FE,$38
  DEFB $7C,$00,$3C,$00,$7C,$18,$FC,$30
  DEFB $FE,$78,$FE,$6C,$FE,$6C,$FE,$38
  DEFB $7C,$00,$FE,$00,$FE,$7C,$FE,$7C
  DEFB $FE,$18,$7C,$38,$7C,$30,$78,$30
  DEFB $78,$00,$7C,$00,$FE,$38,$FE,$6C
  DEFB $FE,$38,$FE,$6C,$FE,$6C,$FE,$38
  DEFB $7C,$00,$7C,$00,$FE,$38,$FE,$6C
  DEFB $FE,$6C,$FE,$3C,$7E,$18,$7C,$30
  DEFB $78,$00
