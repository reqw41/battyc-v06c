; НЕ СОБИРАЕТСЯ. Этот файл не подключает ни batty.asm, ни другие
; собираемые файлы: остаток прежнего варианта вывода — локальные группы
; спрайтов и композиция в ОЗУ («три плоскости», THREE-PLANE-LOCAL-
; COMPOSITOR.md).
; Появился в c3bf6bb, 11.10.2026; подключение снято в 75e0011, 11.10.2026 —
; переход на вывод «3+1».
; Текущий вывод — routines/mono_renderer.asm. Оставлен как архив решений:
; при правках игры его не трогать.
; Canonical owner order: bonus, three balls, bullets, bats, enemy, rocket.
CGObjects: dw object_bonus,object_ball_1,object_ball_2,object_ball_3
 dw object_bullet_1,object_bullet_2,object_bat_2,object_bat_1,object_bat_temp
 dw object_enemy,object_rocket
CGSlots: dw $8000,$8080,$80c0,$8100,$8140,$8160,$8180,$8220,$82c0,$8360,$8400
CGCapacity: db 128,64,64,64,32,32,160,160,160,160,224
CGDesc EQU $8b00
CGOld EQU CGDesc+132
CGRect EQU CGOld+66
CGOwners EQU CGRect+44
CGSizes EQU CGOwners ; previous owner IDs consumed before groups are built
CGLabels EQU CGOwners+11
CGFormat EQU CGLabels+11
CGPending EQU CGFormat+1
CGIndex EQU CGPending+1
CGRoot EQU CGIndex+1
CGMembers EQU CGRoot+1
CGDPtr EQU CGMembers+1
CGOPtr EQU CGDPtr+2
CGRectPtr EQU CGOPtr+2
CGColumn EQU CGRectPtr+2
CGTileLow EQU CGColumn+1
CGTileEnd EQU CGTileLow+1
CGColEnd EQU CGTileEnd+1
CGYEnd EQU CGColEnd+1
CGSpanRows EQU CGYEnd+1
CGSpanBG EQU CGSpanRows+1
CGSpanDst EQU CGSpanBG+2
CGTemp EQU CGSpanDst+2
CGTemp2 EQU CGTemp+1
CGRecord EQU CGTemp2+1
CGFallback EQU CGRecord+6
CGVideo EQU CGFallback+1
CGSource EQU CGVideo+2
CGCols EQU CGSource+2
CGRows EQU CGCols+1
CGWhite EQU CGRows+1
CGScratchC EQU $9780
CGScratchE EQU $9880
CGActive EQU CGWhite+1
CGActiveCount EQU CGActive+11
CGActiveI EQU CGActiveCount+1
CGActiveJ EQU CGActiveI+1
 ASSERT CGActiveJ < $8c40
 ASSERT CGDesc/256 == (CGDesc+131)/256
 ASSERT CGOld/256 == (CGOld+65)/256
 ASSERT CGRect/256 == (CGRect+43)/256
 ASSERT $9000+8*176 == $9580
 ASSERT $9580+8*64 == CGScratchC
CGEnsureOrdinary:
 ld a,(CGPending)
 ld b,a
 ld a,(CGFormat)
 or b
 ret z
 call SUInvalidate
 ret
; A=owner; pointers to 12-byte descriptor, six-byte old record, rect.
CGPointers:
 ld (CGIndex),a
 ld e,a
 add a,a
 ld b,a
 add a,e
 add a,a
 ld c,a
 add a,CGOld%256
 ld l,a
 ld h,CGOld/256
 ld (CGOPtr),hl
 ld a,c
 add a,a
 ld l,a
 ld (CGDPtr),hl
 ld a,e
 add a,a
 add a,a
 add a,CGRect%256
 ld l,a
 ld (CGRectPtr),hl
 ld a,b
 ld hl,CGObjects
 call hl_add_a
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (IXobj),hl
 ret
CGLoad:
 ld hl,(CGDPtr)
 ld e,(hl)
 inc hl
 ld d,(hl)
 inc hl
 ld a,(hl)
 ld (direct_columns),a
 inc hl
 ld a,(hl)
 dec a
 add a,e
 ld e,a
 ex de,hl
 ld (plane_dst),hl
 ex de,hl
 inc hl
 inc hl
 inc hl
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (direct_source),hl
 ex de,hl
 inc hl
 ld a,(hl)
 ld (direct_shift),a
 inc hl
 ld a,(hl)
 ld (direct_width),a
 inc hl
 ld a,(hl)
 ld (direct_rows),a
 inc hl
 ld a,(hl)
 ld (color_enemy),a
 ld hl,(IXobj)
 inc hl
 inc hl
 ld a,(hl)
 ld (plane_x),a
 ret

PreparedSetStep:
 ld (pd_step_0+1),a
 ld (pd_step_1+1),a
 ld (pd_step_2+1),a
 ld (pd_step_3+1),a
 ld (pd_step_4+1),a
 ld (pd_step_5+1),a
 ld (pd_step_6+1),a
 ld (pd_step_7+1),a
 ld (pd_step_8+1),a
 ld (pd_step_9+1),a
 ret
CGCaptureVideo:
 ld a,(hl)
 ld (de),a
 inc de
 ld a,h
 sub $20
 ld h,a
 ld a,(hl)
 ld (de),a
 inc de
 ld a,h
 add a,$20
 ld h,a
 dec l
 dec b
 jp nz,CGCaptureVideo
 ret
CGRestoreVideo:
 ld (cgr_video+1),hl
 ex de,hl
 ld (cgr_bg+1),hl
 ld hl,0
 add hl,sp
 ld (cgr_sp+1),hl
cgr_bg:
 ld hl,0
 di
 ld sp,hl
cgr_video:
 ld hl,0
cgr_video_row:
 pop de
 ld (hl),e
 ld a,h
 sub $20
 ld h,a
 ld (hl),d
 ld a,h
 add a,$20
 ld h,a
 dec l
 dec b
 jp nz,cgr_video_row
cgr_sp:
 ld sp,0
 ei
 ret

; Descriptor preparation (including Smash timer) runs exactly once per tick,
; even for oversized editor objects using the compatibility allocator.
CGDrawLegacyPrepared:
 xor a
cglegacy_owner:
 call CGPointers
 ld hl,(CGDPtr)
 inc hl
 inc hl
 ld a,(hl)
 or a
 jp z,cglegacy_next
 call CGLoad
 call SpriteCachePrepare
 call SUSaveObject
 ld a,(SUNoRoom)
 or a
 jp nz,cglegacy_next
 call PaceAccountDraw
 call PreparedDraw
cglegacy_next:
 ld a,(CGIndex)
 inc a
 cp 11
 jp c,cglegacy_owner
 ret
