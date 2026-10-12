	; IFDEF MX

; Спрайт: кирпич, кадр 1
spr_brik_1 EQU CpcBrickNoGlint

; Спрайт: кирпич, кадр 2
spr_brik_2:
  DEFB $00,$02,$00,$02,$00,$02,$00,$02
  DEFB $00,$02,$00,$06,$00,$FE,$00,$00

; Спрайт: кирпич, кадр 3
spr_brik_3:
  DEFB $00,$02,$00,$02,$00,$06,$00,$06
  DEFB $00,$06,$00,$0E,$0F,$FE,$00,$00

; Спрайт: кирпич, кадр 4
spr_brik_4:
  DEFB $00,$02,$00,$02,$00,$06,$00,$06
  DEFB $00,$0E,$00,$3E,$FF,$FE,$00,$00

; Спрайт: кирпич, кадр 5
spr_brik_5:
  DEFB $FF,$FE,$FF,$FE,$FF,$FE,$FF,$FE
  DEFB $FF,$FE,$FF,$FE,$FF,$FE,$00,$00

; Спрайт: кирпич, кадр 6
spr_brik_6:
  DEFB $00,$02,$00,$02,$00,$02,$00,$06
  DEFB $00,$06,$00,$0E,$01,$FE,$00,$00

; Спрайт: кирпич, кадр 7
spr_brik_7:
  DEFB $00,$02,$00,$02,$00,$06,$00,$06
  DEFB $00,$06,$00,$0E,$FF,$FE,$00,$00

spr_brik_black EQU CpcBrickNoGlint

	; ELSE

; Спрайт: кирпич, кадр 1
; spr_brik_1:
  ; DEFB #00,#01,#7F,#FF,#7F,#FF,#7F,#FF
  ; DEFB #7F,#FF,#7F,#FF,#7F,#FF,#FF,#FF

; Спрайт: кирпич, кадр 2
; spr_brik_2:
  ; DEFB #FF,#FD,#FF,#FD,#FF,#FD,#FF,#FD
  ; DEFB #FF,#FD,#FF,#F9,#FF,#01,#FF,#FF

; Спрайт: кирпич, кадр 3
; spr_brik_3:
  ; DEFB #FF,#FD,#FF,#FD,#FF,#F9,#FF,#F9
  ; DEFB #FF,#F9,#FF,#F1,#F0,#01,#FF,#FF

; Спрайт: кирпич, кадр 4
; spr_brik_4:
  ; DEFB #FF,#FD,#FF,#FD,#FF,#F9,#FF,#F9
  ; DEFB #FF,#F1,#FF,#C1,#00,#01,#FF,#FF

; Спрайт: кирпич, кадр 5
; spr_brik_5:
  ; DEFB #00,#01,#00,#01,#00,#01,#00,#01
  ; DEFB #00,#01,#00,#01,#00,#01,#FF,#FF

; Спрайт: кирпич, кадр 6
; spr_brik_6:
  ; DEFB #FF,#FD,#FF,#FD,#FF,#FD,#FF,#F9
  ; DEFB #FF,#F9,#FF,#F1,#FE,#01,#FF,#FF

; Спрайт: кирпич, кадр 7
; spr_brik_7:
  ; DEFB #FF,#FD,#FF,#FD,#FF,#F9,#FF,#F9
  ; DEFB #FF,#F9,#FF,#F1,#00,#01,#FF,#FF
	
	; ENDIF
  
  
  