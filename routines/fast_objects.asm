; Compact shifted masks and short-column composition in ordinary 64K RAM.
WaitVideoFrame:
 ; Keep the 50 Hz ceiling, but do not wait an extra frame after a slow step.
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
 ld a,(direct_shift)
 or a
 ret z
 ld hl,(IXobj)
 ld a,(hl)
 and $7f
 cp 4
 jp z,scp_eligible
scp_enemy_kind:
 ; Sparks borrow the enemy cache during the death effect.
 cp 7
 ret c
 cp 11
 ret nc
scp_eligible:
scp_kind:
 ld hl,(IXobj)
 ld a,(hl)
 and $7f
 cp 4
 ld bc,$1404
 jp nz,scp_size
 ld bc,$1004
scp_size:
 ld a,(direct_width)
 cp c
 ret nc
 ld hl,(direct_source)
 dec hl
 ld a,(hl)
 cp b
 ret nc
 ld (SpriteCacheHeight),a
 dec hl
 ld (SpriteCacheOriginal),hl
 ld a,(direct_shift)
 ld (SpriteCacheShift),a
 ld b,a
 ld hl,(IXobj)
 ld a,(hl)
 and $7f
 cp 4
 ld a,b
 jp z,scp_phase_index
 or 8
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
 ld a,(hl)
 and 7
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
 ld hl,scb_white
 ld (scb_store+1),hl
 ld a,(color_enemy)
 or a
 ld a,0
 jp z,scb_set_boundary
 ld a,(SpriteCacheHeight)
 ld b,a
 or a
 rra
 ld c,a
 ld a,b
 sub c
scb_set_boundary:
 ld (scb_boundary+1),a
 pop hl
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
scb_boundary:
 cp 0
 jp nz,scb_row
 ld hl,scb_enemy
 ld (scb_store+1),hl
 jp scb_row
scb_pair:
 ld b,a
 ld a,(PreparedCover)
 and b
 ld b,a
 ld a,(PreparedCover)
scb_store:
 jp scb_white
scb_enemy:
 ld (hl),b
 inc hl
 ld (hl),a
 jp scb_step
scb_white:
 ld (hl),a
 inc hl
 ld (hl),b
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
 INCLUDE "routines/local_composite.asm"
 INCLUDE "routines/prepared_sprites.asm"
; Startup inversion and shift generator are dead after initial preparation.
; Entry is patched to WarmStart before these bytes become a cache.
PreparationCache5 EQU start_bin+3
 ASSERT PreparationCache5+256 <= spr_1up
SpriteCacheChoose:
 ld a,(SpriteCacheIndex)
 cp 4
 jp z,scc_low
 cp 5
 jp z,scc_prep5
 cp 6
 jp z,scc_prep6
 cp 7
 jp nz,SpriteCacheAddressBody
 ld hl,SpriteBonusCache7
 jp scc_ready
scc_prep6:
 ld hl,PreparationCache5+128
 jp scc_ready
scc_prep5:
 ld hl,PreparationCache5
 jp scc_ready
scc_low:
 ld hl,$0040
scc_ready:
 ld (SpriteCacheBuffer),hl
 ret
FastObjectCodeEnd:
SpriteCachePixels EQU $7970

; Seven bonus phases: 1..3 here, 4 at 0040, 5..6 in dead startup code,
; 7 at 6c80 after the packed immutable initial object snapshot.
; Enemy blocks hold the larger 18/19-row frames.
SpriteBonusPixels EQU $7970
SpriteEnemyPixels EQU $7af0
 DS $7f50-$,0
 ORG $7f50
SpriteCacheAddressBody:
 ld a,(SpriteCacheIndex)
 and 7
 dec a
 ld l,a
 ld h,0
 DUP 4
 add hl,hl
 EDUP
 ld a,(SpriteCacheIndex)
 and 8
 jp z,sca_bonus
 add hl,hl
 ld d,h
 ld e,l
 add hl,hl
 add hl,hl
 add hl,de
 ld de,SpriteEnemyPixels
 jp sca_ready
sca_bonus:
 add hl,hl
 add hl,hl
 add hl,hl
 ld de,SpriteBonusPixels
sca_ready:
 add hl,de
 ld (SpriteCacheBuffer),hl
 ret
 INCLUDE "routines/restore_background_tail.asm"
SpriteCacheReset:
 ld hl,SpriteCacheMeta
 ld b,32
 xor a
scr_meta:
 ld (hl),a
 inc hl
 dec b
 jp nz,scr_meta
 ret
SpriteCacheAddress:
 jp SpriteCacheChoose
FastObjectTailEnd:
 ASSERT FastObjectTailEnd <= $8000

