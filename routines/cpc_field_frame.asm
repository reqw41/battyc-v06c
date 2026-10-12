; Literal CPC corner/highlight pixels adapted to the existing 8-row top wall.
; Permanent graphics live only in A/C/E. No per-frame repair or save-under.
DrawCpcFieldFrame:
 ld hl,$c0e0
 ld b,32
CpcFrameTopColumn:
 ld de,CpcFrameMiddleTop
 ld a,h
 cp $c0
 jp nz,CpcFrameTopRightCheck
 ld de,CpcFrameLeftTop
CpcFrameTopRightCheck:
 cp $df
 jp nz,CpcFrameTopReady
 ld de,CpcFrameRightTop
CpcFrameTopReady:
 push bc
 ld c,8
CpcFrameTopRow:
 call CpcFramePair
 dec l
 dec c
 jp nz,CpcFrameTopRow
 pop bc
 ld l,$e0
 inc h
 dec b
 jp nz,CpcFrameTopColumn
 ld hl,$c0d8
 ld de,CpcFrameLeftSide
 call CpcFrameSide
 ld hl,$dfd8
 ld de,CpcFrameRightSide
CpcFrameSide:
 ex de,hl
 ld (CpcFrameSideSource+1),hl
 ex de,hl
 ld b,184
CpcFrameSideRow:
CpcFrameSideSource:
 ld de,0
 call CpcFramePair
 dec l
 dec b
 jp nz,CpcFrameSideRow
 ret
CpcFramePair:
 ld a,(de)
 inc de
 ld (hl),a
 push hl
 ld a,h
 sub $20
 ld h,a
 xor a
 ld (hl),a
 ld a,h
 add $40
 ld h,a
 ld a,(de)
 inc de
 ld (hl),a
 pop hl
 ret
