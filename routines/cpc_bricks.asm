; CPC relief: white top/left, solid coloured body, one paper row/column.
; A/C/E only. Glints clear selected body pixels to white, never to paper.
; NativeCpcSelectInk — по индексу цвета кирпича (background_color) заранее
; подставить маски плоскостей в операнды NativeCpcBrickByte: бит 0 -> E,
; бит 1 -> C, бит 2 -> A (00h или FFh). Делается раз на кирпич.
NativeCpcSelectInk:
 ld a,(background_color)
 rra
 sbc a,a
 ld (CpcBrickInkE+1),a
 ld a,(background_color)
 rra
 rra
 sbc a,a
 ld (CpcBrickInkC+1),a
 ld a,(background_color)
 rra
 rra
 rra
 sbc a,a
 ld (CpcBrickInkA+1),a
 ret

; Строка кирпича по номеру строки в клетке (E and 7; клетка начинается с
; младшего байта, кратного 8, и идёт вниз):
; 0 — верхняя строка: белый кант (индекс 0) и бумага в последней точке;
; 1 — нижняя строка: бумага по всей ширине;
; остальные — тело цвета кирпича; в левом столбце первая точка — белый
; кант (маска 7Fh), в правом последняя — бумага (FEh); точки блика A
; вынимаются из тела и становятся белыми. Нечётный столбец экрана —
; левый у кирпича (поле начинается со столбца C1h).
; DE — адрес в плоскости C, A — блик. Регистры, кроме AF, целы.
; DE=C video address, A=additional white glint. Preserve all other registers.
NativeCpcBrickByte:
 push bc
 push de
 cpl
 ld c,a
 ld a,e
 and 7
 ld b,0
 cp 1
 jp z,CpcBrickBottom
 or a
 jp z,CpcBrickPaper
 ld a,d
 and 1
 ld a,$fe
 jp z,CpcBrickBodyMask
 ld a,$7f
CpcBrickBodyMask:
 and c
 ld b,a
CpcBrickPaper:
 ld a,d
 and 1
 xor 1
 ld c,a
 jp CpcBrickStore
CpcBrickBottom:
 ld c,$ff
CpcBrickStore:
 ld a,b
CpcBrickInkC:
 and 0
 ld (de),a
 ld a,d
 sub $20
 ld d,a
 ld a,b
CpcBrickInkA:
 and 0
 ld (de),a
 ld a,d
 add $40
 ld d,a
 ld a,b
CpcBrickInkE:
 and 0
 or c
 ld (de),a
 pop de
 pop bc
 ret

; NativeCpcPrepareAnimation — подготовить кадр анимации попадания:
; выбрать цвет клетки и маски, а последний кадр ZX (spr_brik_1, узор)
; заменить чистым телом без блика (CpcBrickNoGlint).
; HL=C screen address, DE=legacy animation data. Select ink once per brick.
; The final patterned ZX frame becomes the clean solid body, not a pattern.
NativeCpcPrepareAnimation:
 push af
 push bc
 push hl
 push de
 call SUInvalidate
 ld a,h
 sub $c0
 add a,$70
 ld h,a
 ld a,$e0
 sub l
 ld l,a
 call background_select
 call NativeCpcSelectInk
 pop de
 ld a,d
 cp spr_brik_1/256
 jp nz,CpcBrickPrepared
 ld a,e
 cp spr_brik_1%256
 jp nz,CpcBrickPrepared
CpcBrickCleanFrame:
 ld de,CpcBrickNoGlint
CpcBrickPrepared:
 pop hl
 pop bc
 pop af
 ret

; Байт анимации: HL — адрес C, A — блик. Регистры HL и DE сохраняются.
NativeCpcScreenWrite:
 push hl
 push de
 ex de,hl
 call NativeCpcBrickByte
 pop de
 pop hl
 ret
CpcBrickNoGlint:
 DEFB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
