; Used by the routine at LBC10.
; Ввод имени нового рекордсмена, обновление таблицы рекордов и её вывод на экран
input_new_record_name:
  ; DI
  LD HL,current_score_1up+2
  LD DE,score_six_digits
  LD B,$03
L910C_0:
  LD A,(HL)
  RRA
  RRA
  RRA
  RRA
  AND $0F
  LD (DE),A
  INC DE
  LD A,(HL)
  AND $0F
  LD (DE),A
  INC DE
  DEC HL
  dec b
  jp nz,L910C_0
  LD HL,txt_high_score_table+227 ; Текст последней строчки таблицы (указатель строки = "IX")
  LD A,$0B
  LD (hs_rank),A
L910C_1:
  LD B,$06
  PUSH HL			; сохраняем указатель строки (замена PUSH IX)
  LD DE,score_six_digits	; указатель цифр нового счёта (замена IY, база не меняется между попытками)
L910C_2:
  LD A,(DE)		; IY+$00
  LD C,A
  LD A,(HL)		; IX+$00
  CP C
  JP C,L910C_4
  JP NZ,L910C_3
  INC HL
  INC DE
  dec b
  jp nz,L910C_2
L910C_3:
  POP HL
  LD A,(hs_rank)
  CP $0B
  RET Z
  JP L910C_5
L910C_4:
  LD A,(hs_rank)
  DEC A
  LD (hs_rank),A
  POP HL
  LD BC,$FFEE
  ADD HL,BC
  LD A,(hs_rank)
  DEC A
  JP NZ,L910C_1
L910C_5:
  LD (hs_row_ptr),HL	; сохраняем указатель строки перед сдвигом таблицы (HL нужен для LDDR)
  LD A,$0A
  LD D,A
  LD A,(hs_rank)
  LD E,A
  LD A,D
  SUB E
  JP Z,L910C_7
  LD DE,txt_high_scores-1
  LD HL,txt_high_score_table+222 ; Последняя строка таблицы рекордов
L910C_6:
  PUSH AF
  LD B,$0E
  call LDDR8080B		; LDDR
  DEC HL
  DEC HL
  DEC HL
  DEC HL
  DEC DE
  DEC DE
  DEC DE
  DEC DE
  POP AF
  DEC A
  JP NZ,L910C_6
L910C_7:
  LD HL,(hs_row_ptr)
  LD DE,$0012
  ADD HL,DE
  LD (hs_row_ptr),HL
  EX DE,HL		; DE = обновлённый указатель строки (адресат для LDIR)
  LD HL,score_six_digits
  LD BC,$0006
  call LDIR8080B
  LD C,$2C		; пробел
  LD HL,(hs_row_ptr)
  LD DE,$0009
  ADD HL,DE
  LD (HL),$0A		; IX+$09
  INC HL
  LD (HL),C		; IX+$0A
  INC HL
  LD (HL),C		; IX+$0B
  INC HL
  LD (HL),C		; IX+$0C
  INC HL
  LD (HL),C		; IX+$0D
  ;CALL clear_screen_attrib
  CALL clear_screen_pix
  CALL disp_high_score_table_screen
  LD A,(player_number)
  INC A
  LD (txt_player_0_enter_your_name+13),A
  LD DE,txt_player_0_enter_your_name
  CALL print_line
  CALL print_line
  LD HL,(hs_row_ptr)
  DEC HL
  DEC HL
  DEC HL
  DEC HL
  LD (text_line_addr),HL
  LD B,$05
L910C_8:
  LD C,$0A
  PUSH BC
L910C_9:
  CALL get_control_state_1up
  LD A,(ctrl_btns_pressed)
  AND $13
  JP Z,L910C_9
  LD D,A
  and %00010000		; BIT 4,A
  JP NZ,L910C_12
  LD A,D
  CP $03
  JP Z,L910C_9
  POP BC
  RRA
  JP NC,L910C_10
  INC C
  LD A,C
  CP $2E		; после '-' снова '0'
  JP NZ,L910C_11
  LD C,$00
  JP L910C_11
L910C_10:
  DEC C
  ld A,C
  and %10000000		; BIT 7,C
  JP Z,L910C_11
  LD C,$2D		; перед '0' идёт '-'
L910C_11:
  PUSH HL
  LD HL,(hs_row_ptr)
  LD DE,$0009
  ADD HL,DE
  LD (HL),C		; IX+$09
  POP HL
  PUSH BC
	ex DE,HL
	ld HL,(text_line_addr)
	ex DE,HL
  CALL print_line
  CALL play_sound_choose_letter
  LD D,$20
  CALL pause_short
  JP L910C_9
L910C_12:
  CALL play_sound_confirm_letter
  POP BC
  DEC B
  JP Z,L910C_14
  LD HL,(hs_row_ptr)
  INC HL
  LD (hs_row_ptr),HL
  LD DE,$0009
  ADD HL,DE
  LD (HL),$0A		; IX+$09
  PUSH BC
	ex DE,HL
	ld HL,(text_line_addr)
	ex DE,HL
  CALL print_line
L910C_13:
  CALL get_control_state_1up
  LD A,(ctrl_btns_pressed)
  AND $10
  JP NZ,L910C_13
  POP BC
  JP L910C_8
L910C_14:
  CALL disp_high_score_table_screen
  LD B,$0A
  JP pause_long

; Сюда помещается адрес следующей строки текста для печати
text_line_addr:
  DEFW $0000

; Указатель на текущую строку таблицы рекордов, заменяет регистр IX
hs_rank: db 0
hs_row_ptr:
  DEFW $0000

; Used by the routines at disp_high_score_table_screen and L93F8.
; Рисует рамку вокруг экрана
draw_frame:			; Vector 8080 ready
	call MusicStop
	call SetPaletteMenu
	ld a,1
	ld (UiActive),a
	ld a,7
	ld (UiColor),a
	ld a,$ff
	ld (last_color),a
	ld HL,$0000
	ld (counter_misc),HL
	;call clear_screen_attrib
	call clear_screen_pix
; Рисуются боковины
	ld HL,$c000	; Left edge, all 256 visible rows
	ld DE,$df00	; Right edge
	ld B,0		; 256 iterations
draw_frame_0:
	ld a,$C0
	call UiPixelWrite
	ld A,$03
	ex de,hl
	call UiPixelWrite
	ex de,hl
	inc E			; поправлено направление для Вектора
	inc L			; поправлено направление для Вектора
	dec B
	jp nz,draw_frame_0
; Рисуется верх и низ
	ld HL,$c0ff		; Top, menu scroll FF
	ld DE,$c000	; Bottom
	ld B,$20
	ld A,$FF
draw_frame_1:
	call UiPixelWrite
	dec L			; поправлено направление для Вектора
	call UiPixelWrite
	inc L
	ex de,hl
	call UiPixelWrite
	ex de,hl
	inc E			; bottom second row
	ex de,hl
	call UiPixelWrite
	ex de,hl
	dec E
	inc H
	inc D
	dec B
	jp nz,draw_frame_1
	ret

; Used by the routines at input_new_record_name and L927F.
disp_high_score_table_screen:

;  	ld a,c42
;	ld (color_port),a	; Красный цвет

	CALL draw_frame

	LD DE,txt_high_score_table
	LD B,$16
	JP print_message

; Used by the routine at disp_main_menu_and_wait_keys.
disp_hs_table_and_wait_keys:
 CALL disp_high_score_table_screen
 ld hl,300
hs_wait:
 push hl
 call WaitVideoFrame
 pop hl
 ld a,(KeyLine1)
 and $28
 jp z,CheatStartEnabled
 ld a,(KeyLine2)
 cpl
 and 1
 jp nz,CheatStartNormal
 ld a,(JoystickP)
 ld b,a
 ld a,(JoystickP2)
 and b
 cpl
 and $c0
 jp nz,JoystickMenuStart
 ; Any other key returns to the menu (the cheat row is left alone, and
 ; the first second is skipped so that a key still held does not count).
 ld a,h
 or a
 jp nz,hs_no_key
 push hl
 ld hl,KeyLine0
 ld a,(KeyLine2)
 and (hl)
 ld hl,KeyLine4
 and (hl)
 ld hl,KeyLine5
 and (hl)
 ld hl,KeyLine7
 and (hl)
 pop hl
 inc a
 jp nz,disp_main_menu_and_wait_keys
hs_no_key:
 dec hl
 ld a,h
 or l
 jp nz,hs_wait
 jp disp_main_menu_and_wait_keys
