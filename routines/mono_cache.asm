; ОЖИДАНИЕ КАДРА И ПОСТРОЕНИЕ СДВИНУТОЙ ГРАФИКИ (кэш значков HUD).
; Подключается из planes.asm. Вторая половина цикла построения — ветка
; маски покрытия mnn_cover — лежит в mono_renderer.asm.
; WaitVideoFrame — дождаться следующего прерывания кадра, если с прошлого
; вызова его ещё не было. Последнее увиденное значение IntCount хранится
; прямо в операнде CP (самомодифицирующийся код). Включает прерывания.
WaitVideoFrame:
 ei
 ld a,(IntCount)
WaitVideoFrameLast:
 cp 0
 jp nz,wvf_ready
 halt
 ld a,(IntCount)
wvf_ready:
 ld (WaitVideoFrameLast+1),a
 ret
; SpriteCacheShiftSetup — построить в SpriteCacheBuffer копию графики
; SpriteCacheOriginal, сдвинутую на SpriteCacheShift точек вправо и
; обрезанную до SpriteCacheHeight строк. Вызывается из SpriteCacheBuild.
; Формат кэша: байт «столбцов» (на один больше исходного, если сдвиг не 0),
; байт «строк», затем столбцы пар (покрытие, белые точки) — как у исходной
; графики. Каждый байт источника делится на ведущую часть (остаётся в
; этом столбце) и переносимую (уходит в следующий): маски из
; SpriteShiftMasks. Сдвиг — вход в середину цепочки RRCA, адрес входа
; подставляется в JP. Источник читается POP через SP, поэтому DI до конца.
SpriteCacheShiftSetup:
 ld a,(SpriteCacheShift)
 add a,a
 ld hl,MonoNativeRotations
 call hl_add_a
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (mnn_lit_rotate+1),hl
 ld de,mnn_cover_r0-mnn_lit_r0
 add hl,de
 ld (mnn_cover_rotate+1),hl
 ld hl,SpriteShiftMasks
 ld a,(SpriteCacheShift)
 call hl_add_a
 ld a,(hl)
 ld (mnn_lit_lead+1),a
 ld (mnn_cover_lead+1),a
 cpl
 ld (mnn_lit_spill+1),a
 ld (mnn_cover_spill+1),a
 ld hl,mnn_cover_step
 ld de,mnn_lit_step
 ld a,(SpriteCacheShift)
 or a
 jp nz,mnn_select_spill
 ld hl,mnn_lit
 ld de,mnn_row_next
mnn_select_spill:
 ld (mnn_cover_skip+1),hl
 ex de,hl
 ld (mnn_lit_skip+1),hl
 ld hl,(SpriteCacheOriginal)
 ld a,(hl)
 ld (MonoNativeCols),a
 ld b,a
 ld a,(SpriteCacheShift)
 or a
 jp z,mnn_width
 inc b
mnn_width:
 inc hl
 ld a,(SpriteCacheHeight)
 ld c,a
 ld a,(hl)
 sub c
 add a,a
 ld (mnn_source_skip+1),a
 ld hl,(SpriteCacheBuffer)
 ld (hl),b
 inc hl
 ld a,c
 ld (hl),a
 add a,a
 ld (mnn_cover_to_next+1),a
 ld (mnn_cover_from_next+1),a
 ld (mnn_lit_to_next+1),a
 ld (mnn_lit_from_next+1),a
 inc hl
 ld (MonoNativeDest),hl
 ld a,1
 ld (MonoNativeFirst),a
 ld hl,0
 add hl,sp
 ld (mnn_restore+1),hl
 ld hl,(SpriteCacheOriginal)
 inc hl
 inc hl
 di
 ld sp,hl
 ld hl,(MonoNativeDest)
; Первый столбец кэша записывается (операнд слияния = NOP), следующие
; сливаются с тем, что туда уже перенёс предыдущий столбец: белые точки по
; ИЛИ (B6h = OR M), маска покрытия по И (A6h = AND M).
mnn_col:
 ld a,(MonoNativeFirst)
 or a
 ld a,0
 ld b,a
 jp nz,mnn_select_merge
 ld a,$b6 ; OR M for lit
 ld b,$a6 ; AND M for cover
mnn_select_merge:
 ld (mnn_lit_merge),a
 ld a,b
 ld (mnn_cover_merge),a
 ld a,(SpriteCacheHeight)
 ld c,a
mnn_row:
 pop de
mnn_cover_select:
 jp mnn_lit
mnn_lit:
 inc hl
 ld a,d
mnn_lit_rotate:
 jp mnn_lit_r0
mnn_lit_r7: rrca
mnn_lit_r6: rrca
mnn_lit_r5: rrca
mnn_lit_r4: rrca
mnn_lit_r3: rrca
mnn_lit_r2: rrca
mnn_lit_r1: rrca
mnn_lit_r0:
 ld d,a
mnn_lit_lead:
 and $ff
mnn_lit_merge:
 or (hl)
mnn_lit_store:
 ld (hl),a
mnn_lit_skip:
 jp mnn_lit_step
; Перенос: та часть байта, что ушла за край, кладётся в ту же строку
; следующего столбца кэша (через 2*строк байт) и сразу возврат обратно.
mnn_lit_step:
 ld a,l
mnn_lit_to_next:
 add a,0
 ld l,a
 jp nc,mnn_lit_next_ready
 inc h
mnn_lit_next_ready:
 ld a,d
mnn_lit_spill:
 and 0
 ld (hl),a
 ld a,l
mnn_lit_from_next:
 sub 0
 ld l,a
 jp nc,mnn_row_next
 dec h
mnn_row_next:
 inc hl
 dec c
 jp nz,mnn_row
; Конец столбца: пропустить в источнике строки, не вошедшие в высоту
; вывода (2 байта на строку), и перейти к следующему столбцу.
 ld (MonoNativeDest),hl
 ld hl,0
 add hl,sp
mnn_source_skip:
 ld de,0
 add hl,de
 ld sp,hl
 ld hl,(MonoNativeDest)
 ld a,(SpriteCacheShift)
 or a
 jp z,mnn_nextcol
 xor a
 ld (MonoNativeFirst),a
mnn_nextcol:
 ld a,(MonoNativeCols)
 dec a
 ld (MonoNativeCols),a
 jp nz,mnn_col
mnn_restore:
 ld sp,0
 ei
 ret
MonoNativeRotations: dw mnn_lit_r0,mnn_lit_r1,mnn_lit_r2,mnn_lit_r3
 dw mnn_lit_r4,mnn_lit_r5,mnn_lit_r6,mnn_lit_r7
MonoNativeCols: db 0
MonoNativeFirst: db 0
MonoNativeDest: dw 0
MonoBuildBat: db 0

 INCLUDE "routines/restore_background_tail.asm"
