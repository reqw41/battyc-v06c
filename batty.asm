; This experimental cache layout is proved for assets without shadows.
 IFNDEF NO_SPRITE_SHADOWS
 ASSERT 0
 ENDIF
; BATTY
; (C)1987 HIT-PAK
; (С)2020 Юдин С.А. - Адаптация для ПК Специалист

	INCLUDE "batty0.inc"

	org	BATTY0_END
start_bin:
;=================================

; Адрес начала окна ZX-экрана на экране Вектора
zx_scr EQU $C0E0
; Keep the upper HUD position; carry the background and walls to screen row 255.
FieldSpriteLimit EQU $c8
BatHomeY EQU $b5
FieldScroll EQU 5
FieldBottomLo EQU FieldScroll+1
FieldHeight EQU $e0-FieldBottomLo+1
FieldTexturePhase EQU (FieldBottomLo-$21)&15
FieldTextureTiles EQU (FieldHeight+FieldTexturePhase)/16

;sound_port EQU $ff03

; Цвета для стандартного Специалиста
c00 EQU $d0 ; $00 - 00 000 000 Чёрный
c03 EQU $40 ; $03 - 00 000 011 Фиолетовый (Маджента)
c04 EQU $90 ; $04 - 00 000 100 Зелёный
c05 EQU $80 ; $05 - 00 000 101 Голубой (Циан)
c06 EQU $10 ; $06 - 00 000 110 Жёлтый
c07 EQU $00 ; $07 - 00 000 111 Белый

c20 EQU $d0 ; $20 - 00 100 000 Зелёный-Чёрный

c42 EQU $50 ; $42 - 01 000 010 Красный
c43 EQU $40 ; $43 - 01 000 011 Фиолетовый (Маджента)
c44 EQU $90 ; $44 - 01 000 100 Зелёный
c45 EQU $80 ; $45 - 01 000 101 Голубой (Циан)
c46 EQU $10 ; $46 - 01 000 110 Жёлтый
c47 EQU $00 ; $47 - 01 000 111 Белый

c4F EQU $00 ; $4f - 01 001 111 Синий-Белый
c57 EQU $00 ; $57 - 01 010 111 Красный-Белый
c5F EQU $00 ; $5f - 01 011 111 Фиолетовый-Белый

c70 EQU $d0 ; $70 - 01 110 000 Жёлтый-Чёрный


; Начало программы

; Начальная обработка графики.
  INCLUDE "./routines/preparation.asm"

; Элементы оформления игрового поля
  INCLUDE "./gfx/sprites_mono_native_1.asm"

; Знакогенератор
  INCLUDE "./gfx/font.asm"
 INCLUDE "routines/ball_rotation.asm"

; Графика: элементы обрамления экрана
  INCLUDE "./gfx/zx_frame.asm"

; Список уровней и их структура
  INCLUDE "./gfx/levels.asm"

; Поиск нужного спрайта по координатам в IX
  INCLUDE "./routines/sprites_search.asm"

; Спрайты с масками
 IFDEF NO_SPRITE_SHADOWS
  INCLUDE "./gfx/sprites_mono_native_2.asm"
 ELSE
  INCLUDE "./gfx/sprites_with_masks_2.asm"
 ENDIF

; Двухбайтовый счётчик, используемый, например, в мигалке главного меню
counter_misc:
	DEFW $0000

; Случайное число
; random_number+0 - всегда одинаковая последовательность чисел
; random_number+1 - в последовательность вносят коррективы нажатые кнопки управления
random_number:
	DEFW $8E17
random_number_1 EQU random_number+1

; Счётчик, значение которого $8000-$9FFF
random_seed:
	DEFW $8000

; Used by the routine at game_screen_draw_to_buffer.
; Рисует в буфере все магниты на уровне
  INCLUDE "./routines/magnets.asm"

; Used by the routines at print_magnets, print_one_magnet, disp_main_menu_and_wait_keys, set_bonus, game_restart, LBB97 and LBC10.

; Генератор случайных чисел
random_generate:		; Specialist ready
	EX HL,DE
	LD HL,(random_number)	; 8E17
	EX HL,DE
	LD HL,(random_seed)	; 8000

	LD A,(HL)		; 81 отсюда bat_increase_size_ready LD (IX+$15),$81
	ADD A,$05
	LD B,A
	LD A,(ctrl_btns_pressed)
	ADD A,B
	ADD A,E
	LD E,A			; E += (HL) + $05 + (ctrl_btns_pressed)

	LD A,(HL)
	CPL
	ADD A,$16
	ADD A,D
	ADD A,L
	LD D,A			; D += !(HL) + $16 + L

; D - всегда одинаковая последовательность чисел
; E - в последовательность вносят коррективы нажатые кнопки управления

	EX HL,DE
	LD (random_number),HL
	EX HL,DE

	INC HL
	LD A,H
	AND $9F
	LD H,A			; HL = (HL + 1) & $9FFF
	LD (random_seed),HL
	RET

; Состояние нажатых кнопок джойстика и управления
; Bit 0 $01 - вправо
; Bit 1 $02 - влево
; Bit 2
; Bit 3
; Bit 4 $10 - огонь
ctrl_btns_pressed:
	DEFB $00

; Расшифровываем биты клавиатуры и джойстика Вектора
; результат помещается в ctrl_btns_pressed
read_keyboard:
  ; Decode active-low fire/right/left, retaining the legacy bits 2/3.
  ld b,$0c
  ld a,(KeyLine0)
  cpl
  ld c,a
  and $ac
  jp z,nk_right
  ld b,$1c
nk_right:
  ld a,c
  and $42
  jp z,nk_left
  inc b
nk_left:
  ld a,c
  and $11
  jp z,nk_space
  ld a,b
  or 2
  ld b,a
nk_space:
  ld a,(KeyLine7)
  rla
  jp c,nk_keyboard_done
  ld a,b
  or $10
  ld b,a
nk_keyboard_done:
  ld a,b
  ld (ctrl_btns_pressed),a
  ret
NativeJoystickState:
 ld a,(game_mode)
 cp 2
 jp z,NativeJoystickFirst
 ld a,(player_number)
 or a
 jp nz,NativeJoystickState2
NativeJoystickFirst:
 ld a,(game_mode)
 or a
 jp nz,NativeJoystickFirstRead
 ld a,(SoloJoystick2)
 or a
 jp nz,NativeJoystickState2
NativeJoystickFirstRead:
 ld a,(JoystickP)
 jp NativeJoystickDecode
NativeJoystickState2:
 ld a,(JoystickP2)
NativeJoystickDecode:
 ld b,$0c
nk_joystick:
  cpl
  ld c,a
  and $c0
  jp z,nk_joy_left
  ld a,b
  or $10
  ld b,a
nk_joy_left:
  ld a,c
  and 3
  or b
  ld (ctrl_btns_pressed),a
  ret

; Used by the routines at clear_hl_buff16, all_var_init and game_start.
; Очищает буфер адресуемый HL размером, заданным в B
clear_hl_buff:
	LD (HL),$00
	INC HL
	dec B
	jp nz,clear_hl_buff
	RET

spr_level_textures:
	DEFW spr_level_texture_1
	DEFW spr_level_texture_2
	DEFW spr_level_texture_3
	DEFW spr_level_texture_4

; Текстуры уровней 2,3,4 (текстура 1 дальше по тексту)
  INCLUDE "./gfx/sprites_color_2.asm"

; Used by the routine at game_restart.
; Вывод окна с номером уровня и игрока перед началом раунда
show_window_round_number:
 call SUWindowSave

; Вписываем двузначный номер раунда в сообщение в 10-тичной системе
	LD A,(round_number_1up)
	INC A
	LD B,A
	XOR A
next_round_number:
	ADD A,$01
	DAA
	dec B
	jp nz,next_round_number
	LD B,A
	RRA
	RRA
	RRA
	RRA
	AND $0F
	LD (txt_round_xx+10),A
	LD A,B
	AND $0F
	LD (txt_round_xx+11),A
; Вписываем номер игрока в сообщение
	LD A,(player_number)
	INC A
	LD (txt_player_x+11),A
 ld de,txt_player_x
 ld a,(game_mode)
 cp 2
 jp nz,RoundFirstLine
 ld de,txt_game_on
RoundFirstLine:
 call print_line
 ld de,txt_round_xx
 jp print_line

  INCLUDE "./txt/txt_player_x.asm"
  INCLUDE "./txt/txt_round_xx.asm"
  INCLUDE "./txt/txt_game_on.asm"
  INCLUDE "./txt/txt_high_score_table.asm"
  INCLUDE "./txt/txt_high_scores.asm"

; Сюда счёт преобразуется в шесть 10-тичных цифр
score_six_digits:
	DEFB $00,$00,$00,$00,$00,$00

  INCLUDE "./txt/txt_player_0_enter_your_name.asm"

; Used by the routine at LBC10.
  INCLUDE "./routines/record_table.asm"

; Used by the routine at disp_main_menu_and_wait_keys.
; Преобразует цифры в текст и помещает текст в сообщение
score_to_text:		; Specialist ready
	LD B,$03
next_double_digit:
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
	DEC B
	JP NZ,next_double_digit
	RET

; Мусор?
	DEFB $04,$03,$47,$04,$03,$00

coord_ctrl_1up:
	DEFW $8228		; Координаты (X,Y) указателя игрока 1

coord_ctrl_2up:
	DEFW $82B8		; Координаты (X,Y) указателя игрока 2

; Указатели управления игроков
  INCLUDE "./gfx/sprites_no_masks_1.asm"

; Два независимых байта для обратного отсчёта
back_counters:
	DEFW $0000

; Надписи PRESS A и PRESS B
  INCLUDE "./gfx/sprites_no_masks_2.asm"

; Подпрограмма рисования главного меню и опроса клавиатуры в нём
  INCLUDE "./routines/main_menu.asm"

  INCLUDE "./txt/txt_main_menu.asm"
  INCLUDE "./txt/txt_score_1up.asm"
  INCLUDE "./txt/txt_score_2up.asm"
  INCLUDE "./txt/txt_1_player.asm"
  INCLUDE "./txt/txt_2_players.asm"
  INCLUDE "./txt/txt_double_play.asm"
  INCLUDE "./txt/txt_controls.asm"

; Сюда сохраняется указатель на текст перед выводом на экран при смене режима игры
pointer_game_mode_text:
	DEFW txt_1_player
	DEFW txt_controls

; +00 - координата Y
; +01 - указатель на текущий атрибут в таблице
current_game_mode_line_prop:
	DEFB $29,$00

	DEFB $67,$08		; Мусор?

; Used by the routine at disp_main_menu_and_wait_keys.
; Закрашивает текущий режим игры в главном меню нужным цветом (для мигания)
fill_color_current_game_mode:
 ; Re-render the selected text at a frame-based blink rate.
 ld a,(IntCount)
 and $10
 ld a,c06
 jp z,UiFlashReady
 ld a,c47
UiFlashReady:
 ld hl,last_color
 cp (hl)
 ret z
 ld (hl),a
 ld hl,(pointer_game_mode_text)
 inc hl
 inc hl
 ld (hl),a
 dec hl
 dec hl
 ex de,hl
 jp print_line
last_color: db $ff

; Признак необходимости смены игрока, которому зачислять счёт при Double Play
; Если 0, то менять игрока не нужно
need_change_player:
	DEFB $00

; Шаги очков, за которые будет добавляться дополнительная жизнь: 03(0000), 06(0000), 10(0000) и т.д.
live_add_steps:
	DEFB $03,$06,$10,$15,$20,$25,$50,$75
	DEFB $FF

; Used by the routines at kill_enemy_by_bat, handling_bullet, get_bonus and points_calc_and_add.
; Добавление очков из BC текущему игроку
add_points_to_score:
	LD A,(game_mode)
	CP $02
	JP NZ,score_update	; Пропускаем, если режим не Double Play
	LD A,(need_change_player)
	AND A
	JP Z,score_update ; Пропускаем, если в need_change_player ноль

; Если Double Play и в need_change_player не ноль
; Обмениваем игроков
	PUSH BC
	LD HL,score_1up_in_game
	LD DE,score_2up_in_game
	LD B,$0A
	CALL hl_swap_de
	LD HL,current_score_1up
	LD DE,current_score_2up
	LD B,$03
	CALL hl_swap_de
	POP BC
; Обновляем счёт
	CALL score_update
; Меняем игроков обратно
	LD HL,score_1up_in_game
	LD DE,score_2up_in_game
	LD B,$0A
	CALL hl_swap_de
	LD HL,current_score_1up
	LD DE,current_score_2up
	LD B,$03
	JP hl_swap_de

; Добавление очков из ВС к счёту текущего игрока, добавление жизни, если нужно, и обновление цифр на поле
score_update:
	LD HL,live_add_steps
	LD A,(current_score_1up+$02)
score_update_1:
	CP (HL)
	JP C,score_update_2
	INC HL
	JP score_update_1
score_update_2:
	LD E,(HL)

	LD HL,current_score_1up
	LD A,C
	ADD A,(HL)
	DAA
	LD (HL),A
	INC HL
	LD A,B
	ADC A,(HL)
	DAA
	LD (HL),A
	INC HL
	LD A,$00
	ADC A,(HL)
	DAA
	LD (HL),A
	CP E
	JP C,score_update_4

;--------------------------------
; Добавление ещё одной жизни
	PUSH HL
	ld HL,(IXobj)		; текущий объект
	PUSH HL
	LD HL,object_lives_indicator
	ld (IXobj),HL
	CALL hl_buf_addr_calc
	CALL print_obj_to_buff
	CALL plane_static_object
	ld HL,(IXobj)
	ld DE,$0011
	add HL,DE
	LD (HL),D		; (IX+$11) = $00
	ld HL,(IXobj)
	inc HL
	inc HL
	LD A,(HL)		; IX+$02
	ADD A,$10
	CP $E9
	JP NC,score_update_3
	LD (HL),A		; IX+$02
score_update_3:
	LD A,(lives_1up)
	INC A
	LD (lives_1up),A
	CALL get_free_sound_slot
	ld (HL),sound_live_add
	inc HL
	ld (HL),$20
	pop hl
	ld (IXobj),hl		; восстанавливаем текущий объект
	POP HL
;--------------------------------

score_update_4:
	LD HL,(score_1up_in_game)
	LD (score_screen_ptr),HL
	LD HL,current_score_1up+2
	LD A,$01
	LD (scr_score_need_upd),A
; This entry point is used by the routine at game_screen_draw_to_buffer.
print_score_in_game:
	LD B,$03
next_digit:
	LD (digit_ptr_save),HL
	LD A,B
	LD (digit_count_save),A
	LD A,(HL)
	AND $F0
	CALL print_digit
	LD HL,(digit_ptr_save)
	LD A,(HL)
	ADD A,A
	ADD A,A
	ADD A,A
	ADD A,A
	CALL print_digit
	LD HL,(digit_ptr_save)
	LD A,(digit_count_save)
	LD B,A
	DEC HL
	dec B
	jp nz,next_digit
	RET

; Used by the routine at add_points_to_score.
; Печать цифры счёта на поле
print_digit:
 jp NativePrintDigit

; Used by the routines at add_points_for_left_briks and play_sounds_queue.
; Обновляет участок экрана со счётом текущего игрока
scr_score_update:
	XOR A
	LD (scr_score_need_upd),A
	RET ; NativePrintDigit updates the persistent HUD directly.

; Used by the routines at game_restart and briks_calc.
; Поиск адреса уровня по номеру, заданному в ячейке current_level_number_1up
level_addr_calc:
	LD A,(current_level_number_1up)
; This entry point is used by the routine at current_level_2up_copier.
; Поиск адреса уровня по номеру, заданному в А
level_addr_calc_a:
	LD HL,levels
	ADD A,A		; *2
	LD E,A
	LD D,$00
	ADD HL,DE
	ld A,(HL)
	INC HL
	ld H,(HL)
	ld L,A
	LD (current_level_addr),HL
	RET

current_level_addr:
	DEFW $0000

; Used by the routines at LBAED, LBB97 and LBC10.
; Постановка игры на паузу клавишами 1, 2, 3 или 4
pause_game:
	CALL press_1_4_check
	RET Z			; Возвращаемся, если не нажата клавиша 1-4
pause_game_0:
	CALL press_1_4_check	; Если нажата, то крутиться здесь, пока не отпустят
	JP NZ,pause_game_0
pause_game_1:
	CALL press_1_4_check	; Если отпустили, то крутится здесь, пока не нажмут
	JP Z,pause_game_1
pause_game_2:
	CALL press_1_4_check	; Если нажали, то крутится здесь, пока не отпустят
	JP NZ,pause_game_2
	RET

; Проверка нажатия клавиш 1-4
; Выход: Z=1: нет нажатия, Z=0: есть нажатие
press_1_4_check:
	ld A,(KeyLine2)		; Проверка ряда цифр '0'..'7'
	cpl			; Необходимо для правильно установки флага на выходе
	and %00011110		; Маска для клавиш '1'..'4'
	ret

; Used by the routines at input_new_record_name, draw_frame, pause_clear_screen_attrib, print_kinnock, game_restart and LBC10.
;clear_screen_attrib:	; Specialist ready
;	RET

; Used by the routines at input_new_record_name, draw_frame, game_restart and LBC10.
clear_screen_pix:
 jp planes_reset

pause_short:
	LD E,$FF
pause_short_0:
	DEC E
	JP NZ,pause_short_0
	DEC D
	JP NZ,pause_short
	RET

; Сюда временно сохраняется SP
; Obsolete shadow-renderer SP storage removed.

; Used by the routines at LBAED, LBB97 and LBC10.
; Сохранение объектов с экранного буфера с тенью и фоном в save_objs_buff
; Перенос объектов (макс. $0B) в буфер
restore_objs_and_magnet:
 xor a
 ld (current_magnet_prop+1),a
 ret

; This entry point is used by the routines at LBB97 and LBC10.
; Восстанавливает объекты из save_objs_buff в экранный буфер
; Data block at 98FA
; Свойства всех 11-ти наборов спрайтов
; Для сложения с objs_width_sum.
; +$00 - значение для объекта без сдвига по X
; +$01 - значение для объекта со сдвигом по X
; Obsolete shadow-renderer width table removed.

; Routine at 9910
;
; Used by the routines at print_magnets, print_one_magnet, add_points_to_score, bonus_extra_life and game_screen_draw_to_buffer.
; Печатает спрайт с маской в буфер
; На входе: (IXobj) = адрес объекта (спрайт с маской)
print_obj_to_buff:
 jp NativeStaticObject

; Набор свойств 11 объектов по 22 байта:
; $00 номер набора спрайтов объекта
;		BIT7 = 1 - объект не обрабатывается (за пределами экрана)
; $01 номер спрайта в наборе объекта
; $02 координата Х объекта
; $03
; $04 координата Y объекта
; $05
; $06 направление полёта шарика
; $07 скорость движения: врага - $01, шарика slow bonus - $02. Max - $06
; $08 ширина спрайта с тенью в байтах
; $09 высота спрайта с тенью в пикселях
; $0A старший адрес в экранном буфере
; $0B младший адрес в экранном буфере
; $0C ширина объекта без тени в пикселях
; $0D высота объекта без тени в пикселях
; $0E предыдущая координата Х объекта
; $0F предыдущая координата Y объекта
; $10 предыдущая ширина спрайта с тенью в байтах
; $11 предыдущая высота спрайта с тенью в пикселях
; $12 (у врагов)
; $13 (у врагов / используется при замедлении трёх шариков)
; $14 применяемый к объекту бонус. $FF - нет бонуса
; $15 Свойства каретки:
;		BIT0 = 1 - расширенная каретка
;		BIT1 = 1 - каретка в процессе расширения
;		BIT5 = 1 - каретка в процессе расширения (основной флаг)
;		BIT6 = 1 - каретка в процессе уменьшения
;		BIT7 = 1 - каретка не в процессе трансформации

; Keep the first two ball descriptors on one page for the hot selector.
 IF ($ & 255) > 233
 DS 256-($ & 255),0
 ENDIF
; Свойства объекта шарик
object_ball_1:
  DEFB $02,$00,$84,$00,$A8,$00,$38,$02
  DEFB $02,$0C,$00,$00,$08,$07,$00,$00
  DEFB $00,$00,$00,$00,$00,$80

; Свойства объекта шарик 2
object_ball_2:
  DEFB $00,$00,$84,$00,$A8,$00,$38,$02
  DEFB $02,$0C,$00,$00,$08,$07,$00,$00
  DEFB $00,$00,$00,$00,$00,$80

; Свойства объекта шарик 3
object_ball_3:
  DEFB $00,$00,$84,$00,$A8,$00,$38,$02
  DEFB $02,$0C,$00,$00,$08,$07,$00,$00
  DEFB $00,$00,$00,$00,$00,$80

; Свойства объекта пуля 1
object_bullet_1:
  DEFB $00,$00,$84,$00,$A8,$00,$30,$01
  DEFB $01,$08,$00,$00,$04,$08,$00,$00
  DEFB $00,$00,$00,$00,$00,$80

; Свойства объекта пуля 2
object_bullet_2:
  DEFB $00,$00,$84,$00,$A8,$00,$30,$01
  DEFB $01,$08,$00,$00,$04,$08,$00,$00
  DEFB $00,$00,$00,$00,$00,$80

; Свойства объекта каретка 2
object_bat_2:
  DEFB $00,$00,$74,$00,BatHomeY,$00,$00,$00
  DEFB $04,$0D,$00,$00,$1C,$0A,$00,$00
  DEFB $00,$00,$F0,$00,$FF,$80

; Свойства объекта каретка 1
object_bat_1:
  DEFB $01,$00,$74,$00,BatHomeY,$00,$00,$00
  DEFB $04,$0D,$00,$00,$1C,$0A,$00,$00
  DEFB $00,$00,$F0,$00,$00,$80

; Свойства объекта каретка 3
object_bat_temp:
  DEFB $00,$03,$84,$00,BatHomeY,$00,$00,$00
  DEFB $03,$0D,$00,$00,$1B,$0A,$00,$00
  DEFB $00,$00,$00,$00,$00,$00

; Свойства объекта бонус
object_bonus:
  DEFB $00,$00,$28,$00,$9F,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$F0,$60,$00,$00

; Свойства объекта враг (птица или UFO)
object_enemy:
  DEFB $00,$01,$78,$00,$88,$00,$00,$00
  DEFB $03,$18,$00,$00,$18,$18,$00,$00
  DEFB $00,$00,$50,$44,$00,$00

; Свойства объекта ракета
object_rocket:
  DEFB $00,$00,$F8,$00,$A8,$00,$00,$00
  DEFB $03,$1C,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00

; Свойства объекта индикатор жизней
object_lives_indicator:
  DEFB $03,$00,$10,$00,$C8,$00,$00,$00
  DEFB $02,$06,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; В этот объект перед выводом копируются последовательно свойства spr_1up, spr_2up, spr_hi
object_score_indicator:
  DEFB $03,$00,$00,$00,$E8,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; Свойства объекта разделитель поля для двух игроков
object_separator:
  DEFB $03,$05,$7D,$00,$A9,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; Данные окон (спрайтов с фоном) для восстановления из буфера на экран - 7 шт. по 4 байта:
; Первые два байта - координаты
; Вторые два байта - размеры окна
wins_recovery_data: ds 10*3,0 ; deferred brick coordinates and level-byte pointer

; Счётчик количества окон (спрайтов с фоном) для восстановления из буфера на экран
wins_counter:
  DEFB $00

; Used by the routines at add_points_to_score and bonus_extra_life.
; Вывод на экран объекта уже размещённого в буфере
; Данные для вывода берутся из его свойств в IX
; Вход: (IXobj) = адрес объекта
print_obj_from_buf_to_scr:
	JP plane_object
; This entry point is used by the routines at scr_score_update, restore_objs_and_magnet, wins_recovery, game_restart and
; LBC10.
; Копирует прямоугольный участок из буфера на экран c цветом
; Вход: HL - Координаты; BC - Размеры окна
win_bg_recovery:
 jp SUWindowRestore

; Сюда сохраняется текущий бонус
current_bonus:
	DEFB $00

; Used by the routine at LAFFC.
; Выбор и установка бонуса
set_bonus:
	LD A,(object_bonus)
	AND A
	RET NZ
	LD A,(game_mode)
	CP $02
	JP NZ,L9D5A_0
; Режим Double Play
	LD A,(LB28F+$01)
	CP $78
	RET Z
L9D5A_0:
	PUSH BC
	PUSH DE
	PUSH HL
	LD A,$04
	LD (object_bonus+$00),A
	LD HL,$0000
	LD (LA557),HL
	LD HL,(LB28F+$01)
	LD A,L
	LD (object_bonus+$02),A
	LD A,H
	LD (object_bonus+$04),A
	LD A,(object_bat_1+$14)
	LD (current_bonus),A
	LD A,(game_mode)
	CP $02
	JP NZ,L9D5A_1
; Режим Double Play
	LD A,L
	CP $80
	JP C,L9D5A_1
	LD A,(object_bat_2+$14)
	LD (current_bonus),A
L9D5A_1:
	LD A,$F0
	LD (object_bonus+$12),A
	LD A,$60
	LD (object_bonus+$13),A
	XOR A
	LD (object_bonus+$11),A
	LD A,$10
	LD (object_bonus+$0C),A	; Ширина в пикселях = 16
	LD A,$08
	LD (object_bonus+$0D),A	; Высота в пикселях = 8
generate_new_bonus:
	CALL random_generate
	LD A,(random_number_1)
	AND $0F
	LD HL,bonus_table_current
	CALL hl_add_a
	LD A,(current_bonus)
	CP (HL)
	JP Z,generate_new_bonus
	LD A,(HL)
	CP $04			; $04 - spr_bonus_slow
	JP NZ,L9D5A_6

; Дополнительная обработка замедления
	LD A,(object_ball_1)
	AND A
	JP Z,L9D5A_3
	LD A,(object_ball_1+$07)	; Скорость движения
	CP $02
	JP Z,generate_new_bonus	; Если шарик уже на самой низкой скорости, то генерировать новый приз
L9D5A_3:
	LD A,(object_ball_2)
	AND A
	JP Z,L9D5A_4
	LD A,(object_ball_2+$07)	; Скорость движения
	CP $02
	JP Z,generate_new_bonus	; Если второй шарик уже на самой низкой скорости, то генерировать новый приз
L9D5A_4:
	LD A,(object_ball_3)
	AND A
	JP Z,L9D5A_5
	LD A,(object_ball_3+$07)	; Скорость движения
	CP $02
	JP Z,generate_new_bonus	; Если третий шарик уже на самой низкой скорости, то генерировать новый приз
L9D5A_5:
	JP L9D5A_8

L9D5A_6:
	CP $02				; $02 - spr_bonus_triple_ball
	JP NZ,L9D5A_7

; Дополнительная обработка растроения шарика
	LD A,(balls_quantity)
	DEC A
	JP NZ,generate_new_bonus	; Если шариков больше одного, то генерировать новый приз
	JP L9D5A_8

L9D5A_7:
	CP $05				; $05 - spr_bonus_extra_life
	JP NZ,L9D5A_8

; Дополнительная обработка дополнительной жизни
	LD A,(flag_extra_life)
	AND A
	JP NZ,generate_new_bonus	; Если в раунде жизнь уже выпадала, то генерировать новый приз

L9D5A_8:
	LD A,(HL)
	CP $06				; $06 - spr_bonus_rocket_1
	JP NZ,L9D5A_9

; Дополнительная обработка ракеты
	LD A,(object_rocket)
	AND A
	JP NZ,generate_new_bonus	; Если ракета уже включена, то генерировать новый приз
	LD A,(round_number_1up)
	CP $06
	JP C,L9D5A_9		; Пропускаем, если раунд с 0-го по 5-й
	LD A,(random_number)
	AND $C0
	JP NZ,generate_new_bonus	; Сокращаем вероятность выпадения ракеты

L9D5A_9:
	LD A,(HL)
	DEC A				; $01 - spr_bonus_gun
	JP NZ,L9D5A_10

; Дополнительная обработка пулемёта
	LD A,(game_mode)
	CP $02
	JP NZ,L9D5A_10		; Уходим, если не два игрока одновременно
; Режим Double Play
	LD A,(object_bat_1+$14)
	DEC A
	JP Z,generate_new_bonus	; Если уже есть пулемёт на первой каретке, то генерировать новый приз
	LD A,(object_bat_2+$14)
	DEC A
	JP Z,generate_new_bonus	; Если уже есть пулемёт на второй каретке, то генерировать новый приз

; Обработка всех бонусов
L9D5A_10:
	LD A,(HL)		; Берёт код бонуса
	LD (object_bonus+$14),A
	LD (object_bonus+$01),A
 ; calc_write_spr_addr reads IXobj: target the bonus, not the colliding ball.
 ld hl,(IXobj)
 push hl
 ld hl,object_bonus
 ld (IXobj),hl
 CALL calc_write_spr_addr
 pop hl
 ld (IXobj),hl
	POP HL
	POP DE
	POP BC
	RET

; Текущая таблица ($10 байт), из которой случайно выбирается бонус
bonus_table_current:
	DEFB $00,$01,$02,$03,$04,$05,$06,$07
	DEFB $08,$09,$00,$04,$00,$03,$01,$02

	DEFB $00,$01,$02,$03,$04,$05,$06,$02
	DEFB $01,$03,$00,$04,$00,$03,$01,$02

; Таблица бонусов для первых 5-ти раундов (0-5)
bonus_table_first:
	DEFB $00,$01,$02,$03,$04,$05,$06,$07
	DEFB $08,$09,$00,$04,$00,$03,$01,$02

	DEFB $00,$01,$02,$03,$04,$05,$06,$02
	DEFB $01,$03,$00,$04,$00,$03,$01,$02

; Таблица бонусов для 6-го и выше раундов (6-F)
bonus_table_second:
	DEFB $00,$01,$02,$03,$02,$00,$06,$07
	DEFB $08,$09,$00,$03,$00,$02,$01,$03

	DEFB $00,$01,$02,$03,$02,$00,$06,$02
	DEFB $01,$03,$00,$03,$00,$02,$01,$03

; Used by the routine at game_restart.
; Делает необходимые приготовления для вывода врагов на раунде
enemy_prepare:
	LD A,(current_level_number_1up)
	CP $04
	RET Z			; Возвращаемся, если текущий уровень - 4

	LD A,(object_bat_1+$14)
	CP $09
	RET Z

	LD A,(object_bat_2+$14)
	CP $09
	RET Z

	LD A,(briks_quantity_1up)
	CP $2C
	RET NC			; Возвращаемся, если осталось 44 и больше кирпичей

	LD A,(object_enemy)
	AND A
	RET NZ			; Возвращаемся, если object_enemy не пустой

	LD HL,object_enemy
	CALL clear_hl_buff16	; Очищаем object_enemy (22 байта, 0x00-0x15 уже = 0)
	LD HL,prop_uneven	; Нечётный раунд
	LD A,(round_number_1up)
	RRA
	JP NC,L9EAA_0
	LD HL,prop_even		; Чётный раунд

; Заполнение object_enemy данными из нужной таблицы
L9EAA_0:
	LD A,(HL)
	LD (object_enemy+$00),A	; Тип врага: 9 - птица, 8 - UFO
	INC HL
	LD A,(HL)
	LD (object_enemy+$12),A
	INC HL
	LD A,(HL)
	LD (object_enemy+$13),A
	INC HL
	LD A,(HL)
	LD (object_enemy+$0C),A	; Ширина в пикселях
	INC HL
	LD A,(HL)
	LD (object_enemy+$0D),A	; Высота в пикселях
	INC HL
	LD A,(HL)
	LD (object_enemy+$07),A	; Скорость движения
	; +$01, +$04, +$11 = 0 (clear_hl_buff16 уже обнулил)

	LD A,(random_number)
	LD HL,prop_x_coord
	AND $03
	CALL hl_add_a
	LD A,(HL)
	LD (object_enemy+$02),A	; Координата X для печати
	LD A,$10
	LD (object_enemy+$06),A
	LD (object_enemy+$14),A

	LD HL,$0000
	LD (LAA7B),HL
	CALL calc_write_spr_addr
	RET

; Свойство +$02 object_enemy для 4-х раундов подряд
prop_x_coord:
	DEFB $40,$A8,$40,$A8

; Некоторые свойства object_enemy
;+$00,+$12,+$13,+$0C,+$0D,+$07
; Для нечётных раундов
; 09 - птица
prop_uneven:
	DEFB $09,$F0,$70,$18,$0C,$01

; Для чётных раундов
; 08 - UFO
prop_even:
	DEFB $08,$60,$90,$18,$10,$01

; Used by the routine at enemy_prepare.
; Очищает $16 байт в буфере HL
clear_hl_buff16:
	LD BC,$0016
	LD B,C
	JP clear_hl_buff

; Таблица процедур обработки объектов
; все процедуры принимают на вход (IXobj)
handling_table_routines:
	DEFW handling_bat_stub	; $01 gfx_bat
	DEFW handling_ball	; $02 gfx_ball
	DEFW handling_ball	; $03 gfx_screen_elements
	DEFW handling_bonus	; $04 gfx_bonuses
	DEFW handling_bullet	; $05 gfx_bullet
	DEFW handling_rocket	; $06 anim_rocket
	DEFW handling_spark	; $07 anim_spark
	DEFW handling_ufo	; $08 anim_ufo
	DEFW handling_bird	; $09 anim_bird
	DEFW handling_blast	; $0A anim_alien_blast
	DEFW handling_400pts	; $0B gfx_last_sprite

; Обработка объекта
; Вход: (IXobj) = адрес объекта
handling_object:
	ld HL,(IXobj)
	ld A,(HL)		; IX+$00
	LD HL,handling_table_routines-$02
	CALL hl_add_2a
	LD A,(HL)
	INC HL
	LD H,(HL)
	LD L,A
	JP (HL)

; Заглушка для обработка каретки. Настоящая обработка ниже.
handling_bat_stub:
	RET

; Used by the routine at game_restart.
; Реальная обработка текущего состояния каретки
; Вход: (IXobj) = адрес объекта
handling_bat:
	LD A,(object_bat_temp+$06)	; направление
	CP $1C
	LD A,$00
	JP Z,zero_direction
	LD A,$05
zero_direction:
	; Shadow width sum removed.	; Записываем $00 или $05, в зависимости от направления

; На какой стороне всё происходит?
	LD HL,(IXobj)
	INC HL
	INC HL		; +$02
	LD A,(HL)		; IX+$02 Координата X биты
	AND $80
	LD (need_change_player),A	; Если координата X меньше 128, то будет 0

; Обработка нажатия клавиш и изменение координат каретки
	LD A,(ctrl_btns_pressed)
	ld C,A
	and $02		; BIT 1,C	; Нажато Влево
	LD HL,(IXobj)
	INC HL
	INC HL		; +$02
	LD A,(HL)		; IX+$02 Координата X биты
	JP Z,moving_right
	SUB $04			; Уменьшаем координату Х на 4
moving_right:
	LD B,A		; сохраняем координату Х
	LD A,C
	AND $01		; BIT 0,C Нажато Вправо
	LD A,B		; восстанавливаем (LD не трогает флаги)
	JP Z,moving_left
	ADD A,$04		; Увеличиваем координату Х на 4
moving_left:
	LD HL,(IXobj)
	INC HL
	INC HL		; +$02
	LD (HL),A		; IX+$02 Обновляем координату X каретки

; Проверка и убийство врага
	CALL kill_enemy_by_bat

; Требуется ли изменение размеров каретки?
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD A,(HL)		; IX+$15
	CP $41			; %0100 0001
	JP Z,handling_bat_no_transform
	CP $61			; %0110 0001
	JP Z,handling_bat_no_transform
	AND $C1
	CP $80			; %1000 0000 - Обычная каретка
	JP Z,handling_bat_no_transform
	CP $81			; %1000 0001 - Широкая каретка
	JP Z,handling_bat_no_transform

	LD B,A
	AND $40			; BIT6 %0100 0000
	JP NZ,bat_resize	; переход, если каретка в процессе уменьшения

	LD A,(bonus_flag)
	RLA
	JP C,handling_bat_no_transform		; Переходим, если пулемёт

bat_resize:
	LD HL,(IXobj)
	INC HL		; +$01
	LD (HL),$02	; номер спрайта в наборе объекта - spr_bat_normal_shift
	LD HL,(IXobj)
	LD DE,$0008
	ADD HL,DE
	LD (HL),$03	; IX+$08 ширина спрайта с тенью в байтах
	LD A,$01
	LD (object_bat_temp),A	; gfx_bat
	LD A,(counter_misc)
	LD E,A
	LD A,B
	AND $40
	JP NZ,bat_decrease_size		; Переход, если в процессе уменьшения

; Каретка находится в процессе увеличения
	ld A,E
	and $01		; BIT 0,E	; BIT0 счётчика
	JP Z,no_x_decrease
	LD HL,(IXobj)
	INC HL
	INC HL		; +$02
	DEC (HL)		; IX+$02 Уменьшаем координату Х каретки
no_x_decrease:
	CALL check_margins
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD A,(HL)		; IX+$15
	LD B,A
	AND $1E
	LD HL,(IXobj)
	INC HL
	INC HL		; +$02
	ADD A,(HL)		; IX+$02
	ADD A,$08
	LD (object_bat_temp+$02),A
	LD A,(counter_misc)	; helpers above reuse DE: reload animation parity
	RRA
	RET C
; Увеличиваем ширину каретки на 2 пикселя
	LD HL,(IXobj)
	LD DE,$000C
	ADD HL,DE
	INC (HL)		; IX+$0C ширина объекта без тени в пикселях
	INC (HL)		; IX+$0C ширина объекта без тени в пикселях
	LD A,B			; в В(IX+$15)
	ADD A,$02
	OR $20			; Устанавливаем признак увеличения каретки
	CP $30
	JP Z,bat_increase_size_ready	; Если достигли предела увеличения, то переход
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD (HL),A		; IX+$15
	RET
bat_increase_size_ready:
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD (HL),$81		; IX+$15 Каретка расширена
	LD HL,(IXobj)
	LD DE,$000C
	ADD HL,DE
	LD (HL),$2C		; IX+$0C Ширина объекта без тени в пикселях
	JP bat_resize_ready

; Каретка находится в процессе уменьшения
bat_decrease_size:
	ld A,E
	and $01		; BIT 0,E	; BIT0 счётчика
	JP Z,no_x_increase
	LD HL,(IXobj)
	INC HL
	INC HL		; +$02
	INC (HL)		; IX+$02 Увеличиваем координату Х каретки
no_x_increase:
	CALL check_margins
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD A,(HL)		; IX+$15
	AND $3E
	LD B,A
	LD HL,(IXobj)
	INC HL
	INC HL		; +$02
	ADD A,(HL)		; IX+$02
	ADD A,$08
	LD (object_bat_temp+$02),A
	LD A,(counter_misc)	; helpers above reuse DE: reload animation parity
	RRA
	RET C
	LD HL,(IXobj)
	LD DE,$000C
	ADD HL,DE
	DEC (HL)		; IX+$0C ширина объекта без тени в пикселях
	DEC (HL)		; IX+$0C ширина объекта без тени в пикселях
	LD A,B
	SUB $02
	JP C,bat_decrease_size_ready	; Если достигли предела уменьшения, то переход
	OR $40
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD (HL),A		; IX+$15
	RET
bat_decrease_size_ready:
	LD HL,(IXobj)
	LD DE,$000C
	ADD HL,DE
	LD (HL),$1C		; IX+$0C ширина объекта без тени в пикселях
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD (HL),$80		; IX+$15 Обычная каретка

bat_resize_ready:
	LD A,(object_bat_temp)
	OR $80
	LD (object_bat_temp),A

	LD HL,(IXobj)
	INC HL
	INC HL		; +$02
	LD A,(HL)		; IX+$02
	INC A
	AND $FC
	LD (HL),A		; IX+$02 Увеличиваем координату Х, но не больше $FC (252)
	RRA
	RRA
	AND $01
	LD B,A			; BIT2 координаты X - нужен сдвиг или нет
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD A,(HL)		; IX+$15
	AND $01			; Широкая каретка или нет

	ADD A,A			; 0 (2)
	LD C,A
	ADD A,A			; 0 (4)
	ADD A,B			; 0(1) 4(5)
	LD HL,(IXobj)
	INC HL		; +$01
	LD (HL),A		; IX+$01 номер спрайта в наборе объекта (0-1, 4-5)
	LD A,$04
	ADD A,C			; 4 (6)
	LD HL,(IXobj)
	LD DE,$0008
	ADD HL,DE
	LD (HL),A		; IX+$08 ширина спрайта с тенью в байтах (4 или 6)
	RET

; Обработка каретки, когда не требуется её трансформация
handling_bat_no_transform:
	CALL check_left_margin
	CALL check_right_margin
	LD A,(bonus_flag)
	AND A
	JP Z,no_bonus

	push AF
	CALL check_right_margin
	pop AF

	AND $40		; BIT 6,A: rotates do not update the sign flag on i8080
	JP Z,no_bit6

	LD A,(counter_misc)
	RRA
	CALL C,LAAD2

; Gun mode is silent between actual shots.

	LD A,(bonus_flag)
	RLA
	LD HL,(IXobj)
	INC HL		; +$01
	LD A,(HL)		; IX+$01
	JP NC,no_bit7_1		; Переход, если BIT7 bonus_flag = 0
	AND A
	RET NZ
	JP check_bat_increase_size
no_bit7_1:
	SUB $0A
	RET NZ

check_bat_increase_size:
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD B,A		; сохраняем A
	LD A,(HL)
	AND $20		; BIT 5,(IX+$15)
	LD A,B		; восстанавливаем (LD не трогает флаги)
	JP Z,normal_bat		; Переход, если каретка не в процессе расширения
	LD (bonus_flag),A
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD (HL),$22		; IX+$15 Каретка в процессе расширения
	RET

normal_bat:
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD (HL),$80		; IX+$15 Обычная каретка
	LD (bonus_flag),A
	JP no_bonus

no_bit6:
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD A,(HL)		; IX+$15 BIT7=0 Каретка в процессе трансформации
	and %01111101		; BIT0=1 Широкая каретка
	or  %01000001		; BIT1=0 Каретка не в процессе расширения
	ld (HL),A		; IX+$15 BIT6=1 Каретка в процессе уменьшения

	ld A,(bonus_flag)
	RLA
	JP NC,no_bit7_2
	LD HL,(IXobj)
	INC HL		; +$01
	LD (HL),$0C	; IX+$01 spr_bat_normal_shift
	LD HL,(IXobj)
	LD DE,$0013
	ADD HL,DE
	LD (HL),$F0	; IX+$13
	LD A,$C0
	LD (bonus_flag),A
	RET

no_bit7_2:
	LD HL,(IXobj)
	LD DE,$0013
	ADD HL,DE
	LD (HL),$AA	; IX+$13
	LD HL,(IXobj)
	INC HL		; +$01
	LD (HL),$06	; IX+$01 spr_bat_gun_1
	LD A,$41
	LD (bonus_flag),A
	RET

no_bonus:
	LD HL,(IXobj)
	INC HL
	INC HL		; +$02
	LD A,(HL)		; IX+$02 координата Х объекта
	RRA
	RRA
	AND $01
	LD B,A			; BIT2 координаты Х (сдвинута каретка или нет)
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD A,(HL)		; IX+$15
	AND $01			; BIT0
	ADD A,A
	ADD A,A
	ADD A,B
	LD HL,(IXobj)
	INC HL		; +$01
	LD (HL),A		; IX+$01 номер спрайта каретки (0-1,4-5)

	LD HL,(IXobj)
	LD DE,$0014
	ADD HL,DE
	LD A,(HL)		; IX+$14
	DEC A
	RET NZ			; Возвращаемся, если бонус не пулемёт

; Обработка каретки с пулемётом
	LD HL,(IXobj)
	INC HL		; +$01
	LD A,(HL)		; IX+$01
	ADD A,$0A
	LD (HL),A		; IX+$01 Заменяем обычную каретку на соответствующую каретку с пулемётом

; Обработка выстрела
	LD A,(bullet)
	SUB $02
	JP C,free_bullet_1
	LD (bullet),A
	RET
free_bullet_1:
	LD A,(ctrl_btns_pressed)
	AND $10
	RET Z
; Нажат Огонь
	LD HL,object_bullet_1
	LD (IYobj),HL
	LD A,(object_bullet_1)
	AND A
	JP Z,free_bullet_2
	LD HL,object_bullet_2
	LD (IYobj),HL
	LD A,(object_bullet_2)
	AND A
	RET NZ
; Включаем пулю, если хотя бы одна из двух пуль свободна
free_bullet_2:
	LD HL,(IYobj)
	LD (HL),$05		; IY+$00 gfx_bullet
	INC HL
	LD (HL),$00		; IY+$01 spr_bullet_1
	PUSH HL
	LD HL,(IYobj)
	LD DE,$0009
	ADD HL,DE
	LD (HL),$08		; IY+$09 высота спрайта с тенью в пикселях
	POP HL
	PUSH HL
	LD HL,(IXobj)
	INC HL
	INC HL		; +$02
	LD A,(HL)		; IX+$02 координата Х каретки
	POP HL
	ADD A,$0C
	PUSH HL
	LD HL,(IYobj)
	INC HL
	INC HL		; +$02
	LD (HL),A		; IY+$02 Плюс 12 пикселей к X-координате каретки
	POP HL
	PUSH HL
	LD HL,(IYobj)
	LD DE,$0004
	ADD HL,DE
	LD (HL),$B4		; IY+$04: выстрел над битой, Y=180
	POP HL
	PUSH HL
	LD HL,(IYobj)
	LD DE,$0011
	ADD HL,DE
	LD (HL),$00		; IY+$11
	LD DE,$0004
	ADD HL,DE		; +$15
	LD (HL),$00		; IY+$15
	POP HL

	LD A,(bullet)
	CPL
	AND $01
	ADD A,$16
	LD (bullet),A

	push HL
	CALL get_free_sound_slot
	ld (HL),sound_shot
	inc HL
	ld (HL),$02
	pop HL

	RET

; Счётчик активных пуль?
bullet:
	DEFB $00

; Used by the routine at game_restart.
; Опрос управления левого игрока
get_left_player_ctrl_state:
 ld a,(game_mode)
 cp 2
 jp nz,get_control_state_1up
 ld a,(ctrl_type_1up)
 or a
 jp nz,NativeJoystickFirst
 jp NativeKeyboardLeft
get_right_player_ctrl_state:
 and 1
 jp z,read_keyboard
 jp NativeJoystickState2
; Double Play keyboard, left player, for the Vector-06C key layout: the two
; leftmost home-row keys Ф (F) and Ы (Y) move, А (A) fires.
; The right player uses the arrows and the space bar.
NativeKeyboardLeft:
 ld a,(KeyLine7)
 cpl
 and 2 ; Ы: right
 rrca
 or $0c
 ld b,a
 ld a,(KeyLine4)
 cpl
 ld c,a
 and $40 ; Ф: left
 jp z,NativeLeftKey
 inc b
 inc b
NativeLeftKey:
 ld a,c
 and 2 ; А: fire
 jp z,NativeLeftKeyDone
 ld a,b
 or $10
 ld b,a
NativeLeftKeyDone:
 ld a,b
 ld (ctrl_btns_pressed),a
 ret

; Used by the routines at input_new_record_name and get_left_player_ctrl_state.
; Опрос управления первого игрока
get_control_state_1up:
	LD A,(ctrl_type_1up)
; This entry point is used by the routine at get_right_player_ctrl_state.
; Опрос управления
get_control_state:
 and 1
 jp z,keyboard_ctrl
 jp NativeJoystickState
keyboard_ctrl:
LA1DB_7:
LA1DB_71:
 jp read_keyboard

LA270:
	DEFB $00,$00,$00,$00
LA274:
	DEFB $00,$00,$00,$00
LA278:
	DEFB $00,$00,$00,$00
LA27C:
	DEFB $00,$00

; Обработка шарика
handling_ball:
	LD HL,(IXobj)
	LD DE,$0012
	ADD HL,DE
	LD A,(HL)		; IX+$12
	AND $80
	LD (need_change_player),A
	LD A,(counter_2)
	INC A
	LD (counter_2),A
	LD HL,(IXobj)
	LD (ball_split_src),HL	; для LA7A6 (замена самомодифицирующегося "LD IY,nnnn")
	EX DE,HL		; DE = (IXobj)
 ; Only equality is needed here, not a translated 16-bit subtraction.
 ASSERT object_ball_1 / 256 == object_ball_2 / 256
 LD BC,LA278
 LD A,D
 CP object_ball_1 / 256
 JP NZ,LA27E_0
 LD BC,LA270
 LD A,E
 CP object_ball_1 % 256
 JP Z,LA27E_0
 LD BC,LA274
 CP object_ball_2 % 256
 JP Z,LA27E_0
 LD BC,LA278
LA27E_0:
	LD L,C
	LD H,B
	ld (LA27C),HL
	LD A,(HL)
	AND A
	JP Z,LA27E_1
	DEC (HL)
	JP LA27E_12
LA27E_1:
	INC HL
	LD A,(HL)
	AND A
	JP Z,LA27E_6
	PUSH HL
	LD HL,(IXobj)
	LD DE,$0006
	ADD HL,DE
	ADD A,(HL)		; IX+$06
	AND $3F
	LD (HL),A		; IX+$06
	POP HL
	INC HL
	LD B,A
	ADD A,$02
	AND $3C
	LD (HL),A
	AND $0F
	JP NZ,LA27E_4
	LD A,B
	AND $0C
	LD A,(HL)
	JP NZ,LA27E_2
	ADD A,$04
	JP LA27E_3
LA27E_2:
	SUB $04
LA27E_3:
	AND $3F
	LD (HL),A
LA27E_4:
	LD C,(HL)
	INC HL
	LD A,(HL)
	PUSH AF
	LD A,C
	LD (magnet_c_save),A	; сохраняем C (obj_compare его испортит), замена EXX
	POP AF
	LD HL,magnet_properties
	CALL hl_add_a
	LD (IYobj),HL
	INC HL
	LD A,(HL)
	AND $01
	JP NZ,LA27E_5
	CALL obj_compare
	JP NC,LA27E_5
	LD A,(magnet_c_save)
	LD C,A
	PUSH BC
	CALL LAD69
	CALL check_margins
	LD HL,(IXobj)
	LD DE,$0006
	ADD HL,DE
	LD E,(HL)		; IX+$06
	POP BC
	PUSH DE
	LD HL,(IXobj)
	LD DE,$0006
	ADD HL,DE
	LD (HL),C		; IX+$06
	PUSH BC
	CALL LA27E_24
	POP BC
	LD HL,(IXobj)
	LD DE,$0006
	ADD HL,DE
	LD A,(HL)		; IX+$06
	CP C
	POP DE
	RET NZ
	LD HL,(IXobj)
	LD BC,$0006
	ADD HL,BC
	LD (HL),E		; IX+$06
	RET
LA27E_5:
	LD HL,(LA27C)
	LD (HL),$02
	INC HL
	LD (HL),$00
	LD A,(magnet_c_save)
	LD C,A
	LD HL,(IXobj)
	LD DE,$0006
	ADD HL,DE
	LD (HL),C		; IX+$06
	JP LA27E_23
LA27E_6:
	LD A,(magnets_quantity)
	AND A
	JP Z,LA27E_12
	LD B,A
	LD HL,magnet_properties
	LD (IYobj),HL
LA27E_7:
	LD HL,(IYobj)
	INC HL
	LD A,(HL)
	AND $01
	JP NZ,LA27E_8
	PUSH BC
	CALL obj_compare
	POP BC
	JP C,LA27E_9
LA27E_8:
	LD HL,(IYobj)
	LD DE,$0010
	ADD HL,DE
	LD (IYobj),HL
	dec B
	jp nz,LA27E_7
	JP LA27E_12
LA27E_9:
	LD HL,(IYobj)
	LD DE,magnet_properties
	AND A
	CALL SBCHLDE8080	; SBC HL,DE
	LD E,L
	LD HL,(LA27C)
	LD (HL),$00
	INC HL
	LD B,$00
	PUSH HL
	LD HL,(IXobj)
	LD DE,$0006
	ADD HL,DE
	LD A,(HL)		; IX+$06
	POP HL
	ADD A,$10
	AND $3F
	CP $20
	JP C,LA27E_10
	LD B,$FE
LA27E_10:
	LD C,$FF
	PUSH HL
	LD HL,(IYobj)
	LD DE,$0004
	ADD HL,DE
	LD A,(HL)		; IY+$04
	POP HL
	ADD A,$04
	PUSH HL
	LD HL,(IXobj)
	LD DE,$0004
	ADD HL,DE
	CP (HL)			; IX+$04
	POP HL
	JP C,LA27E_11
	LD A,B
	XOR $FE
	LD B,A
LA27E_11:
	LD A,C
	XOR B
	LD (HL),A
	INC HL
	INC HL
	LD (HL),E
LA27E_12:
	LD HL,(IXobj)
	LD DE,$0014
	ADD HL,DE
	LD A,(HL)		; IX+$14
	AND A
	JP Z,LA27E_20
	DEC A
	LD (HL),A		; IX+$14
	JP Z,LA27E_15
	LD A,(game_mode)
	CP $02
	JP NZ,LA27E_13
; Режим Double Play
	LD HL,(IXobj)
	INC HL
	INC HL		; +$02
	LD A,(HL)		; IX+$02
	CP $88
	JP NC,LA27E_18
	CP $80
	JP C,LA27E_13
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD A,(HL)		; IX+$15
	AND $7F
	CP $0A
	JP C,LA27E_18
LA27E_13:
	LD A,(ctrl_btns_pressed)
	AND $10
	JP NZ,LA27E_15		; Нажат ОГОНЬ
	LD A,(object_bat_1+$14)
	AND $7F
	CP $03
	JP NZ,LA27E_15
	LD A,(object_bat_1+$02)
LA27E_14:
	LD B,A
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD A,(HL)		; IX+$15
	AND $7F
	ADD A,B
	LD HL,(IXobj)
	INC HL
	INC HL		; +$02
	LD (HL),A		; IX+$02
	LD HL,(IXobj)
	LD DE,$0004
	ADD HL,DE
	LD (HL),$AF	; IX+$04
	CALL check_margins
	JP LA27E_25
LA27E_15:
	LD HL,(IXobj)
	LD DE,$0014
	ADD HL,DE
	LD (HL),$00	; IX+$14
	LD HL,(IXobj)
	LD DE,$0004
	ADD HL,DE
	LD (HL),$B1	; IX+$04
	LD A,(object_bat_1+$14)
	RLA
	JP NC,LA27E_16
	LD A,$FF
	LD (object_bat_1+$14),A
LA27E_16:
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD A,(HL)		; IX+$15
	AND $7F
	ADD A,$24
	CP $30
	JP NZ,LA27E_17
	LD A,$34
LA27E_17:
	PUSH AF
	LD HL,(IXobj)
	LD DE,$0006
	ADD HL,DE
	POP AF
	LD (HL),A		; IX+$06
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	LD A,(HL)		; IX+$15
	AND $80
	LD (HL),A		; IX+$15
	LD HL,(IXobj)
	LD DE,$0004
	ADD HL,DE
	LD (HL),$AE	; IX+$04
	LD HL,(IXobj)
	LD DE,$0012
	ADD HL,DE
	LD A,(HL)		; IX+$12
	AND $80
	LD (HL),A		; IX+$12
	push HL
	CALL get_free_sound_slot
	ld (HL),sound_ball_start
	inc HL
	ld (HL),$02
	pop HL
	JP LA27E_25
LA27E_18:
	LD A,(ctrl_btns_pressed_copy)
	AND $10
	JP NZ,LA27E_19
	LD A,(object_bat_2+$14)
	AND $7F
	CP $03
	JP NZ,LA27E_19
	LD A,(object_bat_2+$02)
	JP LA27E_14
LA27E_19:
	LD HL,(IXobj)
	LD DE,$0014
	ADD HL,DE
	LD (HL),$00	; IX+$14
	LD HL,(IXobj)
	LD DE,$0004
	ADD HL,DE
	LD (HL),$B1	; IX+$04
	LD A,(object_bat_2+$14)
	RLA
	JP NC,LA27E_16
	LD A,$FF
	LD (object_bat_2+$14),A
	JP LA27E_16
LA27E_20:
	LD A,(counter_misc)
	LD C,A
	AND $03
	JP NZ,LA27E_23
	LD HL,(IXobj)
	LD DE,$0012
	ADD HL,DE
	LD A,(HL)		; IX+$12
	INC A
	LD (HL),A		; IX+$12
	AND $7F
	CP $7F
	JP NZ,LA27E_22
	LD HL,(IXobj)
	LD DE,$0012
	ADD HL,DE
	LD A,(HL)		; IX+$12
	AND $80
	LD (HL),A		; IX+$12
	LD HL,(IXobj)
	LD DE,$0006
	ADD HL,DE
	LD A,(HL)		; IX+$06
	ADD A,$04
	AND $0F
	JP NZ,LA27E_21
	LD A,$04
LA27E_21:
	LD B,A
	LD HL,(IXobj)
	LD DE,$0006
	ADD HL,DE
	LD A,(HL)		; IX+$06
	AND $30
	OR B
	LD (HL),A		; IX+$06
LA27E_22:
	LD A,C
	AND $07
	JP NZ,LA27E_23
	LD HL,(IXobj)
	LD DE,$0013
	ADD HL,DE
	INC (HL)		; IX+$13
	LD A,(HL)		; IX+$13
	SUB $94
	JP NZ,LA27E_23
	LD (HL),A		; IX+$13

	LD HL,(IXobj)
	LD DE,$0007
	ADD HL,DE
	LD A,(HL)		; IX+$07 Увеличение скорости. Max - $06
	CP $06
	JP Z,LA27E_23
	INC A
	LD (HL),A		; IX+$07 Записываем скорость

LA27E_23:
	CALL LAD69
	LD HL,(IXobj)
	LD DE,$0006
	ADD HL,DE
	LD A,(HL)		; direction before testing the walls
	PUSH AF
	CALL bounce_wall
	LD HL,(IXobj)
	LD DE,$0006
	ADD HL,DE
	LD B,(HL)
	POP AF
	CP B
	CALL NZ,set_sound_bat_beat
LA27E_24:
	CALL LAB1F
	CALL LAFFC
	CALL kill_enemy_by_bat
LA27E_25:
  ; Keep the coordinate pointer while setting the phase and checking Y.
  LD HL,(IXobj)
  LD DE,$0015
  ADD HL,DE
  LD A,(HL)
  OR $80
  LD (HL),A
  LD HL,(IXobj)
  INC HL
  INC HL
  LD A,(HL)
  AND $07
  DEC HL
  LD (HL),A
  INC HL
  INC HL
  INC HL
  LD A,(HL)
  CP FieldSpriteLimit
  RET C
  LD HL,(LA27C)
  LD (HL),$00
  INC HL
  LD (HL),$00
  LD HL,(IXobj)
  LD A,(HL)
  OR $80
  LD (HL),A
  LD A,(balls_quantity)
  DEC A
  LD (balls_quantity),A
  RET

; Used by the routines at handling_bat and handling_ball.
; Проверка и убивание врага кареткой, если условия соблюдены
kill_enemy_by_bat:
	LD A,(object_enemy)
	AND $7F
	RET Z			; Возвращаемся, если нет врага
	CP $0A
	RET Z			; Возвращаемся, если враг уже в состоянии взрыва
	LD HL,object_enemy
	LD (IYobj),HL
	CALL obj_compare_2pix
	RET NC			; Возвращаемся, если нет пересечения с кареткой

; This entry point is used by the routine at get_bonus.
; Убивание врага, его взрыв, звук и начисление очков
kill_enemy:
	LD A,$0A
	LD (object_enemy+$00),A	; anim_alien_blast
	XOR A
	LD (object_enemy+$01),A
	LD A,$50
	LD (object_enemy+$12),A
	LD A,$90
	LD (object_enemy+$13),A
	LD A,(object_enemy+$08)
	SUB $02
	ADD A,A
	ADD A,A
	PUSH HL
	LD HL,object_enemy+$02
	ADD A,(HL)
	LD (HL),A		; object_enemy+$02
	POP HL
	LD A,$02
	LD (object_enemy+$08),A
	LD A,$0D
	LD (object_enemy+$09),A
	LD A,(object_enemy+$04)
	ADD A,$04
	LD (object_enemy+$04),A
	PUSH HL
	LD HL,(IXobj)
	LD A,(HL)		; IX+$00
	POP HL
	AND $7F
	CP $02
	JP NZ,LA4CF_4
	PUSH HL
	LD HL,(IXobj)
	LD DE,$0006
	ADD HL,DE
	LD A,(HL)		; IX+$06
	POP HL
	AND $10
	LD DE,$1030
	JP Z,LA4CF_1
	LD DE,$0020
LA4CF_1:
	LD A,(random_number_1)
	LD B,A
	RLA
	JP C,LA4CF_2
	LD E,D
LA4CF_2:
	LD A,B
	AND $0C
	JP NZ,LA4CF_3
	PUSH HL
	LD HL,(IXobj)
	LD BC,$0006
	ADD HL,BC
	LD A,(HL)		; IX+$06
	POP HL
	AND $0C
LA4CF_3:
	OR E
	PUSH HL
	LD HL,(IXobj)
	LD BC,$0006
	ADD HL,BC
	LD (HL),A		; IX+$06
	POP HL
	PUSH HL
	LD HL,(IXobj)
	LD BC,$0012
	ADD HL,BC
	LD A,(HL)		; IX+$12
	AND $80
	LD (HL),A		; IX+$12
	POP HL
LA4CF_4:
	push HL
	LD HL,sounds_queue+21
	LD (HL),$06		; IX+$00
	inc HL
	LD (HL),$30		; IX+$01
	pop HL
	LD BC,$0350
	JP add_points_to_score

LA557:
	DEFW $0000
LA559:
	DEFB $00

; Обработка бонусов
handling_bonus:
handling_bonus_1:
	LD HL,(IXobj)
	LD DE,$0004
	ADD HL,DE
	LD A,(HL)		; IX+$04
	CP $A8
	CALL NC,get_bonus
	LD DE,$0008
	LD B,$02

; This entry point is used by the routine at handling_400pts.
LA55A_0:
	LD HL,(LA557)
	ADD HL,DE
	LD A,H
	CP B
	JP NZ,LA55A_1
	LD H,B
	LD L,$00
LA55A_1:
	LD (LA557),HL
handling_bonus_4:
	PUSH HL
	LD HL,(IXobj)
	LD DE,$0004
	ADD HL,DE
	LD D,(HL)		; IX+$04
	POP HL
	LD A,(LA559)
	LD E,A
	ADD HL,DE
handling_bonus_5:
	ld A,H
	PUSH HL
	LD HL,(IXobj)
	LD DE,$0004
	ADD HL,DE
	LD (HL),A		; IX+$04
	POP HL
	LD A,L
	LD (LA559),A
	LD A,H
	CP FieldSpriteLimit
	RET C
handling_bonus_6:
	ld HL,(IXobj)
	ld A,(HL)
	or %10000000		; SET 7,(IX+$00)
	ld (HL),A
	RET

; Обработка таблички 400 очков
handling_400pts:
	ld HL,(IXobj)
	inc HL
	inc HL
	LD A,(HL)		; IX+$02
LA590:
	ADD A,$00		; Изменяемый аргумент
	LD (HL),A		; IX+$02
	CALL check_left_margin
	CALL check_right_margin
	LD DE,$0028		; 40
	LD B,$80
	JP LA55A_0

; Обработка пули
handling_bullet:
	LD HL,(IXobj)
	INC HL
	INC HL		; +$02
	LD A,(HL)
	AND $80
	LD (need_change_player),A
	LD A,(counter_2)
	INC A
	LD (counter_2),A
	LD HL,(IXobj)
	INC HL		; +$01
	LD A,(HL)
	CP $02
	JP NC,LA5A3_0
	XOR $01
	LD HL,(IXobj)
	INC HL		; +$01
	LD (HL),A
	LD HL,(IXobj)
	LD DE,$0004
	ADD HL,DE
	LD A,(HL)	; IX+$04
	SUB $06
	LD (HL),A	; IX+$04
	JP C,LA5A3_1
	CP $03
	JP NC,LA5A3_2
	JP LA5A3_1
LA5A3_0:
	LD HL,(IXobj)
	INC HL
	INC HL		; +$02
	LD A,(HL)
	AND $F8
	LD (HL),A
	CALL LAAD2
	LD HL,(IXobj)
	INC HL		; +$01
	LD A,(HL)
	AND A
	RET NZ
LA5A3_1:
	LD HL,(IXobj)
	ld A,(HL)		; IX+$00
	or %10000000		; SET 7,(IX+$00)
	ld (HL),A		; IX+$00
	LD A,(bullet)
	AND $01
	LD (bullet),A
	RET
LA5A3_2:
	CALL LAFFC
	LD A,(object_enemy)
	AND $7F
	RET Z
	CP $0A
	RET Z
	LD HL,object_enemy
	LD (IYobj),HL
	CALL obj_compare_2pix
	RET NC
	LD A,$0A
	LD (object_enemy+$00),A	; anim_alien_blast
	XOR A
	LD (object_enemy+$01),A	; spr_alien_blast_1
	LD A,$50
	LD (object_enemy+$12),A
	LD A,$90
	LD (object_enemy+$13),A
	LD A,(object_enemy+$08)	; ширина спрайта с тенью в байтах
	SUB $02
	ADD A,A
	ADD A,A
	LD HL,object_enemy+$02
	ADD A,(HL)		; координата Х объекта
	LD (HL),A		; координата Х объекта
	LD A,$02
	LD (object_enemy+$08),A	; ширина спрайта с тенью в байтах
	LD A,$0D
	LD (object_enemy+$09),A	; высота спрайта с тенью в пикселях
	LD A,(object_enemy+$04)	; координата Y объекта
	ADD A,$04
	LD (object_enemy+$04),A	; координата Y объекта
	LD HL,(IXobj)
	INC HL		; +$01
	LD (HL),$02	; spr_alien_blast_3
	PUSH HL
	LD HL,(IXobj)
	LD DE,$0009
	ADD HL,DE
	LD (HL),$06	; IX+$09
	LD DE,$0009
	ADD HL,DE	; +$12
	LD (HL),$50	; IX+$12
	INC HL
	LD (HL),$50	; IX+$13
	POP HL
	LD HL,(IXobj)
	INC HL
	INC HL		; +$02
	LD A,(HL)	; координата Х объекта
	AND $F8
	LD (HL),A	; координата Х объекта

	push HL
	LD HL,sounds_queue+21
	LD (HL),$06		; IX+$00
	inc HL
	LD (HL),$30		; IX+$01
	pop HL

	LD BC,$0350
	JP add_points_to_score

; Счётчик длительности приза Smash
smash_counter:
	DEFB $00

; Used by the routine at get_bonus.
; Постановка в очередь звука расширения каретки
push_resize_sound:
	push HL
	CALL get_free_sound_slot
	ld (HL),sound_bat_resize_2
	inc HL
	ld (HL),$02
	pop HL
	RET

bonus_flag_copy:
	DEFB $00

; Used by the routines at get_bonus and game_restart.
; Обмен содержимым ячеек bonus_flag_copy и bonus_flag
bonus_flag_swap:
	LD A,(bonus_flag_copy)
	LD B,A
	LD A,(bonus_flag)
	LD (bonus_flag_copy),A
	LD A,B
	LD (bonus_flag),A
	RET

; Used by the routine at handling_bonus.
; Получение бонуса
get_bonus:
 ; Let the rectangle test cover the full paddle height.
	LD HL,object_bat_1
	LD (IYobj),HL
	CALL obj_compare
	JP C,LA67B_0		; Если поймал первой кареткой, то дальше

	LD A,(game_mode)
	CP $02
	RET NZ			; Уходим, если не два игрока одновременно

	LD HL,object_bat_2
	LD (IYobj),HL
	CALL obj_compare
	RET NC			; Уходим, если не поймал второй кареткой

	CALL bonus_flag_swap
	CALL LA67B_0
	JP bonus_flag_swap

LA67B_0:
	LD HL,(IXobj)
	INC HL		; +$01
	LD A,(HL)		; IX+$01
	SUB $0A
	JP NZ,LA67B_1		; Если не бомба переходим на обработку бонусов
	LD (balls_quantity),A	; Обнуляем количество шаров
	RET

; Собственно обработка бонуса
; IY - каретка
; IX - бонус
LA67B_1:
	LD HL,(IYobj)
	LD DE,$0002
	ADD HL,DE
	LD A,(HL)		; IY+$02 Координата Х каретки
	AND $80
	LD (need_change_player),A
	XOR A
	LD (smash_counter),A
	LD BC,$0400
	CALL add_points_to_score	; Добавляем 400 очков за бонус

	LD HL,(IXobj)
	LD DE,$0014
	ADD HL,DE
	LD A,(HL)		; IX+$14
	CP $05
	CALL NZ,push_resize_sound	; Если не spr_bonus_extra_life

	LD HL,(IYobj)
	LD DE,$0014
	ADD HL,DE
	DEC (HL)		; IY+$14
	JP NZ,LA67B_2
	LD A,$80
	LD (bonus_flag),A	; Если у каретки признак пулемёта, то записываем сюда $80
LA67B_2:
	LD A,(counter_misc)
	AND $01
	INC A
	LD B,A
	XOR A
	SUB B			; A = -A, замена NEG (нет NEG на i8080)
	LD (LA557+$01),A
	XOR A
	LD (LA557),A
	LD A,(random_number)
	LD B,A
	AND $01
	INC A
	LD C,A		; сохраняем A
	LD A,B
	RLA		; замена RL B: carry = старый бит7 B (B не нужен после)
	LD A,C		; восстанавливаем (LD не трогает флаги)
	JP C,LA67B_3
	LD B,A
	XOR A
	SUB B			; A = -A, замена NEG
LA67B_3:
	LD (LA590+1),A
	LD HL,(IXobj)
	LD (HL),$0B		; IX+$00 gfx_last_sprite
	LD HL,(IXobj)
	INC HL		; +$01
	LD A,(HL)	; the bonus picture number is its type
	CP $08		; spr_bonus_5000_points
	LD (HL),$00	; IX+$01 spr_400_points
	JP NZ,LA67B_label
	LD (HL),$01	; IX+$01 spr_5000_points (port)
	LD DE,$000B
	ADD HL,DE
	LD (HL),25	; IX+$0C: margins see 25 of 31 pixels, the 400 label shows 22 of 16
LA67B_label:
	CALL calc_write_spr_addr

	LD HL,(IXobj)
	LD DE,$0014
	ADD HL,DE
	LD A,(HL)		; IX+$14
	CP $06		; spr_bonus_rocket_1
	JP Z,get_rocket

	LD HL,(IYobj)
	LD DE,$0014
	ADD HL,DE
	LD (HL),A		; IY+$14
	LD A,(HL)		; IY+$14
	CP $01
	JP NZ,LA67B_4

; Поймали пулемёт
	LD (bonus_flag),A	; $01
	LD A,$01

LA67B_4:
	AND A
	JP Z,bonus_resize 	; Бонус расширитель

	PUSH AF
	LD HL,(IYobj)
	LD DE,$000C
	ADD HL,DE
	LD A,(HL)		; IY+$0C
	CP $22
	JP C,LA67B_5
	XOR A
	LD (object_bat_temp+$11),A
	LD HL,(IYobj)
	LD DE,$0015
	ADD HL,DE
	LD (HL),$4E	; IY+$15
	LD HL,(IYobj)
	INC HL		; +$01
	LD (HL),$04	; IY+$01 spr_bonus_slow
	push HL
	CALL get_free_sound_slot
	ld (HL),sound_triple_ball
	inc HL
	ld (HL),$10
	pop HL
	LD A,(counter_misc)
	AND $FE
	LD (counter_misc),A
LA67B_5:
	POP AF
	CP $08			; spr_bonus_5000_points
	JP NZ,LA67B_6
; Поймали 5000 очков: ровно 5000 вместе с 400 за любой бонус (порт; в оригинале 5400)
	LD BC,$4600
	JP add_points_to_score

LA67B_6:
	CP $09			; spr_bonus_kill_aliens
	JP NZ,LA67B_7
; Бонус KILL ALIENS
	LD A,(object_enemy)
	AND $7F			; Врага нет?
	RET Z
	CP $0A			; Враг уже в процессе взрыва?
	RET Z
	LD HL,(IXobj)
	PUSH HL
	LD HL,LA559		; dummy zero byte: kill_enemy reads type=0 (<>$02), skips ball-direction code
	LD (IXobj),HL
	CALL kill_enemy
	POP HL
	LD (IXobj),HL
	RET

LA67B_7:
	CP $05			; spr_bonus_extra_life
	JP Z,bonus_extra_life
	CP $04			; spr_bonus_slow
	JP NZ,LA67B_8

; Замедление шарика
	LD HL,(IYobj)
	LD DE,$0014
	ADD HL,DE
	LD (HL),$FF		; IY+$14
	LD A,$02		; Скорость движения
	LD (object_ball_1+$07),A
	LD (object_ball_2+$07),A
	LD (object_ball_3+$07),A
	LD HL,(random_number)
	LD A,L
	AND $1F
	ADD A,$1F
	LD (object_ball_1+$13),A
	LD A,H
	AND $1F
	ADD A,$1F
	LD (object_ball_2+$13),A
	LD A,H
	ADD A,L
	AND $1F
	ADD A,$1F
	LD (object_ball_3+$13),A
	RET

LA67B_8:
	CP $02			; spr_bonus_triple_ball
	RET NZ

; Размножение шариков
	LD A,$03
	LD (balls_quantity),A
	LD HL,(IYobj)
	LD DE,$0014
	ADD HL,DE
	LD (HL),$FF		; IY+$14 (каретка)
LA7A6:
	LD HL,(ball_split_src)
	LD (IYobj),HL
	LD HL,(IYobj)
	INC HL
	INC HL		; +$02
	LD A,(HL)		; IY+$02
	LD (ball_split_x),A
	LD HL,(IYobj)
	LD DE,$0004
	ADD HL,DE
	LD A,(HL)		; IY+$04
	LD (ball_split_y),A
	LD HL,(IYobj)
	LD DE,$0006
	ADD HL,DE
	LD A,(HL)		; IY+$06
	AND $0F
	LD DE,$080C		; Если +$06 = $04  (0100)
	CP $04
	JP Z,LA67B_9
	LD DE,$040C		; Если +$06 = $08 (1000)
	CP $08
	JP Z,LA67B_9
	LD DE,$0408		; Если +$06 = предположительно $0C (1100)
LA67B_9:
	LD HL,(IYobj)
	LD BC,$0006
	ADD HL,BC
	LD A,(HL)		; IY+$06
	AND $30
	OR E
	LD (ball2_direction_value+1),A
	LD HL,(IYobj)
	LD BC,$0006
	ADD HL,BC
	LD A,(HL)		; IY+$06
	AND $30
	OR D
	LD (ball3_direction_value+1),A

	LD HL,(IYobj)
	LD BC,$0007
	ADD HL,BC
	LD D,(HL)		; IY+$07 Скорость
	LD HL,(IYobj)
	LD C,(HL)		; IY+$00
	LD HL,(IYobj)
	INC HL		; +$01
	LD B,(HL)		; IY+$01
	LD HL,object_ball_1
	LD (IYobj),HL
	LD A,(object_ball_1)
	AND A
	JP Z,LA67B_10
; Копирование свойств первого шарика во второй + своё направление
	LD HL,object_ball_2
	LD (IYobj),HL
LA67B_10:
	LD A,(ball_split_x)
	LD HL,(IYobj)
	INC HL
	INC HL		; +$02
	LD (HL),A		; IY+$02
	LD A,(ball_split_y)
	LD HL,(IYobj)
	INC HL
	INC HL
	INC HL
	INC HL		; +$04 (INC-цепочка: B,C,D заняты скоростью/типом, ADD HL,DE/BC их испортит)
	LD (HL),A		; IY+$04
	LD HL,(IYobj)
	LD (HL),$02		; IY+$00 gfx_ball
	LD HL,(IYobj)
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL		; +$11
	LD (HL),$00	; IY+$11
	LD HL,(IYobj)
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL		; +$07
	LD (HL),D		; IY+$07 Скорость
	LD HL,(IYobj)
	LD (HL),C		; IY+$00
	LD HL,(IYobj)
	INC HL		; +$01
	LD (HL),B		; IY+$01
ball2_direction:
	LD HL,(IYobj)
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL		; +$06
ball2_direction_value:
	LD (HL),$00	; IY+$06 Направление шарика
	LD HL,object_ball_2
	LD (IYobj),HL
	LD A,(object_ball_2)
	AND A
	JP Z,LA67B_11
; Копирование свойств первого шарика в третий + своё направление
	LD HL,object_ball_3
	LD (IYobj),HL
LA67B_11:
	LD A,(ball_split_x)
	LD HL,(IYobj)
	INC HL
	INC HL		; +$02
	LD (HL),A		; IY+$02
	LD A,(ball_split_y)
	LD HL,(IYobj)
	INC HL
	INC HL
	INC HL
	INC HL		; +$04
	LD (HL),A		; IY+$04
	LD HL,(IYobj)
	LD (HL),$02		; IY+$00 gfx_ball
	LD HL,(IYobj)
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL		; +$11
	LD (HL),$00	; IY+$11
	LD HL,(IYobj)
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL
	INC HL		; +$07
	LD (HL),D		; IY+$07 Скорость
	LD HL,(IYobj)
	LD (HL),C		; IY+$00
	LD HL,(IYobj)
	INC HL		; +$01
	LD (HL),B		; IY+$01
ball3_direction:
	LD HL,(IYobj)
	LD DE,$0006
	ADD HL,DE
ball3_direction_value:
	LD (HL),$00	; IY+$06 Направление шарика
	RET

; Поймали расширитель каретки
bonus_resize:
	XOR A
	LD (object_bat_temp+$11),A
	LD HL,(IYobj)
	LD DE,$0015
	ADD HL,DE
	LD (HL),$20		; IY+$15
	LD A,(bonus_flag)
	AND A
	JP Z,LA67B_13
	LD A,$0A		; spr_bat_gun
LA67B_13:
	PUSH AF
	LD HL,(IYobj)
	INC HL		; +$01
	POP AF
	LD (HL),A		; IY+$01 spr_bat_normal
	push HL
	CALL get_free_sound_slot
	ld (HL),sound_bat_resize_1
	inc HL
	ld (HL),$C0
	pop HL
	LD A,(counter_misc)
	AND $FE
	LD (counter_misc),A
	RET

; Сюда помещается $80, если бонус пулемёт
; $00 - ничего нет
; $41 - пулемёт
; $C0 - обычная с шифтом
bonus_flag:
	DEFB $00

; Used by the routine at get_bonus.
; Получение дополнительной жизни
bonus_extra_life:
	ld HL,(IXobj)
	PUSH HL
	LD HL,object_lives_indicator
	ld (IXobj),HL
	CALL hl_buf_addr_calc
	CALL print_obj_to_buff
	CALL plane_static_object
	xor a
	LD (object_lives_indicator+$11),A	; IX+$11
	ld HL,object_lives_indicator+$02
	LD A,(HL)				; IX+$02
	ADD A,$10
	CP $E9
	JP NC,LA860_0
	LD (HL),A				; IX+$02
LA860_0:
	CALL get_free_sound_slot
	ld (HL),sound_live_add
	inc HL
	ld (HL),$20
	POP HL
	ld (IXobj),HL		; Восстанавливаем текущий объект
	LD A,$01
	LD (flag_extra_life),A
	LD A,(lives_1up)
	INC A
	LD (lives_1up),A
	RET

; Флаг того, что жизнь на раунде уже выпадала
flag_extra_life:
	DEFB $00

; Обработка ракеты
handling_rocket:
	ld HL,(IXobj)
	inc HL
	ld (handling_rocket_1+1),HL
	inc HL
	inc HL
	inc HL
	ld (handling_rocket_3+1),HL
	ld (handling_rocket_4+1),HL

	LD A,(counter_misc)
	AND $01
handling_rocket_1:
	LD ($0001),A		; IX+$01
	CALL calc_write_spr_addr
	LD HL,(LA8CF)
	LD DE,$FFE0
	ADD HL,DE
	LD A,(counter_misc)
	CP $38
	JP C,LA89A_0
	LD (LA8CF),HL
LA89A_0:
	LD A,(LA8D1)
	LD E,A
handling_rocket_3:
	LD A,($0004)		; IX+$04
	ld D,A
	ADD HL,DE
	LD A,L
	LD (LA8D1),A
	LD A,H
handling_rocket_4:
	LD ($0004),A		; IX+$04
	SUB $06
	LD (object_bat_1+$04),A
	LD (object_bat_2+$04),A
	RET

LA8CF:
	DEFB $00,$00
LA8D1:
	DEFB $00

; Обработка искр
handling_spark:
	CALL LAD69
	LD HL,(IXobj)
	LD DE,$0004
	ADD HL,DE
	LD A,(HL)		; IX+$04
	CP $C0
	JP NC,LA8D2_0
	CALL bounce_wall
	LD HL,(IXobj)
	LD DE,$0015
	ADD HL,DE
	DEC (HL)		; IX+$15
	RET NZ
	LD HL,(IXobj)
	INC HL			; +$01
	LD A,(HL)		; IX+$01
	CP $04
	JP Z,LA8D2_0
	INC (HL)		; IX+$01
	CALL calc_write_spr_addr
	LD HL,(IXobj)
	LD DE,$0014
	ADD HL,DE
	LD A,(HL)		; IX+$14
	or A
	rra		; SRL A
	LD (HL),A		; IX+$14
	INC A
	INC HL			; +$15
	LD (HL),A		; IX+$15
	RET
LA8D2_0:
	ld HL,(IXobj)
	ld A,(HL)		; IX+$00
	or %10000000		; SET 7,(IX+$00)
	ld (HL),A		; IX+$00
	RET

; Обработка UFO
handling_ufo:
	LD HL,(IXobj)
	LD DE,$0004
	ADD HL,DE
	LD A,(HL)		; IX+$04
	CP $08
	JP NC,LA902_0
	INC (HL)		; IX+$04
	RET
LA902_0:
	CALL bomb_appear
	LD HL,(LAA7B)
	LD A,H
	AND A
	JP Z,LA902_1
	CALL LAA44
	JP LA902_2
LA902_1:
	LD B,$01
	LD A,(counter_misc)
	AND $03
	CALL Z,LAA7D
	CALL LAD69
	CALL LAFFC
	CALL check_margins
LA902_2:
	LD HL,(IXobj)
	LD DE,$0004
	ADD HL,DE
	LD A,(HL)		; IX+$04
	CP FieldSpriteLimit
	JP C,LA902_3
	ld HL,(IXobj)
	ld A,(HL)		; IX+$00
	or %10000000		; SET 7,(IX+$00)
	ld (HL),A		; IX+$00
	RET
LA902_3:
	LD A,(counter_misc)
	AND $00
	CALL Z,LAAD2
	LD A,(flag_2)
	AND A
	JP NZ,LAA7D_1
	RET

;---------------------------------------------
; Нигде неиспользуемый код Мусор?
; Routine at A94B
; LA94B:
;   AND $04
;   LD C,A
;   LD A,(IX+$06)
;   ADD A,$10
;   AND $3F
;   CP $20
;   JP NC,LA94B_0
;   INC C
;   INC C
; LA94B_0:
;   LD B,$00
;   LD HL,LA96F
;   ADD HL,BC
;   LD A,(HL)
;   LD (IX+$01),A
;   INC HL
;   LD A,(HL)
;   LD (IX+$13),A
;   LD (IX+$12),$F0
;   RET

; LA96F:
;   DEFB $01,$44
;   DEFB $05,$84
;   DEFB $0D,$F0
;   DEFB $09,$C0

;---------------------------------------------
; Used by the routines at handling_ufo and handling_bird.
; Включение бомбы
bomb_appear:
	LD A,(object_bonus)
	AND A
	RET NZ			; Возвращаемся, если уже какой-то бонус падает

	LD A,(random_number)
	LD B,A
	LD A,(random_number_1)
	ADD A,B
	AND $3F
	RET NZ			; Возвращаемся, если случайный номер не удовлетворяет условиям

	LD (object_bonus+$11),A	; Помещаем случайный номер
	LD HL,(IXobj)
	LD DE,$0004
	ADD HL,DE
	LD A,(HL)		; IX+$04 координата Y каретки?
	ADD A,$08
	CP FieldSpriteLimit
	RET NC			; Возвращаемся, если пролетела

	LD (object_bonus+$04),A	; координата Y объекта
	LD A,$04
	LD (object_bonus),A	; gfx_bonuses
	LD HL,(IXobj)
	INC HL
	INC HL			; +$02
	LD A,(HL)		; IX+$02 координата Х объекта
	ADD A,$08
	LD (object_bonus+$02),A	; координата Х объекта
	LD A,$0A
	LD (object_bonus+$01),A	; spr_bomb
	LD A,$08
	LD (object_bonus+$0C),A
	LD (object_bonus+$0D),A
	LD HL,$1002
	LD (object_bonus+$08),HL	; Ширина и высота
	LD HL,$0000
	LD (LA557),HL
	RET

handling_bird:
	LD HL,(IXobj)
	LD DE,$0004
	ADD HL,DE
	LD A,(HL)		; IX+$04
	CP $08
	JP NC,LA9BC_0
	INC (HL)		; IX+$04
	RET
LA9BC_0:
	CALL bomb_appear
	LD HL,(IXobj)
	LD DE,$0006
	ADD HL,DE
	LD A,(HL)		; IX+$06
	SUB $10
	AND $3F
	LD (LAA02+$01),A
	LD HL,(LAA7B)
	LD A,H
	AND A
	JP Z,LA9BC_1
	CALL LAA44
	JP LA9BC_2
LA9BC_1:
	LD B,$01
	LD A,(counter_misc)
	AND $03
	CALL Z,LAA7D
	CALL LAD69
	CALL LAFFC
	CALL check_margins
LA9BC_2:
	LD HL,(IXobj)
	LD DE,$0004
	ADD HL,DE
	LD A,(HL)		; IX+$04
	CP FieldSpriteLimit
	JP C,LA9BC_3
	LD HL,(IXobj)
	ld A,(HL)		; IX+$00
	or %10000000		; SET 7,(IX+$00)
	ld (HL),A		; IX+$00
	RET
LA9BC_3:
	CALL LAAD2
LAA02:
	LD C,$00
	LD HL,(IXobj)
	LD DE,$0006
	ADD HL,DE
	LD A,(HL)		; IX+$06
	SUB $10
	AND $3F
	XOR C
	AND $20
	JP Z,LA9BC_5
	;LD A,(IX+$13)
	;LD (IX+$13),A
	ld A,C
	and %00100000		; BIT 5,C
	JP Z,LA9BC_4
	LD A,$0E
	LD HL,(IXobj)
	INC HL		; +$01
	SUB (HL)		; IX+$01
	JP LA9BC_5
LA9BC_4:
	LD HL,(IXobj)
	INC HL		; +$01
	LD A,(HL)		; IX+$01
	XOR $07
	ADD A,$07
LA9BC_5:
	LD A,(flag_2)
	AND A
	JP NZ,LAA7D_1
	RET

; Обработка взрыва врага
handling_blast:
  LD HL,(IXobj)
  LD DE,$0013
  ADD HL,DE
  LD (HL),$90		; IX+$13
  CALL LAAD2
  LD HL,(IXobj)
  INC HL		; IX+$01
  LD A,(HL)
  AND $3F
  CP $09
  RET NZ
  LD HL,(IXobj)
  LD A,(HL)		; IX+$00
  or %10000000		; SET 7,(IX+$00)
  LD (HL),A
  RET

; Used by the routines at handling_ufo and handling_bird.
LAA44:
  LD A,L
  CP $10
  JP NC,LAA44_0
  LD L,$10
  LD (LAA7B),HL
LAA44_0:
  PUSH HL
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  LD A,(HL)
  POP HL
  CP L
  JP Z,LAA44_2
  JP C,LAA44_1
  PUSH HL
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  DEC (HL)
  DEC (HL)
  POP HL
LAA44_1:
  PUSH HL
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  INC (HL)
  POP HL
LAA44_2:
  PUSH HL
  LD HL,(IXobj)
  LD DE,$0004
  ADD HL,DE
  LD A,(HL)
  POP HL
  CP H
  JP Z,LAA44_4
  JP C,LAA44_3
  PUSH HL
  LD HL,(IXobj)
  LD DE,$0004
  ADD HL,DE
  DEC (HL)
  POP HL
  RET
LAA44_3:
  PUSH HL
  LD HL,(IXobj)
  LD DE,$0004
  ADD HL,DE
  INC (HL)
  POP HL
  RET
LAA44_4:
  PUSH HL
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  LD A,(HL)
  POP HL
  CP L
  RET NZ
  LD HL,$0000
  LD (LAA7B),HL
  RET

LAA7B:
  DEFW $0000

; Used by the routines at handling_ufo and handling_bird.
LAA7D:
  LD HL,(IXobj)
  LD DE,$0006
  ADD HL,DE
  LD A,(HL)		; IX+$06
  LD C,A		; C = saved (IX+$06), was LD L,A
  LD HL,(IXobj)
  LD DE,$0014
  ADD HL,DE
  SUB (HL)		; A = (IX+$06) - (IX+$14)
  JP Z,LAA7D_1
  and %00100000		; BIT 5,A
  LD A,B
  JP NZ,LAA7D_0
  XOR A
  SUB B			; A = -B, replaces NEG (no Z80 NEG on i8080)
LAA7D_0:
  ADD A,C		; was ADD A,L
  AND $3F
  LD HL,(IXobj)
  LD DE,$0006
  ADD HL,DE
  LD (HL),A		; IX+$06
  RET
; This entry point is used by the routines at handling_ufo and handling_bird.
LAA7D_1:
  LD A,(random_number)
  AND $3F
  PUSH AF
  LD HL,(IXobj)
  LD DE,$0014
  ADD HL,DE
  POP AF
  LD (HL),A		; IX+$14
  RET

; Used by the routine at get_bonus.
; Получение бонуса ракеты
get_rocket:
  LD A,$06
  LD (object_rocket),A
  XOR A
  LD (object_rocket+$11),A
  PUSH HL
  LD HL,(IYobj)
  LD DE,$000C
  ADD HL,DE
  LD A,(HL)		; IY+$0C
  POP HL
  CP $1C
  LD A,$04
  JP Z,LAA9D_0
  LD A,$0C
LAA9D_0:
  PUSH HL
  LD HL,(IYobj)
  INC HL
  INC HL		; +$02
  ADD A,(HL)		; IY+$02
  POP HL
  LD (object_rocket+$02),A
  PUSH HL
  LD HL,(IYobj)
  LD DE,$0004
  ADD HL,DE
  LD A,(HL)		; IY+$04
  POP HL
  ADD A,$06
  LD (object_rocket+$04),A
  LD HL,$0000
  LD (LA8CF),HL
  PUSH HL
  LD HL,(IYobj)
  LD DE,$0014
  ADD HL,DE
  INC (HL)		; IY+$14
  POP HL
  RET

; Used by the routines at handling_bat, handling_bullet, handling_ufo, handling_bird and handling_blast.
LAAD2:
  LD HL,(IXobj)
  LD DE,$0012
  ADD HL,DE
  LD A,(HL)		; IX+$12
  LD B,A		; B = saved original (IX+$12)
  SUB $40
  JP NC,LAAD2_1
  LD HL,(IXobj)
  INC HL		; IX+$01
  LD A,(HL)
  AND $3F
  INC A
  LD C,A		; C = frame count (was E)
  LD HL,(IXobj)
  LD DE,$0013
  ADD HL,DE
  LD A,(HL)		; IX+$13
  LD E,A		; E = saved (IX+$13) (was D)
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  CP C
  JP NC,LAAD2_0
  LD A,E
  AND $0F
  LD C,A
LAAD2_0:
  LD HL,(IXobj)
  INC HL		; IX+$01
  LD (HL),C
  LD A,B
  ADD A,A
  ADD A,A
  AND $C0
  OR B			; B still = original (IX+$12), unchanged since read above
  push AF	; save A
  CALL calc_write_spr_addr
  pop AF	; restore A
LAAD2_1:
  LD HL,(IXobj)
  LD DE,$0012
  ADD HL,DE
  LD (HL),A		; IX+$12
  RET

; Used by the routines at set_bonus, enemy_prepare, get_bonus, handling_rocket, handling_spark and LAAD2.
; Вычисляет спрайт из IX+0 и IX+1, и записывает его размер в IX+$08 и IX+9
calc_write_spr_addr:
  LD HL,(IXobj)      ; sprite_search needs HL = object ptr (reads IX+00 and IX+01)
  CALL sprite_search ; returns DE = sprite data ptr, HL clobbered
  LD A,(DE)
  PUSH DE            ; save sprite ptr
  LD HL,(IXobj)
  LD DE,$0008
  ADD HL,DE          ; HL = IXobj+$08
  POP DE
  LD (HL),A          ; (IX+$08) = sprite width
  INC DE
  INC HL
  LD A,(DE)
  LD (HL),A          ; (IX+$09) = sprite height
  RET

; Used by the routines at handling_ball and LAB1F.
set_sound_bat_beat:
  push HL
  CALL get_free_sound_slot
  ld (HL),sound_bat_beat
  pop HL
  RET

; Used by the routine at handling_ball.
LAB1F:
  LD HL,(IXobj)
  LD DE,$0004
  ADD HL,DE
  LD A,(HL)		; IX+$04
  CP $A0
  RET C
  LD HL,(IXobj)
  LD DE,$000F
  ADD HL,DE
  LD A,(HL)		; IX+$0F
  CP $B2
  RET NC
  LD HL,object_bat_1
  LD (IYobj),HL
  CALL obj_compare
  JP C,LAB1F_0
  LD A,(game_mode)
  CP $02
  RET NZ
  LD HL,object_bat_2
  LD (IYobj),HL
  CALL obj_compare
  RET NC
LAB1F_0:
  LD HL,(IXobj)
  LD DE,$0012
  ADD HL,DE
  LD A,(HL)
  AND $7F
  LD (HL),A		; замена RES 7,(HL) (IX+$12)
  LD HL,(IYobj)
  INC HL
  INC HL		; +$02
  LD A,(HL)
  AND $80		; BIT 7,(HL) (IY+$02)
  JP Z,LAB1F_1
  LD HL,(IXobj)
  LD DE,$0012
  ADD HL,DE
  LD A,(HL)
  OR $80
  LD (HL),A		; замена SET 7,(HL) (IX+$12)
LAB1F_1:
  CALL set_sound_bat_beat
  LD HL,(IYobj)
  LD DE,$0014
  ADD HL,DE
  LD A,(HL)		; IY+$14
  CP $03
  JP NZ,LAB1F_4
  LD HL,(IYobj)
  LD DE,$000C
  ADD HL,DE
  LD A,(HL)		; IY+$0C
  CP $1C
  JP NZ,LAB1F_4
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  LD A,(HL)		; IX+$02
  PUSH HL
  LD HL,(IYobj)
  INC HL
  INC HL		; +$02
  SUB (HL)		; IY+$02
  POP HL
  JP NC,LAB1F_2
  XOR A
LAB1F_2:
  AND $FC
  CP $19
  JP C,LAB1F_3
  LD A,$18
LAB1F_3:
  LD B,A
  LD HL,(IXobj)
  LD DE,$0015
  ADD HL,DE
  LD A,(HL)		; IX+$15
  AND $80
  OR B
  LD (HL),A		; IX+$15
  LD HL,(IXobj)
  LD DE,$0014
  ADD HL,DE
  LD (HL),$B0		; IX+$14
  LD HL,(IXobj)
  LD DE,$0004
  ADD HL,DE
  LD (HL),$AF		; IX+$04
  RET
LAB1F_4:
  LD HL,(IXobj)
  LD DE,$0004
  ADD HL,DE
  LD (HL),$AE		; IX+$04
  LD HL,(IXobj)
  LD DE,$0012
  ADD HL,DE
  LD A,(HL)		; IX+$12
  AND $80
  LD (HL),A		; IX+$12
  LD HL,(IYobj)
  LD DE,$000C
  ADD HL,DE
  LD A,(HL)		; IY+$0C
  LD HL,LABEE
  CP $1C
  JP Z,LAB1F_5
  LD HL,LABFC
LAB1F_5:
  PUSH HL
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  LD A,(HL)		; IX+$02
  POP HL
  ADD A,$03
  PUSH HL
  LD HL,(IYobj)
  INC HL
  INC HL		; +$02
  SUB (HL)		; IY+$02
  POP HL
  JP C,LAB1F_7
LAB1F_6:
  CP (HL)
  JP C,LAB1F_7
  INC HL
  INC HL
  JP LAB1F_6
LAB1F_7:
  INC HL
  LD A,(HL)
  LD B,A
  AND $04		; замена BIT 2,A
  LD A,B		; preserve table index while retaining test flags
  JP NZ,LAB1F_8
  JP LAB1F_10
LAB1F_8:
  CALL LAB1F_9
  LD A,(HL)
  CALL LAB1F_10
LAB1F_9:
  PUSH HL		; caller's HL (table walk ptr) must survive this call
  LD HL,(IXobj)
  LD DE,$0006
  ADD HL,DE
  LD A,(HL)		; IX+$06
  XOR $1F
  INC A
  AND $3F
  LD (HL),A		; IX+$06
  POP HL
  RET
LAB1F_10:
  AND $03
  LD B,A
  ADD A,A		; *2
  ADD A,B		; *3
  LD HL,LAC0A
  CALL hl_add_2a
  LD A,$04
LAB1F_11:
  PUSH HL
  LD HL,(IXobj)
  LD DE,$0006
  ADD HL,DE
  CP (HL)		; IX+$06
  POP HL
  JP Z,LAB1F_12
  INC HL
  ADD A,$04
  CP $10
  JP NZ,LAB1F_11
  ADD A,$04
  JP LAB1F_11
LAB1F_12:
  LD A,(HL)
  PUSH HL
  LD HL,(IXobj)
  LD DE,$0006
  ADD HL,DE
  LD (HL),A		; IX+$06
  POP HL
  RET

LABEE:
  DEFB $04,$07,$08,$06,$0C,$05,$10,$00
  DEFB $14,$01,$18,$02,$FF,$03
LABFC:
  DEFB $06,$07,$0C,$06,$12,$05,$1A,$00
  DEFB $20,$01,$26,$02,$FF,$03
LAC0A:
  DEFB $3C,$38,$34,$2C,$28,$24,$3C,$38
  DEFB $34,$34,$34,$34,$3C,$38,$38,$34
  DEFB $38,$38,$3C,$3C,$38,$38,$3C,$3C

; Used by the routines at handling_ball, get_bonus and LAB1F.
; Сравнивает координаты двух объектов, заданных в IX и IY
; Без захлёста
obj_compare:
  LD HL,(IXobj)
  INC HL
  INC HL
  LD E,(HL)	; temp = IX+$02
  LD HL,(IYobj)
  INC HL
  INC HL
  LD A,(HL)	; IY+$02: Координата Х для печати
  LD HL,(IXobj)
  PUSH DE
  LD DE,12
  ADD HL,DE
  POP DE
  LD C,(HL)	; IX+$0C: Ширина объекта без тени в пикселях
  LD HL,(IYobj)
  PUSH DE
  LD DE,12
  ADD HL,DE
  POP DE
  LD B,(HL)	; IY+$0C: Ширина объекта без тени в пикселях
  LD L,E	; L = IX+$02: Координата Х для печати
  CALL LAC22_0
  RET NC
  LD HL,(IXobj)
  INC HL
  INC HL
  INC HL
  INC HL
  LD E,(HL)	; temp = IX+$04
  LD HL,(IYobj)
  INC HL
  INC HL
  INC HL
  INC HL
  LD A,(HL)	; IY+$04: Координата Y для печати
  LD HL,(IXobj)
  PUSH DE
  LD DE,13
  ADD HL,DE
  POP DE
  LD C,(HL)	; IX+$0D: Высота объекта без тени в пикселях
  LD HL,(IYobj)
  PUSH DE
  LD DE,13
  ADD HL,DE
  POP DE
  LD B,(HL)	; IY+$0D: Высота объекта без тени в пикселях
  LD L,E	; L = IX+$04: Координата Y для печати
LAC22_0:
  SUB L			; X IY минус X IX
  JP C,LAC22_1	; Переход, если X IX больше X IY
  SUB C			; и отнимаем от расстояния между X IY и X IX ширину IX
  RET
LAC22_1:
  ADD A,B		; и добавляем расстоянию между X IY и X IX ширину IY
  RET

; Used by the routines at kill_enemy_by_bat, handling_bullet and get_bonus.
; Сравнивает координаты двух объектов, заданных в IX и IY
; С захлёстом в 2 пикселя
obj_compare_2pix:
  LD HL,(IXobj)
  INC HL
  INC HL
  LD E,(HL)	; temp = IX+$02
  LD HL,(IYobj)
  INC HL
  INC HL
  LD A,(HL)	; IY+$02: Координата Х для печати
  LD HL,(IXobj)
  PUSH DE
  LD DE,12
  ADD HL,DE
  POP DE
  LD C,(HL)	; IX+$0C: Ширина объекта без тени в пикселях
  LD HL,(IYobj)
  PUSH DE
  LD DE,12
  ADD HL,DE
  POP DE
  LD B,(HL)	; IY+$0C: Ширина объекта без тени в пикселях
  LD L,E	; L = IX+$02: Координата Х для печати
  CALL LAC45_0
  RET NC
  LD HL,(IXobj)
  INC HL
  INC HL
  INC HL
  INC HL
  LD E,(HL)	; temp = IX+$04
  LD HL,(IYobj)
  INC HL
  INC HL
  INC HL
  INC HL
  LD A,(HL)	; IY+$04: Координата Y для печати
  LD HL,(IXobj)
  PUSH DE
  LD DE,13
  ADD HL,DE
  POP DE
  LD C,(HL)	; IX+$0D: Высота объекта без тени в пикселях
  LD HL,(IYobj)
  PUSH DE
  LD DE,13
  ADD HL,DE
  POP DE
  LD B,(HL)	; IY+$0D: Высота объекта без тени в пикселях
  LD L,E	; L = IX+$04: Координата Y для печати
LAC45_0:
  SUB L			; X IY минус X IX
  JP C,LAC45_1	; Переход, если X IX больше X IY
  DEC C			; Иначе уменьшаем ширину IX на 2
  DEC C
  SUB C			; и отнимаем от расстояния между X IY и X IX ширину IX
  RET
LAC45_1:
  DEC B			; Уменьшаем ширину IY на 2
  DEC B
  ADD A,B		; и добавляем расстоянию между X IY и X IX ширину IY
  RET

; Used by the routines at handling_bat, handling_ball, handling_ufo and handling_bird.
; Не даёт объекту выйти за пределы поля
check_margins:
  CALL check_top_margin
  CALL check_left_margin
  JP check_right_margin

; Used by the routines at handling_ball and handling_spark.
; Отскок от стенки
bounce_wall:
  LD B,$3F
  CALL check_top_margin
  CALL C,change_direction
  LD B,$1F
  CALL check_left_margin
  CALL C,change_direction
  CALL check_right_margin
  RET C
  JP change_direction

;---------------------------
; Нигде неиспользуемый код Мусор?
; Data block at AC8C
;   LD A,(IX+$04)
;   CP $AF
;   RET C
;   LD (IX+$04),$AF
;   RET
;---------------------------

; Used by the routines at check_margins and bounce_wall.
; Проверка, чтобы содержимое IX+$04 не опускалось ниже $08
; Упираемся объектом в верхний край экрана
check_top_margin:
	ld HL,(IXobj)
	ld DE,$0004
	add HL,DE
	LD A,(HL)		; IX+$04
	CP $08
	RET NC
	LD (HL),$08		; IX+$04
	RET

; Used by the routines at handling_bat, handling_400pts, check_margins and bounce_wall.
; Проверка, чтобы содержимое IX+$02 не опускалось ниже $08
; Упираемся объектом в левый край экрана
check_left_margin:
	ld HL,(IXobj)
	inc HL
	inc HL
	LD A,(HL)		; IX+$02
	CP $08
	RET NC
	LD (HL),$08		; IX+$02
	RET

; Used by the routine at game_restart.
; Проверка, чтобы содержимое IX+$02 не опускалось ниже $80.
; Если было ниже, то сброс 0 бита IX+$01
; Вход: (IXobj) = адрес объекта
LACAD:
	ld HL,(IXobj)
	inc HL
	inc HL
	ld A,(HL)		; IX+$02
	CP $80
	RET NC
	ld (HL),$80		; IX+$02
	dec HL
	ld A,(HL)		; IX+$01
	and %11111110		; RES 0,(IX+$01)
	ld (HL),A		; IX+$01
	RET

; Used by the routines at handling_bat, handling_400pts, check_margins and bounce_wall.
; Упираемся объектом в правый край экрана
check_right_margin:
	ld HL,(IXobj)
	inc HL
	inc HL
	ld (check_right_margin_3+1),HL
	ld A,(HL)		; IX+$02
	ld DE,$0C-$02
	add HL,DE
	ADD A,(HL)		; Складываем значение IX+$0C и IX+$02
	CP $F9
	RET C			; Возвращаемся, если сумма меньше $F9
	LD A,$F8
	SUB (HL)		; IX+$0C
check_right_margin_3:
	LD ($0002),A		; Иначе помещаем в IX+$02 значение $F8 - IX+$0C
	RET

; Used by the routine at game_restart.
; Вход: (IXobj)
LACCE:
  LD HL,(IXobj)
  LD DE,$000C
  ADD HL,DE
  LD A,(HL)		; IX+$0C
  PUSH HL
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  ADD A,(HL)		; IX+$02
  POP HL
  CP $80
  RET C
  LD A,$80
  SUB (HL)		; IX+$0C
  PUSH HL
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  LD (HL),A		; IX+$02
  POP HL
  LD A,(HL)		; IX+$0C
  CP $1C
  JP Z,LACCE_0
  CP $2C
  RET NZ
LACCE_0:
  LD HL,(IXobj)
  INC HL		; +$01
  ld A,(HL)		; IX+$01
  or $01		; SET 0,(IX+$01)
  ld (HL),A		; IX+$01
  RET

; Used by the routines at bounce_wall and LAFFC.
; Изменение направления в зависимости от B
change_direction:
  LD HL,(IXobj)
  LD DE,$0006
  ADD HL,DE
  LD A,(HL)		; IX+$06 направление полёта шарика
  XOR B
  INC A
  AND $3F
  LD (HL),A		; IX+$06 направление полёта шарика
  RET

; Used by the routine at LAD13.
LACF9:
  LD HL,(IXobj)
  LD DE,$0007
  ADD HL,DE
  LD D,(HL)		; IX+$07
  LD H,$00
  LD B,H
  LD L,H
  ; Game objects normally use speed 1..3. Avoid the shift/add loop for
  ; these small multipliers; the generic path still accepts all byte values.
  LD A,D
  CP $04
  JP NC,LAD04_0
  OR A
  RET Z
  LD L,C
  DEC D
  JP Z,lacf9_small_done
  ADD HL,BC
  DEC D
  JP Z,lacf9_small_done
  ADD HL,BC
  DEC D
lacf9_small_done:
  XOR A
  RET
LAD04:
  ; The remaining multiplier is normally 0 after only two or three bits.
  LD A,D
  OR A
  RET Z
  LD A,C
  ADD A,A
  LD C,A		; замена SLA C
  LD A,B
  RLA			; замена RL B (перенос от SLA C выше)
  LD B,A
LAD04_0:
  LD A,D
  OR A
  RRA
  LD D,A		; замена SRL D
  JP NC,LAD04
  ADD HL,BC
  JP LAD04

; Used by the routine at LAD69.
LAD13:
  PUSH BC
  CALL LACF9
  POP BC
  INC B
  RET NZ

  LD A,L
  CPL
  LD L,A
  LD A,H
  CPL
  LD H,A	; CPL HL

  INC HL
  RET

; Used by the routine at LAD69.
; Высчитываются значения HL и BC по таблице, а зависимости от направления движения
hl_bc_calc_direction:
	LD HL,(IXobj)
	LD DE,$0006
	ADD HL,DE
	LD A,(HL)		; IX+$06 Направление
	LD D,A		; hl_add_a preserves DE; retain the quadrant here
	AND $0F
	LD B,A
	LD HL,direction_table
	CALL hl_add_a
	LD C,(HL)		; C = YY из таблицы, в зависимости от направления
	LD A,B
	XOR $0F
	INC A
	LD HL,direction_table
	CALL hl_add_a
	LD L,(HL)		; L = XX из таблицы, в зависимости от направления

	LD H,$00		; HL = $00XX, BC = $00YY
	LD B,H
	LD A,D
	LD D,$00		; keep the original DE=$0006 result
	AND $30
	RET Z			; Если направление $00, то HL = $00XX, BC = $00YY

	CP $10
	JP NZ,LAD22_0
	LD A,L
	LD L,C
	LD C,A
	DEC B
	RET			; Если направление $10, то HL = $00YY, BC = $FFXX

LAD22_0:
	CP $20
	JP NZ,LAD22_1
	DEC H
	DEC B
	RET			; Если направление $20, то HL = $FFXX, BC = $FFYY

LAD22_1:
	LD A,C
	LD C,L
	LD L,A
	DEC H
	RET			; Если направление $30, то HL = $FFYY, BC = $00XX

; Из этой таблицы в зависимости от направления движения выбираются значения для HL и BC
direction_table:
  DEFB $FF,$FD,$FA,$F4,$E6,$E0,$D4,$C5
  DEFB $B4,$A1,$8D,$78,$61,$4A,$31,$18

  DEFB $00

; Used by the routines at handling_ball, handling_spark, handling_ufo and handling_bird.
LAD69:
 ; Returns HL=object+5, DE=new Y, carry clear; A/BC are scratch.
 CALL hl_bc_calc_direction
 PUSH HL
 CALL LAD13
 ; Coordinates are big-endian fixed-point pairs: add low, then ADC high.
 EX DE,HL
 LD HL,(IXobj)
 INC HL
 INC HL
 INC HL
 LD A,(HL)
 ADD A,E
 LD (HL),A
 LD E,A
 DEC HL
 LD A,(HL)
 ADC A,D
 LD (HL),A
 LD D,A
 INC HL
 POP BC
 CALL LAD13
 EX DE,HL
 LD HL,(IXobj)
 LD BC,$0005
 ADD HL,BC
 LD A,(HL)
 ADD A,E
 LD (HL),A
 LD E,A
 DEC HL
 LD A,(HL)
 ADC A,D
 LD (HL),A
 LD D,A
 INC HL
 SCF
 CCF
 RET

; Used by the routine at all_metal_briks_animation_snd.
; Печатает текущий кадр анимации перелива всех металлических кирпичей
; На входе в IX адрес текущего кадра анимации (IX - anim_brik)
all_metal_briks_frame:
	LD HL,(current_level_addr)
	LD (cur_level_ptr),HL
	LD HL,zx_scr+$00E0 ; Адрес в экранной области начала рисования кирпичей
	LD B,$0C
LAD8F_0:
	PUSH BC
	PUSH HL
	CALL line_metal_briks_frame
	POP HL
	ld a,$f8 ;LD A,$08	; поправка для Вектора
	ADD L
	LD L,A
LAD8F_1:
	POP BC
	dec B
	jp nz,LAD8F_0
	RET

; Used by the routine at all_metal_briks_frame.
; Печатает одну строку текущего кадра металлических кирпичей
line_metal_briks_frame:
	LD B,$0F
LADAC_0:
	PUSH BC
	PUSH HL
	CALL print_frame_metal_brik
	POP HL
	INC H
	INC H
	POP BC
	PUSH HL
	LD HL,(cur_level_ptr)
	INC HL
	LD (cur_level_ptr),HL
	POP HL
	dec B
	jp nz,LADAC_0
	RET

; Used by the routine at line_metal_briks_frame.
; Рисует текущий кадр одного металлического кирпича, если это он
; В IX указатель на текущий спрайт анимации перелива кирпича
; В HL - адрес в экранной области
print_frame_metal_brik:
 push hl
 ld hl,(cur_level_ptr)
 ld a,(hl)
 pop hl
 and $90
 ret nz
 ; Select the same frame; the black brick has a special last frame.
 push hl
 ld a,h
 sub $c0
 add a,scr_buff/256
 inc a
 ld d,a
 ld a,$e0
 sub l
 rrca
 rrca
 rrca
 and $1f
 or $c0
 ld e,a
 call NativeReadDE
 ld hl,(anim_brik_ptr)
 or a
 jp nz,pm_frame
 ld de,anim_brik+$0e
 call SBCHLDE8080
 ld hl,(anim_brik_ptr)
 jp nz,pm_frame
 ld hl,anim_brik_black
pm_frame:
 ld e,(hl)
 inc hl
 ld d,(hl)
 pop hl
 call NativeCpcPrepareAnimation
 ld b,8
pm_row:
 ld a,(de)
 call NativeCpcScreenWrite
 inc de
 inc h
 ld a,(de)
 call NativeCpcScreenWrite
 inc de
 dec h
 dec l
 dec b
 jp nz,pm_row
 ret

; Used by the routine at game_screen_draw_to_buffer.
; Вывод в буфер всех кирпичей уровня
print_briks:
	LD HL,(current_level_addr)
	LD (cur_level_ptr),HL
	LD HL,scr_buff+$0120	; Адрес начала кирпичей в буфере (было scr_buff+$401)
	LD (brik_addr_buf),HL
	LD HL,attr_buff+$0205	; Адрес начала атрибутов кирпичей в буфере (было attr_buff+$A2)
	LD (brik_attr_buf),HL
	LD B,$0C		; Высота уровня
LADE1_0:
	PUSH BC
	LD HL,(cur_level_ptr)
	PUSH HL			; замена PUSH IY
	CALL print_line_briks
	POP HL
	LD (cur_level_ptr),HL	; замена POP IY

;   IFDEF MX
; 	CALL brik_shadow
;   ELSE
	ld b,$0f
LADE1_01:
	LD HL,(cur_level_ptr)
	INC HL
	LD (cur_level_ptr),HL	; замена inc iy
	dec B
	jp nz,LADE1_01
;   ENDIF

	LD HL,(brik_addr_buf)
	ld a,l
	add $08
	ld l,a
	LD (brik_addr_buf),HL
	LD HL,(brik_attr_buf)
	inc l
	LD (brik_attr_buf),HL
	POP BC
	dec B
	jp nz,LADE1_0
	RET

; Used by the routine at print_briks.
print_line_briks:
	LD B,$0F	; Ширина уровня
	LD HL,(brik_addr_buf)
LAE13_0:
	PUSH BC
	PUSH HL
	PUSH HL
	LD HL,(cur_level_ptr)
 call NativeReadHL ; IY+$00
	POP HL
	or A		; BIT 7,(IY+$00)
	CALL P,print_one_brik_buf	; 	Печатаем кирпич, если не пустота
	POP HL
	INC H
	INC H
	PUSH HL
	LD HL,(cur_level_ptr)
	INC HL
	LD (cur_level_ptr),HL	; замена INC IY
	POP HL
	POP BC
	dec B
	jp nz,LAE13_0
	RET

; Used by the routine at print_briks.
;   IFDEF MX
; brik_shadow:
; 	LD B,$0F
; 	LD HL,(brik_attr_buf)
; brik_shadow_0:
; 	ld A,(IY+$00)
; 	or A		; BIT 7,(IY+$00)
; 	JP M,brik_shadow_1
; 	ld a,(hl)
; 	and %01110111
; 	ld (hl),a
; 	inc h
; ; Проверка на правый крайний столбец - обрамление поля
; 	ld a,h
; 	sub attr_buff/$100
; 	CPL
; 	AND $1F
; 	JP Z,brik_shadow_1
; 	ld a,(hl)
; 	and %01110111
; 	ld (hl),a
; 	JP brik_shadow_2
; brik_shadow_1:
; 	inc h
; brik_shadow_2:
; 	inc h
; 	INC IY
; 	dec B
; 	jp nz,brik_shadow_0
; 	RET
;   ENDIF

;-----------------------------------------------

; Used by the routine at print_line_briks.
; Печатает один цветной кирпич в буфер
; В HL - координаты кирпича
; В IY - ссылка не текущий код кирпича
print_one_brik_buf:
 jp NativePrintBrick

; Цвета кирпичей
briks_colors:
	DEFB $50,$C0,$30,$60,$F0	; Цвета обычных кирпичей
	DEFB $20,$50,$40,$C0		; Серый металл и цветные трудновыбиваемые кирпичи
	DEFB $D0			; Не используется
	DEFB $20,$50,$C0,$40		; Серый металл и цветные невыбиваемые кирпичи
	DEFB $D0			; Не используется

; Хранит адреса пикселей и атрибутов в буфере текущего кирпича
brik_addr_buf:
	DEFW $0000
brik_attr_buf:
	DEFW $0000

; Графика кирпичей
  INCLUDE "./gfx/briks.asm"

; Анимация переливания кирпича
anim_brik:
	DEFW spr_brik_2
	DEFW spr_brik_6
	DEFW spr_brik_3
	DEFW spr_brik_7
	DEFW spr_brik_4
	DEFW spr_brik_5
	DEFW spr_brik_5
	DEFW spr_brik_1
	DEFW $0000

	; Индивидуальная обработка чёрного кирпича
;   IFDEF MX
; 	; Ничего не делаем
;   ELSE
anim_brik_black:
	DEFW spr_brik_black
	DEFW $0000
;   ENDIF


; Used by the routine at LBBFB.
; Добавляет двум игрокам поровну очки за оставшиеся на раунде кирпичи
add_points_for_left_briks:
  LD HL,(current_level_addr)
  LD (cur_level_ptr),HL
  XOR A
  LD (brik_value+$01),A
  LD (need_change_player),A
  LD C,$0C		; Высота раунда
add_points_for_left_briks_0:
  LD B,$0F		; Ширина раунда
add_points_for_left_briks_1:
  PUSH BC
  PUSH BC
  LD HL,(cur_level_ptr)
  LD A,(HL)		; IY+$00
  POP BC
  AND $A0
  JP NZ,add_points_for_left_briks_2	; Если пустое место, то пропускаем

  CALL points_calc_and_add
  CALL scr_score_update
  LD A,(need_change_player)
  XOR $01
  LD (need_change_player),A

add_points_for_left_briks_2:
  CALL play_sounds_queue
  LD D,$03
  CALL pause_short
  LD HL,(cur_level_ptr)
  INC HL
  LD (cur_level_ptr),HL	; замена INC IY (PUSH/POP IY больше не нужны)
  POP BC
  dec B
  jp nz,add_points_for_left_briks_1
  LD A,(brik_value+$01)
  INC A
  LD (brik_value+$01),A
  DEC C
  JP NZ,add_points_for_left_briks_0
  RET

; Used by the routines at add_points_for_left_briks and LAFFC.
; Вычисляет сколько очков добавлять исходя из значения brik_value+$01
points_calc_and_add:
  LD A,(brik_value+$01)
  LD HL,points_table
  CALL hl_add_2a
  LD B,(HL)
  INC HL
  LD C,(HL)			; В BC нужное количество очков
  PUSH BC
  LD HL,(cur_level_ptr)
  LD A,(HL)			; IY+$00 текущий элемент уровня
  POP BC
  AND $0F
  CP $06			; Если цвет меньше 6 (то есть обычный кирпич), то
  JP C,add_points_to_score	; добавляем одинарное количество очков
  LD A,C
  ADD A,C
  DAA
  LD C,A
  LD A,B
  ADC A,B
  DAA
  LD B,A
  JP add_points_to_score	; Добавляем двойное количество очков

; Таблица добавления очков
points_table:
	DEFB $01,$20	;120
	DEFB $01,$10	;110
	DEFB $01,$00	;100
	DEFB $00,$90	; 90
	DEFB $00,$80	; 80
	DEFB $00,$70	; 70
	DEFB $00,$60	; 60
	DEFB $00,$50	; 50
	DEFB $00,$40	; 40
	DEFB $00,$30	; 30
	DEFB $00,$20	; 20
	DEFB $00,$10	; 10

; Used by the routines at handling_ball, handling_bullet, handling_ufo and handling_bird.
LAFFC:
  XOR A
  LD (flag_2),A
  PUSH HL
  LD HL,(IXobj)
  LD DE,$0004
  ADD HL,DE
  LD A,(HL)		; IX+$04
  LD (laffc_row_y+1),A
  POP HL
  CP $80
  RET NC
  PUSH HL
  LD HL,(IXobj)
  LD DE,$000D
  ADD HL,DE
  ADD A,(HL)		; IX+$0D
  POP HL
  CP $20
  RET C
  ; First intersecting row = max(0, (Y-33)/8), inclusive bottom edge.
  ; Entry tests already reject Y>=128 and wrapped end<32.
  ld b,a
  ld a,(laffc_row_y+1)
  cp $21
  jp c,native_row_top
  sub $21
  rrca
  rrca
  rrca
  and $0f
  jp native_row_index
native_row_top:
  ld a,b
  cp $21
  jp c,native_row_miss
  xor a
native_row_index:
  ld e,a
  rlca
  rlca
  rlca
  rlca
  sub e
  ld hl,(current_level_addr)
  call hl_add_a
  ld (cur_level_ptr),hl
  ld h,e
  ld a,e
  rlca
  rlca
  rlca
  add a,$20
  ld c,a
  jp LAFFC_3
native_row_miss:
  ld hl,(current_level_addr)
  ld a,$b4
  call hl_add_a
  ld (cur_level_ptr),hl
  ld b,0
  ret
; Cached operands are also read by the native selector.
laffc_row_y:
  sub $00

LAFFC_3:
  LD A,H
  LD (brik_value+$01),A
  LD HL,(IXobj)
  LD DE,$0004
  ADD HL,DE
  LD A,(HL)		; IX+$04
  PUSH AF
  LD HL,(IXobj)
  LD DE,$000D
  ADD HL,DE
  POP AF
  ADD A,(HL)		; IX+$0D
  SUB C
  LD (LB087+$01),A
  LD H,C
  PUSH HL
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  LD A,(HL)		; IX+$02
  POP HL
  ; Compute the column and signed overlap from (X-8), modulo 256.
  sub 8
  ld l,a
  rrca
  rrca
  rrca
  rrca
  and $0f
  ld e,a
  ld a,l
  and $0f
  or $f0
  ld (LB069+1),a
  ld a,l
  and $f0
  add a,8
  ld l,a
  push hl
  ld hl,(cur_level_ptr)
  ld a,e
  call hl_add_a
  ld (cur_level_ptr),hl
  pop hl

native_column_ready:
  LD D,$0F

  PUSH HL
  LD HL,(cur_level_ptr)
  LD A,(HL)		; IY+$00
  POP HL
  or A		; BIT 7,(IY+$00)
  JP P,LAFFC_7
  LD A,L
  CP $E8
  JP Z,LAFFC_6
  PUSH HL
  LD HL,(IXobj)
  LD BC,$000C
  ADD HL,BC
  LD A,(HL)		; IX+$0C
  POP HL
LB069:
  ADD A,$00
  JP NC,LAFFC_6
  PUSH AF
  LD A,D
  OR $80
  LD D,A		; замена SET 7,D
  POP AF
  LD E,L
  LD A,$10
  ADD A,L
  LD L,A
  PUSH HL
  LD HL,(cur_level_ptr)
  INC HL
  LD (cur_level_ptr),HL
  POP HL
  PUSH HL
  LD HL,(cur_level_ptr)
  LD A,(HL)		; IY+$00
  POP HL
  or A		; BIT 7,(IY+$00)
  JP P,LAFFC_7
  LD L,E
  PUSH HL
  LD HL,(cur_level_ptr)
  DEC HL
  LD (cur_level_ptr),HL
  POP HL
LAFFC_6:
  LD A,H
  CP $78
  RET NC
  LD C,$08
  ADD A,C
  LD H,A
LB087:
  LD A,$00
  SUB C
  RET C
  PUSH HL
  LD HL,(cur_level_ptr)
  LD BC,$000F
  ADD HL,BC
  LD (cur_level_ptr),HL
  POP HL
  LD A,(brik_value+$01)
  INC A
  LD (brik_value+$01),A
  PUSH HL
  LD HL,(cur_level_ptr)
  LD A,(HL)		; IY+$00
  POP HL
  or A		; BIT 7,(IY+$00)
  JP P,LAFFC_7
  LD A,D
  AND $80		; замена BIT 7,D
  RET Z
  LD A,L
  ADD A,$10
  LD L,A
  PUSH HL
  LD HL,(cur_level_ptr)
  INC HL
  LD (cur_level_ptr),HL
  POP HL
  PUSH HL
  LD HL,(cur_level_ptr)
  LD A,(HL)		; IY+$00
  POP HL
  or A		; BIT 7,(IY+$00)
  RET M
LAFFC_7:
  LD (LB28F+$01),HL
  PUSH HL
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  LD A,(HL)		; IX+$02 -> new L
  PUSH AF
  LD HL,(IXobj)
  LD BC,$0004
  ADD HL,BC
  LD A,(HL)		; IX+$04 -> new H
  LD H,A
  POP AF
  LD L,A
  LD (LB1C3+$01),HL
  POP HL
  PUSH AF
  LD A,D
  AND $7F
  LD D,A		; замена RES 7,D
  POP AF
  LD A,L
  CP $E8
  JP Z,LAFFC_8
  PUSH HL
  LD HL,(cur_level_ptr)
  INC HL
  LD A,(HL)		; IY+$01
  POP HL
  AND $80		; BIT 7,(IY+$01)
  JP NZ,LAFFC_9
LAFFC_8:
  PUSH AF
  LD A,D
  AND $FD
  LD D,A		; замена RES 1,D
  POP AF
LAFFC_9:
  CP $08
  JP Z,LAFFC_10
  PUSH HL
  LD HL,(cur_level_ptr)
  DEC HL
  LD A,(HL)		; IY-$01
  POP HL
  AND $80		; BIT 7,(IY-$01)
  JP NZ,LAFFC_11
LAFFC_10:
  PUSH AF
  LD A,D
  AND $FE
  LD D,A		; замена RES 0,D
  POP AF
LAFFC_11:
  LD A,H
  CP $21
  JP C,LAFFC_12
  PUSH HL
  LD HL,(cur_level_ptr)
  LD BC,$FFF1
  ADD HL,BC
  LD A,(HL)		; IY-$0F
  POP HL
  AND $80		; BIT 7,(IY-$0F)
  JP NZ,LAFFC_12
  PUSH AF
  LD A,D
  AND $FB
  LD D,A		; замена RES 2,D
  POP AF
LAFFC_12:
  CP $78
  JP NC,LAFFC_13
  PUSH HL
  LD HL,(cur_level_ptr)
  LD BC,$000F
  ADD HL,BC
  LD A,(HL)		; IY+$0F
  POP HL
  AND $80		; BIT 7,(IY+$0F)
  JP NZ,LAFFC_13
  PUSH AF
  LD A,D
  AND $F7
  LD D,A		; замена RES 3,D
  POP AF
LAFFC_13:
  LD A,D
  LD (LB292+1),A
  PUSH HL
  LD HL,(IXobj)
  LD A,(HL)		; IX+$00
  POP HL
  AND $3F
  CP $05
  JP Z,LAFFC_29
  PUSH HL
  LD HL,(IXobj)
  LD BC,$0006
  ADD HL,BC
  LD A,(HL)		; IX+$06
  POP HL
  LD (smash_direction_value+1),A
  CP $20
  JP NC,LAFFC_14
  PUSH AF
  LD A,D
  AND $F7
  LD D,A		; замена RES 3,D
  POP AF
  JP LAFFC_15
LAFFC_14:
  PUSH AF
  LD A,D
  AND $FB
  LD D,A		; замена RES 2,D
  POP AF
LAFFC_15:
  ADD A,$10
  AND $3F
  CP $20
  JP NC,LAFFC_16
  PUSH AF
  LD A,D
  AND $FD
  LD D,A		; замена RES 1,D
  POP AF
  JP LAFFC_17
LAFFC_16:
  PUSH AF
  LD A,D
  AND $FE
  LD D,A		; замена RES 0,D
  POP AF
LAFFC_17:
  LD A,D
LAFFC_18:
  OR A
  RRA			; замена SRL A
  LD B,$1F
  JP NC,LAFFC_19
  OR A		; i8080 RRA leaves Z unchanged; test the shifted result
  JP Z,LAFFC_26
  JP LAFFC_21
LAFFC_19:
  OR A
  RRA			; замена SRL A
  JP NC,LAFFC_20
  OR A		; i8080 RRA leaves Z unchanged; test the shifted result
  JP Z,LAFFC_27
  JP LAFFC_21
LAFFC_20:
  LD B,$3F
  OR A
  RRA			; замена SRL A
  JP NC,LAFFC_29
  OR A		; i8080 RRA leaves Z unchanged; test the shifted result
  JP Z,LAFFC_28
LAFFC_21:
  LD A,D
  AND $01		; замена BIT 0,D
  JP Z,LAFFC_22
  PUSH BC
  PUSH HL
  LD HL,(IXobj)
  LD BC,$000C
  ADD HL,BC
  LD A,(HL)		; IX+$0C
  PUSH AF
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  POP AF
  ADD A,(HL)		; IX+$02
  POP HL
  POP BC
  SUB L
  JP LAFFC_23
LAFFC_22:
  LD A,L
  ADD A,$10
  PUSH HL
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  SUB (HL)		; IX+$02
  POP HL
LAFFC_23:
  LD C,A
  PUSH BC
  LD A,D
  AND $04		; замена BIT 2,D
  JP Z,LAFFC_24
  PUSH HL
  LD HL,(IXobj)
  LD BC,$000D
  ADD HL,BC
  LD A,(HL)		; IX+$0D
  PUSH AF
  LD HL,(IXobj)
  LD BC,$0004
  ADD HL,BC
  POP AF
  ADD A,(HL)		; IX+$04
  POP HL
  SUB H
  JP LAFFC_25
LAFFC_24:
  LD A,H
  ADD A,$08
  PUSH HL
  LD HL,(IXobj)
  LD BC,$0004
  ADD HL,BC
  SUB (HL)		; IX+$04
  POP HL
LAFFC_25:
  POP BC
  LD E,D
  CP C
  PUSH AF		; сохраняем флаги от CP C (RES не трогает флаги, AND трогает)
  LD A,D
  AND $F3		; замена RES 2,D + RES 3,D вместе
  LD D,A
  POP AF
  JP NC,LAFFC_17
  LD A,E
  AND $0C
  JP LAFFC_18
LAFFC_26:
  PUSH BC
  LD A,L
  PUSH HL
  LD HL,(IXobj)
  LD BC,$000C
  ADD HL,BC
  SUB (HL)		; IX+$0C
  POP HL
  PUSH HL
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  LD (HL),A		; IX+$02
  POP HL
  POP BC
  CALL change_direction
  JP LAFFC_30
LAFFC_27:
  LD A,L
  ADD A,$10
  PUSH HL
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  LD (HL),A		; IX+$02
  POP HL
  CALL change_direction
  JP LAFFC_30
LAFFC_28:
  PUSH BC
  LD A,H
  PUSH HL
  LD HL,(IXobj)
  LD BC,$000D
  ADD HL,BC
  SUB (HL)		; IX+$0D
  POP HL
  PUSH HL
  LD HL,(IXobj)
  LD BC,$0004
  ADD HL,BC
  LD (HL),A		; IX+$04
  POP HL
  POP BC
  CALL change_direction
  JP LAFFC_30
LAFFC_29:
  LD A,H
  ADD A,$08
  PUSH HL
  LD HL,(IXobj)
  LD DE,$0004
  ADD HL,DE
  LD (HL),A		; IX+$04
  POP HL
  CALL change_direction
  JP LAFFC_30
LAFFC_30:
  LD A,$01
  LD (flag_2),A
  PUSH HL
  LD HL,(IXobj)
  LD A,(HL)		; IX+$00
  POP HL
  AND $7F
  CP $02
  JP Z,LAFFC_32
  CP $05
  JP Z,LAFFC_31
  AND $FE
  CP $08
  RET NZ
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  LD E,(HL)		; IX+$02 -> new L
  LD HL,(IXobj)
  LD BC,$0004
  ADD HL,BC
  LD D,(HL)		; IX+$04 -> new H
  PUSH DE
  POP HL
  LD (LAA7B),HL
LB1C3:
  LD HL,$0000
  PUSH HL
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  POP DE
  LD (HL),E		; IX+$02
  INC HL
  INC HL		; +$04
  LD (HL),D		; IX+$04
  RET
LAFFC_31:
  LD HL,(IXobj)
  INC HL		; +$01
  LD (HL),$02	; IX+$01
  LD HL,(IXobj)
  LD DE,$0009
  ADD HL,DE
  LD (HL),$06	; IX+$09
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  LD A,(HL)		; IX+$02
  AND $F8
  LD (HL),A		; IX+$02
  LD HL,(IXobj)
  LD DE,$0012
  ADD HL,DE
  LD (HL),$50	; IX+$12
  LD HL,(IXobj)
  LD DE,$0013
  ADD HL,DE
  LD (HL),$50	; IX+$13
  JP LAFFC_33
LAFFC_32:
  PUSH HL
  LD HL,(cur_level_ptr)
  LD A,(HL)		; IY+$00
  POP HL
  AND $20		; BIT 5,(IY+$00)
  JP NZ,LAFFC_34
  LD A,(object_bat_1+$14)
  CP $07
  JP Z,LAFFC_38
  LD A,(object_bat_2+$14)
  CP $07
  JP Z,LAFFC_38
LAFFC_33:
  PUSH HL
  LD HL,(cur_level_ptr)
  LD A,(HL)		; IY+$00
  POP HL
  AND $10		; BIT 4,(IY+$00)
  JP NZ,LAFFC_38
  PUSH HL
  LD HL,(cur_level_ptr)
  LD A,(HL)		; IY+$00
  POP HL
  AND $20		; BIT 5,(IY+$00)
  JP NZ,LAFFC_34
  PUSH HL
  LD HL,(cur_level_ptr)
  LD A,(HL)
  OR $10		; SET 4,(IY+$00)
  LD (HL),A
  POP HL
LAFFC_34:
  LD HL,(LB28F+$01)		; координаты (X,Y)
  PUSH HL
  LD HL,briks_data
  LD (briks_walk_ptr),HL
  POP HL
  LD B,$05
LAFFC_35:
  PUSH HL
  LD HL,(briks_walk_ptr)
  LD A,(HL)		; IX+$00
  POP HL
  AND A
  JP Z,LAFFC_36
  PUSH HL
  LD HL,(briks_walk_ptr)
  LD DE,$0007
  ADD HL,DE
  LD (briks_walk_ptr),HL
  POP HL
  dec B
  jp nz,LAFFC_35
  JP LAFFC_37
LAFFC_36:
  PUSH HL			; save координаты
  CALL screen_addr_calc	; HL = screen addr result
  PUSH HL
  LD HL,(briks_walk_ptr)
  INC HL		; +$01
  POP DE		; D=H(screen),E=L(screen)
  LD (HL),E		; IX+$01
  INC HL
  LD (HL),D		; IX+$02
  POP HL			; restore координаты
  CALL scr_buff_addr_calc	; HL = buffer addr result
  PUSH HL
  LD HL,(briks_walk_ptr)
  LD DE,$0003
  ADD HL,DE
  POP DE		; D=H(buffer),E=L(buffer)
  LD (HL),E		; IX+$03
  INC HL
  LD (HL),D		; IX+$04
  LD HL,(briks_walk_ptr)
  INC (HL)		; IX+$00
  LD HL,(cur_level_ptr)
  EX DE,HL		; DE = cur_level_ptr
  LD HL,(briks_walk_ptr)
  LD BC,$0005
  ADD HL,BC
  LD (HL),E		; IX+$05
  INC HL
  LD (HL),D		; IX+$06
LAFFC_37:
  LD A,$02
  LD (sounds_queue+28+$00),A
  LD A,$09
  LD (sounds_queue+28+$01),A
  LD A,$B0
  LD (sounds_queue+28+$02),A
  RET
LAFFC_38:
  LD A,(briks_quantity_1up)
  DEC A
  LD (briks_quantity_1up),A
  CALL points_calc_and_add
  LD HL,(IXobj)
  LD A,(HL)		; IX+$00
  AND $7F
  CP $02
  JP NZ,LB28F
  LD HL,(IXobj)
  LD DE,$0012
  ADD HL,DE
  LD A,(HL)		; IX+$12
  AND $80
  LD (HL),A		; IX+$12
  LD A,(object_bat_1+$14)
  CP $07
  JP Z,LAFFC_39
  LD A,(object_bat_2+$14)
  CP $07
  JP NZ,LB28F
LAFFC_39:
  LD HL,(LB1C3+$01)
  PUSH HL
  LD HL,(IXobj)
  INC HL
  INC HL		; +$02
  POP DE
  LD (HL),E		; IX+$02
  INC HL
  INC HL		; +$04
  LD (HL),D		; IX+$04
LB28B:
  LD HL,(IXobj)
  LD DE,$0006
  ADD HL,DE
smash_direction_value:
  LD (HL),$00	; IX+$06
LB28F:
  LD HL,$0000		; Координаты на экране
LB292:
  LD A,$00
  LD BC,$0208
  RRA
  JP NC,LAFFC_41
  DEC L
  INC B
LAFFC_41:
  RRA
  JP NC,LAFFC_42
  INC B
LAFFC_42:
  RRA
  JP NC,LAFFC_43
  DEC H
  INC C
LAFFC_43:
  RRA
  JP NC,LAFFC_44
  INC C
;===============================================
; Выбивание кирпича
LAFFC_44:
brik_value:
 LD A,0 ; collision row index, also used for scoring
brik_value_0:
	LD A,(random_number_1)
	AND $0F
	CP $05
	CALL C,set_bonus
	PUSH HL	; keep brick coordinates through object-type check
	LD HL,(IXobj)
	LD A,(HL)		; IX+$00
	AND $7F
	CP $05
	POP HL
	JP Z,LB2D8
	push HL
	push DE
	push BC
	CALL get_free_sound_slot
	ld (HL),sound_normall_brik
	inc HL
	ld (HL),$04
	pop BC
	pop DE
	pop HL
LB2D8:
 ld hl,(cur_level_ptr)
 ld a,(hl)
 or $80
 ld (hl),a
 ld a,(balls_quantity)
 cp 3
 jp z,NativeRestoreQueued
 jp NativeRestoreBrick

 INCLUDE "./routines/restore_brick_background.asm"

; Обновление цвета знакоместа сразу на экране по данным из буфера цвета
; На входе в HL - адрес в буфере атрибутов
col_zm_rest:
 jp NativeRecolorCell

; Used by the routines at show_window_round_number, input_new_record_name, disp_main_menu_and_wait_keys, print_message and print_txt_players_1_and_2.
; На входе в DE адрес сообщения
print_line:			; Specialist ready
	EX DE,HL
	LD E,(HL)
	INC HL
	LD D,(HL)
	INC HL
	LD A,(HL)
	CALL UiSetColor
	INC HL
	LD B,(HL)
	INC HL


print_line_0:
 jp PrintOutlinedLine
PrintLineBody:
	EX DE,HL
	push bc
	CALL screen_addr_calc
	pop bc
 ld a,(UiActive)
 or a
 jp nz,PrintLineKeepPixels
 call ClearOutlinedLine
PrintLineKeepPixels:
	LD A,B
	AND $3F
	LD B,A
print_line_1:
	PUSH BC
	CALL print_symbol
	POP BC
	INC DE
	DEC B
	JP NZ,print_line_1
	RET

; Used by the routine at print_line.
; DE указывает на код печатаемого символа
print_symbol:		; Specialist ready
	PUSH DE
	LD A,(DE)
	EX DE,HL
	PUSH DE

	LD L,A
	LD H,$00
	ADD HL,HL
	LD E,L
	LD D,H
	ADD HL,HL		; А умножаем на 6
	ADD HL,DE		; и помещаем HL

	LD DE,font+$05
	ADD HL,DE		; В HL адрес символа в знакогенераторе

	POP DE
	EX DE,HL
	PUSH HL
	LD B,$06
; HL - указатель на код печатаемого символа
; DE - адрес символа в знакогенераторе
; B - $06
symbol_call_jump:
	JP LB551

LB551:
	LD A,(DE)
	CALL UiPixelWrite
	DEC DE
	inc l		; поправлено направление для Вектора
	DEC B
	JP NZ,LB551
	POP HL
	INC H
	POP DE
	RET

; Used by the routines at fill_color_current_game_mode and fill_gen_win_attrib.
; Вычисляет координаты в экранной области
; На входе в HL координаты, на выходе там же адрес в атрибутах
screen_coord_attrib:

; Used by the routines at show_window_round_number, print_obj_from_buf_to_scr, LAFFC, print_line and print_sprite.
; На входе в HL координаты, на выходе там же адрес на экране
screen_addr_calc:
 ld a,h
 ld c,a
 ld a,l
 rrca
 rrca
 rrca
 and 31
 ld b,a
 or $c0
 ld h,a
 ld a,$e0
screen_addr_calc_1:
 sub c
 ld l,a
 ld c,0
 ret

hl_add_2a:
	add A,A
; Used by the routines at print_magnets, print_one_magnet, fill_color_current_game_mode, print_obj_to_buff, set_bonus, enemy_prepare, handling_object,
; handling_ball, LAB1F, hl_bc_calc_direction, print_one_brik_buf, points_calc_and_add, running_dot and game_screen_draw_to_buffer.
hl_add_a:
	ADD A,L
	LD L,A
	RET NC
	INC H
	RET

; Used by the routine at game_screen_draw_to_buffer.
; Вывод ч/б спрайта без маски в буфер
; Спрайт рисуется снизу вверх
print_sprite_pix:
 push hl
 call scr_buff_addr_calc
 ld a,h
 add $50
 ld h,a
 ld a,$e0
 sub l
 ld l,a
 ld a,(de)
 ld c,a
 inc de
 ld a,(de)
 ld (print_sprite_pix_height+1),a
 ld (print_sprite_pix_stride+1),a
 inc de
print_sprite_pix_height:
 ld b,0
print_sprite_pix_byte:
 ld a,(de)
 ld (NativeWriteValue),a
 ld a,l
 cp $21
 jp c,print_sprite_pix_skip
 cp $e1
 jp nc,print_sprite_pix_skip
 ld a,(NativeWriteValue)
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 xor a
 ld (hl),a
 ld a,h
 add $20
 ld h,a
print_sprite_pix_skip:
 inc de
 inc l
 dec b
 jp nz,print_sprite_pix_byte
 ld a,l
print_sprite_pix_stride:
 sub 0
 ld l,a
 inc h
 dec c
 jp nz,print_sprite_pix_height
 pop hl
 ret

; Used by the routine at disp_main_menu_and_wait_keys.
; Вывод ч/б спрайта без маски на экран
print_sprite:
	PUSH HL
	CALL screen_addr_calc
	LD A,(DE)
	LD (LB605+$01),A
	INC DE
	LD A,(DE)
	INC DE
	LD C,A
print_sprite_0:
	PUSH HL
LB605:
	LD B,$00
print_sprite_1:
	LD A,(DE)
	CALL UiPixelWrite
	INC DE
	INC H
	DEC B
	JP NZ,print_sprite_1
	POP HL
	inc l   	; поправлено направление для Вектора
	DEC C
	JP NZ,print_sprite_0
	POP HL
	RET

; Used by the routine at game_screen_draw_to_buffer.
; Вывод атрибутов цветного спрайта в буфер
print_sprite_attrib:
	push hl
	call scr_buff_attr_calc
	ld a,(de)		; Ширина
	ld c,a
	inc de
	ld a,(de)		; Высота
	ld (print_sprite_attrib_1+$01),a
	ld (print_sprite_attrib_3+$01),a
	inc de
print_sprite_attrib_1:
	ld b,$00
print_sprite_attrib_2:
	ld a,l
	or %11000000	; Костыль, чтобы атрибуты всегда писались исключительно в буфер атрибутов
	ld l,a
	ld a,(de)
	call NativeWriteHL
	call NativeRecolorCell
	inc de
	dec l
	dec B
	jp nz,print_sprite_attrib_2
	ld a,l
print_sprite_attrib_3:
	add a,$00
	ld l,a
	inc h
	dec c
	jp nz,print_sprite_attrib_1
	pop hl
	ret

; Used by the routines at game_restart, LBAED, LBB97 and LBC10.
; Вызов процедуры, переданной в HL, для 11 свойств спрайтов
; HL = адрес процедуры
call_hl_for_all_obj:
	LD (LB678+$01),HL
	LD HL,object_ball_1
	LD B,$0B
LB66A_0:
	LD A,(HL)
	ADD A,A
	JP Z,LB678_1
	PUSH BC		; only live objects call a handler
	ld (IXobj),HL		; Текущий объект с которым работают процедуры
	push HL
LB678:
	CALL LB678		; Вызов подпрограммы поданной на вход этой процедуры в HL
	pop HL
	POP BC
LB678_1:
	LD DE,$0016
	ADD HL,DE
	dec B
	jp nz,LB66A_0
	RET

; Used by the routines at print_magnets, add_points_to_score, bonus_extra_life and game_screen_draw_to_buffer.
; Вычисляем адрес в буфере из координат IX+$02 и IX+$04
; Кладём адрес в IX+$0A и IX+$0B
; Вход: (IXobj) = адрес объекта
ix_buf_addr_calc:
	ld HL,(IXobj)
; Вход: HL = адрес объекта
hl_buf_addr_calc:
	push HL
	ld DE,$000A
	add HL,DE
	ld (hl_buf_addr_calc_1+1),HL
	pop HL		; IX
	inc HL
	inc HL
	LD E,(HL)	; IX+$02
	inc HL
	inc HL
	LD D,(HL)	; IX+$04
	ex DE,HL
; Координаты в HL
	CALL scr_buff_addr_calc
; Результат в HL
	ex DE,HL
hl_buf_addr_calc_1:
	ld HL,$0000	; IX+$0A
	LD (HL),D	; IX+$0A
	inc HL
	LD (HL),E	; IX+$0B
	RET

; Used by the routines at game_restart, LBB97 and LBC10.
; Заполняет briks_data данными
fill_briks_data:
	LD HL,briks_data
	LD B,$05
next_brik:
	push BC
	LD A,(HL)
	AND A
	CALL NZ,metal_brik_anim
	LD DE,$0007
	ADD HL,DE
	pop BC
	dec B
	jp nz,next_brik
	RET

; Used by the routine at fill_briks_data.
; Рисуем один кадр переливания кирпича одновременно в буфер и на экран
; Вход: HL, на выходе то же значение!
metal_brik_anim:
  LD (metal_brik_slot_ptr),HL
  LD HL,(metal_brik_slot_ptr)
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL		; +$05
  LD A,(HL)		; IY+$05
  INC HL		; +$06
  LD H,(HL)		; IY+$06
  LD L,A
	ld A,(HL)
	or A		; BIT 7,(HL)		; Проверяем 7 бит (пустота) текущего элемента
	JP P,LB6A9_0
	LD HL,(metal_brik_slot_ptr)
	LD (HL),$00		; IY+$00 Помечаем текущий слот данных свободным
	RET
LB6A9_0:
 ; Use the animation slot counter, not the level byte (strength/color bits).
 ld hl,(metal_brik_slot_ptr)
 ld e,(hl)
 inc hl
 inc hl
 inc hl
 ld c,(hl)
 inc hl
 ld b,(hl)
 ld d,c
 ld a,c
 rrca
 rrca
 rrca
 or $c0
 ld c,a
 call NativeReadBC
 ld c,d
 or a
 jp nz,LB6A9_01
 ld a,e
 cp 15
 jp nz,LB6A9_03
 ld hl,anim_brik_black
 jp LB6A9_02

LB6A9_01:
	ld a,e
LB6A9_03:
	INC A
	AND $FE
	LD HL,anim_brik-$02
	LD E,A
	LD D,$00
	ADD HL,DE
; В HL ссылка на спрайт текущей анимации переливания кирпича
LB6A9_02:
	LD E,(HL)
	INC HL
	LD D,(HL)
	PUSH DE
	PUSH BC
	LD HL,(metal_brik_slot_ptr)
	INC HL		; +$01
	LD A,(HL)
	INC HL		; +$02
	LD H,(HL)		; IY+$02
	LD L,A			; IY+$01
	POP BC
	POP DE
; DE - адрес спрайта текущего кадра анимации
; HL - адрес на экране
; BC - адрес в буфере
;-----------------------
 call NativeCpcPrepareAnimation
	LD A,$07
LB6A9_1:
	ld (LB6A9_20+1),A	; save A
LB6A9_10:
;	ld a,$00
;	ld (color_port),a	; Цвет левой половины кирпича (на случай тени)
	LD A,(DE)		; байт из спрайта
	CALL NativeCpcScreenWrite	; Solid body and white glint in A/C/E
	; Native background already updated
	INC H
	inc b
	INC DE
LB6A9_11:
;	ld a,$00
;	ld (color_port),a	; Цвет правой половины кирпича
	LD A,(DE)		; байт из спрайта
	CALL NativeCpcScreenWrite	; Solid body and white glint in A/C/E
	; Native background already updated
	DEC H
	dec L			; Изменено направление для Вектора
	INC DE
	dec B
	inc c
LB6A9_20:
	ld A,$00		; restore A
	DEC A
	JP NZ,LB6A9_1
;-----------------------
  LD HL,(metal_brik_slot_ptr)
	LD A,(HL)
	INC A
	AND $0F
	LD (HL),A
	RET
; -- end of metal_brik_anim -------

; 5 строк по 7 элементов каждая
; Сведения о 5 кирпичах
; IX+$00 - 0 - свободно, 1 - заполнено
; IX+$01 - 2 байта адрес на экране
; IX+$04 - 2 байта адрес в экранном буфере
; IX+$06 - 2 байта - адрес (IY) текущего элемента (кирпича) на текущем уровне
briks_data:
	DEFB $00,$00,$00,$00,$00,$00,$00
	DEFB $00,$00,$00,$00,$00,$00,$00
	DEFB $00,$00,$00,$00,$00,$00,$00
	DEFB $00,$00,$00,$00,$00,$00,$00
	DEFB $00,$00,$00,$00,$00,$00,$00

; Used by the routines at LBAED, LBB97 and LBC10.
; Восстанавливает несколько окон, количество задано в A
wins_recovery:
 ld a,(QueueFresh)
 cp 2
 jp nc,brq_frame_done
 call NativeRestoreQueueStep
brq_frame_done:
 xor a
 ld (QueueFresh),a
 ret

; Used by the routine at all_metal_briks_animation_snd.
; Проигрывает один звук металлического кирпича, если на уровне есть хотя бы один такой кирпич
one_play_sound_metal_brik:
	NOP			;WARN: изменяемая команда NOP / RET
	LD A,$C9		; Код команды RET
	LD (one_play_sound_metal_brik),A
	LD HL,(current_level_addr)
	LD B,$B4
LB74A:
	LD A,(HL)
	AND $90
	JP Z,LB754
	INC HL
	dec B
	jp nz,LB74A
	JP LB764
LB754:
;TODO	LD IY,(iy_storage)
	LD HL,sounds_queue
	LD (snd_slot_ptr),HL
	CALL play_sound_metal_brik
	; DI
LB764:
	RET

; Used by the routine at game_restart.
; Анимация со звуком разом всех трудновыбиваемых кирпичей перед началом раунда
all_metal_briks_animation_snd:
	XOR A
	LD (one_play_sound_metal_brik),A
	LD HL,anim_brik
	LD (anim_brik_ptr),HL
LB765_0:
;TODO	LD IY,(iy_storage)

; Пауза для анимации металлических кирпичей
; Вместо halt необходимо ставить паузу
  ; EI
  ; HALT
  ; EI
  ; HALT
  ; DI
	ld d,$20		; Константа выставлена на глаз
	call pause_short

	CALL all_metal_briks_frame

	LD HL,(anim_brik_ptr)
	LD A,(HL)		; IX+$00
	LD C,A
	INC HL
	LD A,(HL)		; IX+$01
	LD B,A
	LD H,B
	LD L,C
	LD DE,spr_brik_5
	XOR A
	CALL SBCHLDE8080	; SBC HL,DE

	CALL Z,one_play_sound_metal_brik

	LD HL,(anim_brik_ptr)
	INC HL
	INC HL
	LD (anim_brik_ptr),HL
	INC HL
	LD A,(HL)		; IX+$01 новой позиции
	AND A

	JP NZ,LB765_0
	RET

; Ячейки хранения стандартного значения IY для корректной работы IM1
;iy_storage:
;TODO	DEFW $0000

; Used by the routine at game_restart.
;return:
;  RET

; Used by the routines at show_window_round_number, disp_high_score_table_screen, disp_main_menu_and_wait_keys, print_kinnock and LBC10.
; На входе в DE адрес сообщения, в B - количество выводимых строк
print_message:		; Specialist ready
	PUSH BC
	CALL print_line
	POP BC
	DEC B
	JP NZ,print_message
	RET

; Data block at B79E
; Мусор?

;--------------------------
; Данные для первого игрока
score_1up_in_game:
	DEFW $0F00	; Адрес в буфере (на старте игры вычисляется по координатам $F010)
	DEFB $47,$06	; Рудимент, не используется?
	DEFW $0000	; 6-й и 5-й разряды счёта
	DEFW $0000	; 4-й и 3-й разряды счёта
	DEFW $0000	; 2-й и 1-й разряды счёта
;--------------------------

; Мусор?

hi_score_in_game:
	DEFW $0F68	; Адрес в буфере (на старте игры вычисляется по координатам $F068)
	DEFB $47,$06	; Рудимент, не используется?

;HI score - 3 ячейки
hi_score:
	DEFB $00,$00,$10

; Мусор?
	DEFB $26,$1E,$19

;--------------------------
score_2up_in_game:
	DEFW $0FD0	; Адрес в буфере (на старте игры вычисляется по координатам $F0C0)
	DEFB $47,$06	; Рудимент, не используется?
	DEFW $0000	; 6-й и 5-й разряды счёта
	DEFW $0000	; 4-й и 3-й разряды счёта
	DEFW $0000	; 2-й и 1-й разряды счёта
;--------------------------

; Мусор?
	DEFB $06,$07

; Used by the routine at LBC10.
pause_clear_screen_attrib:
	CALL pause_short
	dec B
	jp nz,pause_clear_screen_attrib
	ret ;JP clear_screen_attrib

; Used by the routines at input_new_record_name, game_restart, LBBFB and LBC10.
; Пауза - в B задаётся количество циклов. Один цикл - примерно 0,3 сек.
pause_long:
	LD D,$00
	CALL pause_short
	dec B
	jp nz,pause_long
	RET

; Unreferenced duplicated RET at the old B7E4 location removed.

; Общие переменные игры
; Режим игры:
; 00 - 1 Player
; 01 - 2 Players
; 02 - Double Play
game_mode:
	DEFB $00
player_number:
	DEFB $00  	; Номер игрока: 0 / 1
frames_copy:
	DEFB $00	; Копия системного счётчика кадров

; Данные первого игрока
lives_1up:
	DEFB $03	; Количество жизней
briks_quantity_1up:	; Количество кирпичей на текущем уровне
	DEFB $00
current_level_number_1up:
	DEFB $00		; Текущий уровень - один из 15-ти
round_number_1up:
	DEFB $00	; Номер раунда. Он может быть больше, чем число уровней!
current_score_1up:
	DEFB $00,$00,$00	;Текущий счёт 1-го игрока (три ячейки)

; Тип управления первого игрока:
; $00 - Keyboard
; $01 - native Vector joystick
ctrl_type_1up:
	DEFB $00

; Данные второго игрока
lives_2up:
	DEFB $00
;briks_quantity_2up:
	DEFB $00
current_level_number_2up:
	DEFB $00
;round_number_2up:
	DEFB $00
current_score_2up:
	DEFB $00,$00,$00
ctrl_type_2up:
	DEFB $00

; Used by the routine at game_restart.
; Инициализация всех переменных, подготовка всех буферов
all_var_init:
	LD A,(ball_x_coord+$01)
	XOR $88
	LD (ball_x_coord+$01),A	; Запись в object_ball_1+2
; Restore all 11 original records from the immutable packed snapshot.
	CALL InitialObjectsRestore
; A = 0
	xor A
	;LD (LBAEB+$01),A	; меняем параметр команды JR (но нет других мест изменения параметра)
	LD (bonus_flag),A
	LD (bonus_flag_copy),A
	LD (current_magnet_prop+1),A
	LD (ctrl_btns_pressed),A
	LD (ctrl_btns_pressed_copy),A
	INC A
; A = 1
	LD (balls_quantity),A
	LD A,(game_mode)
	CP $02
	JP NZ,LB7F8_1
; Режим Double Play
	LD A,$01
	LD (object_bat_2),A
	LD A,$38
	LD (object_bat_1+$02),A	; Координата X
	LD A,$B0
	LD (object_bat_2+$02),A	; Координата X
ball_x_coord:
	LD A,$48		; Здесь самомодификация кода
	LD (object_ball_1+$02),A
	CP $C0
	JP NZ,LB7F8_1
	LD A,(object_ball_1+$12)
	OR $80
	LD (object_ball_1+$12),A
	LD A,$FF
	LD (object_bat_1+$14),A
	LD A,$83
	LD (object_bat_2+$14),A
LB7F8_1:
	LD HL,$8CC0			; Это не адрес!
	LD (object_ball_1+$14),HL
	LD L,$08
; Ball speed below is fixed at 3; the old level clamp was overwritten.
LB7F8_2:
	LD A,$03
	LD H,A
	LD (object_ball_1+$06),HL
	LD A,$0E
	LD (running_dot_frame_1up),A
	LD (running_dot_frame_2up),A
	LD A,$83
	LD (object_bat_1+$14),A
	XOR A
	LD (wins_counter),A
	LD HL,wins_recovery_data
	LD (wins_recovery_ptr),HL
	LD HL,bonus_table_first
	LD A,(round_number_1up)
	CP $06
	JP C,LB7F8_3
	LD HL,bonus_table_second
LB7F8_3:
	LD DE,bonus_table_current
	LD BC,$0010		; 16
	call LDIR8080B		; LDIR
	LD HL,LA270
	LD B,$0C
	CALL clear_hl_buff
	LD HL,sounds_queue
	LD B,$23		; 35
	CALL clear_hl_buff
	LD HL,briks_data
	LD B,$23		; 35
	JP clear_hl_buff

; Used by the routine at briks_calc.
; Сброс свойств всех кирпичей на уровне
; На входе в HL - адрес уровня
bricks_reset:
	LD B,$B4		; 180 - количество всех ячеек на уровне
bricks_reset_0:
	LD A,(HL)
	CP $C0
	JP Z,bricks_reset_1	; Если пустое место, то пропускаем
	ld C,A		; save A
	and %00100000	; BIT 5,A: test the unbreakable flag
	JP NZ,bricks_reset_1	; Если невыбиваемый, то пропускаем
	ld A,C
	and %00111111	; RES 7,(HL) / RES 6,(HL)  Сбрасываем бит пустоты
	or  %00010000	; SET 4,(HL)  Устанавливаем признак обычного кирпича
	ld (HL),A
	AND $0F
	CP $06
	JP C,bricks_reset_1	; Если цвет меньше 6 (то есть обычный кирпич), то пропускаем
	ld A,(HL)
	and %11101111	; RES 4,(HL)  Всем цветам 6 и выше (до невыбиваемых) сбрасываем признак обычного кирпича
	ld (HL),A
bricks_reset_1:
	INC HL
	dec B
	jp nz,bricks_reset_0
	RET

; Рисование бегающих точек на каретках
  INCLUDE "./routines/running_dots.asm"

; Ячейка для временного хранения нажатых кнопок управления
ctrl_btns_pressed_copy:
	DEFB $00

; kinnock:
; 	DEFB $01	; Если сюда записать ноль, то перед игрой будет надпись про Киннока

; Used by the routine at game_restart.
; print_kinnock:
; 	LD A,(kinnock)
; 	AND A
; 	RET NZ
; 	LD DE,txt_kinnock
; 	LD B,$02
; 	CALL print_message
; 	LD D,$00
; 	CALL pause_short
; 	JP clear_screen_attrib

;   INCLUDE "./txt/txt_kinnock.asm"

; Начало программы
; Used by the routine at L6800.
game_start:
;TODO	LD (iy_storage),IY

	LD HL,$F010 ; HUD digits at Y=-16.
	CALL scr_buff_addr_calc
	LD (score_1up_in_game),HL	; Адрес в буфере по координатам

	LD HL,$F0C0
	CALL scr_buff_addr_calc
	LD (score_2up_in_game),HL	; Адрес в буфере по координатам

	LD HL,$F068
	CALL scr_buff_addr_calc
	LD (hi_score_in_game),HL	; Адрес в буфере по координатам

; A fresh start restores the original snapshot, including after warm reset.
	CALL InitialObjectsRestore

	xor a
	; Shadow width sum removed.

; Used by the routine at LBC10.
; Повторный запуск главного меню (после проигрыша), минуя некоторые инициализации
game_restart:
	ld a,(score_1up_in_game+1)
	sub scr_buff/$100
	AND $1F
	CP $02
	CALL NZ,players_swap

;----------------------------------
	CALL disp_main_menu_and_wait_keys
	XOR A
	LD (UiActive),A
;----------------------------------

; Непосредственный запуск игры
	xor a
	ld l,a
	ld h,a
	ld (current_score_1up),HL
	ld (current_score_1up+$02),A
; Обнуление внутриигрового счёта
	LD (score_1up_in_game+$04),HL
	LD (score_1up_in_game+$06),HL
	LD (score_1up_in_game+$08),HL
	LD (score_2up_in_game+$04),HL
	LD (score_2up_in_game+$06),HL
	LD (score_2up_in_game+$08),HL

	LD A,$03		; Количество жизней
	LD (lives_1up),A
	LD A,$C0
	LD (ball_x_coord+$01),A	; Запись в object_ball_1+2
	XOR A			; Начальный уровень = 0
	LD (current_level_number_1up),A
	LD (round_number_1up),A
	LD (player_number),A
	CALL briks_calc		; Сброс свойств всех кирпичей на уровне
	LD DE,current_level_copy
	LD HL,(current_level_addr)
	LD BC,$00B4		; 180 - количество ячеек на уровне
	call LDIR8080B		; LDIR
	LD DE,lives_2up
	LD HL,lives_1up
	LD BC,$0007
	call LDIR8080B		; LDIR
	LD A,(game_mode)
	AND A
	JP NZ,LB9E8_0
; Есть второй игрок
	LD (lives_2up),A	; = 0
LB9E8_0:
	; LB9E8_1 performs the full reset for a new game.

; This entry point is used by the routines at LBBFB and LBC10.
; Сюда возвращаемся когда потеряли жизнь
LB9E8_1:
	XOR A
	LD (UiActive),A
	CALL SetPaletteLevel
	CALL level_addr_calc
	CALL planes_reset
	CALL game_screen_draw_to_buffer
	CALL all_var_init
	;CALL clear_screen_attrib
	;CALL print_kinnock
	;CALL buff_to_screen_attrib
	;CALL return		; Заглушка, пустая подпрограмма
	CALL show_window_round_number
	; Three-channel Vector fanfare accompanies the round announcement.
	CALL MusicStart
	LD B,$04
	CALL pause_long		; Пауза 1,2 сек. (4*0.3)
	CALL MusicStop
	CALL all_metal_briks_animation_snd
; Восстанавливаем из буфера пиксели над окном с надписью о номере раунда
	LD HL,$8158		; Координаты
	LD BC,$0A28		; Размеры окна
	CALL win_bg_recovery
; Play starts or resumes: restart the game clock.
GameplayStart:
	CALL PaceClockStart
; This entry point is used by the routine at LBAED.
LB9E8_2:
 call CheatPoll
 jp c,LBBFB_0
	LD A,(random_number_1)
	CP $99
	CALL Z,print_one_magnet
	XOR A
	LD (counter_2),A
	CALL get_left_player_ctrl_state
	LD HL,(counter_misc)
	INC HL
	LD (counter_misc),HL
	CALL enemy_prepare
	CALL random_generate
	ld HL,object_bat_1
	ld (IXobj),HL
	CALL handling_bat
	LD A,(game_mode)
	CP $02
	JP NZ,LB9E8_3
	CALL bonus_flag_swap
	LD A,(ctrl_btns_pressed)
	PUSH AF
	LD A,(ctrl_type_2up)
	CALL get_right_player_ctrl_state
	LD A,(ctrl_btns_pressed)
	LD (ctrl_btns_pressed_copy),A
	LD HL,object_bat_2
	ld (IXobj),HL
	CALL handling_bat
	POP AF
	LD (ctrl_btns_pressed),A
	ld HL,object_bat_1
	ld (IXobj),HL
	CALL LACCE
  	ld HL,object_bat_2
	ld (IXobj),HL
  	CALL LACAD
	CALL bonus_flag_swap
LB9E8_3:
	LD HL,handling_object
	CALL call_hl_for_all_obj
	CALL fill_briks_data
LBAEB:
	;JR LBAED_0		;WARN: Параметр JR изменяемый! но почему-то задаётся только в одном месте
LBAED:
	LD A,(object_rocket)
	AND A
	JP NZ,LBAED_6
; This entry point is used by the routine at game_restart.
LBAED_0:
	LD A,(balls_quantity)
	AND A
	JP Z,LBC10
	LD A,(briks_quantity_1up)
	AND A
	JP Z,LBC10
	CALL play_sounds_queue
; The old object-count heuristic led to the same redraw path in every case.
LBAED_1:
LBAED_2:
LBAED_3:
LBAED_4:
LBAED_5:
GameplayLogicDone:
 ; This logic step is paid for. If game time is still owed, one more logic
 ; step before the picture is drawn. A logic step can itself take a raster
 ; (metal brick animation), so the catch-up is limited to one step per draw
 ; and at most one owed step is carried over: the game slows down there
 ; instead of freezing the picture.
 call PaceUpdate
 dec (hl)
 jp z,pace_draw
 ld a,(hl)
 cp 2
 jp c,pace_catch
 ld a,(pw_steps+1) ; carry over no more than one draw's steps
 ld (hl),a
pace_catch:
 ld a,1 ; catch-up steps left before the next draw
 dec a
 jp m,pace_draw
 ld (pace_catch+1),a
 jp PaceMark
pace_draw:
 ld a,1
 ld (pace_catch+1),a
 call wins_recovery
 ; The frame wait is taken inside the renderer, between sprite preparation
 ; and the erase of the old images: the erased interval then starts at the
 ; top border instead of crossing the middle of the field.
 ; Only the one-ball game is tied to the raster this way; with two and
 ; three balls the output starts at once and the clock wait, if any, comes
 ; after it, in front of the next logic step.
 ld a,(balls_quantity)
 dec a
 jp nz,GameplayDrawBegin
GameplaySyncInside:
 inc a
 ld (GameplaySync),a
GameplayDrawBegin:
 call RCBegin
 CALL planes_begin
 CALL DrawMovingObjects
 call GameplaySyncPoint ; renderer left early: keep the frame pace
 call RCFlush
	LD HL,object_bat_1+2
	CALL running_dot
	LD A,(game_mode)
	CP $02
	JP NZ,direct_dots_done
	CALL running_dot_frame_swap
	LD HL,object_bat_2+2
	CALL running_dot
	CALL running_dot_frame_swap

direct_dots_done:
	CALL restore_objs_and_magnet
	CALL pause_game
	JP PaceTail ; no logic step ahead of game time

LBAED_6:
	ld B,$0B		; 11
	ld DE,$0016
	ld HL,object_ball_1
LBAED_7:
	LD A,(HL)		; IX+$00
	AND A
	JP Z,LBAED_8
	ld A,(HL)
	or %10000000		; SET 7,(IX+$00)
	ld (HL),A
LBAED_8:
	ADD HL,DE
	dec B
	jp nz,LBAED_7

	LD A,$01
	PUSH HL
	LD HL,(IYobj)
	LD (HL),A
	POP HL
	LD A,$06
	LD (object_rocket),A
	LD A,$05
	LD (sounds_queue),A
	XOR A
	LD (counter_misc),A
 ld (SfxCooldown),a
	JP LBB97_0

LBB97:
	LD A,(counter_misc)
	INC A
	LD (counter_misc),A
	CALL random_generate
	LD HL,handling_object
	CALL call_hl_for_all_obj
	CALL fill_briks_data
; This entry point is used by the routine at LBAED.
LBB97_0:
;TODO	LD IY,(iy_storage)

  ; Непонятно на что влияющая задержка
  ; Вместо halt необходимо ставить паузу
  ; EI
  ; HALT
  ; DI

  ; ld d,$10		; Константа выставлена на глаз
  ; call pause_short

	CALL play_sounds_queue
	CALL WaitVideoFrame
	CALL planes_begin
	CALL DrawMovingObjects
	LD A,(wins_counter)
	AND A
	CALL NZ,wins_recovery
	CALL pause_game
	LD A,(object_rocket)
	AND A
	JP Z,LBBFB
	JP LBB97

; Used by the routine at LBBFB.
increment_round_number:
 call NativeRestoreQueueFlush
	LD A,(round_number_1up)
	INC A
	LD (round_number_1up),A
	LD A,(current_level_number_1up)
	INC A
	CP $0F			; Максимальное количество уровней
	JP Z,LBBE0_0
	LD (current_level_number_1up),A
	JP LBBE0_1
LBBE0_0:
	XOR A
	LD (current_level_number_1up),A
LBBE0_1:
	JP briks_calc		; Сброс свойств всех кирпичей на уровне, и возврат

; Used by the routine at LBB97.
LBBFB:
	CALL add_points_for_left_briks
; This entry point is used by the routine at LBC10.
LBBFB_0:
	LD A,(briks_quantity_1up)
	AND A
	CALL Z,play_sounds_queue
	CALL increment_round_number
	LD B,$02
	CALL pause_long
	JP LB9E8_1

; Used by the routine at LBAED.
LBC10:
 call NativeRestoreQueueFlush
LBC10_0:

	LD HL,object_ball_1
	LD B,$0B		; 11
	LD DE,$0016
	LD A,(object_rocket)
	PUSH AF
LBC10_1:
	LD A,(HL)		; IX+$00
	AND A
	JP Z,LBC10_2
	ld A,(HL)
	or %10000000		; SET 7,(IX+$00)
	ld (HL),A
LBC10_2:
	ADD HL,DE
	dec B
	jp nz,LBC10_1
	POP AF

	LD (object_rocket),A
	CALL WaitVideoFrame
	CALL planes_begin
	CALL DrawMovingObjects
	LD A,(wins_counter)
	AND A
	CALL NZ,wins_recovery
	LD A,(briks_quantity_1up)
	AND A
	JP Z,LBBFB_0
	LD A,$08
	LD (sounds_queue),A
	LD A,$3D
	LD (sounds_queue+$01),A
	XOR A
	LD (flag_extra_life),A
	LD HL,object_ball_1
	LD B,$0A		; 10 объектов
	LD A,(object_bat_1+$02)
	LD C,A
	LD A,(object_bat_2+$02)
	SUB C
	LD (LBCE6+$01),A
	LD A,(object_bat_1+$0C)	; ширина объекта без тени в пикселях
	or a
	rra		; SRL A
	ADD A,C
	SUB $0C
	LD C,A
	ld A,$1B
; HL = адрес записи объекта, A = направление, C = координата X
LBC10_3:
	ld (HL),$07		; (IX+$00) = anim_spark
	inc HL
	ld (HL),$00		; (IX+$01) = 0 - номер спрайта в наборе объекта
	inc HL
	ld (HL),C		; (IX+$02) = координата Х объекта
	inc HL
	inc HL
	ld (HL),$AE		; (IX+$04) = координата Y объекта
	inc HL
	inc HL
	ld (HL),A		; (IX+$06) = направление полёта
	inc HL
	LD (HL),$02		; (IX+$07) = скорость движения
	inc HL
	LD (HL),$02		; (IX+$08) = ширина спрайта с тенью в байтах
	inc HL
	LD (HL),$0B		; (IX+$09) = высота спрайта с тенью в пикселях
	inc HL
	inc HL
	inc HL
	LD (HL),$08		; (IX+$0C) = ширина объекта без тени в пикселях
	inc HL
	LD (HL),$07		; (IX+$0D) = высота объекта без тени в пикселях
	inc HL
	inc HL
	inc HL
	inc HL
	LD (HL),$00		; (IX+$11) = 0 - предыдущая высота спрайта с тенью в пикселях
	inc HL
	inc HL
	inc HL
	LD (HL),$18		; (IX+$14) = применяемый к объекту бонус
	inc HL
	LD (HL),$18		; (IX+$15) = Свойства каретки
	inc HL			; HL = IX+$16

	add A,$05		; меняем направление
	and $3F

	INC C
	INC C
	INC C			; Увеличиваем координату X
	dec B
	jp nz,LBC10_3

	LD A,(game_mode)
	CP $02
	JP NZ,LBC10_5
; Режим Double Play
	LD HL,object_ball_2+2	; HL = IX+$02
	LD DE,$0016+$0016
	LD B,$05
LBC10_4:
	LD A,(HL)
LBCE6:
	ADD A,$00
	LD (HL),A		; (IX+$02) = A
	ADD HL,DE		; на два объекта дальше
	dec B
	jp nz,LBC10_4

LBC10_5:
	CALL random_generate
	LD HL,handling_object
	CALL call_hl_for_all_obj
	CALL fill_briks_data


	CALL play_sounds_queue
	CALL WaitVideoFrame
	CALL SparksRender
	LD A,(wins_counter)
	AND A
	CALL NZ,wins_recovery

	CALL pause_game

	LD A,(object_ball_2)
	AND A
	JP NZ,LBC10_5

	LD B,$03
	CALL pause_long
	LD A,(lives_1up)
live_dec:
	DEC A			; Отнимаем жизнь
	LD (lives_1up),A
	JP Z,LBC10_6
	LD A,(game_mode)
	CP $01
	JP NZ,ResumeLife
	LD A,(lives_2up)
	OR A
	JP Z,ResumeLife
	CALL current_level_2up_copier
	JP LB9E8_1

; Same player/level: preserve texture, border, brick state and magnets.
ResumeLife:
	CALL MonoRemove ; retire the final death-particle footprints
	CALL all_var_init
	LD DE,$e018 ; all 32 columns, lives HUD at Y=200, height=6
	LD BC,$2006
	CALL plane_erase_dual
	CALL DrawLifeIcons
	JP GameplayStart

; Жизней не осталось
LBC10_6:
 call MonoRemove ; retain the playfield; retire the last particles
 call DrawGameOverPanel
	LD A,(player_number)
	INC A
	LD (txt_player_0+$0C),A		; Номер игрока для надписи GAME OVER PLAYER X
	LD DE,txt_game_over
 call print_line
 call GameOverPlayerLine
 ld hl,GameOverScore
 call MusicStartScore
	LD B,$0C
	CALL pause_clear_screen_attrib
	CALL hi_score_update
	CALL input_new_record_name
	LD A,(game_mode)
	CP $02
	JP NZ,LBC10_7
	CALL players_swap
	CALL hi_score_update
	CALL input_new_record_name
	CALL players_swap
	JP game_restart
LBC10_7:
	DEC A
	JP NZ,game_restart
	LD A,(lives_2up)
	AND A
	JP Z,game_restart
	CALL current_level_2up_copier
	JP LB9E8_1

  INCLUDE "./txt/txt_game_over.asm"
  INCLUDE "./txt/txt_player_0.asm"

; Used by the routine at LBC10.
print_txt_players_1_and_2:
	LD DE,txt_players_1_and_2
	JP print_line

  INCLUDE "./txt/txt_players_1_and_2.asm"

; Мусор????

; Used by the routine at game_restart.
;--------------------------------------------------
; Перенос данных (пикселей) вместе с цветом из буфера на экран
buff_to_screen_pixs:
 ret ; Background pixels are already in their native video planes.

; Used by the routines at add_points_to_score and current_level_2up_copier.
; Обмен содержимым ячеек адресуемых парами HL и DE
; Количество ячеек для обмена задаётся в регистре B
hl_swap_de:
	LD C,(HL)
	LD A,(DE)
	LD (HL),A
	LD A,C
	LD (DE),A
	INC HL
	INC DE
	dec B
	jp nz,hl_swap_de
	RET

; Used by the routine at LBC10.
; Делает копию текущего уровня 2-го игрока в current_level_copy
current_level_2up_copier:
	LD A,(lives_2up)
	AND A
	RET Z
	ex DE,HL
	ld HL,(current_level_addr)
	ex DE,HL
	PUSH DE
	LD A,(current_level_number_2up)
	CALL level_addr_calc_a
	POP DE
	LD BC,current_level_copy
	LD A,$B4
LBE0C_0:
	ld (LBE0C_1+1),A	; save A
	LD A,(DE)
	PUSH AF
	LD A,(BC)
	LD (HL),A
	POP AF
	LD (BC),A
	INC HL
	INC DE
	INC BC
LBE0C_1:
	ld A,$00		; restore A
	DEC A
	JP NZ,LBE0C_0

; This entry point is used by the routines at game_restart and LBC10.
; Обмен данными игроков
players_swap:
	LD HL,lives_1up
	LD DE,lives_2up
	LD B,$08
	CALL hl_swap_de		; Обмен данными игроков
	LD HL,score_1up_in_game
	LD DE,score_2up_in_game
	LD B,$0A
	CALL hl_swap_de		; Обмен счётов игроков
	LD A,(lives_1up)
	AND A
	RET Z			; Возвращаемся, если жизней не осталось
	LD A,(player_number)
	XOR $01
	LD (player_number),A	; Смена номера игрока
	RET

; Used by the routines at game_restart and increment_round_number.
; Подсчитывает количество кирпичей на уровне
briks_calc:
	CALL level_addr_calc
	PUSH HL			; Адрес уровня
	CALL bricks_reset	; Сброс свойств всех кирпичей на уровне
	POP HL
	LD B,$B4		; 180 - количество всех ячеек на уровне
	LD C,$00
briks_calc_0:
	LD A,(HL)
	AND $A0			; 0x0x xxxx - признак наличия выбиваемого кирпича на уровне
	JP NZ,briks_calc_1
	INC C
briks_calc_1:
	INC HL
	dec B
	jp nz,briks_calc_0
	LD A,C
	LD (briks_quantity_1up),A
	RET

; Used by the routine at LBC10.
; Обновляем рекордный счёт, если текущий счёт выше
hi_score_update:
	LD HL,hi_score+2
	LD DE,current_score_1up+2
	LD B,$03
hi_score_update_0:
	LD A,(DE)
	CP (HL)
	RET C
	JP NZ,hi_score_update_1
	DEC DE
	DEC HL
	dec B
	jp nz,hi_score_update_0
hi_score_update_1:
	LD DE,hi_score
	LD HL,current_score_1up
	LD BC,$0003
	call LDIR8080B		; LDIR
	RET

; Used by the routine at game_restart.
; Рисуем полный игровой экран со всеми элементами в буфере
game_screen_draw_to_buffer:
	LD HL,spr_level_textures
	LD A,(current_level_number_1up)
	AND $03
	CALL hl_add_2a
 call NativeReadHL
	inc HL
	ld H,(HL)
	ld L,A

	CALL NativeFillTexture

;-----------------------------------------
; Рисуем индикаторы количества жизней
	CALL DrawLifeIcons

;---------------------------------
; Рисуем разделитель игроков, если соответствующий режим игры
LBE8B_10:
	LD A,(game_mode)
	CP $02
	JP NZ,LBE8B_11
	ld HL,object_separator
	ld (IXobj),HL
	CALL hl_buf_addr_calc
	CALL print_obj_to_buff

;------------------------------
; Рисуем 1UP, HI и 2UP
LBE8B_11:
	LD HL,object_score_indicator
	ld (IXobj),HL
	inc HL
 push af
 ld a,$01
 call NativeWriteHL ; (IX+$01) = $01: spr_1up
 pop af
	inc HL
 push af
 ld a,$0c
 call NativeWriteHL ; (IX+$02) = $0C: «ИГРОК 1» по центру над счётом
 pop af
	CALL ix_buf_addr_calc
	CALL print_obj_to_buff
	ld HL,(IXobj)
	inc HL
	INC (HL)		; INC (IX+$01): spr_2up
	inc HL
 push af
 ld a,$bc
 call NativeWriteHL ; (IX+$02) = $BC: «ИГРОК 2» по центру над счётом
 pop af
	CALL ix_buf_addr_calc
	CALL print_obj_to_buff
	ld HL,(IXobj)
	inc HL
	INC (HL)		; INC (IX+$01): spr_hi
	inc HL
 push af
 ld a,$68
 call NativeWriteHL ; (IX+$02) = $68: «РЕКОРД» над счётом
 pop af
	CALL ix_buf_addr_calc
	CALL print_obj_to_buff

;----------------------------
; Рисуем цифры счетов игроков и рекорда
	LD HL,(score_1up_in_game)
	LD (score_screen_ptr),HL
	LD HL,current_score_1up+2
	CALL print_score_in_game

	LD HL,(score_2up_in_game)
	LD (score_screen_ptr),HL
	LD HL,current_score_2up+2
	CALL print_score_in_game

	LD HL,(hi_score_in_game)
	LD (score_screen_ptr),HL
	LD HL,hi_score+2
	CALL print_score_in_game


	CALL print_magnets

	CALL print_briks

;   IFDEF MX
; ; Рисует на поле тень от бордюра
; 	; Вертикаль
; 	LD HL,attr_buff+$0101
; 	LD B,$17
; LBFCF_0:
; 	ld a,(hl)
; 	and %01110111
; 	ld (hl),a
; 	inc l
; 	dec B
; 	jp nz,LBFCF_0
; 	; Горизонталь
; 	LD HL,attr_buff+$0201
; 	LD B,$1D
; LBFCF_1:
; 	ld a,(hl)
; 	and %01110111
; 	ld (hl),a
; 	INC h
; 	dec B
; 	jp nz,LBFCF_1
;   ENDIF

 jp DrawFieldFrame

; Графика текстуры уровня 1
  INCLUDE "./gfx/sprites_color_3.asm"
 INCLUDE "routines/smash_rotation_3.asm"

; Used by the routines at print_obj_from_buf_to_scr, LAFFC, print_sprite_pix, ix_buf_addr_calc and game_start.
; На входе в HL координаты
; H - Y (0-192)
; L - X (0-255)
; На выходе в HL адрес в буфере scr_buff ($DA00)
scr_buff_addr_calc:		; Specialist ready
	ld a,l
	rra
	rra
	rra
	and %11111
	ld b,a
	ld c,h
	ld hl,scr_buff
	add hl,bc
	ret

; Used by the routines at LAFFC and print_sprite_attrib.
; На входе в HL координаты,
; H - Y (0-192)
; L - X (0-255)
; на выходе там же адрес в буфере атрибутов D700
scr_buff_attr_calc:		; Specialist ready
	ld a,l
	rra
	rra
	rra
	and %11111
	ld b,a
	ld a,h
	rra
	rra
	rra
	and %11111
	ld c,a
	ld hl,attr_buff
	add hl,bc
	ret

; Процедуры работы со звуком
  INCLUDE "./routines/sound.asm"

;  INCLUDE "./routines/specialist.asm"

; Переменная для хранения адреса текущего объекта, заменяет регистр IX
IXobj:
	DEFW $0000

; Переменная для хранения адреса второго объекта (для сравнений), заменяет регистр IY
IYobj:
	DEFW $0000

; Переменная для хранения указателя на текущий уровень (для LAFFC), заменяет регистр IY
cur_level_ptr:
	DEFW $0000

; Указатель на текущий слот wins_recovery_data (LB2D8), заменяет регистр IX
wins_recovery_ptr:
	DEFW wins_recovery_data

; Временная переменная для (IXobj+$04) в print_obj_to_buff: читается ДО перенаправления SP
; в данные спрайта (см. LD SP,HL там) — после этого PUSH/POP использовать нельзя.
obj_y_coord_tmp:
	DEFB $00

; Временная переменная для адреса спрайта (результат sprite_search) в print_obj_to_buff:
; DE затирается ниже промежуточными LD DE,offset для эмуляции (IXobj+n), поэтому
; сохраняем его в память и восстанавливаем перед использованием как указатель на спрайт.
sprite_ptr_tmp:
	DEFW $0000

; Переменные для LA7A6 (размножение шариков): адрес шарика-источника и его координаты
ball_split_src:
	DEFW $0000
ball_split_x:
	DEFB $00
ball_split_y:
	DEFB $00

; Сохранение C (ширина магнита) вокруг obj_compare в handling_ball, заменяет EXX
magnet_c_save:
	DEFB $00

; Переменные для print_digit/print_score_in_game, заменяют EXX (альтернативный набор регистров)
score_screen_ptr:
	DEFW $0000
digit_ptr_save:
	DEFW $0000
digit_count_save:
	DEFB $00

; Указатель на текущий кадр анимации перелива металлических кирпичей, заменяет регистр IX
anim_brik_ptr:
	DEFW $0000

; Указатель на текущий слот briks_data в metal_brik_anim, заменяет регистр IY
metal_brik_slot_ptr:
	DEFW $0000

; Счётчик строк для byte_put_width_shift_*, заменяет EX AF,AF' (альтернативный AF)
; Obsolete shadow-renderer row counter removed.

; Переменная для обхода briks_data (LAFFC_34-37), заменяет регистр IX локально
briks_walk_ptr:
	DEFW $0000

; 3 байта - Системная переменная FRAMES (Системный счётчик $5C78)
frames:
	DEFB $00

; Сумма ширин (с некоторым коэффициентом) всех объектов на экране
; Shadow width sum removed.

; Количество шариков на поле
balls_quantity:
	DEFB $00

; Флаг. 0 или 1. Назначение пока непонятно.
flag_2:
	DEFB $00

; Счётчик. В одном месте обнуляется, в двух увеличивается. В одном месте сравнивается с 3.
counter_2:
	DEFB $00

; Если не 0, то нужно обновить цифры счёта на экране
scr_score_need_upd:
	DEFB $00

;--------------------------------------------
 INCLUDE "./routines/ui_colors.asm"
 INCLUDE "./routines/planes.asm"
 INCLUDE "./routines/native_background.asm"
; A dedicated background color follows the original four-level cycle.
SetPaletteLevel:
 ld a,1 ; the border continues the HUD paper around the screen
 ld (BorderColor),a
 ld a,FieldScroll ; Field starts at row 37; texture and side walls end at 255.
 ld (ScreenScroll),a
 ld a,(current_level_number_1up)
 and 3
 ld e,a
 ld d,0
 ld hl,LevelPaperColors
 add hl,de
 ld a,(hl)
 ld (PaletteGame+1),a
 ld hl,LevelTextureColors
 add hl,de
 ld a,(hl)
 ld (PaletteGame+2),a
 jp SetPaletteGame
 INCLUDE "routines/sparks_render.asm"
DrawLifeIcons:
; Рисуем индикаторы количества жизней
	LD A,$08		; Координата X для указателя первой жизни
	LD (object_lives_indicator+$02),A
	LD A,(lives_1up)
	DEC A
	RET Z		; One remaining life has no spare-life icon
	LD B,A
	ld HL,object_lives_indicator
	ld (IXobj),HL
LBE8B_8:
	PUSH BC
	CALL ix_buf_addr_calc
	CALL print_obj_to_buff
	LD A,(object_lives_indicator+$02)	; Координата X
	ADD A,$10		; на 16 правее
	CP $E9			; Если жизни не помещаются на экран, то не рисуем
	JP NC,LBE8B_9
	LD (object_lives_indicator+$02),A
LBE8B_9:
	POP BC
	dec B
	jp nz,LBE8B_8

	RET

 INCLUDE "routines/initial_objects.asm"






MonoRegionsIntersect EQU RCBegin
 INCLUDE "routines/mono_draw_bare.asm"
 INCLUDE "routines/mono_shift_draw.asm"
 INCLUDE "routines/mono_cache_reset.asm"
 INCLUDE "routines/magnet_center_draw.asm"
 INCLUDE "routines/cheat_keys.asm"
 INCLUDE "routines/cpc_bricks.asm"
 INCLUDE "routines/menu_controls.asm"
 INCLUDE "routines/mono_ball_shift.asm"
 INCLUDE "routines/restore_brick_fast.asm"
 INCLUDE "routines/magnet_background_cache.asm"
 INCLUDE "routines/brick_restore_queue.asm"
 INCLUDE "routines/mono_uncovered.asm"


BATTYCODE_END:
	ASSERT BATTYCODE_END <= $6b00

; Буфер на $100 Сюда копируются 180 ($B4) байт кирпичей из текущего уровня
current_level_copy EQU $6d00

; Буфер на $200 для сохранения объектов с тенью и фоном из экранного буфера (макс: 1 + $0B * $16 = $F3 = 243).
; В первой ячейке - количество объектов в буфере, далее $B объектов по $16 байт:
; +00 - младший адрес в экранном буфере
; +01 - старший адрес в экранном буфере
; +03 - шаг отступа для выполнения череды LDI
; +04 - высота спрайта с тенью в пикселях + 1
; +05...XX - данные спрайта с тенью и фоном
; Буфер должен быть не менее $200 байт

; Буферу и стеку хватает $200 байт
save_objs_buff EQU $6e00
; Верхушка стека
stack EQU $6c00

; Буфер на $2100 теневого экрана 256*256 точек = 256*(256/8) = $2000
; В конце нужно ещё 256 байт, которые портятся из-за тени от искры
scr_buff EQU $7000
attr_buff EQU scr_buff+$c0

; Буфер на $100 для $0B объектов по $16 байт = $DC
; Packed InitialObjectsData at $6c00 replaces the unpacked snapshot.

; Буфер размером $e00 ($1000 - $200) Адрес генерируемой таблицы сдвигов байтов
table_shifts EQU $7200

;=================================

; Reclaim the lower stack area for code/cache tags; keep 96 stack bytes.
; Natural death traces use 44 bytes including interrupt execution.
; Game, death and transition tests guard StackFloor on every instruction.
 IF $ < $6b00
 DS $6b00-$,0
 ENDIF
 ORG $6b00
 INCLUDE "routines/mono_isolation_data.asm"

 ASSERT $ <= $6b60
 IF $ < $6b60
 DS $6b60-$,0
 ENDIF
RCBoundary:
ClearShapeFlags:
 ret
LevelPaperColors: db $80,$10,$81,$03
LevelTextureColors: db $c0,$20,$c1,$05
 INCLUDE "routines/mono_cache_address.asm"
MonoZeroColumn EQU RCBegin
 INCLUDE "routines/game_over_score.asm"
 INCLUDE "routines/menu_pointer_row.asm"
 ASSERT $ <= $6ba0
StackFloor EQU $6ba0
; Exactly 180 level bytes are copied/swapped; the remaining 76 bytes are code.
 DS $6c00-$,0
 ORG $6c00
 INCLUDE "routines/initial_objects_data.asm"
SpriteBonusCache7 EQU $6c80
 ASSERT SpriteBonusCache7+128 <= current_level_copy
 DS $6c80-$,0
 ORG $6c80
 INCLUDE "routines/mono_window.asm"
 ASSERT $ <= $6d00
 DS $6db4-$,0
 ORG $6db4


RCReset:
 jp MonoReset
MonoIncludeRegion:
 ret ; obsolete isolation entry
 INCLUDE "routines/mono_pace_kernel.asm"
MonoShifts: ds 11,0
MonoDrawWhiteGeneral:
 ld a,b
 or a
 jp nz,MonoShiftDraw
 ld hl,(MonoDrawSource)
 dec hl
 ld a,(MonoDrawRows)
 cp (hl)
 jp nz,MonoShiftDraw
 jp MonoDraw
 INCLUDE "routines/game_over_panel.asm"

 ASSERT $ <= $6e00

 ; Renderer and per-owner phase cache in ordinary RAM below video.
 DS $7144-$,0
 ORG $7144

 INCLUDE "routines/native_static_masks.asm"
 ASSERT $ <= SpriteCacheOriginal
 DS $7200-$,0
 ORG $7200
 INCLUDE "routines/mono_renderer.asm"
 INCLUDE "routines/restore_brick_setup.asm"
 INCLUDE "routines/restore_brick_fringe_fast.asm"
 INCLUDE "routines/native_digit_cache.asm"
 INCLUDE "routines/pace_tail.asm"
MonoCodeEnd:
 ASSERT $ <= $7a00
 IF $ < $7a00
 DS $7a00-$,0
 ENDIF
 ORG $7a00
 DS $600,0
end_bin:
