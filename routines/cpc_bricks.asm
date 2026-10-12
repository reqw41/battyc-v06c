; CPC relief: white top/left, solid coloured body, one paper row/column.
; A/C/E only. Glints clear selected body pixels to white, never to paper.
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
