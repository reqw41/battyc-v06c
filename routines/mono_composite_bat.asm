; НЕ СОБИРАЕТСЯ. Этот файл не подключает ни batty.asm, ни другие
; собираемые файлы: остаток прежнего варианта вывода — «3+1»: составная бита
; из двух половин (THREE_PLUS_ONE_TRANSFORMS.md).
; Появился в 6c3249e, 12.10.2026; подключение снято в 2d9cd0e, 13.10.2026 —
; вывод «замещение на месте», MERGE.md.
; Текущий вывод — routines/mono_renderer.asm. Оставлен как архив решений:
; при правках игры его не трогать.
MonoPairPrepare:
 ld a,(MonoPairActive)
 or a
 ret z
 ld a,(MonoRegions+39)
 or a
 ret nz
 ld a,2
 ld (MonoPairActive),a
 ld a,7
 call mcb_build
 ld a,8
 call mcb_build
 ld a,7
 ld (MonoOwner),a
 ld a,($7cd8)
 ld b,a
mcb_delta:
 ld a,0
 add a,b
 ld b,a
 ld a,($7c34)
 cp b
 jp nc,mcb_width
 ld hl,$7c36
 ld e,a
 ld d,0
 ; Columns have 20 bytes; clear only the new tail of the left cache.
 ld c,a
mcb_offset:
 ld de,20
 add hl,de
 dec c
 jp nz,mcb_offset
 ld c,a
 ld a,b
 sub c
 ld c,a
mcb_clear_col:
 ld d,10
mcb_clear_row:
 ld (hl),$ff
 inc hl
 ld (hl),0
 inc hl
 dec d
 jp nz,mcb_clear_row
 dec c
 jp nz,mcb_clear_col
 ld a,b
mcb_width:
 ld ($7c34),a
mcb_desc:
 ld hl,0
 inc hl
 inc hl
 ld (hl),a
 inc hl
 inc hl
 ld (hl),$36
 inc hl
 ld (hl),$7c
 inc hl
 inc hl
 inc hl
 inc hl
 ld (hl),0 ; suppress temp descriptor width
 xor a
 ld (MonoShifts+7),a
 ld (MonoTags+29),a ; composite invalidates the left source/phase tag
 ld a,(mcb_delta+1)
 ld hl,$7c37
 or a
 jp z,mcb_merge_ready
 ld b,a
 ld de,20
mcb_merge_offset:
 add hl,de
 dec b
 jp nz,mcb_merge_offset
mcb_merge_ready:
 ld de,$7cdb
 ld a,($7cd8)
 ld b,a
mcb_merge_col:
 ld c,10
mcb_merge_row:
 ld a,(de)
 or (hl)
 ld (hl),a
 inc de
 inc de
 inc hl
 inc hl
 dec c
 jp nz,mcb_merge_row
 dec b
 jp nz,mcb_merge_col
 ret
