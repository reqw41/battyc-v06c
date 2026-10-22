; ПЛОСКОСТИ ЭКРАНА «3+1» И ЗАПИСЬ ФОНА.
; A000/C000/E000 — фон (восемь цветов), 8000 — белые движущиеся объекты
; (THREE_PLUS_ONE.md). Цвет фона в клетке 8x8 задаёт атрибут: старшая
; тетрада — номер в background_colors, а там индекс цвета 0..7, биты
; которого раскладываются по плоскостям: бит 0 — E, бит 1 — C, бит 2 — A.
; Бумага — всегда индекс 1 (только E), поэтому для точки бумаги E = 1, а
; для точки чернил E повторяет бит 0 цвета чернил.
; Исходная строка: A/C/E = eight background colours; 8000 = white overlay.
; planes_reset — очистить экран и атрибуты перед раундом. Все четыре
; плоскости заливаются одним проходом PUSH сверху вниз (SP = 0): первые
; 6 КБ (E800..FFFF) — FFh, дальше до 8000 — нули (переключение на 13-м
; блоке — PaperPlaneNextBlock в paper_plane_fill.asm). DI на время
; подмены стека. OUT (10h),0 перед заливкой выключает квазидиск, чтобы
; стековые записи шли в основную память. Затем все атрибуты = D0h,
; сброс оверлея и описателей вывода (MonoReset).
planes_reset:
 xor a
 ld hl,0
 add hl,sp
 ld (pr_restore+1),hl
 ld de,$ffff
 di
 out ($10),a
 ld hl,0
 ld sp,hl
 ld b,0
 ld c,16
pr_fill:
 DUP 4
 push de
 EDUP
 dec b
 jp nz,pr_fill
 jp PaperPlaneNextBlock
pr_restore:
 ld sp,0
 ei
 ld hl,NativeAttrs
 ld bc,NativeAttrBytes
pr_attrs:
 ld a,$d0
 ld (hl),a
 inc hl
 dec bc
 ld a,b
 or c
 jp nz,pr_attrs
 xor a
 ld (OverlayActive),a
 jp MonoReset
; background_write — записать байт рисунка фона (background_pixel) в
; клетку по адресу экрана C (DE), цветом из её атрибута.
; Вход: HL — виртуальная координата прежней игры (см. native_background:
; столбец 70h.., строка), DE — адрес в плоскости C. Портит AF.
background_write:
 call background_select
 jp background_write_selected
; background_select — по виртуальной координате HL найти атрибут клетки и
; положить её индекс цвета в background_color. Регистры, кроме A, целы.
background_select:
 push hl
 push bc
 push de
 ld a,l
 rrca
 rrca
 rrca
 and $1f
 or $c0
 ld l,a
 call NativeAttrAddress
 ld a,(hl)
 rrca
 rrca
 rrca
 rrca
 and $0f
 ld hl,background_colors
 call hl_add_a
 ld a,(hl)
 ld (background_color),a
 pop de
 pop bc
 pop hl
 ret
; background_write_selected — тот же вывод для уже выбранного цвета:
; C = рисунок, если бит 1 цвета; A = рисунок, если бит 2; E = FFh для
; нечётного цвета чернил, иначе инверсия рисунка (бумага — индекс 1).
background_write_selected:
 push bc
 push de
 ld a,(background_pixel)
 ld c,a
bw_field:
 ld a,(background_color)
 and 2
 ld a,0
 jp z,bw_c
 ld a,c
bw_c:
 ld (de),a
 ld a,d
 sub $20
 ld d,a
 ld a,(background_color)
 and 4
 ld a,0
 jp z,bw_a
 ld a,c
bw_a:
 ld (de),a
 ld a,d
 add a,$40
 ld d,a
 ; Paper index 1. Odd ink sets E too; even ink clears it.
 ld a,(background_color)
 and 1
 ld a,$ff
 jp nz,bw_e
 ld a,c
 cpl
bw_e:
 ld (de),a
 pop de
 pop bc
 ret
background_color: db 0
background_pixel: db 0
; Таблица: тетрада атрибута -> индекс цвета фона 0..7.
background_colors: db 6,4,3,6,7,4,5,6,7,4,5,6,7,2,6,0
; Прежний вход начала кадра: описатели теперь живут в MonoDesc/MonoOld.
planes_begin:
 ret ; descriptors live in MonoDesc/MonoOld, not plane_old
; FastErasePlain — обнулить прямоугольник в белой плоскости 8000.
; ClearDst — адрес верхней строки первого столбца (адрес плоскости E
; переводится в 8000 вычитанием 60h из старшего байта), ClearColumns,
; ClearRows. Столбец за столбцом, строки вниз (dec l). Портит AF, BC, HL.
FastErasePlain:
 ld hl,(ClearDst)
 ld a,h
 cp $e0
 jp c,fep_ready
 sub $60
 ld h,a
fep_ready:
 ld a,(ClearColumns)
 ld b,a
fep_col:
 push hl
 ld a,(ClearRows)
 ld c,a
fep_row:
 xor a
 ld (hl),a
 dec l
 dec c
 jp nz,fep_row
 pop hl
 inc h
 dec b
 jp nz,fep_col
 ret
; plane_erase_dual — то же с аргументами в регистрах: C = строк, B =
; столбцов, DE = адрес. Пустой прямоугольник (C = 0) — сразу выход.
plane_erase_dual:
 ld a,c
 or a
 ret z
 ld (ClearRows),a
 ld a,b
 ld (ClearColumns),a
 ex de,hl
 ld (ClearDst),hl
 jp FastErasePlain
 INCLUDE "routines/direct_sprites.asm"
; plane_static_object — нарисовать постоянный значок HUD (жизни, счёт)
; через plane_object со своим слотом и с пределами HUD вместо пределов
; поля: три операнда сравнения в plane_object_fast временно правятся на
; FEh и после вывода возвращаются в FieldSpriteLimit.
plane_static_object:
 ld hl,(plane_slot)
 push hl
 ld hl,plane_static_slot
 ld (plane_slot),hl
 ld a,$fe
 ld (pd_visible_limit+1),a
 ld (pd_height_limit+1),a
 inc a
 ld (pd_height_compare+1),a
 call plane_object
 ld a,FieldSpriteLimit
 ld (pd_visible_limit+1),a
 ld (pd_height_limit+1),a
 inc a
 ld (pd_height_compare+1),a
 pop hl
 ld (plane_slot),hl
 ret
plane_static_slot: ds 4,0
; plane_object — вывести объект IXobj белым в 8000 как статический значок
; (владелец 11): геометрия — plane_object_fast, сдвинутая графика — из кэша
; (MonoCachePrepare), вывод — MonoDraw по ИЛИ. color_valid = 0 — объект не
; виден, ничего не рисуется.
plane_object:
 xor a
 ld (color_valid),a
 call plane_object_fast
 ld a,(color_valid)
 or a
 ret z
 ld a,11
 ld (MonoOwner),a
 call MonoCachePrepare
 ld hl,(direct_source)
 ld (MonoDrawSource),hl
 ld hl,(plane_dst)
 ld (MonoDrawVideo),hl
 ld a,(direct_columns)
 ld (MonoDrawCols),a
 ld a,(direct_rows)
 ld (MonoDrawRows),a
 xor a
 ld (MonoFastDraw),a
 jp MonoDraw
color_valid: db 0
; Тёплый перезапуск: новый стек и игра заново.
WarmStart:
 ld sp,stack
 jp game_start
 INCLUDE "routines/mono_cache.asm"

; plane_screen_write — записать байт фона A по адресу экрана C (HL),
; переведя адрес в виртуальную координату прежней игры (страница scr_buff).
; Регистры, кроме AF, целы.
plane_screen_write:
 ld (background_pixel),a
 push hl
 push de
 push bc
 ex de,hl
 ld a,d
 sub $c0
 add a,scr_buff/256
 ld h,a
 ld a,$e0
 sub e
 ld l,a
 ld a,(background_pixel)
 call background_write
 pop bc
 pop de
 pop hl
 ret
