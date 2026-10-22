; Сгенерировано: BATTY_LANG=en node verify/generate-mono-assets.js (из gfx/sprites_with_masks_1.asm
; и lang/en/font.asm; заголовки счёта и цифры — шрифтом языка). Руками не править.
; Формат графики Маска-Спрайт-Маска-Спрайт... По знакоместам!
; Первые две цифры - заголовок:
; 1 - ширина в байтах (без учёта маски)
; 2 - высота в пикселях

; Спрайт: надпись 1UP
; Data block at 68ED
spr_1up:
 DEFB $03,$08,$e7,$18,$c7,$38,$e7,$18,$e7,$18,$e7,$18
 DEFB $c3,$3c,$ff,$00,$ff,$00,$39,$c6,$39,$c6,$39,$c6
 DEFB $39,$c6,$01,$fe,$81,$7e,$ff,$00,$ff,$00,$03,$fc
 DEFB $39,$c6,$39,$c6,$03,$fc,$3f,$c0,$3f,$c0,$ff,$00
 DEFB $ff,$00
spr_2up:
 DEFB $03,$08,$83,$7c,$01,$fe,$39,$c6,$e3,$1c,$8f,$70
 DEFB $01,$fe,$ff,$00,$ff,$00,$39,$c6,$39,$c6,$39,$c6
 DEFB $39,$c6,$01,$fe,$81,$7e,$ff,$00,$ff,$00,$03,$fc
 DEFB $39,$c6,$39,$c6,$03,$fc,$3f,$c0,$3f,$c0,$ff,$00
 DEFB $ff,$00
spr_hi:
 DEFB $02,$08,$39,$c6,$39,$c6,$01,$fe,$01,$fe,$39,$c6
 DEFB $39,$c6,$ff,$00,$ff,$00,$cf,$30,$cf,$30,$cf,$30
 DEFB $cf,$30,$cf,$30,$cf,$30,$ff,$00,$ff,$00
spr_score_digits:
 DEFB $0a,$08,$ff,$83,$ff,$19,$ff,$2d,$ff,$35,$ff,$19
 DEFB $ff,$83,$ff,$ff,$ff,$ff,$ff,$e7,$ff,$c7,$ff,$e7
 DEFB $ff,$e7,$ff,$e7,$ff,$c3,$ff,$ff,$ff,$ff,$ff,$83
 DEFB $ff,$01,$ff,$39,$ff,$e3,$ff,$8f,$ff,$01,$ff,$ff
 DEFB $ff,$ff,$ff,$83,$ff,$39,$ff,$e1,$ff,$e1,$ff,$39
 DEFB $ff,$83,$ff,$ff,$ff,$ff,$ff,$f3,$ff,$e3,$ff,$cb
 DEFB $ff,$9b,$ff,$01,$ff,$fb,$ff,$ff,$ff,$ff,$ff,$01
 DEFB $ff,$3f,$ff,$03,$ff,$f9,$ff,$39,$ff,$83,$ff,$ff
 DEFB $ff,$ff,$ff,$f1,$ff,$c7,$ff,$93,$ff,$39,$ff,$39
 DEFB $ff,$83,$ff,$ff,$ff,$ff,$ff,$01,$ff,$01,$ff,$f3
 DEFB $ff,$f3,$ff,$e7,$ff,$e7,$ff,$ff,$ff,$ff,$ff,$83
 DEFB $ff,$39,$ff,$83,$ff,$39,$ff,$39,$ff,$83,$ff,$ff
 DEFB $ff,$ff,$ff,$83,$ff,$39,$ff,$39,$ff,$81,$ff,$f9
 DEFB $ff,$f9,$ff,$ff,$ff,$ff
