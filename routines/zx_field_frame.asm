; ZX field frame in the three RGB planes: pipes and connectors, one bit per
; pixel, coloured by two masks per material (see verify/generate-zx-frame.js).
; A = bits & maskA, C = bits & maskC, E = ~bits | maskC.
; Permanent graphics: drawn once per level, no per-frame repair.
; DrawFieldFrame — нарисовать рамку поля (MERGE.md, «Прочее»: рамка из ZX
; Spectrum, раскраска по мотивам ремейка). Рисунок и раскраска ячеек
; генерируются: verify/generate-zx-frame.js -> gfx/zx_frame.asm
; (ZxFrameTop/Side, последовательности ячеек *Seq и маски *Masks).
; Верхняя полоса — 32 ячейки по 8 строк в строке E0h, правая половина —
; зеркало левой (ячейки в обратном порядке, биты отражены). Боковые
; стенки — столбцы C0h и DFh от строки D8h вниз на FieldHeight-8 строк,
; ячейки по кругу из 7; правая стенка — зеркальная. Ячейку рисует
; zf_cell (mono_renderer.asm). Портит всё.
DrawFieldFrame:
 ld a,1
 ld (zf_mode+1),a ; top band: the masks are row patterns
 ld hl,$c0e0
 xor a
; Номер ячейки 0..31: для 16..31 берётся ячейка 31-i с отражением.
; Байт последовательности: младшие 2 бита — пара масок материала,
; старшие — номер рисунка ячейки (по 8 байт).
zf_top:
 ld (zf_top_index+1),a
 cp 16
 sbc a,a
 cpl
 ld (zf_mirror+1),a ; right half: mirrored cells in reverse order
 ld a,(zf_top_index+1)
 jp nz,zf_top_source
 cpl
 and 15
zf_top_source:
 push hl
 ld e,a
 ld d,0
 ld hl,ZxFrameTopSeq
 add hl,de
 ld a,(hl)
 ld c,a
 and 3
 add a,a
 ld e,a
 ld hl,ZxFrameTopMasks
 add hl,de
 ld a,(hl)
 ld (zf_pattern_a),a
 inc hl
 ld a,(hl)
 ld (zf_pattern_c),a
 ld a,c
 and $fc
 add a,a
 ld e,a
 ld hl,ZxFrameTop
 add hl,de
 ex de,hl
 pop hl
 ld c,8
 call zf_cell
 ld l,$e0
 inc h
zf_top_index:
 ld a,0
 inc a
 cp 32
 jp nz,zf_top
 xor a
 ld (zf_mode+1),a ; side walls: plain bit masks
 ld (zf_mirror+1),a
 ld h,$c0
 call zf_side
 ld a,$ff
 ld (zf_mirror+1),a
 ld h,$df
; Стенка: ячейки по кругу ZxFrameSideSeq (7 штук), маски постоянные;
; последняя ячейка может быть короче 8 строк.
zf_side:
 ld l,$d8
 ld b,FieldHeight-8
zf_side_wrap:
 xor a
zf_side_cell:
 ld (zf_side_index+1),a
 push hl
 ld e,a
 ld d,0
 ld hl,ZxFrameSideSeq
 add hl,de
 ld a,(hl)
 add a,a
 ld hl,ZxFrameSideMasks
 call hl_add_a
 ld a,(hl)
 ld (zf_mask_a+1),a
 inc hl
 ld a,(hl)
 ld (zf_mask_c+1),a
 ld (zf_mask_e+1),a
 ld a,e
 add a,a
 add a,a
 add a,a
 ld e,a
 ld hl,ZxFrameSide
 add hl,de
 ex de,hl
 pop hl
 ld a,b
 cp 8
 jp c,zf_side_rows
 ld a,8
zf_side_rows:
 ld c,a
 ld a,b
 sub c
 ld b,a
 push bc
 call zf_cell
 pop bc
 ld a,b
 or a
 ret z
zf_side_index:
 ld a,0
 inc a
 cp 7
 jp nz,zf_side_cell
 jp zf_side_wrap
zf_pattern_a: db 0
zf_pattern_c: db 0
