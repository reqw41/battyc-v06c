; НЕ СОБИРАЕТСЯ. Этот файл не подключает ни batty.asm, ни другие
; собираемые файлы: остаток прежнего варианта вывода — «3+1»: составная бита
; из двух половин (THREE_PLUS_ONE_TRANSFORMS.md).
; Появился в 6c3249e, 12.10.2026; подключение снято в 2d9cd0e, 13.10.2026 —
; вывод «замещение на месте», MERGE.md.
; Текущий вывод — routines/mono_renderer.asm. Оставлен как архив решений:
; при правках игры его не трогать.
; Fold the two animated halves into one white descriptor before isolation.
; Physical collision objects and transformation timing remain separate.
MonoPairActive EQU $71e5
MonoCompositeBat:
 xor a
 ld (MonoPairActive),a
 ld hl,object_bat_1
 ld a,(hl)
 dec a
 ret nz
 inc hl
 ld a,(hl)
 cp 2
 ret nz
 ld hl,object_bat_temp
 ld a,(hl)
 dec a
 ret nz
 inc hl
 ld a,(hl)
 cp 3
 ret nz
 ld hl,(mono_new_base+1)
 ld de,49
 add hl,de
 ld (mcb_desc+1),hl
 ld a,(hl)
 ld b,a
 ld de,7
 add hl,de
 ld a,(hl)
 cp b
 ret nz
 inc hl
 ld a,(hl)
 ld c,a
 ld de,-7
 add hl,de
 ld a,c
 sub (hl)
 ret c
 cp 5
 ret nc
 ld (mcb_delta+1),a
 inc hl
 ld a,(hl)
 or a
 ret z
 inc hl
 ld a,(hl)
 cp 10
 ret nz
 ld de,6
 add hl,de
 ld a,(hl)
 or a
 ret z
 inc hl
 ld a,(hl)
 cp 10
 ret nz
 ; Fold the geometry first. Isolated halves can draw directly through SP.
 ld hl,(mcb_desc+1)
 inc hl
 inc hl
 ld b,(hl)
 push hl
 ld de,7
 add hl,de
 ld a,(hl)
 ld (hl),0
 ld c,a
 ld a,(mcb_delta+1)
 add a,c
 cp b
 jp nc,mcb_geometry_width
 ld a,b
mcb_geometry_width:
 pop hl
 ld (hl),a
 ld a,1
 ld (MonoPairActive),a
 ret
