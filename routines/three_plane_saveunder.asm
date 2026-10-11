; Vanilla 64 KB, no banking. 8000..9fff ignored by both palettes.
; Save each object immediately before drawing; restore in REVERSE draw order.
; Thus saved pixels may contain earlier objects, and reverse restore removes
; all of them correctly even when objects move across each other.
SUObjectPlanes EQU 2
SUData EQU $8000
SUDataEnd EQU $8e00
SUScratch EQU $8e00       ; 448 B scratch, then 64 B cache tags at 8fc0
SUWindowData EQU $9b00   ; 1280 B, fixed 10-column x 40-row x 3-plane window
RCBegin:
 ret
RCFlush:
 ret
RCActive EQU $71b8
SUReset:
 xor a
 ld (SUCount),a
 ld (SUStatic),a
 ld (SUWindowValid),a
 ld (SUNoRoom),a
 ld (SUDropped),a
 ld (RCActive),a
 ld a,2
 ld (SUWorkPlanes),a
 ld hl,SUData
 ld (SUDataNext),hl
 ld hl,SURecords
 ld (SURecordNext),hl
 ld hl,0
 ld (PaceWork),hl
 ret

; Restore all old footprints before a framebuffer background read or change.
; Preserves all registers and flags. Background event paths can invalidate
; early; the next normal planes_begin becomes a no-op, never resurrecting
; a destroyed brick or overwriting an updated magnet.
SUInvalidate:
 push af
 ld a,(SUCount)
 or a
 jp z,sui_empty
 push bc
 push de
 push hl
 ld (SURestoreLeft),a
 ld a,2
 ld (SUWorkPlanes),a
 ld hl,(SURecordNext)
 ld de,-6
 add hl,de
 ld (SURestoreRecord),hl
 xor a
 ld (SUCount),a
sui_next:
 ld hl,(SURestoreRecord)
 ld e,(hl)
 inc hl
 ld d,(hl)
 inc hl
 ld a,(hl)
 ld (SUWorkCols),a
 inc hl
 ld a,(hl)
 ld (SUWorkRows),a
 inc hl
 ex de,hl
 ld (SUWorkDst),hl
 ex de,hl
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (SUWorkData),hl
 ex de,hl
 call PaceAccountRestore
 call SUCopyRestore
 ld hl,(SURestoreRecord)
 ld de,-6
 add hl,de
 ld (SURestoreRecord),hl
 ld a,(SURestoreLeft)
 dec a
 ld (SURestoreLeft),a
 jp nz,sui_next
 ld hl,SUData
 ld (SUDataNext),hl
 ld hl,SURecords
 ld (SURecordNext),hl
 pop hl
 pop de
 pop bc
sui_empty:
 pop af
 ret

SUSaveObject:
 xor a
 ld (SUNoRoom),a
 ld a,2
 ld (SUWorkPlanes),a
 ld a,(direct_rows)
 inc a
 and $fe               ; even footprint enables pairwise POP throughout
 ld (SUWorkRows),a
 ld e,a
 ld d,0
 ld a,(direct_columns)
 ld (SUWorkCols),a
 ld b,a
 ld hl,0
suso_size:
 add hl,de
 dec b
 jp nz,suso_size
 add hl,hl              ; bytes = 2 * cols * even rows
 ex de,hl
 ld hl,(SUDataNext)
 ex de,hl
 add hl,de
 ld a,h
 cp SUDataEnd/256
 jp c,suso_fits
 jp nz,suso_no_room
 ld a,l
 or a
 jp nz,suso_no_room
suso_fits:
 ld (SUDataNext),hl
 ex de,hl
 ld (SUWorkData),hl
 ex de,hl
 ld hl,(plane_dst)
 ld a,(SUWorkRows)
 ld b,a
 ld a,l
 sub b
 inc a
 ld l,a                ; contiguous ascending addresses from bottom
 ld (SUWorkDst),hl
 ex de,hl
 ld hl,(SURecordNext)
 ld (hl),e
 inc hl
 ld (hl),d
 inc hl
 ld a,(SUWorkCols)
 ld (hl),a
 inc hl
 ld a,(SUWorkRows)
 ld (hl),a
 inc hl
 push hl
 ld hl,(SUWorkData)
 ex de,hl
 pop hl
 ld (hl),e
 inc hl
 ld (hl),d
 inc hl
 ld (SURecordNext),hl
 ld a,(SUCount)
 inc a
 ld (SUCount),a
 jp SUCopySave
suso_no_room:
 ld a,1
 ld (SUNoRoom),a
 ld a,(SUDropped)
 inc a
 ld (SUDropped),a
 ret

; Pairwise source-SP copy. SP spans the complete object, never CALL/PUSH
; while hijacked; restore before EI. C/E planes, column-major, bottom-up.
SUCopySave:
 ld hl,0
 add hl,sp
 ld (SUCopySP),hl
 ld hl,(SUWorkDst)
 ld (SUPlaneDst),hl
 ld hl,(SUWorkData)
 ld (sus_buf+1),hl
 ld a,(SUWorkRows)
 or a
 rra
 ld c,a
 add a,a
 add a,a
 add a,c               ; 5 bytes per unrolled POP/write pair
 ld c,a
 ld a,sus_words_end%256
 sub c
 ld l,a
 ld a,sus_words_end/256
 sbc a,0
 ld h,a
 ld (sus_dispatch+1),hl
 ld a,(SUWorkPlanes)
 ld (SUPlane),a
 di
sus_plane:
 ld hl,(SUPlaneDst)
 ld (sus_video+1),hl
 ld a,(SUWorkCols)
 ld b,a
sus_col:
sus_video:
 ld hl,0
 ld sp,hl
sus_buf:
 ld hl,0
sus_dispatch:
 jp sus_words_end
 DUP 32
 pop de
 ld (hl),e
 inc hl
 ld (hl),d
 inc hl
 EDUP
sus_words_end:
 ld (sus_buf+1),hl
 ld hl,(sus_video+1)
 inc h
 ld (sus_video+1),hl
 dec b
 jp nz,sus_col
 ld hl,(SUPlaneDst)
 ld a,h
 sub $20
 ld h,a
 ld (SUPlaneDst),hl
 ld a,(SUPlane)
 dec a
 ld (SUPlane),a
 jp nz,sus_plane
 ld hl,(SUCopySP)
 ld sp,hl
 ei
 ret
