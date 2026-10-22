; НЕ СОБИРАЕТСЯ. Этот файл не подключает ни batty.asm, ни другие
; собираемые файлы: остаток прежнего варианта вывода — четырёхплоскостная
; база до опытов с тремя плоскостями (PREPARED-SPRITES.md).
; Появился в c77b911, 11.10.2026; подключение снято в 75e0011, 11.10.2026 —
; переход на вывод «3+1».
; Текущий вывод — routines/mono_renderer.asm. Оставлен как архив решений:
; при правках игры его не трогать.
; Compact shifted masks and short-column composition in ordinary 64K RAM.
WaitVideoFrame:
 ; SP blits can mask the raster IRQ. Skip HALT only when a conservative
 ; instruction-cost bound proves the preceding work took >= one frame.
 ld hl,(PaceWork)
 ld de,-936             ; 936*64 = 59904 Vector cycles, one raster frame
 add hl,de
 ld hl,0
 ld (PaceWork),hl
 jp c,wvf_slow
 ei
 ld a,(IntCount)
WaitVideoFrameLast:
 cp 0
 jp nz,wvf_ready
 halt
 ld a,(IntCount)
 jp wvf_ready
wvf_slow:
 ei
 ld a,(IntCount)
wvf_ready:
 ld (WaitVideoFrameLast+1),a
 ret

; Lower bounds, generated/checked in JS against actual i8080 execution.
; Draw includes the preceding successful SUSaveObject, whose fixed setup
; plus sprite geometry/cache selection exceeds 2048 cycles. No game logic,
; IRQ or accounting cost is counted. Saturate so long cold/background paths
; cannot wrap the bound.
PaceAccountDraw:
 ld a,(direct_rows)
 ld hl,PaceDrawCols
 call hl_add_a
 ld e,(hl)
 ld d,0
 ld a,(direct_columns)
 ld b,a
 ld hl,49               ; floor((680+456+2048)/64)
 jp pace_multiply
PaceAccountRestore:
 ld a,(SUWorkRows)
 or a
 rra
 ld hl,PaceRestoreCols
 call hl_add_a
 ld e,(hl)
 ld d,0
 ld a,(SUWorkCols)
 ld b,a
 ld hl,9                ; floor(628/64)
pace_multiply:
 add hl,de
 dec b
 jp nz,pace_multiply
 ex de,hl
 ld hl,(PaceWork)
 add hl,de
 jp nc,pace_store
 ld hl,$ffff
pace_store:
 ld (PaceWork),hl
 ret
PaceDrawCols:
 db 0,13,15,18,20,23,25,28,30,33,35,38,40,43,45,48,50
 db 53,55,58,60,63,65,68,70,74,75,78,80,84,85,88,90
PaceRestoreCols:
 db 0,3,4,6,7,8,10,11,13,14,15,17,18,19,21,22,24
 db 25,26,28,29,30,32,33,35,36,37,39,40,41,43,44,46
SpriteShiftMasks: db $ff,$7f,$3f,$1f,$0f,$07,$03,$01
NativeRotateByte:
 push hl
 ld b,a
 ld a,(NativeShift)
 ld c,a
 ld hl,SpriteShiftMasks
 call hl_add_a
 ld a,b
nrb_loop:
 rrca
 dec c
 jp nz,nrb_loop
 ld b,a
 and (hl)
 push af
 ld a,(hl)
 cpl
 and b
 ld c,a
 pop af
 pop hl
 ret
SpriteCachePrepare:
 ld hl,(direct_source)
 dec hl
 ld a,(hl)
 ld (SpriteCacheHeight),a
 dec hl
 ld (SpriteCacheOriginal),hl
 ld a,(direct_shift)
 ld (SpriteCacheShift),a
 ld b,a
 ld hl,(IXobj)
 ld a,(hl)
 and $7f
 cp 1
 jp z,scp_bat
 cp 2
 jp z,scp_ball
 cp 4
 jp z,scp_bonus
 cp 7
 jp c,scp_scratch
 cp 11
 jp nc,scp_scratch
 ld a,(direct_width)
 cp 4
 jp nc,scp_scratch
 ld a,(SpriteCacheHeight)
 cp 20
 jp nc,scp_scratch
 ld a,b
 or 8
 jp scp_phase_index
scp_bonus:
 ld a,(direct_width)
 cp 4
 jp nc,scp_scratch
 ld a,(SpriteCacheHeight)
 cp 16
 jp nc,scp_scratch
 ld a,b
 jp scp_phase_index
scp_bat:
 ld a,(plane_x)
 and 7
 or 16
 jp scp_phase_index
scp_ball:
 ld a,(plane_x)
 and 7
 or 24
scp_phase_index:
 ld (SpriteCacheIndex),a
 add a,a
 ld hl,SpriteCacheMeta
 call hl_add_a
 ld (SpriteCacheEntry),hl
 push hl
 ld hl,(SpriteCacheOriginal)
 ex de,hl
 pop hl
 ld a,e
 cp (hl)
 jp nz,scp_miss
 inc hl
 ld a,d
 cp (hl)
 jp nz,scp_miss
 jp scp_hit
scp_miss:
 ld hl,(SpriteCacheOriginal)
 ex de,hl
 ld hl,(SpriteCacheEntry)
 ld (hl),e
 inc hl
 ld (hl),d
 call SpriteCacheAddress
 call SpriteCacheBuild
scp_hit:
 call SpriteCacheAddress
 jp scp_result
scp_scratch:
 ld hl,SUScratch
 ld (SpriteCacheBuffer),hl
 call SpriteCacheBuild
 ld hl,SUScratch
scp_result:
 ld a,(hl)
 ld (direct_width),a
 inc hl
 inc hl
 ld (direct_source),hl
 xor a
 ld (direct_shift),a
 inc a
 ld (PreparedFlag),a
 ret
SpriteCacheBuild:
 call SpriteSetRotation
 jp scb_source
SpriteSetRotation:
 ld hl,SpriteShiftMasks
 ld a,(SpriteCacheShift)
 call hl_add_a
 ld a,(hl)
 ld (scr_lead+1),a
 cpl
 ld (scr_spill+1),a
 ld a,(SpriteCacheShift)
 add a,a
 ld hl,SpriteRotateTable
 call hl_add_a
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (scr_jump+1),hl
 ret
scb_source:
 ld hl,(SpriteCacheOriginal)
 ld e,(hl)
 ld a,e
 ld (SpriteCacheWidth),a
 ld a,(SpriteCacheShift)
 or a
 jp z,scb_width
 inc e
scb_width:
 ld hl,(SpriteCacheBuffer)
 ld (hl),e
 inc hl
 ld a,(SpriteCacheHeight)
 ld (hl),a
 ld (SpriteCacheRows),a
 add a,a
 dec a
 ld (scb_column_step+1),a
 inc hl
 ld (PreparedRow),hl
 push hl
 ld hl,(SpriteCacheOriginal)
 inc hl
 inc hl
 ex de,hl
 pop hl
scb_row:
 ld hl,(PreparedRow)
 xor a
 ld (SpriteCacheCarryMask),a
 ld (SpriteCacheCarryPixel),a
 ld a,(SpriteCacheWidth)
 ld (SpriteCacheBytes),a
scb_byte:
 ld a,(de)
 inc de
 call SpriteRotate
 ld b,a
 ld a,(SpriteCacheCarryMask)
 or b
 ld (PreparedCover),a
 ld a,c
 ld (SpriteCacheCarryMask),a
 ld a,(de)
 inc de
 call SpriteRotate
 ld b,a
 ld a,(SpriteCacheCarryPixel)
 or b
 call scb_pair
 ld a,c
 ld (SpriteCacheCarryPixel),a
 ld a,(SpriteCacheBytes)
 dec a
 ld (SpriteCacheBytes),a
 jp nz,scb_byte
 ld a,(SpriteCacheShift)
 or a
 jp z,scb_next_row
 ld a,(SpriteCacheCarryMask)
 ld (PreparedCover),a
 ld a,(SpriteCacheCarryPixel)
 call scb_pair
scb_next_row:
 ld hl,(PreparedRow)
 inc hl
 inc hl
 ld (PreparedRow),hl
 ld a,(SpriteCacheRows)
 dec a
 ld (SpriteCacheRows),a
 ret z
 jp scb_row
scb_pair:
 ; Native pair = complement of cover, then lit pixels. Both white and
 ; enemy-coloured rows share this encoding; draw selects destination planes.
 ld b,a
 ld a,(PreparedCover)
 and b
 ld b,a
 ld a,(PreparedCover)
 cpl
 ld (hl),a
 inc hl
 cpl
 xor b
 ld (hl),a
scb_step:
scb_column_step:
 ld a,0
 jp hl_add_a
SpriteRotate:
scr_jump:
 jp scr0
scr7: rrca
scr6: rrca
scr5: rrca
scr4: rrca
scr3: rrca
scr2: rrca
scr1: rrca
scr0:
 ld b,a
scr_lead:
 and $ff
 push af
 ld a,b
scr_spill:
 and 0
 ld c,a
 pop af
 ret

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

SpriteCacheOriginal EQU $71d1
SpriteCacheEntry EQU $71d3
SpriteCacheBuffer EQU $71d5
SpriteCacheIndex EQU $71d7
SpriteCacheShift EQU $71d8
SpriteCacheHeight EQU $71d9
SpriteCacheWidth EQU $71da
SpriteCacheRows EQU $71db
SpriteCacheBytes EQU $71dc
SpriteCacheCarryMask EQU $71dd
SpriteCacheCarryPixel EQU $71de
ClearDst EQU $71df
ClearColumns EQU $71e1
ClearRows EQU $71e2
ClearPass EQU $71e3
NativeMagnetSetOverlay:
 push hl
 push af
 ld hl,(IXobj)
 ld a,l
 sub magnet_properties & $ff
 rrca
 rrca
 rrca
 rrca
 and 3
 ld hl,NativeMagnetOverlayFlags
 call hl_add_a
 pop af
 ld (hl),a
 pop hl
 ret
 INCLUDE "routines/three_plane_saveunder.asm"
 INCLUDE "routines/prepared_sprites.asm"
PreparationCache5 EQU start_bin+3
 ASSERT PreparationCache5+256 <= spr_1up
SpriteCacheChoose:
 ld a,(SpriteCacheIndex)
 add a,a
 ld hl,SpriteCacheAddresses
 call hl_add_a
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (SpriteCacheBuffer),hl
 ret
SpriteCacheAddress:
 jp SpriteCacheChoose
SpriteCacheAddresses:
 dw SpriteBonusCache0,SpriteBonusPixels,SpriteBonusPixels+128,SpriteBonusPixels+256
 dw $0040,PreparationCache5,PreparationCache5+128,SpriteBonusCache7
 dw SpriteEnemyCache0,SpriteEnemyPixels,SpriteEnemyPixels+160,SpriteEnemyPixels+320
 dw SpriteEnemyPixels+480,SpriteEnemyPixels+640,SpriteEnemyPixels+800,SpriteEnemyPixels+960
 DUP 8,phase
 dw $9000+phase*176
 EDUP
 DUP 8,phase
 dw $9580+phase*64
 EDUP
SpriteCacheReset:
 ld hl,SpriteCacheMeta
 ld b,64
 xor a
scr_meta:
 ld (hl),a
 inc hl
 dec b
 jp nz,scr_meta
 ret
FastObjectCodeEnd:
 ASSERT $ <= $7840
SpriteBonusCache0 EQU $7840
SpriteEnemyCache0 EQU $78c0
SpriteBonusPixels EQU $7970
SpriteEnemyPixels EQU $7af0
 DS $7f50-$,0
 ORG $7f50
 INCLUDE "routines/restore_background_tail.asm"
FastObjectTailEnd:
 ASSERT FastObjectTailEnd <= $8000
