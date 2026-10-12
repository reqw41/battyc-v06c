; Shared sprite selection, Smash timer and width accounting.
sprite_draw_prepare:
 ld hl,(IXobj)
 ld a,(hl)
	CP $02
	JP NZ,obj_processing_1	; Переходим, если объект не шарик

; Обработка объекта шарик
	LD A,(object_bat_1+$14)	; применённый к объекту бонус
	CP $07			; spr_bonus_smash
	JP Z,set_big_ball
	LD A,(object_bat_2+$14)	; применённый к объекту бонус
	CP $07			; spr_bonus_smash
	JP NZ,obj_processing

; Установка большого шарика
set_big_ball:
	ld HL,(IXobj)
	inc HL
	LD (HL),$08		; IX+$01 = spr_big_ball
	ld DE,$15-$01
	add HL,DE
	ld A,(HL)		; IX+$15
	and %01111111		; RES 7,(IX+$15)
	ld (HL),A		; IX+$15

; Обработка длительности действия приза
	LD A,(counter_misc)
	RRA
	JP C,obj_processing	; Переход, если нечётное значение counter_misc
	LD A,(smash_counter)
	INC A
	LD (smash_counter),A	; Увеличение счётчика длительности приза Smash
	CP $F8			; Длительность действия приза Smash
	JP C,obj_processing

; Отключение действия приза, если пришло время
	LD A,(object_bat_1+$14)	; применённый к объекту бонус
	CP $07			; spr_bonus_smash
	JP NZ,not_smash
	LD A,$FF
	LD (object_bat_1+$14),A	; применённый к объекту бонус
not_smash:
	LD A,(object_bat_2+$14)	; применённый к объекту бонус
	CP $07			; spr_bonus_smash
	JP NZ,obj_processing
	LD A,$FF
	LD (object_bat_2+$14),A	; применённый к объекту бонус

obj_processing:
 ld a,(balls_quantity)
 cp 3
 jp nc,obj_processing_1
 ld hl,(IXobj)
 ld a,(hl)
 cp 2
 jp nz,obj_processing_1
 inc hl
 ld a,(hl)
 cp 8
 jp nc,obj_processing_1
 ld (hl),0
 ld de,20
 add hl,de
 ld a,(hl)
 and $7f
 ld (hl),a
obj_processing_1:
 ret

; Direct OR blit. Source is the original mask/XOR pairs, read with POP.
; The visible bitmap against zero is mask XOR stored pixel.
; The descending E-plane row address replaces the ascending shadow address.
plane_object_fast:
 ld hl,(IXobj)
 ld a,(hl)
 or a
 jp p,pd_visible
 ld (hl),0
 ret
pd_visible:
 ; The normal field limits are constant. Only plane_static_object changes
 ; the three immediates while drawing persistent HUD sprites.
 inc hl
 inc hl
 ld a,(hl)
 ld (plane_x),a
 inc hl
 inc hl
 ld a,(hl)
pd_visible_limit:
 cp FieldSpriteLimit
 jp c,pd_position_valid
 ; Retire objects beyond the selected field/HUD limit.
 ld hl,(IXobj)
 ld (hl),0
 ret
pd_position_valid:
 ld (plane_y),a
 ; Keep previous coordinates used by collision guards, despite removing the
 ; old shadow renderer which used to write object offsets 14 and 15.
 ld de,10
 add hl,de
 ld a,(plane_x)
 ld (hl),a
 inc hl
 ld a,(plane_y)
 ld (hl),a
 call sprite_draw_prepare
 ld hl,(IXobj)
 call sprite_search
 ex de,hl
 ld a,(hl)
 or a
 ret z
 ld (direct_width),a
 inc hl
 ld a,(hl)
 ld b,a
 call MonoBonusHeight
 ld a,(plane_y)
 add a,b
pd_height_compare:
 cp FieldSpriteLimit+1
 jp c,pd_height
 ld a,(plane_y)
 ld b,a
pd_height_limit:
 ld a,FieldSpriteLimit
 sub b
 ld b,a
pd_height:
 ld a,b
 or a
 ret z
 ld (direct_rows),a
 ld a,1
 ld (color_valid),a
 inc hl
 ld (direct_source),hl
 ld hl,(IXobj)
 ld de,21
 add hl,de
 ld a,(hl)
 or a
 ld a,0
 jp m,pd_shift
 ld a,(plane_x)
 and 7
pd_shift:
 ld (direct_shift),a
 ld c,a
 ld a,(direct_width)
 ld b,a
 ld a,c
 or a
 jp z,pd_cols
 inc b
pd_cols:
 ld a,(plane_x)
 rrca
 rrca
 rrca
 and $1f
 ld c,a
 ld a,32
 sub c
 cp b
 jp nc,pd_unclipped
 ld b,a
pd_unclipped:
 ld a,b
 ld (direct_columns),a
 ld a,(plane_y)
 ld h,a
 ld a,(plane_x)
 ld l,a
 call screen_addr_calc
 ld a,h
 sub $40
 ld h,a
 ld (plane_dst),hl
 ex de,hl
 ld hl,(plane_slot)
 ld (hl),d
 inc hl
 ld (hl),e
 inc hl
 ld a,(direct_columns)
 ld (hl),a
 inc hl
 ld a,(direct_rows)
 ld (hl),a
 inc hl
 ld (plane_slot),hl
 ret

plane_x: db 0
plane_y: db 0
plane_dst: dw 0
plane_slot: dw plane_old
plane_old: ds 44,0
direct_source: dw 0
direct_width: db 0
direct_rows: db 0
direct_shift: db 0
direct_columns: db 0

; Draw a falling bonus before the wide paddle blit. Clearing at frame start
; and drawing it last could put its entire lifetime behind the raster beam.
; Temporarily remove it from the ordinary loop to keep one draw/erase slot.
DrawMovingObjects:
 jp MonoRender
