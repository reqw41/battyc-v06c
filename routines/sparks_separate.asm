; B = remaining object records, supplied by call_hl_for_all_obj.
; A spark moves at most 2 pixels/step. Its old/new byte footprints cannot
; meet another spark when |dx| >= 32 OR |dy| >= 13 (max height 11).
; Check retiring objects as well: their old pixels still need clearing.
SparksClassify:
 ld a,(SparksUnsafe)
 or a
 ret nz
 ld hl,(IXobj)
 ld a,(hl)
 cp 7
 jp nz,ss_unsafe
 dec b
 ret z
 inc hl
 inc hl
 ld a,(hl)
 ld (ss_x+1),a
 inc hl
 inc hl
 ld a,(hl)
 ld (ss_y+1),a
 ld de,18
 add hl,de
ss_other:
 ld a,(hl)
 or a
 jp z,ss_next
 cp 7
 jp nz,ss_unsafe
 push hl
 inc hl
 inc hl
 ld a,(hl)
ss_x:
 sub 0
 jp nc,ss_abs_x
 cpl
 inc a
ss_abs_x:
 cp 32
 jp nc,ss_far
 inc hl
 inc hl
 ld a,(hl)
ss_y:
 sub 0
 jp nc,ss_abs_y
 cpl
 inc a
ss_abs_y:
 cp 13
ss_far:
 pop hl
 jp c,ss_unsafe
ss_next:
 ld de,22
 add hl,de
 dec b
 jp nz,ss_other
 ret
ss_unsafe:
 ld a,1
 ld (SparksUnsafe),a
 ret
