; НЕ СОБИРАЕТСЯ. Этот файл не подключает ни batty.asm, ни другие
; собираемые файлы: остаток прежнего варианта вывода — локальные группы
; спрайтов и композиция в ОЗУ («три плоскости», THREE-PLANE-LOCAL-
; COMPOSITOR.md).
; Появился в c3bf6bb, 11.10.2026; подключение снято в 75e0011, 11.10.2026 —
; переход на вывод «3+1».
; Текущий вывод — routines/mono_renderer.asm. Оставлен как архив решений:
; при правках игры его не трогать.
; Isolated moving owner: copy only old/new intersection from saved BG,
; sample new fringes, shade final sprite, then erase only retiring fringes.
CGIsolated:
 xor a
 ld (CGRecord+3),a
 ld hl,(CGDPtr)
 ex de,hl
 ld hl,(CGOPtr)
 ld a,(de)
 cp (hl)
 jp nz,cgi_general
 inc de
 inc de
 inc de
 inc hl
 inc hl
 inc hl
 ld a,(de)
 cp (hl)
 jp nz,cgi_general
 ld a,1
 ld (CGRecord+3),a
cgi_general:
 ld hl,(CGDPtr)
 inc hl
 inc hl
 ld a,(hl)
 or a
 jp z,cgi_retired
 xor a
 ld (CGRecord),a             ; 0 capture; 1 restore only outer fringes
 ld hl,(CGOPtr)
 ld (CGRecord+4),hl
 ld hl,(CGDPtr)
 call CGOutside
 call CGLoad
 call SpriteCachePrepare
 call CGShadeSaved
cgi_retired:
 ld a,1
 ld (CGRecord),a
 ld hl,(CGDPtr)
 ld (CGRecord+4),hl
 ld hl,(CGOPtr)
 jp CGOutside
CGOutside:
 ld e,(hl)
 inc hl
 ld d,(hl)
 ld a,d
 sub $e0
 ld (CGColumn),a
 inc hl
 ld a,(hl)
 or a
 ret z
 ld (CGCols),a
 inc hl
 ld a,(hl)
 ld (CGRows),a
 dec a
 add a,e
 ld e,a
 ex de,hl
 ld (CGVideo),hl
 inc l
 ld a,l
 ld (CGTileEnd),a
 ex de,hl
 inc hl
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (CGSource),hl
 ld a,(CGRows)
 ld b,a
 ld a,(CGTileEnd)
 sub b
 ld (CGTileLow),a
cgo_column:
 ld hl,(CGRecord+4)
 ld a,(CGRecord+3)
 or a
 jp z,cgo_vertical
 call CGHorizontalIntersect
 jp c,cgo_whole
 ld a,(CGRecord)
 or a
 jp nz,cgo_nextcol
 ld hl,(CGSource)
 ex de,hl
 ld hl,(CGSpanBG)
 ld a,(CGRows)
 call CGCopyPacked
 jp cgo_nextcol
cgo_vertical:
 call CGIntersect
 jp c,cgo_whole
 ld a,(CGSpanDst)
 sub CGScratchE%256
 ld b,a
 ld a,(CGTileLow)
 add a,b
 ld b,a
 ld a,(CGVideo)
 sub b
 ld (CGWhite),a              ; upper fringe rows
 ld a,(CGRecord)
 or a
 jp nz,cgo_upper
 ld a,(CGWhite)
 add a,a
 ld hl,(CGSource)
 call hl_add_a
 ex de,hl
 ld hl,(CGSpanBG)
 ld a,(CGSpanRows)
 call CGCopyPacked
cgo_upper:
 ld a,(CGWhite)
 ld hl,(CGVideo)
 push hl
 ld hl,(CGSource)
 ex de,hl
 pop hl
 call CGOutsideSpan
 ld a,(CGSpanRows)
 ld b,a
 ld a,(CGWhite)
 add a,b
 ld b,a
 ld hl,(CGVideo)
 ld a,l
 sub b
 ld l,a
 push hl
 ld a,b
 add a,a
 ld hl,(CGSource)
 call hl_add_a
 ex de,hl
 pop hl
 ld a,(CGRows)
 sub b
 call CGOutsideSpan
 jp cgo_nextcol
cgo_whole:
 ld hl,(CGVideo)
 push hl
 ld hl,(CGSource)
 ex de,hl
 pop hl
 ld a,(CGRows)
 call CGOutsideSpan
cgo_nextcol:
 ld hl,(CGVideo)
 inc h
 ld (CGVideo),hl
 ld hl,(CGSource)
 ld a,(CGRows)
 add a,a
 call hl_add_a
 ld (CGSource),hl
 ld a,(CGColumn)
 inc a
 ld (CGColumn),a
 ld a,(CGCols)
 dec a
 ld (CGCols),a
 jp nz,cgo_column
 ret
