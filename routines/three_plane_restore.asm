SUCopyRestore:
 ld hl,0
 add hl,sp
 ld (SUCopySP),hl
 ld hl,(SUWorkDst)
 ld (SUPlaneDst),hl
 ld a,(SUWorkRows)
 or a
 rra
 ld c,a
 add a,a
 add a,a
 add a,c
 ld c,a
 ld a,sur_words_end%256
 sub c
 ld l,a
 ld a,sur_words_end/256
 sbc a,0
 ld h,a
 ld (sur_dispatch+1),hl
 ld a,(SUWorkPlanes)
 ld (SUPlane),a
 ld hl,(SUWorkData)
 di
 ld sp,hl
sur_plane:
 ld hl,(SUPlaneDst)
 ld a,(SUWorkCols)
 ld b,a
sur_col:
sur_dispatch:
 jp sur_words_end
 DUP 32
 pop de
 ld (hl),e
 inc l
 ld (hl),d
 inc l
 EDUP
sur_words_end:
 ld a,(SUWorkDst)
 ld l,a
 inc h
 dec b
 jp nz,sur_col
 ld hl,(SUPlaneDst)
 ld a,h
 sub $20
 ld h,a
 ld (SUPlaneDst),hl
 ld a,(SUPlane)
 dec a
 ld (SUPlane),a
 jp nz,sur_plane
 ld hl,(SUCopySP)
 ld sp,hl
 ei
 ret

SUWindowSetup:
 ; Cold overlay saves all three planes, including coloured menu text.
 ld a,3
 ld (SUWorkPlanes),a
 ld hl,$8158
 call screen_addr_calc
 ld a,h
 add a,$20
 ld h,a
 ld (ClearDst),hl
 ld a,l
 sub 39
 ld l,a
 ld (SUWorkDst),hl
 ld a,10
 ld (SUWorkCols),a
 ld (ClearColumns),a
 ld a,40
 ld (SUWorkRows),a
 ld (ClearRows),a
 ld hl,SUWindowData
 ld (SUWorkData),hl
 ret
SUWindowSave:
 call SUInvalidate
 call SUWindowSetup
 call SUCopySave
 ld a,1
 ld (SUWindowValid),a
 jp FastErasePlain
SUWindowRestore:
 ld a,(SUWindowValid)
 or a
 ret z
 call SUInvalidate
 call SUWindowSetup
 call SUCopyRestore
 xor a
 ld (SUWindowValid),a
 ld (OverlayActive),a
 ret
